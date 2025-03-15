module main

import rand
import math

fn (mut app App) handle_call() {
	match app.bf.mem[app.conf.mem_start] {
		0 {
			pos := app.bf.mem[app.conf.mem_start + 1]
			if pos > app.bf.mem.len - 1 {
				app.dbg('index ${pos} out of bounds!', true)
				return
			}
			app.dbg('idx: ${app.bf.mem[app.conf.mem_start + 1]} val: ${app.bf.mem[
				app.bf.mem[app.conf.mem_start + 1] + app.conf.mem_start]}' + 
				'\n firt 10 cells: ${app.bf.mem[app.conf.mem_start..app.conf.mem_start+10]}', false)
		}
		1 {
			x1, x2, y1, y2, color := app.bf.mem[app.conf.mem_start + 1], app.bf.mem[
				app.conf.mem_start + 2], app.bf.mem[app.conf.mem_start + 3], app.bf.mem[
				app.conf.mem_start + 4], app.bf.mem[app.conf.mem_start + 5]
			x := int(x1) * 256 + x2
			y := int(y1) * 256 + y2
			if x > app.conf.m_width || y > app.conf.m_height {
				app.dbg('invalid pixel cord. x: ${x}  y: ${y}', false)
				return
			}
			app.bf.mem[y * app.conf.m_width + x] = color
		}
		2 {
			x1, x2, y1, y2, w1, w2, h1, h2, color := app.bf.mem[app.conf.mem_start + 1], app.bf.mem[
				app.conf.mem_start + 2], app.bf.mem[app.conf.mem_start + 3], app.bf.mem[
				app.conf.mem_start + 4], app.bf.mem[app.conf.mem_start + 5], app.bf.mem[
				app.conf.mem_start + 6], app.bf.mem[app.conf.mem_start + 7], app.bf.mem[
				app.conf.mem_start + 8], app.bf.mem[app.conf.mem_start + 9]
			x := int(x1) * 256 + x2
			y := int(y1) * 256 + y2
			w := int(w1) * 256 + w2
			h := int(h1) * 256 + h2
			if x > app.conf.m_width || y > app.conf.m_height {
				app.dbg('invalid start cord. x: ${x}  y: ${y}', false)
				return
			}
			if x + w > app.conf.m_width || y + h > app.conf.m_height {
				app.dbg('rect out of bounds. x: ${x + w}  y: ${y + h}', false)
				return
			}
			for cy in y .. y + h {
				for cx in x .. x + w {
					app.bf.mem[cy * app.conf.m_width + cx] = color
				}
			}
		}
		3 {
			pos, from, to := app.bf.mem[app.conf.mem_start + 1], app.bf.mem[app.conf.mem_start + 2], app.bf.mem[
				app.conf.mem_start + 3]
			if from == to {
				if from == 0 {
					app.bf.mem[app.conf.mem_start + pos] = rand.u8()
					return
				}
				app.dbg('invalid rand diaposon: [${from}; ${to})', true)
			} else {
				app.bf.mem[app.conf.mem_start + pos] = u8(rand.int_in_range(from, to) or { 0 })
			}
		}
		4 {
			app.dbg('Exiting (call ${app.bf.mem[app.conf.mem_start]})', false)
			app.gg.quit()
		}
		5 {
			x1, x2, y1, y2, r1, r2, filled, color :=
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4],
				app.bf.mem[app.conf.mem_start + 5],
				app.bf.mem[app.conf.mem_start + 6],
				app.bf.mem[app.conf.mem_start + 7] > 0,
				app.bf.mem[app.conf.mem_start + 8]
			x := int(x1) * 256 + x2
			y := int(y1) * 256 + y2
			if x > app.conf.m_width || y > app.conf.m_height {
				app.dbg('invalid start cord. x: ${x}  y: ${y}', false)
				return
			}
			//eprintln("x: ${x} y ${y} r: ${r1*256 + r2} w: ${app.conf.m_width} filled: $filled color: ${color}")
			cords := gen_circle(x, y, r1*256 + r2, app.conf.m_width, filled)
			for cord in cords{if cord < app.conf.mem_start && cord > 0 {app.bf.mem[cord] = color}}
		}
		10 {
			from, to := app.bf.mem[app.conf.mem_start + 1], app.bf.mem[app.conf.mem_start + 2]
			app.bf.mem[app.conf.mem_start + to] = app.bf.mem[app.conf.mem_start + from]
			app.bf.mem[app.conf.mem_start + to - 1] = app.bf.mem[app.conf.mem_start + from - 1]
			app.bf.mem[app.conf.mem_start + to - 1] = 0
			app.bf.mem[app.conf.mem_start + to] = 0
		}
		11 {
			from, to := app.bf.mem[app.conf.mem_start + 1], app.bf.mem[app.conf.mem_start + 2]
			app.bf.mem[app.conf.mem_start + to] = app.bf.mem[app.conf.mem_start + from]
			app.bf.mem[app.conf.mem_start + to - 1] = app.bf.mem[app.conf.mem_start + from - 1]
		}
		12 {
			n11, n12, n21, n22 := 
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4]
			n1 := int(int(n11) * 256) + n12
			n2 := int(int(n21) * 256) + n22
			if n1 > n2 {app.bf.mem[app.conf.mem_start + 16] = 1}
			else if n1 == n2 {app.bf.mem[app.conf.mem_start + 16] = 2}
			else {app.bf.mem[app.conf.mem_start + 16] = 0}
		}
		13 {
			n11, n12, n21, n22 := 
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4]
			res := (int(int(n11) * 256) + n12) + (int(int(n21) * 256) + n22)
			app.bf.mem[app.conf.mem_start + 1] = u8(res / 256)
			app.bf.mem[app.conf.mem_start + 2] = u8(res % 256)
		}
		14 {
			n11, n12, n21, n22 := 
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4]
			res := (int(int(n11) * 256) + n12) - (int(int(n21) * 256) + n22)
			app.bf.mem[app.conf.mem_start + 1] = u8(res / 256)
			app.bf.mem[app.conf.mem_start + 2] = u8(res % 256)
		}
		15 {
			n11, n12, n21, n22 := 
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4]
			res := (int(int(n11) * 256) + n12) * (int(int(n21) * 256) + n22)
			app.bf.mem[app.conf.mem_start + 1] = u8(res / 256)
			app.bf.mem[app.conf.mem_start + 2] = u8(res % 256)
		}
		16 {
			n11, n12, n21, n22 := 
				app.bf.mem[app.conf.mem_start + 1],
				app.bf.mem[app.conf.mem_start + 2],
				app.bf.mem[app.conf.mem_start + 3],
				app.bf.mem[app.conf.mem_start + 4]
			res := (int(int(n11) * 256) + n12) / (int(int(n21) * 256) + n22)
			app.bf.mem[app.conf.mem_start + 1] = u8(res / 256)
			app.bf.mem[app.conf.mem_start + 2] = u8(res % 256)
		}
		else {}
	}
}

fn gen_circle(x int, y int, r int, w int, filled bool) []int {
    mut points := []int{}

    if filled {
        for i in 0 .. r + 1 {
            for j in 0 .. 360 {
                angle := j * math.pi / 180.0
                px := x + int(i * math.cos(angle))
                py := y + int(i * math.sin(angle))
                points << px + py * w
            }
        }
    } else {
        for i in 0 .. 360 {
            angle := i * math.pi / 180.0
            px := x + int(r * math.cos(angle))
            py := y + int(r * math.sin(angle))
            points << px + py * w 
        }
    }

    return points
}