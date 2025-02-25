const std = @import("std");
const testing = std.testing;
const Timer = @import("../components/timer.zig");

test "Timer initialization" {
    const timer = Timer.init();
    try testing.expect(timer.val == 0); // Initial value should be 0
}

test "Timer set and get value" {
    var timer = Timer.init();

    timer.set(0x10);
    try testing.expectEqual(timer.get(), 0x10);

    timer.set(0xFF);
    try testing.expectEqual(timer.get(), 0xFF);

    timer.set(0);
    try testing.expectEqual(timer.get(), 0);
}

test "Timer update - no decrement when value is 0" {
    var timer = Timer.init();
    timer.set(0);

    timer.update(); // Update should not change the value if it's already 0

    try testing.expectEqual(timer.get(), 0);
}

test "Timer update - decrement by 1 after approximately 1/60th of a second" {
    var timer = Timer.init();
    timer.set(2); // Set initial value to 2, so we can decrement to 1

    std.time.sleep(std.time.ns_per_s / 60); // Sleep for roughly 1/60th of a second
    timer.update();

    try testing.expectEqual(timer.get(), 1); // Should decrement by 1
}

test "Timer update - decrement by more than 1 if more time has passed" {
    var timer = Timer.init();
    timer.set(5); // Set initial value to 5

    std.time.sleep(3 * std.time.ns_per_s / 60); // Sleep for roughly 3/60th of a second
    timer.update();

    try testing.expectEqual(timer.get(), 2); // Should decrement by 3 (5 - 3 = 2)
}

test "Timer update - decrement to 0 if time passed is greater than current value" {
    var timer = Timer.init();
    timer.set(2); // Set initial value to 2

    std.time.sleep(5 * std.time.ns_per_s / 60); // Sleep for roughly 5/60th of a second, more than enough to decrement to 0
    timer.update();

    try testing.expectEqual(timer.get(), 0); // Should decrement to 0
}

test "Timer update - multiple updates decrementing correctly over time" {
    var timer = Timer.init();
    timer.set(10); // Set initial value to 10

    std.time.sleep(2 * std.time.ns_per_s / 60);
    timer.update();
    try testing.expectEqual(timer.get(), 8); // Decrement by 2

    std.time.sleep(1 * std.time.ns_per_s / 60);
    timer.update();
    try testing.expectEqual(timer.get(), 7); // Decrement by 1

    std.time.sleep(5 * std.time.ns_per_s / 60);
    timer.update();
    try testing.expectEqual(timer.get(), 2); // Decrement by 5

    std.time.sleep(3 * std.time.ns_per_s / 60);
    timer.update();
    try testing.expectEqual(timer.get(), 0); // Decrement to 0

    timer.update(); // Further updates should not change value when it's 0
    try testing.expectEqual(timer.get(), 0);
}
