const std = @import("std");
const g = @import("globals.zig");
const Chip8 = @import("chip-8.zig");
const Stack = @import("components/stack.zig");
const Register = @import("components/register.zig").Registers;

pub const Chip8State = struct {
    PC: u16,
    I_reg: u16,

    last_instruction_nr: u16,
    last_instruction: []const u8,

    stack: [16]u16,
    register: Register,
    display: [g.rows * g.cols]u1,
    delay_timer: u8,
    sound_timer: u8,

    pub fn new(chip8: *const Chip8) Chip8State {
        var stack = [_]u16{0} ** 16;
        std.mem.copyForwards(u16, &stack, &chip8.stack.stack);
        const state = Chip8State{
            .PC = chip8.*.PC,
            .I_reg = chip8.*.I_reg,
            .stack = stack,
            .display = chip8.*.display_arr,
            .register = chip8.*.register,
            .last_instruction = chip8.last_instruction,
            .last_instruction_nr = chip8.*.last_instruction_nr,
            .delay_timer = chip8.delay_timer.get(),
            .sound_timer = chip8.sound_timer.get(),
        };
        return state;
    }
};

const buffer_len = 200;

pub const CircularStepBuffer = struct {
    buffer: [buffer_len]?Chip8State = [_]?Chip8State{null} ** buffer_len,
    curr_index: u16 = 0,
    end_index: u16 = 0,
    len: u16 = buffer_len,

    pub fn reset(self: *CircularStepBuffer) void {
        self.buffer = [_]?Chip8State{null} ** buffer_len;
        self.curr_index = 0;
        self.end_index = 0;
    }

    pub fn saveState(self: *CircularStepBuffer, state: *const Chip8) void {
        self.buffer[self.end_index] = Chip8State.new(state);

        self.curr_index = self.end_index;
        self.end_index = (self.end_index + 1) % self.len;
    }

    pub fn getCurrent(self: *const CircularStepBuffer) ?*const Chip8State {
        // std.debug.print("\nGet Current. Curr: {d}, End: {d}", .{ self.curr_index, self.end_index });
        const curr = self.buffer[self.curr_index];

        if (curr) |_| {
            return &(self.buffer[self.curr_index].?);
        }

        return null;
    }

    /// Attempts to retrieve the previous `Chip8State` from the buffer.
    /// Returns `null` if the index is empty or if stepping back would reach the start.
    pub fn stepBack(self: *CircularStepBuffer) ?*const Chip8State {
        self.decrementCurr();

        if (self.curr_index == self.end_index) {
            self.incrementCurr();
            return null;
        }

        const prev = self.buffer[self.curr_index];

        if (prev) |_| {
            return &(self.buffer[self.curr_index].?);
        }

        self.incrementCurr();
        return null;
    }

    /// Attempts to retrieve the next`Chip8State` from the buffer.
    /// Returns `null` if the index is empty or if stepping forward would reach the end.
    pub fn stepForward(self: *CircularStepBuffer) ?*const Chip8State {
        self.incrementCurr();

        if (self.curr_index == self.end_index) {
            self.decrementCurr();
            return null;
        }

        const next = self.buffer[self.curr_index];

        if (next) |_| {
            return &(self.buffer[self.curr_index].?);
        }

        self.decrementCurr();
        return null;
    }

    fn incrementCurr(self: *CircularStepBuffer) void {
        self.curr_index = (self.curr_index + 1) % self.len;
    }

    fn decrementCurr(self: *CircularStepBuffer) void {
        const index: i32 = @intCast(self.curr_index);
        const len: i32 = @intCast(self.len);
        self.curr_index = @intCast(@mod(index - 1, len));
    }
};
