const std = @import("std");
const Emulator = @import("emulator.zig");
const rom_parser = @import("components/rom_parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var emulator = try Emulator.init(alloc);
    defer emulator.deinit();

    const program_name = "snake.ch8";
    emulator.loadProgram(program_name);

    // try emulator.step_through_program();
    emulator.run();
}
