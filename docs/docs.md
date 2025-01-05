

# Vatafak Documentation

## Introduction

Vatafak is a virtual machine (VM) for [Brainfuck](https://wikipedia.org/wiki/Brainfuck) which  expands  its  capabilities. The standard Brainfuck, despite being a Turing-complete language, remains very limited in working with the OS, using randomness, and other aspects. Vatafak is an attempt to make the development of applications on Brainfuck more real and easier

## Installing Vatafak from source

The best way to get the latest and greatest Vatafak, is to build it from source. It is easy, and won't take much time:

First, install [V compiler](https://github.com/vlang/v) if you don't have it:
```bash
git clone --depth=1 https://github.com/vlang/v
cd v
make
sudo ./v symlink && cd..
```

Then use it to build Vatafak:

```bash
git clone https://github.com/hedgeg0d/vatafak
cd vatafak
v -prod .
```

## Vatafak project structure

Currently, the Vatafak project consists of 2 files: a configuration file (extension .conf) and a Brainfuck source code file (extension .vtf). To create a project you can use `new` command:
```bash
./vatafak new test_proj
```
This will create a directory `test_proj` with all files required. To run the project use this syntax:
```bash
./vatafak test_proj
```

## Configuration file

Configuration file contains settings, which will be used by Vatafak. The configuration file contains settings that will be used by Vatafak to determine the properties of the window and other aspects of the application.

This section explains the configuration file fields using the [Jumper](https://github.com/hedgeg0d/vatafak/examples/jumper/main.conf) project example.
```
window_width 1000
window_height 1000
window_title BFJumper
matrix_width 100
matrix_height 100
tape_size 100
debug_output false
clean_framebuffer true
```

- `window_width` and `window_height` set app window size. 
- `matrix_width` and `matrix_height` set real resolution, for example if you set matrix to 10x10, and window to 100x100, every matrix cell will be 10x10 pixels on the screen.
- `window_title` sets the window title.
- `tape_size`  specifies size of Brainfuck tape, which will never be used by Vatafak (user space).
- `debug_output` determines whether debug information will be outputted
- `clean_framebuffer` determines whether the frame buffer will be reset after each frame is rendered.

Command `gen-config` can be used to generate template configuration file.

## Vatafak memory structure

Vatafak uses only the Brainfuck tape during operation, its size is determined automatically, accounting the size of the tape from the configuration file.

 1. First, frame buffer size is allocated. For example if matrix is 10x10, frame buffer size is 100 cells.
 2. Then, special buffer is allocated. It is 27 cells long, it's purpose will be described later.
 3. Then follows the user space, size of which is specified in the .conf file.

Since the tape, especially when using a larger matrix, becomes too long, three additional symbols were introduced in addition to the 8 existing in brainfuck before that:

- `/` - sets pointer to 0 (start of frame buffer)
- `*` - sets pointer to first cell of special buffer
- `_` - sets pointer to first cell of user space

### 8-bit color
Each cell of frame buffer represent one tile on screen. The cells are 8-bit, so they can encode one of 256 colors. Vatafak uses [3-3-2 color scheme](https://en.wikipedia.org/wiki/8-bit_color).

## Special buffer
Special buffer is used to interact with Vatafak from Brainfuck code. Its main purpose is to call runtime functions. 

Structure of special buffer:
```
[ 0    1 - 10   11 - 16    17 - 26 ]  
code    args      out     16-bit zone
```
### 16-bit zone
All cells in the Brainfuck tape are 8-bit. But often bigger values are needed. That's why there is 16-bit zone in special buffer. It contain 5 unsigned 16-bit values, each consists of two cells. Even cells in this section are least significant, applying `+` and `-` operators to them, will account most important byte.

Example:
```
17 cell: 0
18 cell: 255
Pointer on 18, applying `+` will result to
17 cell: 1
18 cell: 0 
```
### Runtime functions
To call Vatafak from the code, you need to enter the function code and its arguments in the appropriate cells.
Here is the table of function codes, their arguments and descriptions.

| code | arguments | description |
|--|--|--|
| 0 | idx | if `debug_output` is enabled, prints the value of cell[`idx` + `start_of-special_buffer`] |
| 1 | u16(x x) u16(y y) color|sets the pixel by the coordinates to specified color|
| 2 | u16(x x) u16(y y) u16(w w) u16(h h) color| draws rectangle of specified color and size, on specified coordinates |
| 3 |idx from to| generate random number(u8) in [from; to) diapason ans put it to cell[`idx` + `start_of-special_buffer`]. If from and to arguments are `0`, then diapason will be [0;255] |
| 4 | (no args) | terminate app |
| 10 | from to | move 16-bit value to destination. both args are least significant bytes
| 11 | from to | copy 16-bit value to destination. both args are least significant bytes

### Events
Some events can be processed from Brainfuck, and events can have additional values placed in the out-section. Event code is put to first cell of out-section. All events trigger `on_event` function.
|code| values | description
|--|--|--|
| 0 | keycode | Keyboard key press
| 1 | button u16(cord_x cord_x) u16(cord_y cord_y) | Mouse button down. if right button pressed, `button` is `1`, else `0`

## Writing code
Three functions can be declared in Brainfuck code, which will be called at different times. 
### Function limits
For easier code writing, functions have limitations on the space that can be used. The left and right limits are set. If you move to the left while standing on the leftmost cell, the pointer moves to the right limit, and vice versa. `/`, `*` and `_` operators can be used to ignore them.
### Function declaration rules
the name of the function should be the only text on the line. everything between the name and the word end will refer to this function. Function example:
```
on_frame
+[>-]-
end
```
This  function will fill the screen with white  color  in  each  frame.
| function | limits | when called
|--|--|--|
| init | [`begin_of_special_buffer`; `last_cell_in_tape`] | at app launch
| on_frame | [`0`;`begin_of_special_buffer`)| before drawing frame
| on_event | [`begin_of_special_buffer`; `last_cell_in_tape`] | after every event
