const std = @import("std");
const Stack = @This();

stack: std.ArrayList(u16),

pub fn init(alloc: std.mem.Allocator) Stack {
    return Stack{ .stack = std.ArrayList(u16).initCapacity(alloc, 4) catch std.debug.panic("Couldnt create stack", .{}) };
}

pub fn deinit(self: Stack) void {
    self.stack.deinit();
}

pub fn push(self: *Stack, data: u16) void {
    self.stack.append(data) catch std.debug.panic("Ran out of memory in the stack", .{});
}

pub fn pop(self: *Stack) u16 {
    return self.stack.pop();
}

pub fn reset(self: *Stack) void {
    while (self.stack.popOrNull() != null) {}
}
