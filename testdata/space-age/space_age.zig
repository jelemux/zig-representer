pub const Planet = enum(u64) {
    mercury = 24_084_670,
    venus = 61_519_726,
    earth = 100_000_000,
    mars = 188_081_580,
    jupiter = 1_186_261_500,
    saturn = 2_944_749_800,
    uranus = 8_401_684_600,
    neptune = 16_479_132_000,

    pub fn age(self: Planet, seconds: usize) f64 {
        var earthYears: f64 = @intToFloat(f64, seconds) / 31557600.0;
        return earthYears / (@intToFloat(f64, @enumToInt(self)) / 100_000_000.0);
    }
};
