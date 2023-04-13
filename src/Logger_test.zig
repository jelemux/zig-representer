const std = @import("std");
const testing = std.testing;
const fs = std.fs;

const Logger = @import("Logger.zig");

test "should parse log-level from string" {
    const lowerDebugLevel = try Logger.Level.fromString("debug");
    try testing.expectEqual(Logger.Level.Debug, lowerDebugLevel);
    const upperDebugLevel = try Logger.Level.fromString("DEBUG");
    try testing.expectEqual(Logger.Level.Debug, upperDebugLevel);

    const lowerInfoLevel = try Logger.Level.fromString("info");
    try testing.expectEqual(Logger.Level.Info, lowerInfoLevel);
    const upperInfoLevel = try Logger.Level.fromString("INFO");
    try testing.expectEqual(Logger.Level.Info, upperInfoLevel);

    const lowerWarnLevel = try Logger.Level.fromString("warn");
    try testing.expectEqual(Logger.Level.Warn, lowerWarnLevel);
    const upperWarnLevel = try Logger.Level.fromString("WARN");
    try testing.expectEqual(Logger.Level.Warn, upperWarnLevel);

    const lowerErrorLevel = try Logger.Level.fromString("error");
    try testing.expectEqual(Logger.Level.Error, lowerErrorLevel);
    const upperErrorLevel = try Logger.Level.fromString("ERROR");
    try testing.expectEqual(Logger.Level.Error, upperErrorLevel);

    try testing.expectError(error.InvalidLogLevel, Logger.Level.fromString("trace"));
}

test "should log with appropriate level" {
    // given
    var tmp_dir = std.testing.tmpDir(fs.Dir.OpenDirOptions{});
    defer tmp_dir.cleanup();

    var log_file = try tmp_dir.dir.createFile("test.log", fs.File.CreateFlags{.read = true});
    defer log_file.close();

    var sut = Logger.new(log_file, .Debug);

    var levels = std.EnumSet(Logger.Level).initFull();
    var level_iter = levels.iterator();

    const expected_line_endings = [_][]const u8{
        "[DEBUG]: this is a debug message",
        "[INFO]: this is a info message",
        "[WARN]: this is a warn message",
        "[ERROR]: this is a error message",
        "[INFO]: this is a info message",
        "[WARN]: this is a warn message",
        "[ERROR]: this is a error message",
        "[WARN]: this is a warn message",
        "[ERROR]: this is a error message",
        "[ERROR]: this is a error message",
    };

    // when
    while (level_iter.next()) |level| {
        sut.setLevel(level);
        try sut.debug("this is a {s} message", .{"debug"});
        try sut.info("this is a {s} message", .{"info"});
        try sut.warn("this is a {s} message", .{"warn"});
        try sut.err("this is a {s} message", .{"error"});
    }

    // then
    try log_file.seekTo(0);

    const allocator = std.testing.allocator;
    const file_content = try log_file.readToEndAlloc(allocator, 545);
    defer allocator.free(file_content);

    var lines = std.mem.split(u8, file_content, "\n");

    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        if (i == 10) {
            try std.testing.expectEqualStrings("", line);

            const expect_eof: ?[]const u8 = null;
            try std.testing.expectEqual(expect_eof, lines.next());

            break;
        }

        try std.testing.expectStringEndsWith(line, expected_line_endings[i]);
    }
}
