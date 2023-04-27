const std = @import("std");
const Gpa = std.heap.GeneralPurposeAllocator(.{});

const Cli = @import("cmd/Cli.zig");
const Logger = @import("pkg/Logger.zig");

pub fn main() !void {
    var gpa = Gpa{};
    defer _ = gpa.deinit();

    var cli = Cli.init(gpa.allocator());
    defer cli.deinit();

    try cli.addArgs();
    const args = cli.parseAndValidateArgs() catch |err| {
        if (err == Cli.Error.MissingRequiredArgs) {
            var logger = Logger.new(Logger.global_file, Logger.global_level);
            try logger.err("Missing required arguments. See usage above.", .{});
            return;
        } else return err;
    };

    Logger.global_level = args.log_level;
    if (args.use_log_file) {
        Logger.global_file = try std.fs.cwd().createFile("zig-representer.log", std.fs.File.CreateFlags{.read = true, .truncate = false});
        try Logger.global_file.seekFromEnd(0);
    }

    // var logger = Logger.new(Logger.global_file, Logger.global_level);
}

test "emit methods docs" {
    std.testing.refAllDeclsRecursive(@This());
}
