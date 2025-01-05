import os
import strconv
import math

fn color_to_u8(r int, g int, b int) u8 {
    r_index := r / 32
    g_index := g / 32
    b_index := b / 64
    return u8((r_index << 5) | (g_index << 2) | b_index)
}

fn find_pair(n int) (int, int) {
	sqrtn := int(math.sqrt(n))
	for i := sqrtn; i >= 2; i-- {
		if n % i == 0 {return i32(i), i32(n / i)}
	}
	return 0, 0
}

fn craft_num(num u8) string {
	mut ret := ''
	if num < 12 {ret += "+".repeat(num)}
	else {
		mut first, mut second := find_pair(num)
		if first != 0 && second != 0 {
			ret += '>' + '+'.repeat(first) + '[-<' + '+'.repeat(second)+'>]'
		} else {
			first, second = find_pair(num-1)
			ret += '>' + '+'.repeat(first) + '[-<' + '+'.repeat(second)+'>]<+>'
		}
	}
	return ret + '\n'
}

fn main() {
	args := os.args
	if args.len < 2 {eprintln('specify ppm image'); exit(0)}
	lines := os.read_lines(args[1]) or {panic(err)}
	if lines[0] != 'P3' || lines[1] != '100 100' {eprintln('P3 ppm image 100x100 required.'); exit(0)}
	os.mkdir('${args[1].split('.')[0]}') or {eprintln('failed to create folder ${args[1].split('.')[0]}'); exit(0)}
	os.chdir('${args[1].split('.')[0]}') or {panic(err); exit(0)}
	if os.exists('${args[1].split('.')[0]}.vtf') {os.rm(args[1].split('.')[0]+'.vtf') or {panic(err)}}
	mut of := os.create('${args[1].split('.')[0]}.vtf') or {panic(err)}
	of.write_string('init\n/') or {print('')}
	for line in lines[3..] {
		parts := line.split(' ')
		if parts.len == 3 {
			r := strconv.atoi(parts[0]) or {0}
			g := strconv.atoi(parts[1]) or {0}
			b := strconv.atoi(parts[2]) or {0}
			of.write_string(craft_num(color_to_u8(r, g, b))) or {print('')}
		}
	}
	of.write_string('end') or {print('')}
	of = os.create('${args[1].split('.')[0]}.conf') or {panic(err)}
	w, h := strconv.atoi(lines[1].split(' ')[0]) or {0}, strconv.atoi(lines[1].split(' ')[1]) or {0}
	of.write_string('window_width ${w * 5}\n' + 
		'window_height ${h * 5}\n' + 
		'window_title ${args[1].split('.')[0]}\n' +
		'matrix_width ${w}\n' +
		'matrix_height ${h}\n' +
		'tape_size 0\n' +
		'debug_output false\n' +
		'clean_framebuffer false\n') or {panic(err)}
	println('\nProject ${args[1].split('.')[0]} was succesfully created!')
}