const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const Chip8 = @import("../chip-8.zig");

const StackGui = @This();

screen_area: rl.Rectangle,
content: rl.Rectangle,
view: rl.Rectangle,
scroll: rl.Vector2,

const padding: f32 = 4.0;
const line_height: f32 = 30;

pub fn init(screen_area: rl.Rectangle) StackGui {
    const content = rl.Rectangle.init(0, 0, screen_area.width - 15, 16 * (padding + line_height));
    const view = rl.Rectangle.init(0, 0, 0, 0);
    const scroll = rl.Vector2.zero();
    return StackGui{
        .screen_area = screen_area,
        .content = content,
        .view = view,
        .scroll = scroll,
    };
}

pub fn draw(self: *StackGui, stack: []const u16) void {
    _ = rg.guiScrollPanel(self.screen_area, "STACK:", self.content, &self.scroll, &self.view);
    rl.beginScissorMode(@intFromFloat(self.view.x), @intFromFloat(self.view.y), @intFromFloat(self.view.width), @intFromFloat(self.view.height));
    if (stack.len == 0) {
        const text = "EMPTY";
        const size: i32 = 60;
        const text_displacement = rl.measureTextEx(rl.getFontDefault(), text, size, 10.0);
        const x: i32 = @intFromFloat(self.screen_area.x + self.screen_area.width / 2 - text_displacement.x / 2);
        const y: i32 = @intFromFloat(self.screen_area.y + self.screen_area.height / 2 - text_displacement.y / 2);
        rl.drawText(text, x, y, size, rl.Color.gray);
        rl.endScissorMode();
        return;
    }

    for (stack, 0..) |item, i| {
        const index: f32 = @floatFromInt(i);
        self.draw_pointer(i, item, self.scroll.y + (padding + line_height) * index);
    }

    rl.endScissorMode();
}
fn draw_pointer(self: *const StackGui, nr: usize, addr: u16, y_coord: f32) void {
    const rect = rl.Rectangle.init(self.view.x + padding, self.view.y + y_coord + padding, self.view.width - 2 * padding, line_height);
    rl.drawRectangleRounded(rect, 0.3, 4, rl.Color.dark_gray);

    var buf: [50]u8 = [_]u8{0} ** 50;
    _ = std.fmt.bufPrint(&buf, "nr: {d:0>2}         ptr: 0x{X:0>4}", .{ nr, addr }) catch unreachable;

    rl.drawText(@ptrCast(&buf), @as(i32, @intFromFloat(self.view.x)) + 15, @as(i32, @intFromFloat(self.view.y + y_coord + padding)) + 5, 20, rl.Color.white);
}
