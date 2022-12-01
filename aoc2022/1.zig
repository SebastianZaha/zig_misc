const std = @import("std");

pub fn checkMax(max: []usize, current: usize) void {
	if (current > max[0]) {
		max[2] = max[1];
		max[1] = max[0];
		max[0] = current;
	} else if (current > max[1]) {
		max[2] = max[1];
		max[1] = current;
	} else if (current > max[0]) {
		max[0] = current;
	}
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
	defer {
		const leaked = gpa.deinit();
		if (leaked) @panic("mem leak");
	}
    
	const example = try std.fs.cwd().readFileAlloc(allocator, "1_input.txt", 10*1024*1024);
	defer allocator.free(example);

	const stdout = std.io.getStdOut().writer();

	var max: [3]usize = .{0,0,0};
	var current: usize = 0;

	var it = std.mem.split(u8, example, "\n");
	while (it.next()) |line| {
		if (line.len == 0) {
			checkMax(&max, current);
			current = 0;
		} else {
			current += try std.fmt.parseInt(usize, line, 10);
		}
	}
	checkMax(&max, current);

    try stdout.print("max: {}+{}+{} = {}!\n", .{max[0], max[1], max[2], max[0]+max[1]+max[2]});
}
