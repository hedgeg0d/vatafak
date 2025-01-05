module main

fn (mut app App) run(limit_left int, limit_right int) {
    mut loop_stack := []int{}
    code_len := app.bf.code.len
    mut iterations := [][2]int{}
    for i := 0; i < code_len; i++ {
        cmd := app.bf.code[i]
        match cmd {
            `>` { if app.bf.ptr+1 != limit_right {app.bf.ptr++} else {app.bf.ptr = limit_left + 1} }
            `<` { if app.bf.ptr-1 != limit_left {app.bf.ptr--}  else {app.bf.ptr = limit_right - 1}}
            `+` {
				app.bf.mem[app.bf.ptr] = (app.bf.mem[app.bf.ptr] + 1) % 256  
				if app.bf.ptr > app.conf.mem_start + 17 && app.bf.ptr < app.conf.mem_start + 27 && 
					(app.bf.ptr - app.conf.mem_start) % 2 == 0 && app.bf.mem[app.bf.ptr] == 0 {
					app.bf.mem[app.bf.ptr-1]++
				}
			}
            `-` { 
				app.bf.mem[app.bf.ptr] = (app.bf.mem[app.bf.ptr] - 1) % 256
				if app.bf.ptr > app.conf.mem_start + 17 && app.bf.ptr < app.conf.mem_start + 27 && 
					(app.bf.ptr - app.conf.mem_start) % 2 == 0 && app.bf.mem[app.bf.ptr] == 255 {
					app.bf.mem[app.bf.ptr-1]--
				}
			}
            `.` { 
				if app.bf.ptr != app.conf.mem_start {
					//app.bf.out += app.bf.mem[app.bf.ptr].ascii_str()
					//eprintln(app.bf.out)
					eprint(app.bf.mem[app.bf.ptr].ascii_str())
					}
				else {app.handle_call()}
			}
            `[` {
                if i+2 < code_len && app.bf.code[i+1] == `-` && app.bf.code[i+2] == `]` {
                    app.bf.mem[app.bf.ptr] = 0
                    i += 2
                    continue
                }
                if app.bf.mem[app.bf.ptr] == 0 {
                    mut open_brackets := 1
                    for open_brackets > 0 && i + 1 < app.bf.code.len {
                        i++
                        if app.bf.code[i] == `[` {open_brackets++} 
						else if app.bf.code[i] == `]` {open_brackets--}
                    }
                    if open_brackets != 0 {eprintln("invalid loop");return}
                } else {
                    mut found := -1
                    for n, j in iterations {if j[0] == i {found = n}}
                    if found != -1 {iterations[found][1]++; if iterations[found][1] > 257 {eprintln("endless loop"); return}}
                    else {iterations << [i, 0]!}
                    loop_stack << i
                }
            }
            `]` {
                if loop_stack.len > 0 && app.bf.mem[app.bf.ptr] != 0 {i = loop_stack.last() /* Jump back to the matching `[`*/} 
				else if loop_stack.len > 0 {loop_stack.delete_last()}
            }
			`*` {app.bf.ptr = app.conf.mem_start}
			`/` {app.bf.ptr = 0}
			`_` {app.bf.ptr = app.conf.tape_start}
            else {}
        }
    }
}