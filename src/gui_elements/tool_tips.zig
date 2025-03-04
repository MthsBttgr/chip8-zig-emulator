const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

/// If mouse is within bounds, tooltip will show up
/// Orientation decides wich side it will appear on and what direction it will go
pub fn draw(bounds: rl.Rectangle, text: [:0]const u8, orientation: Orientation) void {
    if (!rl.checkCollisionPointRec(rl.getMousePosition(), bounds)) {
        return;
    }
    var lines = std.mem.splitSequence(u8, text, "\n");
    var line_nr: i32 = 0;
    var line_width: i32 = 0;
    while (lines.next()) |line| {
        line_nr += 1;
        var zero_buf: [256]u8 = [_]u8{0} ** 256;
        std.mem.copyForwards(u8, &zero_buf, line[0..]);
        const width = rl.measureText(@ptrCast(&zero_buf), 20);
        if (width > line_width) line_width = width;
    }

    const line_spacing = 5;
    rl.setTextLineSpacing(line_spacing);
    const rect_width: i32 = line_width + 2 * 10;
    const rect_height: i32 = line_nr * 20 + 2 * 10 + (line_nr - 1) * line_spacing;

    const rect: rl.Rectangle = switch (orientation) {
        .rightup => blk: {
            const bounds_lower_right = rl.Vector2{ .x = bounds.x + bounds.width, .y = bounds.y + bounds.height };
            const rect_upper_left = rl.Vector2{ .x = bounds_lower_right.x, .y = bounds_lower_right.y - @as(f32, @floatFromInt(rect_height)) };

            break :blk rl.Rectangle.init(rect_upper_left.x, rect_upper_left.y, @floatFromInt(rect_width), @floatFromInt(rect_height));
        },
        .rightdown => blk: {
            const rect_upper_left = rl.Vector2{ .x = bounds.x + bounds.width, .y = bounds.y };

            break :blk rl.Rectangle.init(rect_upper_left.x, rect_upper_left.y, @floatFromInt(rect_width), @floatFromInt(rect_height));
        },
        .leftdown => blk: {
            const rect_upper_left = rl.Vector2{ .x = bounds.x - @as(f32, @floatFromInt(rect_width)), .y = bounds.y };

            break :blk rl.Rectangle.init(rect_upper_left.x, rect_upper_left.y, @floatFromInt(rect_width), @floatFromInt(rect_height));
        },
        .leftup => blk: {
            const bounds_lower_left = rl.Vector2{ .x = bounds.x, .y = bounds.y + bounds.height };
            const rect_upper_left = rl.Vector2{ .x = bounds_lower_left.x - @as(f32, @floatFromInt(rect_width)), .y = bounds_lower_left.y - @as(f32, @floatFromInt(rect_height)) };

            break :blk rl.Rectangle.init(rect_upper_left.x, rect_upper_left.y, @floatFromInt(rect_width), @floatFromInt(rect_height));
        },
        .midup => blk: {
            const rect_upper_left = rl.Vector2{ .x = bounds.x + (bounds.width - @as(f32, @floatFromInt(rect_width))) / 2, .y = bounds.y - @as(f32, @floatFromInt(rect_height)) };

            break :blk rl.Rectangle.init(rect_upper_left.x, rect_upper_left.y, @floatFromInt(rect_width), @floatFromInt(rect_height));
        },
    };

    var col = rl.Color.black;
    col.a = 200;

    rl.drawRectangleRec(rect, col);
    rl.drawText(text, @intFromFloat(rect.x + 10), @intFromFloat(rect.y + 10), 20, rl.Color.white);
}

const Orientation = enum {
    rightup,
    rightdown,
    leftup,
    leftdown,
    midup,
};
