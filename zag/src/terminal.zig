// Hardware text mode color constants
pub const VgaColor = u8;
pub const VGA_COLOR_BLACK = 0;
pub const VGA_COLOR_BLUE = 1;
pub const VGA_COLOR_GREEN = 2;
pub const VGA_COLOR_CYAN = 3;
pub const VGA_COLOR_RED = 4;
pub const VGA_COLOR_MAGENTA = 5;
pub const VGA_COLOR_BROWN = 6;
pub const VGA_COLOR_LIGHT_GREY = 7;
pub const VGA_COLOR_DARK_GREY = 8;
pub const VGA_COLOR_LIGHT_BLUE = 9;
pub const VGA_COLOR_LIGHT_GREEN = 10;
pub const VGA_COLOR_LIGHT_CYAN = 11;
pub const VGA_COLOR_LIGHT_RED = 12;
pub const VGA_COLOR_LIGHT_MAGENTA = 13;
pub const VGA_COLOR_LIGHT_BROWN = 14;
pub const VGA_COLOR_WHITE = 15;

fn vga_entry_color(fg: VgaColor, bg: VgaColor) u8 {
    return fg | (bg << 4);
}

fn vga_entry(uc: u8, color: u8) u16 {
    var c: u16 = color;

    return uc | (c << 8);
}

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

var row: usize = 0;
var column: usize = 0;

var currentColor = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);

const buffer = @intToPtr([*]volatile u16, 0xB8000);

pub fn initialize() void {
    var y: usize = 0;
    while (y < VGA_HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            putCharAt(' ', currentColor, x, y);
        }
    }
}


pub fn setColor(new_color: u8) void {
    currentColor = new_color;
}


pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vga_entry(c, new_color);
}


pub fn putChar(c: u8) void {

    if (c == '\n') {
        row +=1;
        column = 0;
        return;
    }

    putCharAt(c, currentColor, column, row);
    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}


pub fn write(data: []const u8) void {
    for (data) |c|
        putChar(c);
}