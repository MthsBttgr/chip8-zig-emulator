const std = @import("std");
const rl = @import("raylib");
const g = @import("../globals.zig");

const ErrBar = @This();

screen_area: rl.Rectangle,

pub fn draw(self: *const ErrBar) void {
    rl.drawRectangleRec(self.screen_area, rl.Color.black);
    rl.drawRectangleLinesEx(self.screen_area, 1, rl.Color.white);

    const col = if (std.mem.eql(u8, g.error_msg, "Errors:")) rl.Color.white else rl.Color.red;

    rl.drawText(@ptrCast(g.error_msg), @intFromFloat(self.screen_area.x + 5), @intFromFloat(self.screen_area.y + 5), 20, col);
}
