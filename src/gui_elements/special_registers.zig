const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const Chip8 = @import("../chip-8.zig");

const SpecialRegisters = @This();

screen_area: rl.Rectangle,

const padding: f32 = 4;
const line_height: f32 = 50;

pub fn draw(self: *const SpecialRegisters, pc: u16, i_reg: u16, last_instruction_nr: u16, last_instruction: []const u8) void {
    rl.drawRectangleRec(self.screen_area, rl.Color.gray);

    var buf: [100]u8 = [_]u8{0} ** 100;
    _ = std.fmt.bufPrint(&buf, "Program Counter: 0x{X:0>4}", .{pc}) catch {};
    var bounds = self.screen_area;
    bounds.x += padding;
    bounds.y += padding;
    bounds.width -= 2 * padding;
    bounds.height = line_height;
    _ = rg.guiStatusBar(bounds, @ptrCast(&buf));

    buf = std.mem.zeroes(@TypeOf(buf));
    _ = std.fmt.bufPrint(&buf, "I Register: 0x{X:0>4}", .{i_reg}) catch {};
    bounds.y += line_height + padding;
    _ = rg.guiStatusBar(bounds, @ptrCast(&buf));

    buf = std.mem.zeroes(@TypeOf(buf));
    _ = std.fmt.bufPrint(&buf, "Last Instruction:\n  {s}\n  0x{X:0>4}", .{ last_instruction, last_instruction_nr }) catch {};
    bounds.y += line_height + padding;
    bounds.height += line_height * 0.6;
    rl.drawRectangleRec(bounds, rl.Color.dark_gray);
    rl.drawRectangleLinesEx(bounds, 3, rl.Color.white);
    if (rl.checkCollisionPointRec(rl.getMousePosition(), bounds)) {
        var new_bounds = bounds;
        new_bounds.width = @as(f32, @floatFromInt(last_instruction.len)) * 12;
        rl.drawRectangleRec(new_bounds, rl.Color.dark_gray);
        rl.drawText(@ptrCast(&buf), @as(i32, @intFromFloat(bounds.x + 7)), @as(i32, @intFromFloat(bounds.y)) + 7, 20, rl.Color.white);
        return;
    }
    rl.beginScissorMode(@as(i32, @intFromFloat(bounds.x)), @as(i32, @intFromFloat(bounds.y)), @as(i32, @intFromFloat(bounds.width - padding)), @as(i32, @intFromFloat(bounds.height)));
    rl.drawText(@ptrCast(&buf), @as(i32, @intFromFloat(bounds.x + 7)), @as(i32, @intFromFloat(bounds.y)) + 7, 20, rl.Color.white);
    rl.endScissorMode();
}
