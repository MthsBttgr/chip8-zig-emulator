const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");
const Chip8 = @import("../chip-8.zig");

const CodeView = @This();

screen_area: rl.Rectangle,
code_view_area: rl.Rectangle,
content: rl.Rectangle,
view: rl.Rectangle,
scroll: rl.Vector2,

var follow_pc = true;

const padding: f32 = 4.0;
const line_height: f32 = 30;

pub fn init(screen_area: rl.Rectangle) CodeView {
    const content = rl.Rectangle.init(0, 0, screen_area.width - 2 * padding - 7, (padding + line_height) * 0x1000);
    const view = rl.Rectangle.init(0, 0, 0, 0);
    const scroll = rl.Vector2.zero();
    var code_view_area = screen_area;
    code_view_area.height = screen_area.height - 40;
    return CodeView{ .screen_area = screen_area, .code_view_area = code_view_area, .content = content, .view = view, .scroll = scroll };
}

pub fn stepThroughDraw(self: *CodeView, code: []u8, pc: u16) void {
    if (g.show_code_during_step_through == false) {
        rl.drawRectangleRec(self.screen_area, rl.Color.gray);
        rl.drawText("Not supported in step-through mode\nby default - can be enabled", @intFromFloat(self.screen_area.x + padding), @intFromFloat(self.screen_area.y + self.screen_area.height / 2), 10, rl.Color.white);
        return;
    }
    self.draw(code, pc);
}

pub fn draw(self: *CodeView, code: []u8, pc: u16) void {
    _ = rg.guiScrollPanel(self.code_view_area, "ADDR:          VAL:", self.content, &self.scroll, &self.view);
    const pc_offset = @as(f32, @floatFromInt(pc)) * (padding + line_height);

    var button_area = self.code_view_area;
    button_area.y += self.code_view_area.height;
    button_area.height = 40;
    button_area.width -= 40;

    var checkbox_area = button_area;
    checkbox_area.x += checkbox_area.width + 5;
    checkbox_area.y += 5;
    checkbox_area.width = 30;
    checkbox_area.height = 30;

    _ = rg.guiCheckBox(checkbox_area, "", &follow_pc);

    if (rg.guiButton(button_area, "Find current PC") > 0 or follow_pc) {
        self.scroll.y = -pc_offset + 100;
    }

    rl.beginScissorMode(@intFromFloat(self.view.x), @intFromFloat(self.view.y), @intFromFloat(self.view.width), @intFromFloat(self.view.height));

    for (code, 0..) |item, i| {
        const index: f32 = @floatFromInt(i);
        self.drawSingleCode(item, @truncate(i), self.scroll.y + (padding + line_height) * index, pc);
    }
    rl.endScissorMode();

    rl.drawRectangleLinesEx(self.screen_area, 1.0, rl.Color.white);
}

fn drawSingleCode(self: *const CodeView, code: u8, addr: u16, y_coord: f32, pc: u16) void {
    const rect = rl.Rectangle.init(self.view.x + padding, self.view.y + y_coord + padding, self.view.width - 2 * padding, line_height);
    const col = if (pc == addr) rl.Color.sky_blue else rl.Color.dark_gray;
    rl.drawRectangleRounded(rect, 0.3, 4, col);

    var buf: [20]u8 = [_]u8{0} ** 20;
    _ = std.fmt.bufPrint(&buf, "0x{X:0>4}     0x{X:0>2}", .{ addr, code }) catch unreachable;

    rl.drawText(@ptrCast(&buf), @as(i32, @intFromFloat(self.view.x)) + 15, @as(i32, @intFromFloat(y_coord + self.view.y + padding)) + 5, 20, rl.Color.white);
}
