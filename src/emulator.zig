const Emulator = @This();
const std = @import("std");
const Chip8 = @import("chip-8.zig");
const rl = @import("raylib");
const g = @import("globals.zig");
const StepBack = @import("step_back.zig").CircularStepBackBuffer;
const rom_parser = @import("components/rom_parser.zig");

const GUI = @import("gui_elements/gui.zig");

chip8: Chip8,

// alloc: std.mem.Allocator,

pub fn init() Emulator {
    return Emulator{
        .chip8 = Chip8.init(),
    };
}

pub fn loadProgram(self: *Emulator, program_name: []const u8) void {
    self.chip8.loadProgram(program_name);
}

pub fn run(self: *Emulator) void {
    rl.initWindow(1460, 735, "emulator view");
    rl.setTargetFPS(60);
    var gui = GUI.init();

    var history = StepBack{};

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.space)) {
            g.paused = !g.paused;
            g.step_through = false;
            g.step_left = false;
            g.step_right = false;
            history.reset();
            g.error_msg = "Errors:";
        }
        if (!g.paused) {
            self.chip8.runUntillTimeout();
        } else {
            if (rl.isKeyPressed(.right) or g.step_right) {
                g.step_through = true;

                if (history.stepForward() == null) {
                    self.chip8.executeOneInstruction();
                    history.saveState(&self.chip8);
                }
                g.step_right = false;
            } else if (rl.isKeyPressed(.left) or g.step_left) {
                g.step_through = true;

                _ = history.stepBack();
                g.step_left = false;
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);

        if (history.getCurrent()) |curr| {
            gui.drawFromChip8State(curr, self);
        } else {
            gui.drawFromChip8(self);
        }
        rl.endDrawing();
    }
}
