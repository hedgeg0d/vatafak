module main
import os
import strconv
import gg
import gx

struct GameConfig {
mut:
	win_width	int
	win_height	int
	win_title	string
	m_width		int
	m_height	int
	tape_size	int
	mem_start	int
	tape_start	int
	debug		bool
	clean_buff	bool = true
}

struct BfState {
mut:
    mem        []u8
    ptr         int
    code        string
    input       []u8
    input_ptr   int
    last        int
    out         string
}

struct FuncList {
mut:
	on_frame		int = -1
	on_frame_code	string
	on_event		int = -1
	on_event_code	string
	init			int = -1
	init_code		string
}

struct App {
mut:
	gg			&gg.Context = unsafe { nil }
	bf			BfState
	conf		GameConfig
	code		[]string
	fl			FuncList
}

const special_buffer_size 	= 27
const version				= "0.0.1"

fn (mut app App) dbg(msg string, is_critical bool) {
	if !app.conf.debug {return}
	if is_critical {eprintln(('\x1b[31m${msg}x1b[0m')); return}
	eprintln(msg)
}

fn (mut app App) scan_funcs() {
	mut awaiting := ''
	for n, line in app.code {
		match line {
			'on_frame' {
				if awaiting != '' {panic('line ${n+1}: unable to declare function inside ${awaiting}.')}
				if app.fl.on_frame == -1 {app.fl.on_frame = n+1; awaiting = line}
				else {panic('line ${n+1}: redifinition of ${line} function.')}
			}
			'on_event' {
				if awaiting != '' {panic('line ${n+1}: unable to declare function inside ${awaiting}.')}
				if app.fl.on_event == -1 {app.fl.on_event = n+1; awaiting = line}
				else {panic('line ${n+1}: redifinition of ${line} function.')}
			}
			'init' {
				if awaiting != '' {panic('line ${n+1}: unable to declare function inside ${awaiting}.')}
				if app.fl.init == -1 {app.fl.init = n+1; awaiting = line}
				else {panic('line ${n+1}: redifinition of ${line} function.')}
			}
			'end' {
				if awaiting == '' {panic('line ${n+1}: unrecognized end.')} else {
					match awaiting {
						'on_frame' {
							for code_line in app.code[app.fl.on_frame..n] {app.fl.on_frame_code += code_line}
						}
						'on_event' {
							for code_line in app.code[app.fl.on_event..n] {app.fl.on_event_code += code_line}
						}
						'init' {
							for code_line in app.code[app.fl.init..n] {app.fl.init_code += code_line}
						}
						else {panic('line ${n+1}: end of the unrecognized function ${awaiting}')}
					}
					awaiting = ''
				}
			}
			else {}
		}
	}
}

fn u8_to_color(byte_value u8) gx.Color {
    red := (byte_value >> 5) * 32
    green := ((byte_value & 0b11100) >> 2) * 32
    blue := (byte_value & 0b11) * 64

    return gx.rgb(red, green, blue)
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.mouse_down {
			mw, mh := app.conf.m_width, app.conf.m_height
			cw, ch := app.conf.win_width / mw, app.conf.win_height / mh
			x := int(e.mouse_x / cw)
			y := int(e.mouse_y / ch)
			app.bf.ptr = app.conf.mem_start
			app.bf.code = app.fl.on_event_code
			app.bf.mem[app.conf.mem_start+11] = 1
			app.bf.mem[app.conf.mem_start+12] = if e.mouse_button == .right {u8(1)} else {u8(0)}
			app.bf.mem[app.conf.mem_start+13] = u8(x / 256)
			app.bf.mem[app.conf.mem_start+14] = u8(x % 256)
			app.bf.mem[app.conf.mem_start+15] = u8(y / 256)
			app.bf.mem[app.conf.mem_start+16] = u8(y % 256)
			app.run(app.conf.mem_start-1, app.bf.mem.len)
		}
		.mouse_up {}
		.key_down {
			app.bf.ptr = app.conf.mem_start
			app.bf.code = app.fl.on_event_code
			app.bf.mem[app.conf.mem_start+12] = u8(e.key_code)
			app.run(app.conf.mem_start-1, app.bf.mem.len)
		}
		.resized, .restored, .resumed {}
		else {}
	}
}

fn init(mut app App) {
	app.bf.mem = []u8{cap: app.conf.tape_size, len: app.conf.tape_size, init: 0}
	app.bf.ptr = app.conf.m_width + app.conf.m_height
	app.bf.ptr = app.conf.mem_start
	app.bf.code = app.fl.init_code
	app.run(app.conf.mem_start-1, app.bf.mem.len)
}

fn frame(mut app App) {
	app.gg.begin()
	app.bf.code = app.fl.on_frame_code
	app.bf.ptr = 0
	app.run(-1, app.conf.mem_start)
	mut x, mut y := 0, 0
	mw, mh := app.conf.m_width, app.conf.m_height
	cw, ch := app.conf.win_width / mw, app.conf.win_height / mh
	for i in 0.. mw * mh {
		app.gg.draw_rect_filled(x, y, cw, ch, u8_to_color(app.bf.mem[i]))
		if app.conf.clean_buff {app.bf.mem[i] = 0}
		x += cw; if (i+1) % mw == 0 {x = 0; y += ch}
	}
	app.gg.end()
}

fn main() {
	args := os.args
	mut config_file := ''
	mut source_file := ''
	if args.len > 1 {
		match args[1] {
			'man' {eprintln('Docs were moved to https://github.com/hedgeg0d/vatafak/blob/main/docs/docs.md')}
			'help' {
				eprintln('\nVatafak is a VM for the Brainfuck programming language, which can be used to create something interesting in it. Standart Brainfuck' +
				'is very limited, so Vatafak extends its capabilities and adds some new fetures.\n\nTo get started you will need to read the documentation: ' +
				'vatafak man\n\nTo create new project: vatafak new <project name>\n\nTo run the application use: vatafak <project path>\n Example: vatafak .\n\nOther' +
				' supported command:\ngen-config - generates project config file, which can be used as a template.\n\n\nVersion: ${version}')
				exit(0)
			}
			'new' {
				if args.len < 3 {eprintln('Error: project name is required.\n\nvatafak new <name>\n\n')}
				os.mkdir_all(args[2], os.MkdirParams{}) or {eprintln('Error: failed to create folder ${args[2]}.'); exit(0)}
				os.chdir(args[2]) or {eprintln('Error: failed creating new project'); exit(0)}
				os.write_file('main.conf','window_width 700\nwindow_height 700\nwindow_title Demo\nmatrix_width 7\nmatrix_height 7' +
				'\ntape_size 100\ndebug_output true\nclean_framebuffer true')
				or {eprintln('Error: failed to generate config file'); exit(0)}
				os.write_file('main.vtf', 'init\n\nend\n\non_frame\n\nend\n\non_event\n\nend\n')
				or {eprintln('Error: failed to generate source file'); exit(0)}
				eprintln('\nProject ${args[2]} succesfully created!\n')
				exit(0)
			}
			'gen-config' {
				os.write_file('main.conf','window_width 700\nwindow_height 700\nwindow_title Demo\nmatrix_width 7\nmatrix_height 7\ntape_size 100\ndebug_output true')
				or {eprintln('Error: failed to generate config file'); exit(0)}
			}
			else {
				os.chdir(args[1]) or {
					eprintln('Error: Vatafak requires a valid path to a project. To get a guide on how to use it, use the command:\n\nvatafak help\n\n')
					exit(0)
				}
				entries := os.ls('.') or {eprintln('failed to ls'); exit(0)}
				for entry in entries {
					if !os.is_dir(os.join_path(os.home_dir(), entry)) {
						if entry.ends_with('.conf') {if config_file == '' {config_file = entry}}
						else if entry.ends_with('.vtf') {source_file = entry}
					}
				}
			}
		}
	}
	mut lines := []string{}
	if os.exists(config_file) {lines = os.read_lines(config_file) or {exit(0)}}
	mut conf := GameConfig{}
	for n, line in lines {
		if line.trim_space() == '' {continue}
		parts := line.split(' ')
		if parts.len < 2 {println('Unrecognized line ${n+1}.'); continue}
		match parts[0] {
			'window_width' {
				val := strconv.atoi(parts[1]) or {-1}
				if val > 0 {conf.win_width = val}
				else {println('invalid value for ${parts[0]}')}
			}
			'window_height' {
				val := strconv.atoi(parts[1]) or {-1}
				if val > 0 {conf.win_height = val}
				else {println('invalid value for ${parts[0]}')}
			}
			'matrix_width' {
				val := strconv.atoi(parts[1]) or {-1}
				if val > 0 {conf.m_width = val}
				else {println('invalid value for ${parts[0]}')}
			}
			'matrix_height' {
				val := strconv.atoi(parts[1]) or {-1}
				if val > 0 {conf.m_height = val}
				else {println('invalid value for ${parts[0]}')}
			}
			'tape_size' {
				val := strconv.atoi(parts[1]) or {-1}
				if val > 1 {conf.tape_size = val}
				else {println('invalid value for ${parts[0]}')}
			}
			'window_title' {
				if parts[1].len > 0 {conf.win_title = parts[1]} else {conf.win_title = "Vatafak Game"}
			}
			'debug_output' {
				if parts[1] == 'true' {conf.debug = true}
			}
			'clean_framebuffer' {
				if parts[1] == 'false' {conf.clean_buff = false}
			}
			else {println('Unrecognized setting on line ${n+1}: ${parts[0]}.')}
		}
	}
	conf.tape_size = conf.m_width * conf.m_height + conf.tape_size + special_buffer_size
	conf.mem_start = conf.m_width * conf.m_height
	conf.tape_start = conf.mem_start + special_buffer_size
	mut app := &App{}
	app.conf = conf
	if os.exists(source_file) {app.code = os.read_lines(source_file)or{['']}; app.scan_funcs()}
	else {println('Game source code was not find. Use\n\nvatafak man\n\nfor guide how to write games using vatafak.')}
	app.gg = gg.new_context(
		bg_color: gx.black
		width: conf.win_width
		height: conf.win_height
		window_title: conf.win_title
		event_fn: on_event
		frame_fn: frame
		init_fn: init
		user_data: app
	)
	if config_file != '' {app.gg.run()}
}
