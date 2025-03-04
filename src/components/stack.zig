const std = @import("std");
const Stack = @This();

stack: [24]u16 = [_]u16{0} ** 24, // original has 48 byte stack, i just copied that -> there is no real reason it cant be larger though
ptr: u8 = 0,

pub fn push(self: *Stack, data: u16) void {
    if (self.ptr >= 16) return;
    self.stack[self.ptr] = data;
    self.ptr += 1;
}

pub fn pop(self: *Stack) u16 {
    if (self.ptr == 0) return 0;
    self.ptr -= 1;
    return self.stack[self.ptr];
}

pub fn items(self: *const Stack) []const u16 {
    return self.stack[0..self.ptr];
}

pub fn reset(self: *Stack) void {
    self.stack = [_]u16{0} ** 24;
}
