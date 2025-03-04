const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const Registers = @import("../components/register.zig").Registers;

const RegisterGui = @This();

screen_area: rl.Rectangle,

pub fn init(screen_area: rl.Rectangle) RegisterGui {
    rg.guiSetStyle(.statusbar, rg.GuiControlProperty.base_color_normal, rl.colorToInt(rl.Color.dark_gray));
    rg.guiSetStyle(.statusbar, rg.GuiControlProperty.text_color_normal, rl.colorToInt(rl.Color.white));
    rg.guiSetStyle(.default, rg.GuiDefaultProperty.text_size, 20);
    return RegisterGui{ .screen_area = screen_area };
}

pub fn draw(self: *const RegisterGui, registers: *const Registers, sound_timer: u8, delay_timer: u8) void {
    rl.drawRectangleRec(self.screen_area, rl.Color.gray);

    const l_padding = self.screen_area.x + 10.0;
    const r_padding = self.screen_area.x + self.screen_area.width - 10.0;
    const t_padding = self.screen_area.y + 10.0;
    const b_padding = self.screen_area.y + self.screen_area.height - 10.0;

    const x_spacing = (r_padding - l_padding) / 6.0;
    const y_spacing = (b_padding - t_padding) / 3.0;

    const cols: i32 = 6;
    const rows: i32 = 3;

    for (0..rows) |y_coord| {
        for (0..cols) |x_coord| {
            // if ((x_coord + y_coord * cols) > 15) return;

            const x = @as(f32, @floatFromInt(x_coord));
            const y = @as(f32, @floatFromInt(y_coord));
            const rect = rl.Rectangle.init(l_padding + x_spacing * x, t_padding + y_spacing * y, x_spacing, y_spacing);

            const coord = x_coord + y_coord * cols;
            const text: [20]u8 = if (coord < 16) blk: {
                break :blk registers.getNullterminatedString(@truncate(x_coord + y_coord * cols));
            } else if (coord == 16) blk: {
                var buf: [20]u8 = [_]u8{0} ** 20;
                _ = std.fmt.bufPrint(&buf, "S-Timer: {d}", .{sound_timer}) catch unreachable;
                break :blk buf;
            } else blk: {
                var buf: [20]u8 = [_]u8{0} ** 20;
                _ = std.fmt.bufPrint(&buf, "D-Timer: {d}", .{delay_timer}) catch unreachable;
                break :blk buf;
            };

            _ = rg.guiStatusBar(rect, @ptrCast(&text));
        }
    }
}
