const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");
const tool_tip = @import("tool_tips.zig");

const Settings = @This();

screen_area: rl.Rectangle,

content: rl.Rectangle,
view: rl.Rectangle,
scroll: rl.Vector2,

emu_speed_tooltip_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
tooltips_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
grid_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
fps_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
codeview_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
cosmac_shift_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
legacy_jump_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
inc_I_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
clear_vf_rect: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),

var edit_emu_speed: bool = false;

const line_height: f32 = 40;
const padding: f32 = 10;

pub fn init(screen_area: rl.Rectangle) Settings {
    const content = rl.Rectangle.init(0, 0, screen_area.width - 2 * padding, (padding + line_height) * 10);
    const view = rl.Rectangle.init(0, 0, 0, 0);
    const scroll = rl.Vector2.zero();

    rg.guiSetStyle(.checkbox, rg.GuiControlProperty.base_color_normal, rl.colorToInt(rl.Color.dark_gray));
    rg.guiSetStyle(.checkbox, rg.GuiControlProperty.base_color_pressed, rl.colorToInt(rl.Color.white));

    return Settings{ .screen_area = screen_area, .content = content, .view = view, .scroll = scroll };
}

pub fn draw(self: *Settings) void {
    _ = rg.guiScrollPanel(self.screen_area, "Settings: ", self.content, &self.scroll, &self.view);

    rl.beginScissorMode(@intFromFloat(self.view.x), @intFromFloat(self.view.y), @intFromFloat(self.view.width), @intFromFloat(self.view.height));

    var rect = rl.Rectangle.init(self.view.x + padding, self.scroll.y + padding + self.view.y, self.view.width - 2 * padding, line_height);

    rl.drawRectangleRec(rect, rl.Color.light_gray);
    self.emu_speed_tooltip_rect = rect;
    var emu_speed_rect = rect;
    emu_speed_rect.width -= 170;
    emu_speed_rect.x += 170;

    if (rl.checkCollisionPointRec(rl.getMousePosition(), rect) and rl.isMouseButtonPressed(.left)) edit_emu_speed = !edit_emu_speed;
    if (!rl.checkCollisionPointRec(rl.getMousePosition(), rect) and rl.isMouseButtonPressed(.left)) edit_emu_speed = false;
    _ = rg.guiValueBox(emu_speed_rect, "Emulation speed:  ", &g.instructions_pr_frame, 1, 1000000, edit_emu_speed);
    if (g.instructions_pr_frame > 1000000) g.instructions_pr_frame = 1000000; // Raylib does a weird thing where i can add an extra digit while editing, and that tanks fps, so just limiting that
    rl.drawRectangleLinesEx(rect, 1, rl.Color.dark_gray);
    rect.y += line_height + padding;
    self.codeview_rect = rect;
    drawSetting(rect, "Step-through Code View", &g.show_code_during_step_through);
    rect.y += line_height + padding;

    const line_start1 = rl.Vector2.init(self.screen_area.x, rect.y);
    const line_end1 = rl.Vector2.init(self.screen_area.x + self.screen_area.width, rect.y);
    rl.drawLineEx(line_start1, line_end1, 2, rl.Color.light_gray);

    rect.y += padding;
    self.grid_rect = rect;
    drawSetting(rect, "Show Grid", &g.show_grid);
    rect.y += line_height + padding;
    self.fps_rect = rect;
    drawSetting(rect, "Show FPS", &g.show_fps);
    rect.y += line_height + padding;
    self.tooltips_rect = rect;
    drawSetting(rect, "Tooltips", &g.show_tooltips);
    rect.y += line_height + padding;

    const line_start2 = rl.Vector2.init(self.screen_area.x, rect.y);
    const line_end2 = rl.Vector2.init(self.screen_area.x + self.screen_area.width, rect.y);
    rl.drawLineEx(line_start2, line_end2, 2, rl.Color.light_gray);

    rect.y += padding;
    self.cosmac_shift_rect = rect;
    drawSetting(rect, "Cosmac Shift:", &g.set_VX_to_VY_before_shift);
    rect.y += line_height + padding;
    self.legacy_jump_rect = rect;
    drawSetting(rect, "Legacy Jump:", &g.treat_jump_as_BNNN);
    rect.y += line_height + padding;
    self.inc_I_rect = rect;
    drawSetting(rect, "Increment I", &g.increment_I_on_store_load);
    rect.y += line_height + padding;
    self.clear_vf_rect = rect;
    drawSetting(rect, "Clear VF", &g.clear_VF_after_logic_instructions);

    rl.endScissorMode();
}

fn drawSetting(area: rl.Rectangle, text: [*:0]const u8, setting: *bool) void {
    _ = rg.guiToggle(area, text, setting);
}

pub fn drawTooltips(self: *const Settings) void {
    if (!rl.checkCollisionPointRec(rl.getMousePosition(), self.view)) return;

    tool_tip.draw(self.grid_rect, "Enables/Disables grid view in gamescreen", .rightdown);
    tool_tip.draw(self.fps_rect, "Enable/Disable fps counter", .rightdown);
    tool_tip.draw(self.codeview_rect, "Enables/Disables codeview during step-through\nThis is due to the codeview not being stored for each step\nTherefore it might be inaccurate for the current step\nInstead it shows how memory is currently layed out in the emulator", .rightdown);
    tool_tip.draw(self.tooltips_rect, "Enable/Disable tooltips", .rightdown);

    tool_tip.draw(self.cosmac_shift_rect, "Shift VY in to VX before shifting bits\nThis was the original implementation, but was changed in later versions\nSome games expect different behaviour\nLater editions used a temporary variable\nIf turned on, the first behaviour will be emulated\nIf turned off the latter will be", .rightdown);
    tool_tip.draw(self.legacy_jump_rect, "Jumps to addrs NNN + V0\nHowever some later editions jumped to NNN + VX\nIf turned on, the first behaviour will be emulated\nIf turned off the latter will be", .rightdown);
    tool_tip.draw(self.inc_I_rect, "The original incremented the I register when storing or loading data in memory\nLater editions used a temporary variable\nIf turned on, the first behaviour will be emulated\nIf turned off the latter will be", .rightdown);
    tool_tip.draw(self.clear_vf_rect, "The original cleared register VF after logic instructions\nLater version didn't\nLater editions used a temporary variable\nIf turned on, the first behaviour will be emulated\nIf turned off the latter will be", .rightdown);
    tool_tip.draw(self.emu_speed_tooltip_rect, "Edit how many instructions that are run each frame\nMinimum 1 - Maximum 1000000\nFPS should be around 60\nDefault is 20", .rightdown);
}
