const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");
const tool_tip = @import("tool_tips.zig");
const Chip8 = @import("../chip-8.zig");

const Playbar = @This();

screen_area: rl.Rectangle,

rect_b1: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
rect_b2: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
rect_b3: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
rect_b4: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),

const padding: f32 = 2.0;

pub fn init(screen_area: rl.Rectangle) Playbar {
    const rect_b1 = blk: {
        var temp = screen_area;
        temp.x += padding;
        temp.y += padding;
        temp.height -= 2 * padding;
        temp.width = (screen_area.width - 5 * padding) / 4;

        break :blk temp;
    };

    const rect_b2 = blk: {
        var temp = rect_b1;
        temp.x += temp.width + padding;
        break :blk temp;
    };
    const rect_b3 = blk: {
        var temp = rect_b2;
        temp.x += temp.width + padding;
        break :blk temp;
    };
    const rect_b4 = blk: {
        var temp = rect_b3;
        temp.x += temp.width + padding;
        break :blk temp;
    };

    return Playbar{ .screen_area = screen_area, .rect_b1 = rect_b1, .rect_b2 = rect_b2, .rect_b3 = rect_b3, .rect_b4 = rect_b4 };
}

pub fn draw(self: *const Playbar, chip8: *Chip8) void {
    rl.drawRectangleRounded(self.screen_area, 0.3, 4, rl.Color.dark_gray);

    const play_text = if (g.paused) "#133#" else "#131#";

    if (rg.guiButton(self.rect_b1, "#129#") > 0) {
        chip8.reset();
    }
    if (rg.guiButton(self.rect_b2, "#114#") > 0) g.step_left = true;
    if (rg.guiButton(self.rect_b3, play_text) > 0) g.paused = !g.paused;
    if (rg.guiButton(self.rect_b4, "#115#") > 0) g.step_right = true;
}

pub fn draw_tooltips(self: *const Playbar) void {
    if (!rl.checkCollisionPointRec(rl.getMousePosition(), self.screen_area)) return;
    tool_tip.draw(self.rect_b1, "Reset execution of current program.\nProgram is completely reloaded from the file, \nin case memory got changed during execution", .leftdown);
    tool_tip.draw(self.rect_b2, "Step back one instruction during stepthrough mode.\nDuring stepthrough mode, the state of the chip8 is saved\nevery instruction. Up to 200 states can be saved\nbefore old ones are forgotten\n\nLeft arrow key can also be used", .leftdown);
    tool_tip.draw(self.rect_b3, "Pause/Start program execution", .leftdown);
    tool_tip.draw(self.rect_b4, "Step forward one instruction during stepthrough mode.\nDuring stepthrough mode, the state of the chip8 is saved\nevery instruction. Up to 200 states can be saved\nbefore old ones are forgotten\n\nRight arrow key can also be used", .leftdown);
}
