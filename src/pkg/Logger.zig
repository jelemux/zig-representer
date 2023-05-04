//! Provides simple logging functionality.
//! Is not thread-safe.

const Logger = @This();

const std = @import("std");
const fs = std.fs;
const WriteError = std.os.WriteError;

pub const Error = error{InvalidLogLevel} || WriteError;

pub var global_level = Level.Error;
pub var global_file = std.io.getStdOut();


const Color = enum(u8) {
    const Self = @This();

    Cyan = 36,
    Green = 32,
    Yellow = 33,
    Red = 31,
    Reset = 0,

    /// Writes the matching ANSI escape code of this color to the given file.
    fn print(self: Self, out: anytype) WriteError!void {
        try out.print("\x1b[{d}m", .{@enumToInt(self)});
    }
};

/// The log-level. Higher levels include all the previous levels.
pub const Level = enum {
    const Self = @This();

    Debug,
    Info,
    Warn,
    Error,

    /// Parses a string into a log-level (case-insensitive).
    /// Errors if no matching log-level can be found.
    pub fn fromString(s: []const u8) error{InvalidLogLevel}!Self {
        return if (std.ascii.eqlIgnoreCase(s, "debug")) Logger.Level.Debug
            else if (std.ascii.eqlIgnoreCase(s, "info")) Logger.Level.Info
            else if (std.ascii.eqlIgnoreCase(s, "warn")) Logger.Level.Warn
            else if (std.ascii.eqlIgnoreCase(s, "error")) Logger.Level.Error
            else error.InvalidLogLevel;
    }

    /// Returns the log-level as a uppercase string.
    fn toString(self: Self) []const u8 {
        return switch (self) {
            Self.Debug => "DEBUG",
            Self.Info => "INFO",
            Self.Warn => "WARN",
            Self.Error => "ERROR",
        };
    }

    /// Returns the associated terminal color for the log-level.
    fn color(self: Self) Color {
        return switch (self) {
            Self.Debug => Color.Cyan,
            Self.Info => Color.Green,
            Self.Warn => Color.Yellow,
            Self.Error => Color.Red,
        };
    }
};

file: fs.File,
level: Level,

/// Initializes the `Logger` with the given output file and log-level.
pub fn new(file: fs.File, level: Level) Logger {
    return Logger{
        .file = file,
        .level = level,
    };
}

/// Sets the log-level of this `Logger`-instance.
/// Overwrites any existing log-level configuration for this logger.
pub fn setLevel(self: *Logger, level: Level) void {
    self.level = level;
}

/// Formats and logs the given message if the given log-level is higher than the level of this logger.
pub fn log(self: *Logger, level: Level, comptime fmt: []const u8, args: anytype) Error!void {
    if (@enumToInt(level) < @enumToInt(self.level)) {
        return;
    }

    const out = self.file.writer();
    const is_tty = self.file.isTty();

    try out.print("{} [", .{std.time.timestamp()});
    if (is_tty) try level.color().print(out);
    try out.print("{s}", .{level.toString()});
    if (is_tty) try Color.Reset.print(out);
    try out.print("]: ", .{});

    try out.print(fmt, args);
    _ = try out.write("\n");

    if (!is_tty) try self.file.sync();
}

/// Logs with `Level.Debug` level.
pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) Error!void {
    try self.log(Level.Debug, fmt, args);
}

/// Logs with `Level.Info` level.
pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) Error!void {
    try self.log(Level.Info, fmt, args);
}

/// Logs with `Level.Warn` level.
pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) Error!void {
    try self.log(Level.Warn, fmt, args);
}

/// Logs with `Level.Error` level.
pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) Error!void {
    try self.log(Level.Error, fmt, args);
}

test "Color.print() should write colors correctly to file" {
    // given
    var tmp_dir = std.testing.tmpDir(fs.Dir.OpenDirOptions{});
    defer tmp_dir.cleanup();

    var color_file = try tmp_dir.dir.createFile("colors.txt", fs.File.CreateFlags{.read = true});
    defer color_file.close();

    var colors = std.EnumSet(Color).initFull();
    var color_iter = colors.iterator();

    // when
    while (color_iter.next()) |color| {
        try color.print(color_file.writer());
    }

    // then
    try color_file.sync();
    try color_file.seekTo(0);

    const allocator = std.testing.allocator;
    const file_content = try color_file.readToEndAlloc(allocator, 100);
    defer allocator.free(file_content);

    try std.testing.expectEqualStrings("\x1b[0m\x1b[31m\x1b[32m\x1b[33m\x1b[36m", file_content);
}

test "should parse log-level from string" {
    const lowerDebugLevel = try Logger.Level.fromString("debug");
    try std.testing.expectEqual(Logger.Level.Debug, lowerDebugLevel);
    const upperDebugLevel = try Logger.Level.fromString("DEBUG");
    try std.testing.expectEqual(Logger.Level.Debug, upperDebugLevel);

    const lowerInfoLevel = try Logger.Level.fromString("info");
    try std.testing.expectEqual(Logger.Level.Info, lowerInfoLevel);
    const upperInfoLevel = try Logger.Level.fromString("INFO");
    try std.testing.expectEqual(Logger.Level.Info, upperInfoLevel);

    const lowerWarnLevel = try Logger.Level.fromString("warn");
    try std.testing.expectEqual(Logger.Level.Warn, lowerWarnLevel);
    const upperWarnLevel = try Logger.Level.fromString("WARN");
    try std.testing.expectEqual(Logger.Level.Warn, upperWarnLevel);

    const lowerErrorLevel = try Logger.Level.fromString("error");
    try std.testing.expectEqual(Logger.Level.Error, lowerErrorLevel);
    const upperErrorLevel = try Logger.Level.fromString("ERROR");
    try std.testing.expectEqual(Logger.Level.Error, upperErrorLevel);

    try std.testing.expectError(error.InvalidLogLevel, Logger.Level.fromString("trace"));
}

test "should convert log-level to uppercase string" {
    const expected_levels = [_][]const u8{"DEBUG", "INFO", "WARN", "ERROR"};

    var levels = std.EnumSet(Logger.Level).initFull();
    var level_iter = levels.iterator();

    var i: usize = 0;
    while (level_iter.next()) |level| : (i += 1) {
        try std.testing.expectEqualStrings(expected_levels[i], level.toString());
    }
}

test "should return correct color for log-level" {
    const expected_colors = [_]Color{.Cyan, .Green, .Yellow, .Red};

    var levels = std.EnumSet(Logger.Level).initFull();
    var level_iter = levels.iterator();

    var i: usize = 0;
    while (level_iter.next()) |level| : (i += 1) {
        try std.testing.expectEqual(expected_colors[i], level.color());
    }
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

