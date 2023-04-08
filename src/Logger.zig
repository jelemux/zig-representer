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

    fn print(self: Self, out: fs.File) !void {
        try out.print("\x1b[{d}m", .{@enumToInt(self)});
    }
};

pub const Level = enum {
    const Self = @This();

    Debug,
    Info,
    Warn,
    Error,

    pub fn fromString(s: []const u8) error{InvalidLogLevel}!Self {
        return if (std.ascii.eqlIgnoreCase(s, "debug")) Logger.Level.Debug
            else if (std.ascii.eqlIgnoreCase(s, "info")) Logger.Level.Info
            else if (std.ascii.eqlIgnoreCase(s, "warn")) Logger.Level.Warn
            else if (std.ascii.eqlIgnoreCase(s, "error")) Logger.Level.Error
            else error.InvalidLogLevel;
    }

    fn toString(self: Self) []const u8 {
        return switch (self) {
            Self.Debug => "DEBUG",
            Self.Info => "INFO",
            Self.Warn => "WARN",
            Self.Error => "ERROR",
        };
    }

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

pub fn new(file: fs.File, level: Level) Logger {
    return Logger{
        .file = file,
        .level = level,
    };
}

pub fn setLevel(self: *Logger, level: Level) void {
    self.level = level;
}

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

pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Debug, fmt, args);
}

pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Info, fmt, args);
}

pub fn warn(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Warn, fmt, args);
}

pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
    try self.log(Level.Error, fmt, args);
}

test "emit methods docs" {
    std.testing.refAllDecls(@This());
}