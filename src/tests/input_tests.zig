const std = @import("std");
const testing = std.testing;
const KeyInput = @import("../components/input.zig").KeyInput;

test "KeyInput initialization - all keys are false" {
    const input = KeyInput{};

    try testing.expectEqual(input.k0, false);
    try testing.expectEqual(input.k1, false);
    try testing.expectEqual(input.k2, false);
    try testing.expectEqual(input.k3, false);
    try testing.expectEqual(input.k4, false);
    try testing.expectEqual(input.k5, false);
    try testing.expectEqual(input.k6, false);
    try testing.expectEqual(input.k7, false);
    try testing.expectEqual(input.k8, false);
    try testing.expectEqual(input.k9, false);
    try testing.expectEqual(input.kA, false);
    try testing.expectEqual(input.kB, false);
    try testing.expectEqual(input.kC, false);
    try testing.expectEqual(input.kD, false);
    try testing.expectEqual(input.kE, false);
    try testing.expectEqual(input.kF, false);
}

test "KeyInput reset - sets all keys to false" {
    var input = KeyInput{};

    // Set some keys to true
    input.k0 = true;
    input.k5 = true;
    input.kF = true;

    input.reset();

    try testing.expectEqual(input.k0, false);
    try testing.expectEqual(input.k1, false);
    try testing.expectEqual(input.k2, false);
    try testing.expectEqual(input.k3, false);
    try testing.expectEqual(input.k4, false);
    try testing.expectEqual(input.k5, false);
    try testing.expectEqual(input.k6, false);
    try testing.expectEqual(input.k7, false);
    try testing.expectEqual(input.k8, false);
    try testing.expectEqual(input.k9, false);
    try testing.expectEqual(input.kA, false);
    try testing.expectEqual(input.kB, false);
    try testing.expectEqual(input.kC, false);
    try testing.expectEqual(input.kD, false);
    try testing.expectEqual(input.kE, false);
    try testing.expectEqual(input.kF, false);
}

test "KeyInput set and get - valid key numbers" {
    var input = KeyInput{};

    // Test setting and getting each key
    for (0..16) |key_nr| {
        input.set(@truncate(key_nr), true);
        try testing.expectEqual(input.get(@truncate(key_nr)), true);
    }
    for (0..16) |key_nr| {
        input.set(@truncate(key_nr), false);
        try testing.expectEqual(input.get(@truncate(key_nr)), false);
    }

    // Test specific keys again with different values
    input.set(3, true);
    try testing.expectEqual(input.get(3), true);
    input.set(12, true);
    try testing.expectEqual(input.get(12), true);
    input.set(3, false);
    try testing.expectEqual(input.get(3), false);
    input.set(12, false);
    try testing.expectEqual(input.get(12), false);
}

test "KeyInput get - returns false for invalid key number (out of range)" {
    var input = KeyInput{};

    // Test get with invalid key numbers (outside 0-15 range)
    try testing.expectEqual(input.get(16), false);
    try testing.expectEqual(input.get(20), false);
    try testing.expectEqual(input.get(255), false);
}

test "KeyInput set - does nothing for invalid key number (out of range)" {
    var input = KeyInput{};

    // Set key 0 to true as a baseline
    input.set(0, true);
    try testing.expectEqual(input.get(0), true);

    // Attempt to set invalid key numbers - should not affect other keys and not panic
    input.set(16, true);
    input.set(20, true);
    input.set(255, true);

    // Check if key 0 is still true (invalid set should not affect valid keys)
    try testing.expectEqual(input.get(0), true);
    // Check if invalid get still returns false (as tested in separate test)
    try testing.expectEqual(input.get(16), false);
}
