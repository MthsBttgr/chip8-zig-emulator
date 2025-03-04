const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");

const GameScreen = @This();

screen_area: rl.Rectangle,

pub fn draw(self: *const GameScreen, display_array: [g.cols * g.rows]u1) void {
    const x_offset: i32 = @intFromFloat(self.screen_area.x);
    const y_offset: i32 = @intFromFloat(self.screen_area.y);
    g.cell_width = @divFloor(@as(i32, @intFromFloat(self.screen_area.width)), g.cols);
    g.cell_height = @divFloor(@as(i32, @intFromFloat(self.screen_area.height)), g.rows);

    for (0..g.rows) |y| {
        const y_coord = @as(i32, @intCast(y));
        for (0..g.cols) |x| {
            const x_coord = @as(i32, @intCast(x));
            if (display_array[y * g.cols + x] == 1) {
                rl.drawRectangle(x_coord * g.cell_width + x_offset, y_coord * g.cell_height + y_offset, g.cell_width, g.cell_height, rl.Color.white);
            }
            if (g.show_grid) {
                rl.drawRectangleLines(x_coord * g.cell_width + x_offset, y_coord * g.cell_height + y_offset, g.cell_width, g.cell_height, rl.Color.gray);
            }
        }
    }

    if (g.show_fps) rl.drawFPS(x_offset + 15, y_offset + 15);

    if (g.paused and !g.step_through) {
        const text = "PAUSE";
        const size: i32 = 250;
        const text_displacement = rl.measureTextEx(rl.getFontDefault(), text, size, 25.0);
        const x: i32 = @intFromFloat(self.screen_area.x + self.screen_area.width / 2 - text_displacement.x / 2);
        const y: i32 = @intFromFloat(self.screen_area.y + self.screen_area.height / 2 - text_displacement.y / 2);
        var col = rl.Color.white;
        col.a = 200;
        rl.drawText("PAUSE", x, y, 250, col);
    }
}
