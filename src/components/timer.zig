///There are two timers in a Chip8
/// Delay Timer and Sound Timer
/// Both decrement at a rate of 60hz
/// This Struct is used to keep track of this
const std = @import("std");

const Timer = @This();

val: u8 = 0,
timer: std.time.Timer,

const ns_pr_frame: u64 = std.time.ns_per_s / 60;

pub fn init() Timer {
    return Timer{
        .timer = std.time.Timer.start() catch unreachable,
    };
}

///Checks if enough time has passed, and decrements the timer the appropriate amount
pub fn update(self: *Timer) void {
    if (self.val == 0) return;

    const time_since_reset = self.timer.read();

    if (time_since_reset < std.time.ns_per_s / 60) return;
    self.timer.reset();

    const diff = time_since_reset / ns_pr_frame;

    if (diff > self.val) {
        self.val = 0;
        return;
    }

    self.val -= @intCast(diff);
}

pub fn get(self: *const Timer) u8 {
    return self.val;
}

pub fn set(self: *Timer, val: u8) void {
    self.val = val;
}
