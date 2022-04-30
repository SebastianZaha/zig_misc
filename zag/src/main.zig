// https://wiki.osdev.org/Bare_Bones

const std = @import("std");
const terminal = @import("terminal.zig");
const x86 = @import("arch_x86.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

const ALIGN = (1 << 0);
const MEMINFO = (1 << 1);
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

export var multiboot align(4) linksection(".multiboot") = MultiBoot {
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, kmain, .{});
    
    x86.halt();
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    terminal.setColor(terminal.VGA_COLOR_RED);
    terminal.write("\n#####################################################################\n");
    terminal.write("KERNEL PANIC: ");
    terminal.write(msg);
    terminal.write("\n#####################################################################\n");
    
    x86.stop();
}

fn kmain() void {
    terminal.initialize();
    terminal.write("Booting kernel, built with Zig version ");
    terminal.write(std.fmt.comptimePrint("{}", .{std.builtin.zig_version}));
    terminal.write("\n");

    gdt.initialize();
    idt.initialize();

    x86.halt();
}
