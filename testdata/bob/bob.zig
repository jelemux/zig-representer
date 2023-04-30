const ascii = @import("std").ascii;
const mem = @import("std").mem;

pub fn response(s: []const u8) []const u8 {
    if (@" "(s)) {
        return "Fine. Be that way!";
    }
    if (@"DA FUQ?"(s)) {
        return "Calm down, I know what I'm doing!";
    }
    if (@"AARGH!"(s)) {
        return "Whoa, chill out!";
    }
    if (@"?"(s)) {
        return "Sure.";
    }
    return "Whatever.";
}

fn @"?"(s: []const u8) bool {
    var trimmed: []const u8 = mem.trimRight(u8, s, &ascii.whitespace);
    return trimmed[trimmed.len-1] == '?';
}

fn @"AARGH!"(s: []const u8) bool {
    var contains_letters: bool = false;
    for (s) |char| {
        if (char >= 'a' and char <= 'z') {
            return false;
        }
        if (!contains_letters and char >= 'A' and char <= 'Z') {
            contains_letters = true;
        }
    }
    return contains_letters;
}

fn @"DA FUQ?"(s: []const u8) bool {
    return @"?"(s) and @"AARGH!"(s);
}

fn @" "(s: []const u8) bool {
    for (s) |char| {
        if (!ascii.isWhitespace(char)) {
            return false;
        }
    }
    return true;
}