module main

struct BfState {
mut:
	mem       []u8
	ptr       int
	code      string
	input     []u8
	input_ptr int
	last      int
	out       string
}

/*fn (mut app App) run_byte(limit_left int, limit_right int, byte_code []u8) {
	mut loop_stack := []int{}
	code_len := byte_code.len
	mut awaiting_operator := false
	mut counter := 0
	mut byte_order := 0
	for i in byte_code {
		if i == 0 {awaiting_operator = true; continue}
		if !awaiting_operator {
			counter += i * int(math.powi(256, byte_order))
			byte_order++
		} else {
			print('$counter${i.ascii_str()} ')
			match i {
				`>` {
					app.bf.ptr += counter
					if app.bf.ptr >= limit_right {
						app.bf.ptr = limit_left + (app.bf.ptr - (limit_right - 1))
					}
				}
				`<` {
					app.bf.ptr -= counter
					if app.bf.ptr <= limit_left {
						app.bf.ptr = limit_right - (math.abs(app.bf.ptr) - (limit_left+1))
					}
				}
				`+` {

				}
				else {}
			}
			counter = 0
			byte_order = 0
			awaiting_operator = false
		}
	}
}*/
//@[direct_array_access]
fn (mut app App) run(limit_left int, limit_right int) {
	mut loop_stack := []int{}
	code_len := app.bf.code.len
	mut iterations := [][2]int{}
	for i := 0; i < code_len; i++ {
		cmd := app.bf.code[i]
		match cmd {
			`>` {
				if app.bf.ptr + 1 != limit_right {
					app.bf.ptr++
				} else {
					app.bf.ptr = limit_left + 1
				}
			}
			`<` {
				if app.bf.ptr - 1 != limit_left {
					app.bf.ptr--
				} else {
					app.bf.ptr = limit_right - 1
				}
			}
			`+` {
				app.bf.mem[app.bf.ptr] = (app.bf.mem[app.bf.ptr] + 1) % 256
				if app.bf.ptr > app.conf.mem_start + 17 && app.bf.ptr < app.conf.mem_start + 27
					&& (app.bf.ptr - app.conf.mem_start) % 2 == 0 && app.bf.mem[app.bf.ptr] == 0 {
					app.bf.mem[app.bf.ptr - 1]++
				}
			}
			`-` {
				app.bf.mem[app.bf.ptr] = (app.bf.mem[app.bf.ptr] - 1) % 256
				if app.bf.ptr > app.conf.mem_start + 17 && app.bf.ptr < app.conf.mem_start + 27
					&& (app.bf.ptr - app.conf.mem_start) % 2 == 0 && app.bf.mem[app.bf.ptr] == 255 {
					app.bf.mem[app.bf.ptr - 1]--
				}
			}
			`.` {
				if app.bf.ptr != app.conf.mem_start {
					// app.bf.out += app.bf.mem[app.bf.ptr].ascii_str()
					// eprintln(app.bf.out)
					eprint(app.bf.mem[app.bf.ptr].ascii_str())
				} else {
					app.handle_call()
				}
			}
			`[` {
				if i + 2 < code_len && app.bf.code[i + 1] == `-` && app.bf.code[i + 2] == `]` {
					app.bf.mem[app.bf.ptr] = 0
					i += 2
					continue
				}
				if app.bf.mem[app.bf.ptr] == 0 {
					mut open_brackets := 1
					for open_brackets > 0 && i + 1 < app.bf.code.len {
						i++
						if app.bf.code[i] == `[` {
							open_brackets++
						} else if app.bf.code[i] == `]` {
							open_brackets--
						}
					}
					if open_brackets != 0 {
						app.dbg('invalid loop', true)
						return
					}
				} else {
					mut found := -1
					for n, j in iterations {
						if j[0] == i {
							found = n
						}
					}
					if found != -1 {
						iterations[found][1]++
						if iterations[found][1] > 257 {
							app.dbg('endless loop', true)
							return
						}
					} else {
						iterations << [i, 0]!
					}
					loop_stack << i
				}
			}
			`]` {
				if loop_stack.len > 0 && app.bf.mem[app.bf.ptr] != 0 {
					i = loop_stack.last()
				} else if loop_stack.len > 0 {
					loop_stack.delete_last()
				}
			}
			`*` {
				app.bf.ptr = app.conf.mem_start
			}
			`/` {
				app.bf.ptr = 0
			}
			`_` {
				app.bf.ptr = app.conf.tape_start
			}
			else {}
		}
	}
}

const allowed_chars = [`+`, `-`, `>`, `<`, `[`, `]`, `,`, `.`, `/`, `*`, `_`]

fn separate_bf(line string) string {
	mut bf := []u8{}
	for c in line {
		if c == `#` { break }
		if c in allowed_chars {
			bf << c
		}
	}
	return bf.bytestr()
}

fn compress_bf(input string) []u8 {
	mut result := []u8{}
	mut count := 1
	mut last_char := u8(0)
	for i in 0 .. input.len {
		c := input[i]
		if c == last_char {count++}
		else {
			if last_char != 0 {
				result << encode_count(count)
				result << last_char
			}
			last_char = c
			count = 1
		}
	}
	if last_char != 0 {
		result << encode_count(count)
		result << last_char
	}
	return result
}

fn encode_count(c int) []u8 {
	mut count := c
	mut bytes := []u8{}
	mut byte_count := 0
	for count > 0 {
		count >>= 8
		byte_count++
	}
	count = c
	for i in 0 .. byte_count {bytes << u8((count >> ((byte_count - 1 - i) * 8)) & 0xFF)}
	bytes << u8(0)
	return bytes
}
