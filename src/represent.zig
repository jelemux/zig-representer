//! Contains the main execution logic to implement the representer interface.
//! See https://github.com/exercism/docs/blob/main/building/tooling/representers/interface.md
const std = @import("std");
const Allocator = std.mem.Allocator;
const fs = std.fs;

const normalize = @import("pkg/normalize.zig").normalize;

const Version = "1.0.0";

pub fn represent(
    gpa: Allocator,
    input_path: []const u8,
    output_path: []const u8
) !void {
    _ = output_path;

    var input_is_absolute = true;
    std.fs.accessAbsolute(input_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            input_is_absolute = false;
        } else {
            return err;
        }
    };

    // open input dir
    var input_dir = if (input_is_absolute)
        try std.fs.openIterableDirAbsolute(input_path, .{})
    else
        try std.fs.cwd().openIterableDir(input_path, .{})
    ;
    defer input_dir.close();

    // read files from input dir
    var files_contents = std.ArrayList([]const u8).init(gpa);
    defer files_contents.deinit();
    try readFilesRecursive(input_dir, &files_contents);
    defer while (files_contents.popOrNull()) |contents| {
        gpa.free(contents);
    };

    // create normalization
    var normalization = try normalize(gpa, files_contents.items);
    _ = normalization;

    // open output dir
    // write representation.txt to output dir
    // write mapping.json to to output dir
    // write representation.json to output dir
    // TODO
}

/// Reads file contents from all subdirectories.
/// File contents must be freed manually.
fn readFilesRecursive(iter_dir: std.fs.IterableDir, files_contents: *std.ArrayList([]const u8)) !void {
    var dir_iter = iter_dir.iterate();
    while (try dir_iter.next()) |entry| {
        switch (entry.kind) {
        .File => {
            const contents = try iter_dir.dir.readFileAlloc(files_contents.allocator, entry.name, 1048576);
            try files_contents.append(contents);
        },
        .Directory => {
            var next_dir = try iter_dir.dir.openIterableDir(entry.name, .{});
            defer next_dir.close();
            try readFilesRecursive(next_dir, files_contents);
        },
        else => {},
        }
    }
}

const RepresentationJson = struct {
    version: []const u8 = Version,
};
