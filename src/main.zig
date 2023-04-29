const std = @import("std");
const Gpa = std.heap.GeneralPurposeAllocator(.{});

const Cli = @import("cmd/Cli.zig");
const Logger = @import("pkg/Logger.zig");
const represent = @import("represent.zig").represent;

pub fn main() !void {
    var gpa = Gpa{};
    defer _ = gpa.deinit();

    var cli = Cli.init(gpa.allocator());
    defer cli.deinit();

    try cli.addArgs();
    const args = cli.parseAndValidateArgs() catch |err| {
        if (err == Cli.Error.MissingRequiredArgs) {
            var logger = Logger.new(Logger.global_file, Logger.global_level);
            try logger.err("Missing required arguments. See options above.", .{});
            return;
        } else return err;
    };

    Logger.global_level = args.log_level;
    if (args.use_log_file) {
        Logger.global_file = try std.fs.cwd().createFile("zig-representer.log", std.fs.File.CreateFlags{.read = true, .truncate = false});
        try Logger.global_file.seekFromEnd(0);
    }

    var logger = Logger.new(Logger.global_file, Logger.global_level);
    try logger.info("Creating representation...", .{});

    represent(gpa.allocator(), args.slug, args.input_dir, args.output_dir) catch |err| {
        try logger.err("Could not create representation: {s}", .{err});
        std.os.exit(1);
    };

    try logger.info("Finished representation.", .{});
}

test "emit methods docs" {
    std.testing.refAllDeclsRecursive(@This());
}
