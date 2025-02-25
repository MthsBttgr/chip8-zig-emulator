const Emulator = @This();
const std = @import("std");
const Chip8 = @import("chip-8.zig");
const rl = @import("raylib");
const g = @import("globals.zig");
const StepBack = @import("step_back.zig").CircularStepBackBuffer;
const rom_parser = @import("components/rom_parser.zig");

const GUI = @import("gui_elements/gui.zig");

chip8: Chip8,

alloc: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) !Emulator {
    return Emulator{
        .alloc = alloc,
        .chip8 = try Chip8.init(alloc),
    };
}

pub fn deinit(self: *Emulator) void {
    self.chip8.deinit();
}

pub fn load_program(self: *Emulator, program_name: []const u8) void {
    const rom = rom_parser.load_rom(program_name, self.alloc);
    defer self.alloc.free(rom);

    self.chip8.load_program(rom, program_name);
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
            self.chip8.run_untill_timeout();
        } else {
            if (rl.isKeyPressed(.right) or g.step_right) {
                g.step_through = true;

                if (history.step_forward() == null) {
                    self.chip8.execute_one_instruction();
                    history.save_state(&self.chip8);
                }
                g.step_right = false;
            } else if (rl.isKeyPressed(.left) or g.step_left) {
                g.step_through = true;

                _ = history.step_back();
                g.step_left = false;
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);

        if (history.get_current()) |curr| {
            gui.draw_from_chip8state(curr, self);
        } else {
            gui.draw_from_chip8(self);
        }
        rl.endDrawing();
    }
}
