const std = @import("std");

const yazap = @import("yazap");
const App = yazap.App;
const flag = yazap.flag;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var app = App.init(allocator, "zig-representer", "An Exercism representer for the Zig programming language.");
    defer app.deinit();

    var root = app.rootCommand();
    try root.addArg(flag.argOne("slug", 's', "The slug of the exercise to be analyzed (e.g. 'reverse-string')."));
    try root.addArg(flag.argOne("input-dir", 'i', "A path to a directory containing the submitted file(s)."));
    try root.addArg(flag.argOne("output-dir", 'o', "A path to a directory where the representation should be written to."));

    const root_args = try app.parseProcess();

    if (!(root_args.hasArgs())) {
        try app.displayHelp();
        return;
    }

    if (root_args.valueOf("slug")) |slug| {
        std.debug.print("slug: {s}\n", .{slug});
    }

    if (root_args.valueOf("input-dir")) |input_dir| {
        std.debug.print("input_dir: {s}\n", .{input_dir});
    }

    if (root_args.valueOf("output-dir")) |output_dir| {
        std.debug.print("output_dir: {s}\n", .{output_dir});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
