const std = @import("std");

const Cli = @import("Cli.zig");
const Logger = @import("Logger.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var cli = Cli.init(allocator);
    defer cli.deinit();

    try cli.addArgs();
    const args = try cli.parseAndValidateArgs();

    Logger.global_level = args.log_level;

//    const stdout_file = std.io.getStdOut().writer();
//    var logger = Logger.new(stdout_file, Logger.global_level);
}

test "emit methods docs" {
    std.testing.refAllDecls(@This());
}
