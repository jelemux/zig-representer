const std = @import("std");
const Allocator = std.mem.Allocator;

const r = @import("render.zig");
const Logger = @import("Logger.zig");

pub const NameMappings = std.StringHashMapUnmanaged([]const u8);

pub const Normalization = struct {
    const Self = @This();
    code: []u8,
    mappings: NameMappings,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.code);
        self.mappings.deinit(allocator);
    }
};

/// Creates a normalized representation of the given Zig code.
pub fn normalize(allocator: Allocator, code: []const u8) !Normalization {
    //var logger = Logger.new(Logger.global_file, Logger.global_level);

    var ast = try std.zig.parse(allocator, @ptrCast([:0]const u8, code));
    defer ast.deinit(allocator);

    return r.renderNormalization(allocator, ast);
}

test "should remove top-level doc comments" {
    // given
    const input =
        \\//! A top-level doc comment.
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 = "";
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 0), representation.mappings.count());
}

test "should rename const declarations" {
    // given
    const input =
        \\const std = @import("std");
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_1 = @import("std");
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "std"), representation.mappings.get("placeholder_1").?);
}

test "should not rename main function" {
    // given
    const input =
        \\pub fn main() !void {
        \\}
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn main() !void {
        \\}
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 0), representation.mappings.count());
}

test "should rename function" {
    // given
    const input =
        \\pub fn helloWorld() !void {
        \\}
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_1() !void {
        \\}
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "helloWorld"), representation.mappings.get("placeholder_1").?);
}

test "should remove doc comment" {
    // given
    const input =
        \\/// Prints "Hello, World!" to std out.
        \\pub fn helloWorld() !void {
        \\}
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_1() !void {
        \\}
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "helloWorld"), representation.mappings.get("placeholder_1").?);
}

test "should remove comment" {
    // given
    const input =
        \\// Some comment.
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 = "";
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 0), representation.mappings.count());
}

test "should rename var" {
    // given
    const input =
        \\var something = "";
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\var placeholder_1 = "";
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "something"), representation.mappings.get("placeholder_1").?);
}

test "should rename var usage" {
    // given
    const input =
        \\var something = "";
        \\pub fn main() !void {
        \\    something = "asdf";
        \\}
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\var placeholder_1 = "";
        \\pub fn main() !void {
        \\    placeholder_1 = "asdf";
        \\}
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "something"), representation.mappings.get("placeholder_1").?);
}

test "should rename struct fields" {
    // given
    const input =
        \\const something = struct {
        \\    some_field: u32,
        \\};
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_1 = struct {
        \\    placeholder_2: u32,
        \\};
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 2), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "something"), representation.mappings.get("placeholder_1").?);
    try std.testing.expectEqual(@as([]const u8, "some_field"), representation.mappings.get("placeholder_2").?);
}

test "should rename enum variants" {
    // given
    const input =
        \\const something = enum {
        \\    ok,
        \\    not_ok,
        \\};
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_1 = enum {
        \\    placeholder_2,
        \\    placeholder_3,
        \\};
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 3), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "something"), representation.mappings.get("placeholder_1").?);
    try std.testing.expectEqual(@as([]const u8, "ok"), representation.mappings.get("placeholder_2").?);
    try std.testing.expectEqual(@as([]const u8, "not_ok"), representation.mappings.get("placeholder_3").?);
}

test "should rename union variants" {
    // given
    const input =
        \\const something = union {
        \\    int: i64,
        \\    float: f64,
        \\    boolean: bool,
        \\};
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_1 = union {
        \\    placeholder_2: i64,
        \\    placeholder_3: f64,
        \\    placeholder_4: bool,
        \\};
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 4), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "something"), representation.mappings.get("placeholder_1").?);
    try std.testing.expectEqual(@as([]const u8, "int"), representation.mappings.get("placeholder_2").?);
    try std.testing.expectEqual(@as([]const u8, "float"), representation.mappings.get("placeholder_3").?);
    try std.testing.expectEqual(@as([]const u8, "boolean"), representation.mappings.get("placeholder_4").?);
}

test "should normalize hello world" {
    // given
    const input =
        \\//! A simple hello world program.
        \\const std = @import("std");
        \\
        \\
        \\pub fn main() !void {
        \\    try helloWorld();
        \\}
        \\
        \\/// Prints "Hello, World!" to std out.
        \\pub fn helloWorld() !void {
        \\    // This creates a writer to the std out file.
        \\    const stdout = std.io.getStdOut().writer();
        \\    try stdout.print("Hello, {s}!\n", .{"world"});
        \\}
        \\
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_1 = @import("std");
        \\pub fn main() !void {
        \\    try placeholder_2();
        \\}
        \\pub fn placeholder_2() !void {
        \\    const placeholder_3 = placeholder_1.io.getStdOut().writer();
        \\    try placeholder_3.print("Hello, {s}!\n", .{"world"});
        \\}
    ;
    try std.testing.expectEqual(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 3), representation.mappings.count());
    try std.testing.expectEqual(@as([]const u8, "std"), representation.mappings.get("placeholder_1").?);
    try std.testing.expectEqual(@as([]const u8, "helloWorld"), representation.mappings.get("placeholder_2").?);
    try std.testing.expectEqual(@as([]const u8, "stdout"), representation.mappings.get("placeholder_3").?);
}
