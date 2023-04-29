const std = @import("std");
const Allocator = std.mem.Allocator;

const renderTree = @import("render.zig").renderTree;

pub const NameMappings = struct {
    replacements: std.StringHashMap([]const u8),

    pub fn init(gpa: Allocator) NameMappings {
        return NameMappings{
            .replacements = std.StringHashMap([]const u8).init(gpa),
        };
    }

    pub fn get(self: *NameMappings, name: []const u8) ?[]const u8 {
        return self.replacements.get(name);
    }

    pub fn count(self: *NameMappings) u32 {
        return self.replacements.count();
    }

    pub fn mapName(self: *NameMappings, name: []const u8) Allocator.Error![]const u8 {
        if (self.replacements.get(name)) |placeholder| {
            return placeholder;
        } else {
            const placeholder: []const u8 = try std.fmt.allocPrint(self.replacements.allocator, "placeholder_{d}", .{self.replacements.count()});
            const dupedName = try self.replacements.allocator.dupe(u8, name);
            try self.replacements.put(dupedName, placeholder);
            return placeholder;
        }
    }

    pub fn deinit(self: *NameMappings) void {
        var valueIter = self.replacements.valueIterator();
        while (valueIter.next()) |value| {
            self.replacements.allocator.free(value.*);
        }

        var keyIter = self.replacements.keyIterator();
        while (keyIter.next()) |key| {
            self.replacements.allocator.free(key.*);
        }

        self.replacements.deinit();
    }
};

pub const Normalization = struct {
    const Self = @This();
    code: []u8,
    mappings: NameMappings,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.code);
        self.mappings.deinit();
    }
};

/// Creates a normalized representation of the given Zig code.
pub fn normalize(gpa: Allocator, code: []const u8) !Normalization {
    var ast = try std.zig.parse(gpa, @ptrCast([:0]const u8, code));
    defer ast.deinit(gpa);

    var mappings = NameMappings.init(gpa);
    var buffer = std.ArrayList(u8).init(gpa);
    defer buffer.deinit();

    try renderTree(&buffer, ast, &mappings);

    const normalized_code = buffer.toOwnedSlice();
    return Normalization{.code = normalized_code, .mappings = mappings};
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
    try std.testing.expectEqualStrings(expectedCode, representation.code);
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
        \\const placeholder_0 = @import("std");
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("std").?);
}

test "should rename main function" {
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
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 2), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("void").?);
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
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 2), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("helloWorld").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("void").?);
}

test "should remove doc comment" {
    // given
    const input =
        \\/// The main method.
        \\pub fn main() !void {
        \\}
    ;
    const allocator = std.testing.allocator;

    // when
    var representation = try normalize(allocator, input);
    defer representation.deinit(allocator);

    // then
    const expectedCode: []const u8 =
        \\pub fn placeholder_0() !placeholder_1 {}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 2), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("void").?);
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
    try std.testing.expectEqualStrings(expectedCode, representation.code);
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
        \\var placeholder_0 = "";
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 1), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("something").?);
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
        \\var placeholder_0 = "";
        \\pub fn placeholder_1() !placeholder_2 {
        \\    placeholder_0 = "asdf";
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 3), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), representation.mappings.get("void").?);
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
        \\const placeholder_0 = struct {
        \\    placeholder_1: placeholder_2,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 3), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("some_field").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), representation.mappings.get("u32").?);
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
        \\const placeholder_0 = enum {
        \\    placeholder_1,
        \\    placeholder_2,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 3), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("ok").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), representation.mappings.get("not_ok").?);
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
        \\const placeholder_0 = union {
        \\    placeholder_1: placeholder_2,
        \\    placeholder_3: placeholder_4,
        \\    placeholder_5: placeholder_6,
        \\};
        \\
    ;
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 7), representation.mappings.count());
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("something").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("int").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), representation.mappings.get("i64").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), representation.mappings.get("float").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), representation.mappings.get("f64").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_5"), representation.mappings.get("boolean").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_6"), representation.mappings.get("bool").?);
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
    try std.testing.expectEqualStrings(expectedCode, representation.code);
    try std.testing.expectEqual(@as(u32, 9), representation.mappings.count());

    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), representation.mappings.get("std").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), representation.mappings.get("main").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), representation.mappings.get("void").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), representation.mappings.get("helloWorld").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), representation.mappings.get("stdout").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_5"), representation.mappings.get("io").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_6"), representation.mappings.get("getStdOut").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_7"), representation.mappings.get("writer").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_8"), representation.mappings.get("print").?);
}
