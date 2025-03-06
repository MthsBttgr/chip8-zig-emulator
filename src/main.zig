const std = @import("std");
const Emulator = @import("emulator.zig");
const g = @import("globals.zig");

pub fn main() !void {
    var emulator = Emulator.init();
    emulator.chip8.memory.loadProgram(&g.blank_screen_program);
    emulator.run();
}
