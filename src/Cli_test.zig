const std = @import("std");
const testing = std.testing;

const Cli = @import("Cli.zig");

test "should add arguments successfully" {
    var cli = Cli.init(testing.allocator);
    defer cli.deinit();

    try cli.addArgs();
}

test "should throw for missing arguments" {
    var cli = Cli.init(testing.allocator);
    defer cli.deinit();

    try testing.expectError(Cli.CliError.MissingArgs, cli.parseAndValidateArgs());
}