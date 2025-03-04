const std = @import("std");
const Emulator = @import("emulator.zig");
const g = @import("globals.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var emulator = try Emulator.init(alloc);
    defer emulator.deinit();

    emulator.chip8.loadProgram(&g.blank_screen_program, "Filepicker");

    // try emulator.step_through_program();
    emulator.run();
}
