//! Contains the main execution logic to implement the representer interface.
//! See https://github.com/exercism/docs/blob/main/building/tooling/representers/interface.md
const std = @import("std");
const Allocator = std.mem.Allocator;

const normalize = @import("pkg/normalize.zig").normalize;

const Version = "1.0.0";

const RepresentationJson = struct {
    version: []const u8 = Version,
};

pub fn represent(
    gpa: Allocator,
    slug: []const u8,
    input_dir: []const u8,
    output_dir: []const u8
) !void {
    _ = gpa;
    _ = slug;
    _ = input_dir;
    _ = output_dir;

    // TODO
    // open input dir
    // read files from input dir

    // create normalization
//    var normalization = normalize(gpa, )

    // open output dir
    // write representation.txt to output dir
    // write mapping.json to to output dir
    // write representation.json to output dir
}
