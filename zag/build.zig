const std = @import("std");
const Builder = std.build.Builder;
const builtin = std.builtin;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zag", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(std.zig.CrossTarget {
        .cpu_arch = std.Target.Cpu.Arch.i386,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    });
    exe.setLinkerScriptPath("src/linker.ld");
    exe.setOutputDir(b.cache_root);
    
    exe.addAssemblyFile("src/interrupts.s");

    exe.install();


    b.default_step.dependOn(&exe.step);

    const qemu = b.step("qemu", "Run the OS in qemu");
    const run_qemu = b.addSystemCommand(&[_][]const u8{
        "D:\\Program Files\\qemu\\qemu-system-i386.exe",
        "-kernel",
        b.fmt("{s}\\zag", .{b.cache_root}),
    });
    qemu.dependOn(&run_qemu.step);
    run_qemu.step.dependOn(&exe.step);
}