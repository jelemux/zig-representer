const std = @import("std");
const Allocator = std.mem.Allocator;

const NameMappings = @import("NameMappings.zig");
const renderTree = @import("render.zig").renderTree;

pub const Normalization = struct {
    const Self = @This();
    representation: []const u8,
    mappings: NameMappings,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.representation);
        self.mappings.deinit();
    }
};

/// Creates a normalized representation of the given Zig code.
pub fn normalize(gpa: Allocator, files_contents: [][]const u8) Allocator.Error!Normalization {
    var mappings = NameMappings.init(gpa);
    errdefer mappings.deinit();

    var representations = std.ArrayList([]const u8).init(gpa);
    defer representations.deinit();
    defer while (representations.popOrNull()) |representation| {
        gpa.free(representation);
    };

    for (files_contents) |contents| {
        var ast = try std.zig.parse(gpa, @ptrCast([:0]const u8, contents));
        defer ast.deinit(gpa);

        var buffer = std.ArrayList(u8).init(gpa);
        defer buffer.deinit();

        try renderTree(&buffer, ast, &mappings);

        const normalized_code = buffer.toOwnedSlice();
        try representations.append(normalized_code);
    }

    std.sort.sort([]const u8, representations.items, {}, comptime sortByLen(u8));
    const representation = try std.mem.join(gpa, "\n//---\n", representations.items);

    return Normalization{.representation = representation, .mappings = mappings};
}

fn sortByLen(comptime T: type) fn (void, []const T, []const T) bool {
    const impl = struct {
        fn inner(context: void, lhs: []const T, rhs: []const T) bool {
            _ = context;
            return lhs.len < rhs.len;
        }
    };
    return impl.inner;
}

test "should remove top-level doc comments" {
    // given
    var input = [_][]const u8{
        \\//! A top-level doc comment.
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 = "";
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 0), normalization.mappings.count());
}

test "should rename const declarations" {
    // given
    var input = [_][]const u8{
        \\const std = @import("std");
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_0 = @import("std");
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 1), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("std").?);
}

test "should rename main function" {
    // given
    var input = [_][]const u8{
        \\pub fn main() !void {
        \\}
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 2), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("void").?);
}

test "should rename function" {
    // given
    var input = [_][]const u8{
        \\pub fn helloWorld() !void {
        \\}
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 2), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("helloWorld").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("void").?);
}

test "should remove doc comment" {
    // given
    var input = [_][]const u8{
        \\/// The main method.
        \\pub fn main() !void {
        \\}
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 2), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("void").?);
}

test "should remove comment" {
    // given
    var input = [_][]const u8{
        \\// Some comment.
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 = "";
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 0), normalization.mappings.count());
}

test "should rename var" {
    // given
    var input = [_][]const u8{
        \\var something = "";
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\var placeholder_0 = "";
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 1), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("something").?);
}

test "should rename var usage" {
    // given
    var input = [_][]const u8{
        \\var something = "";
        \\pub fn main() !void {
        \\    something = "asdf";
        \\}
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\var placeholder_0 = "";
        \\pub fn placeholder_1() !placeholder_2 {
        \\    placeholder_0 = "asdf";
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 3), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("void").?);
}

test "should rename struct fields" {
    // given
    var input = [_][]const u8{
        \\const something = struct {
        \\    some_field: u32,
        \\};
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_0 = struct {
        \\    placeholder_1: placeholder_2,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 3), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("some_field").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("u32").?);
}

test "should rename enum variants" {
    // given
    var input = [_][]const u8{
        \\const something = enum {
        \\    ok,
        \\    not_ok,
        \\};
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_0 = enum {
        \\    placeholder_1,
        \\    placeholder_2,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 3), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("ok").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("not_ok").?);
}

test "should rename union variants" {
    // given
    var input = [_][]const u8{
        \\const something = union {
        \\    int: i64,
        \\    float: f64,
        \\    boolean: bool,
        \\};
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_0 = union {
        \\    placeholder_1: placeholder_2,
        \\    placeholder_3: placeholder_4,
        \\    placeholder_5: placeholder_6,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 7), normalization.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("int").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("i64").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), normalization.mappings.get("float").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), normalization.mappings.get("f64").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_5"), normalization.mappings.get("boolean").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_6"), normalization.mappings.get("bool").?);
}

test "should normalize hello world" {
    // given
    var input = [_][]const u8{
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
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\const placeholder_0 = @import("std");
        \\
        \\pub fn placeholder_1() !placeholder_2 {
        \\    try placeholder_3();
        \\}
        \\pub fn placeholder_3() !placeholder_2 {
        \\    const placeholder_4 = placeholder_0.placeholder_5.placeholder_6().placeholder_7();
        \\    try placeholder_4.placeholder_8("Hello, {s}!\n", .{"world"});
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 9), normalization.mappings.count());

    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("std").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("void").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), normalization.mappings.get("helloWorld").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), normalization.mappings.get("stdout").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_5"), normalization.mappings.get("io").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_6"), normalization.mappings.get("getStdOut").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_7"), normalization.mappings.get("writer").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_8"), normalization.mappings.get("print").?);
}

test "should normalize multiple files" {
    // given
    var input = [_][]const u8{
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
        ,
        \\var something = "";
        \\pub fn main() !void {
        \\    something = "asdf";
        \\}
    };
    const allocator = std.testing.allocator;

    // when
    var normalization = try normalize(allocator, &input);
    defer normalization.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\var placeholder_9 = "";
        \\pub fn placeholder_1() !placeholder_2 {
        \\    placeholder_9 = "asdf";
        \\}
        \\
        \\//---
        \\const placeholder_0 = @import("std");
        \\
        \\pub fn placeholder_1() !placeholder_2 {
        \\    try placeholder_3();
        \\}
        \\pub fn placeholder_3() !placeholder_2 {
        \\    const placeholder_4 = placeholder_0.placeholder_5.placeholder_6().placeholder_7();
        \\    try placeholder_4.placeholder_8("Hello, {s}!\n", .{"world"});
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, normalization.representation);
    try std.testing.expectEqual(@as(u32, 10), normalization.mappings.count());

    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), normalization.mappings.get("std").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), normalization.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), normalization.mappings.get("void").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), normalization.mappings.get("helloWorld").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), normalization.mappings.get("stdout").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_5"), normalization.mappings.get("io").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_6"), normalization.mappings.get("getStdOut").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_7"), normalization.mappings.get("writer").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_8"), normalization.mappings.get("print").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_9"), normalization.mappings.get("something").?);
}
