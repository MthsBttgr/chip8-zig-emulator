const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");
const Chip8 = @import("../chip-8.zig");
const Chip8State = @import("../step_back.zig").Chip8State;
const Emulator = @import("../emulator.zig");

const Rect = @import("../rect.zig");

const RegisterGui = @import("registers_gui.zig");
const CodeView = @import("code_view.zig");
const Playbar = @import("playbar.zig");
const StackGui = @import("stack_gui.zig");
const SpecialRegisters = @import("special_registers.zig");
const Filepicker = @import("filepicker.zig");
const Settings = @import("settings.zig");
const GameScreen = @import("game_screen.zig");
const ErrBar = @import("err_bar.zig");

const GUI = @This();

registers: RegisterGui,
code_view: CodeView,
playbar: Playbar,
stack: StackGui,
special_registers: SpecialRegisters,
filepicker: Filepicker,
settings: Settings,
game_screen: GameScreen,
err_bar: ErrBar,

pub fn init() GUI {
    var game_screen_space = Rect.initRect(rl.Rectangle{ .x = 300, .y = 23, .width = @floatFromInt(g.cols * g.cell_width), .height = @floatFromInt(g.rows * g.cell_height) });
    var reggui_space = game_screen_space.addToY(game_screen_space.height()).setHeight(200);
    const code_view_space = game_screen_space.addToX(game_screen_space.width()).setY(0).setWidth(200).addToHeight(reggui_space.height() + game_screen_space.y());
    var playbar_space = game_screen_space.setY(0).addToX(300).setHeight(game_screen_space.y()).addToWidth(-600);
    var special_registers_space = reggui_space.addToX(-300).setWidth(300);
    var stack_space = special_registers_space.addToY(-200).setHeight(200);
    var filepicker_space = playbar_space.setX(0).setWidth(300);
    const settings_space = stack_space.setY(filepicker_space.height()).setHeight(stack_space.y() - filepicker_space.y());
    const err_bar_space = Rect.init().setY(reggui_space.y() + reggui_space.height()).setHeight(30.0).setWidth(code_view_space.width() + game_screen_space.width() + settings_space.width());

    const filepicker = Filepicker.init(filepicker_space.build(), "snake.ch8");
    const stackgui = StackGui.init(stack_space.build());
    const special_registers = SpecialRegisters{ .screen_area = special_registers_space.build() };
    const playbar = Playbar.init(playbar_space.build());
    const code_view = CodeView.init(code_view_space.build());
    const reggui = RegisterGui.init(reggui_space.build());
    const game_screen = GameScreen{ .screen_area = game_screen_space.build() };
    const settings = Settings.init(settings_space.build());
    const err_bar = ErrBar{ .screen_area = err_bar_space.build() };

    return GUI{
        .registers = reggui,
        .code_view = code_view,
        .playbar = playbar,
        .stack = stackgui,
        .special_registers = special_registers,
        .filepicker = filepicker,
        .settings = settings,
        .game_screen = game_screen,
        .err_bar = err_bar,
    };
}

pub fn height(self: *const GUI) f32 {
    return self.playbar.screen_area.height + self.game_screen.screen_area.height + self.registers.screen_area.height;
}

pub fn drawFromChip8(self: *GUI, emulator: *Emulator) void {
    const chip8 = &emulator.chip8;
    self.game_screen.draw(chip8.display_arr);
    self.registers.draw(&chip8.register, chip8.sound_timer.get(), chip8.delay_timer.get());
    self.code_view.draw(chip8.memory.mem.items, chip8.PC);
    self.playbar.draw(chip8);
    self.special_registers.draw(chip8.PC, chip8.I_reg, chip8.last_instruction_nr, chip8.last_instruction);
    self.settings.draw();
    self.stack.draw(chip8.stack.items());
    self.filepicker.draw(emulator);
    self.err_bar.draw();

    if (g.step_through) {
        rl.drawText("Step-through mode", 300, 2, 20, rl.Color.red);
    }

    if (!g.show_tooltips) return;
    self.settings.drawTooltips();
    self.playbar.drawTooltips();
}

pub fn drawFromChip8State(self: *GUI, state: *const Chip8State, emulator: *Emulator) void {
    self.game_screen.draw(state.display);
    self.registers.draw(&state.register, state.sound_timer, state.delay_timer);
    self.code_view.stepThroughDraw(emulator.chip8.memory.mem.items, state.PC);
    self.settings.draw();
    const stack = std.mem.trimRight(u16, &state.stack, &[_]u16{0});
    self.stack.draw(stack);
    self.special_registers.draw(state.PC, state.I_reg, state.last_instruction_nr, state.last_instruction);
    self.filepicker.draw(emulator);
    self.playbar.draw(&emulator.chip8);
    self.err_bar.draw();

    if (g.step_through) {
        rl.drawText("Step-through mode", 300, 2, 20, rl.Color.red);
    }

    if (!g.show_tooltips) return;
    self.settings.drawTooltips();
    self.playbar.drawTooltips();
}
