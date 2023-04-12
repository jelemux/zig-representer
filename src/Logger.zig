//! Provides simple logging functionality.
//! Is not thread-safe.

const Logger = @This();

const std = @import("std");
const fs = std.fs;

pub var global_level = Level.Warn;

const Color = enum(u8) {
    const Self = @This();

    Cyan = 36,
    Green = 32,
    Yellow = 33,
    Red = 31,
    Reset = 0,

    /// Writes the matching ANSI escape code of this color to the given file.
    fn print(self: Self, out: fs.File) !void {
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
pub fn log(self: *Logger, level: Level, comptime fmt: []const u8, args: anytype) !void {
    if (@enumToInt(level) < @enumToInt(self.level)) {
        return;
    }

    var bw = std.io.bufferedWriter(self.file);
    const out = bw.writer();
    const is_tty = self.file.isTty();

    try out.print("{} [", .{std.time.timestamp()});
    if (is_tty) try level.color().print(out);
    try out.print("{s}", .{level.toString()});
    if (is_tty) try Color.Reset.print(out);
    try out.print("]: ", .{});

    try out.print(fmt, args);
    _ = try out.write("\n");

    try bw.flush();
}

/// Logs with `Level.Debug` level.
pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Debug, fmt, args);
}

/// Logs with `Level.Info` level.
pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Info, fmt, args);
}

/// Logs with `Level.Warn` level.
pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Warn, fmt, args);
}

/// Logs with `Level.Error` level.
pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Error, fmt, args);
}

test "emit methods docs" {
    std.testing.refAllDecls(@This());
}
