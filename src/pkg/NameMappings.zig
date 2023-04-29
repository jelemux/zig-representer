//! Holds mappings of identifiers to their respective replacements.

const NameMappings = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const json = std.json;

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

/// Maps the given identifier to a placeholder.
/// Returns the placeholder that the identifier is mapped to.
/// Equal identifiers get the same placeholder, irrespective of scope.
pub fn mapName(self: *NameMappings, name: []const u8) Allocator.Error![]const u8 {
    if (self.replacements.get(name)) |placeholder| {
        return placeholder;
    } else {
        const placeholder: []const u8 = try std.fmt.allocPrint(self.replacements.allocator, "placeholder_{d}", .{self.replacements.count()});
        const duped_name = try self.replacements.allocator.dupe(u8, name);
        try self.replacements.put(duped_name, placeholder);
        return placeholder;
    }
}

/// Returns a json-formatted string of the mappings.
/// Keys and values of the underlying replacements get swapped,
/// so the placeholders become keys and the actual variable names are written as values.
/// The output has to be freed manually.
pub fn toJson(self: *NameMappings) Allocator.Error![]const u8 {
    var mapping_object = json.ObjectMap.init(self.replacements.allocator);
    defer mapping_object.deinit();

    var iter = self.replacements.iterator();
    while (iter.next()) |entry| {
        const placeholder = entry.value_ptr.*;
        const original_name = entry.key_ptr.*;
        try mapping_object.put(placeholder, json.Value{ .String = original_name });
    }

    return json.stringifyAlloc(self.replacements.allocator, json.Value{ .Object = mapping_object }, json.StringifyOptions{ .whitespace = .{} });
}

pub fn deinit(self: *NameMappings) void {
    var value_iter = self.replacements.valueIterator();
    while (value_iter.next()) |value| {
        self.replacements.allocator.free(value.*);
    }

    var key_iter = self.replacements.keyIterator();
    while (key_iter.next()) |key| {
        self.replacements.allocator.free(key.*);
    }

    self.replacements.deinit();
}

test "should map different placeholders for different identifiers" {
    // given
    var sut = NameMappings.init(std.testing.allocator);
    defer sut.deinit();

    // when
    const placeholder_0 = try sut.mapName("abc");
    const placeholder_1 = try sut.mapName("abcd");
    const placeholder_2 = try sut.mapName("dabc");
    const placeholder_3 = try sut.mapName("Abc");
    const placeholder_4 = try sut.mapName("ABC");

    // then
    try std.testing.expectEqualStrings("placeholder_0", placeholder_0);
    try std.testing.expectEqualStrings("placeholder_1", placeholder_1);
    try std.testing.expectEqualStrings("placeholder_2", placeholder_2);
    try std.testing.expectEqualStrings("placeholder_3", placeholder_3);
    try std.testing.expectEqualStrings("placeholder_4", placeholder_4);

    try std.testing.expectEqual(@as(u32, 5), sut.count());

    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_0"), sut.get("abc").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), sut.get("abcd").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), sut.get("dabc").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_3"), sut.get("Abc").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_4"), sut.get("ABC").?);
}

test "should map same placeholders for same identifiers" {
    // given
    var sut = NameMappings.init(std.testing.allocator);
    defer sut.deinit();

    // when
    const placeholder_0 = try sut.mapName("abc");
    const placeholder_1 = try sut.mapName("abc");
    const placeholder_2 = try sut.mapName("Abc");
    const placeholder_3 = try sut.mapName("Abc");
    const placeholder_4 = try sut.mapName("ABC");
    const placeholder_5 = try sut.mapName("ABC");

    // then
    try std.testing.expectEqualStrings("placeholder_0", placeholder_0);
    try std.testing.expectEqualStrings("placeholder_0", placeholder_1);
    try std.testing.expectEqualStrings("placeholder_1", placeholder_2);
    try std.testing.expectEqualStrings("placeholder_1", placeholder_3);
    try std.testing.expectEqualStrings("placeholder_2", placeholder_4);
    try std.testing.expectEqualStrings("placeholder_2", placeholder_5);

    try std.testing.expectEqual(@as(u32, 3), sut.count());

    try std.testing.expectEqualStrings("placeholder_0", sut.get("abc").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_1"), sut.get("Abc").?);
    try std.testing.expectEqualStrings(@as([]const u8, "placeholder_2"), sut.get("ABC").?);
}

test "should create empty json" {
    // given
    const allocator = std.testing.allocator;
    var sut = NameMappings.init(allocator);
    defer sut.deinit();

    // when
    const mappingJson = try sut.toJson();
    defer allocator.free(mappingJson);

    // then
    const expectedJson = "{}";

    try std.testing.expectEqualStrings(expectedJson, mappingJson);
}

test "should create json correctly" {
    // given
    const allocator = std.testing.allocator;
    var sut = NameMappings.init(allocator);
    defer sut.deinit();

    _ = try sut.mapName("TwoFer");
    _ = try sut.mapName("two_fer");
    _ = try sut.mapName("foo");
    _ = try sut.mapName("foo");
    _ = try sut.mapName("bar");

    // when
    const mappingJson = try sut.toJson();
    defer allocator.free(mappingJson);

    // then
    const expectedJson =
        \\{
        \\    "placeholder_0": "TwoFer",
        \\    "placeholder_1": "two_fer",
        \\    "placeholder_2": "foo",
        \\    "placeholder_3": "bar"
        \\}
    ;

    try std.testing.expectEqualStrings(expectedJson, mappingJson);
}
