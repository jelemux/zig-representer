//! A wrapper around `App` specifically to the zig-representer.

const Cli = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const yazap = @import("yazap");
const App = yazap.App;
const flag = yazap.flag;

const Logger = @import("Logger.zig");

/// The arguments the zig-representer CLI takes.
pub const Args = struct {
    slug: []const u8,
    input_dir: []const u8,
    output_dir: []const u8,
    log_level: Logger.Level,
};

pub const CliError = error{MissingRequiredArgs};

app: App,

pub fn init(allocator: Allocator) Cli {
    const app = App.init(
        allocator,
        "zig-representer",
        "An Exercism representer for the Zig programming language."
    );
    return Cli{
        .app = app,
    };
}

/// Adds all the args for zig-representer to the app.
pub fn addArgs(self: *Cli) !void {
    var root = self.app.rootCommand();
    try root.addArg(flag.argOne("slug", 's', "[required] The slug of the exercise to be analyzed (e.g. 'reverse-string')."));
    try root.addArg(flag.argOne("input-dir", 'i', "[required] A path to a directory containing the submitted file(s)."));
    try root.addArg(flag.argOne("output-dir", 'o', "[required] A path to a directory where the representation should be written to."));
    try root.addArg(flag.option("log-level", 'l', &[_][]const u8{
        "debug",
        "info",
        "warn",
        "error",
    }, "Defines the verbosity of the logging. Must be one of 'debug', 'info', 'warn' or 'error'."));
}

/// Parses, validates and returns the args.
pub fn parseAndValidateArgs(self: *Cli) !Args {
    const root_args = try self.app.parseProcess();

    if (!(root_args.isPresent("slug") and root_args.isPresent("input-dir") and root_args.isPresent("output_dir"))) {
        try self.app.displayHelp();
        return CliError.MissingRequiredArgs;
    }

    const log_level_raw = root_args.valueOf("log-level") orelse "warn";
    const log_level = try Logger.Level.fromString(log_level_raw);

    return Args{
        .slug = root_args.valueOf("slug").?,
        .input_dir = root_args.valueOf("input-dir").?,
        .output_dir = root_args.valueOf("output-dir").?,
        .log_level = log_level,
    };
}

/// Frees all the allocated memory of the app.
pub fn deinit(self: *Cli) void {
    self.app.deinit();
}
