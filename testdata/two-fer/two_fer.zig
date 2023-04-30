const std = @import("std");

/// Prints 'One for <name>, one for me.' to the provided buffer.
/// If name is `null`, 'you' is printed instead.
pub fn twoFer(buffer: []u8, name: ?[]const u8) ![]u8 {
    // `orelse` provides a default value if name is null.
    return std.fmt.bufPrint(buffer, "One for {s}, one for me.", .{name orelse "you"});
}
