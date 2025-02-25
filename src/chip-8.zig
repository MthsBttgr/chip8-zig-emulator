const Chip8 = @This();
const std = @import("std");
const Emulator = @import("emulator.zig");
const Memory = @import("components/memory.zig");
const Stack = @import("components/stack.zig");
const Register = @import("components/register.zig").Registers;
const Timer = @import("components/timer.zig");
const rl = @import("raylib");
const input = @import("components/input.zig");
const g = @import("globals.zig");

PC: u16 = 0x0200,
display_arr: [g.rows * g.cols]u1 = [_]u1{0} ** g.rows ** g.cols,
I_reg: u16 = 0,
delay_timer: Timer,
sound_timer: Timer,
memory: Memory,
stack: Stack,
register: Register,
flag_registers: [8]u8 = [_]u8{0} ** 8,
input: input.KeyInput = input.KeyInput{},

last_instruction: []const u8 = "",
last_instruction_nr: u16 = 0,

pub fn init(alloc: std.mem.Allocator) !Chip8 {
    return Chip8{
        .memory = try Memory.init(alloc),
        .stack = Stack.init(alloc),
        .register = Register{},
        .delay_timer = Timer.init(),
        .sound_timer = Timer.init(),
    };
}

pub fn reset(self: *Chip8) void {
    self.memory.reset();
    self.register.reset();
    self.PC = 0x0200;
    self.I_reg = 0;
    self.last_instruction = "";
    self.stack.reset();
    self.display_arr = [_]u1{0} ** g.rows ** g.cols;
}

pub fn deinit(self: *Chip8) void {
    self.memory.deinit();
    self.stack.deinit();
}

///Reads an instruction from memory
///An instruction consists of 16 bits, so it reads 2 u8 from memory and increments the program counter
pub fn fetch(self: *Chip8) u16 {
    const res = @as(u16, self.memory.load_addr(self.PC)) << 8 | @as(u16, self.memory.load_addr(self.PC + 1));
    self.PC += 2;

    return res;
}

pub fn peek(self: *const Chip8) u16 {
    const res = @as(u16, self.memory.load_addr(self.PC)) << 8 | @as(u16, self.memory.load_addr(self.PC + 1));
    return res;
}

///Loads rom and makes a copy of the bytes
pub fn load_program(self: *Chip8, program: []const u8, program_name: []const u8) void {
    self.register.reset();
    self.PC = 0x0200;
    self.I_reg = 0;
    self.last_instruction = "";
    self.stack.reset();
    self.display_arr = [_]u1{0} ** g.rows ** g.cols;

    self.memory.load_program(program, program_name);
}

pub fn decode_and_execute(
    self: *Chip8,
    instruction: u16,
) void {
    self.last_instruction_nr = instruction;
    const x = (instruction & 0x0F00) >> 8;
    const y = (instruction & 0x00F0) >> 4;
    const n = instruction & 0x000F;
    const nn: u8 = @truncate(instruction & 0x00FF);
    const nnn = instruction & 0x0FFF;

    switch (instruction) {
        0x00E0 => {
            self.display_arr = [_]u1{0} ** 64 ** 32; // Clear screen
            self.last_instruction = "Clear sreen";
        },
        0x00EE => { // Return from subroutine
            const ret_addr = self.stack.pop();
            self.PC = ret_addr;
            self.last_instruction = "return from subroutine: 0x00EE";
        },
        0x1000...0x1FFF => {
            self.PC = nnn;
            self.last_instruction = "jump: 0x1NNN";
        }, // 0x1NNN => jump
        0x2000...0x2FFF => { // Jump to subroutine
            self.stack.push(self.PC);
            self.PC = nnn;
            self.last_instruction = "jump to subroutine: 0x2NNN";
        },
        0x3000...0x3FFF => { // Skip if VX == NN
            if (self.register.get(x) == nn) {
                self.PC += 2;
            }
            self.last_instruction = "Skip if VX == NN: 0x3XNN";
        },
        0x4000...0x4FFF => { // Skib if VX != NN
            if (self.register.get(x) != nn) {
                self.PC += 2;
            }
            self.last_instruction = "Skib if VX != NN: 0x4XNN";
        },
        0x5000...0x5FF0 => { // Skip if VX == VY
            if (self.register.get(x) == self.register.get(y)) {
                self.PC += 2;
            }
            self.last_instruction = "Skip if VX == VY: 0x5XY0";
        },
        0x9000...0x9FF0 => { //skip if VX != VY
            if (self.register.get(x) != self.register.get(y)) {
                self.PC += 2;
            }
            self.last_instruction = "skip if VX != VY: 0x9XY0";
        },
        0x6000...0x6FFF => { //0x6XNN => Set register X
            self.register.set(x, nn);
            self.last_instruction = "Set register X: 0x6XNN";
        },
        0x7000...0x7FFF => {
            const bits = self.register.get(x);
            const res, _ = @addWithOverflow(bits, nn);
            self.register.set(x, res);
            self.last_instruction = "ADD to register x: 0x7XNN";
        },
        0x8000...0x8FFE => { // Seven different instructions that are differentiated by the last half byte
            switch (n) {
                0 => {
                    self.register.set(x, self.register.get(y));
                    self.last_instruction = "VX = VY: 0x8XY0";
                },
                1 => { // VX = VX | VY
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);

                    self.register.set(x, vx | vy);
                    self.last_instruction = "VX = VX | VY: 0x8XY1";

                    if (g.clear_VF_after_logic_instructions) self.register.set(0xF, 0);
                },
                2 => { // VX = VX & VY
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);

                    self.register.set(x, vx & vy);
                    self.last_instruction = "VX = VX & VY: 0x8XY1";
                    if (g.clear_VF_after_logic_instructions) self.register.set(0xF, 0);
                },
                3 => { // VX = VX ^ VY
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);

                    self.register.set(x, vx ^ vy);

                    self.last_instruction = "VX = VX ^ VY: 0x8XY3";
                    if (g.clear_VF_after_logic_instructions) self.register.set(0xF, 0);
                },
                4 => { // add with overflow
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);

                    const res, const o_bit = @addWithOverflow(vx, vy);

                    self.register.set(x, res);
                    self.register.VF = @as(u8, o_bit);

                    self.last_instruction = "VX = VX + VY <- with overflow: 0x8XY4";
                },
                5 => { //VX = VX - VY
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);
                    const res, const o_bit = @subWithOverflow(vx, vy);

                    self.register.set(x, res);
                    self.register.VF = @as(u8, 1 - o_bit);

                    self.last_instruction = "VX = VX - VY: 0x8XY5";
                },
                7 => { // VX = VY - VX
                    const vx = self.register.get(x);
                    const vy = self.register.get(y);
                    const res, const o_bit = @subWithOverflow(vy, vx);

                    self.register.set(x, res);
                    self.register.VF = @as(u8, 1 - o_bit);

                    self.last_instruction = "VX = VY - VX: 0x8XY7";
                },
                6 => { // SHift VX Right
                    if (g.set_VX_to_VY_before_shift) {
                        self.register.set(x, self.register.get(y));
                    }

                    const vx = self.register.get(x);

                    const o_bit: u1 = @truncate(vx); // There is no @shrwithOverflow()

                    self.register.set(x, vx >> 1);
                    self.register.VF = @as(u8, o_bit);

                    self.last_instruction = "Shift VX Right: 0x8XYE";
                },
                0xE => { // Shift VX left
                    if (g.set_VX_to_VY_before_shift) {
                        self.register.set(x, self.register.get(y));
                    }

                    const vx = self.register.get(x);

                    const res, const o_bit = @shlWithOverflow(vx, 1);

                    self.register.set(x, res);
                    self.register.VF = @as(u8, o_bit);

                    self.last_instruction = "Shift VX left: 0x8XY6";
                },
                else => {
                    g.error_msg = "Reached an instruction that doesnt exist on chip8";
                    self.last_instruction = "Unknown";
                    g.paused = true; // stop execution
                    self.PC -= 2; // set PC back to the instruction that doesnt exist
                    std.log.err("couldnt run opcode. Opcode unknown: {x}", .{instruction});
                },
            }
        },
        0xA000...0xAFFF => {
            self.I_reg = nnn;
            self.last_instruction = "Set I register: 0xANNN";
        },
        0xB000...0xBFFF => { // 0xBNNN | 0xBXNN: Jump with offset
            self.PC = nnn + if (g.treat_jump_as_BNNN) self.register.get(0) else self.register.get(x);
            self.last_instruction = if (g.treat_jump_as_BNNN) "PC = NNN + V0 <- Jump with offset: 0xBNNN" else "PC = NNN + VX <- Jump with offset: 0xBXNN";
        },
        0xC000...0xCFFF => { // 0xCXNN - Random
            var seed: u64 = undefined;
            std.posix.getrandom(std.mem.asBytes(&seed)) catch {
                seed = 1234; // Chosen at random - almost
            };
            var prng = std.Random.DefaultPrng.init(seed);
            const rng = prng.random();

            const res: u8 = rng.int(u8) & nn;
            self.register.set(x, res);

            self.last_instruction = "VX = {random nr} & nn: 0xCXNN";
        },
        0xD000...0xDFFF => { // 0xDXYN | draw command
            var x_coordinate: usize = self.register.get(x) & @as(u8, 63);
            var y_coordinate: usize = self.register.get(y) & @as(u8, 31);

            const x_base_coord = x_coordinate;

            self.register.VF = @as(u8, 0);

            for (0..n) |offset| { //n = height of sprite
                if (y_coordinate > (g.rows - 1)) break; //if y_coordinate is outside the screen, exit loop
                x_coordinate = x_base_coord;

                const i: u8 = @intCast(offset);
                const pixels = self.memory.load_addr(self.I_reg + i); //load horizontal slice of pixels in sprite

                // std.debug.print("pixels: 0b{b}\n", .{pixels});

                for (0..8) |pixel_nr| {
                    if (x_coordinate > (g.cols - 1)) break; //if x_coordinate outside the screen, exit inner loop

                    const inv_pixel_nr = 7 - pixel_nr; //inverting so that loop counts right to left instead of left to right
                    const pixel: u1 = @truncate(pixels >> @truncate(inv_pixel_nr));

                    if (self.display_arr[get_disp_arr_index(y_coordinate, x_coordinate)] & pixel == 1) {
                        self.register.VF = @as(u8, 1);
                    }

                    self.display_arr[get_disp_arr_index(y_coordinate, x_coordinate)] ^= pixel;

                    x_coordinate += 1;
                }

                y_coordinate += 1;
            }

            self.last_instruction = "Draw screen: 0xDXYN";
            // return true;
        },
        0xE09E...0xEFFF => { // two instructions in this range
            switch (nn) {
                0x9E => {
                    if (self.input.get(self.register.get(x))) {
                        self.PC += 2;
                    }
                    self.last_instruction = "Skip if keynr(VX) is down: 0xE09E";
                },
                0xA1 => {
                    if (!self.input.get(self.register.get(x))) {
                        self.PC += 2;
                    }
                    self.last_instruction = "Skip if keynr(VX) is NOT down: 0xE0A1";
                },
                else => {
                    g.error_msg = "Reached an instruction that doesnt exist on chip8";
                    self.last_instruction = "Unknown";
                    g.paused = true; // stop execution
                    self.PC -= 2; // set PC back to the instruction that doesnt exist
                    std.log.err("couldnt run opcode. Opcode unknown: {x}", .{instruction});
                },
            }
        },
        0xF000...0xFFFF => { // nine instructions in this range
            switch (nn) {
                0x07 => {
                    self.register.set(x, self.delay_timer.get());
                    self.last_instruction = "VX = delay timer: 0xFX07";
                },
                0x15 => {
                    self.delay_timer.set(self.register.get(x));
                    self.last_instruction = "delay timer = VX: 0xFX15";
                },
                0x18 => {
                    self.sound_timer.set(self.register.get(x));
                    self.last_instruction = "sound timer = VX: 0xFX18";
                },
                0x29 => { // Set I-reg to the font character in VX
                    const character: u16 = (self.register.get(x) & 0x0F);

                    self.I_reg = self.memory.font_start_addr + @as(u16, 5) * character; // A character is 5 bytes
                    self.last_instruction = "Points I reg to character nr VX: 0xFX29";
                },
                0x33 => { // binary to decimal
                    const vx = self.register.get(x);
                    const ones = vx % 10;
                    const tens = (vx / 10) % 10;
                    const hundreds = vx / 100;

                    self.memory.set_addr(self.I_reg, hundreds);
                    self.memory.set_addr(self.I_reg + 1, tens);
                    self.memory.set_addr(self.I_reg + 2, ones);

                    self.last_instruction = "Store VX as decimal in memory: 0xFX33";
                },
                0x55 => {
                    var inc_i: u16 = 0;
                    for (0..(x + 1)) |reg| {
                        const data = self.register.get(@truncate(reg));
                        self.memory.set_addr(self.I_reg + @as(u16, @truncate(reg)), data);

                        inc_i += 1;
                    }

                    if (g.increment_I_on_store_load) self.I_reg += inc_i;

                    self.last_instruction = "Store reg 0..X in mem: 0xFX55";
                },
                0x65 => {
                    var inc_i: u16 = 0;
                    for (0..(x + 1)) |reg| {
                        const data = self.memory.load_addr(self.I_reg + @as(u16, @truncate(reg)));
                        self.register.set(@truncate(reg), data);

                        inc_i += 1;
                    }
                    if (g.increment_I_on_store_load) self.I_reg += inc_i;
                    self.last_instruction = "Store mem in reg 0..X : 0xFX65";
                },
                0x75 => {
                    for (0..(x + 1)) |reg| {
                        const data = self.register.get(@truncate(reg));
                        self.flag_registers[reg] = data; // In original emulators there are only 8 flag registers
                    }

                    self.last_instruction = "store reg 0..x in flag reg: 0xFX75";
                },
                0x85 => {
                    for (0..(x + 1)) |reg| {
                        const data = self.flag_registers[reg]; // In original emulators there are only 8 flag registers
                        self.register.set(@truncate(reg), data);
                    }

                    self.last_instruction = "store flag reg in reg 0..x: 0xFX85";
                },
                0x1E => {
                    const I_reg_is_0FFF = self.I_reg == 0x0FFF;
                    self.I_reg += self.register.get(x);

                    if (I_reg_is_0FFF and self.I_reg >= 0x1000) {
                        self.register.VF = @bitCast(@as(u8, 1));
                    }
                    self.last_instruction = "VF = 1 IF I-reg overflows from 0xFFF: 0xFX1E";
                },
                0x0A => {
                    // this instruction blocks chip8 execution
                    self.last_instruction = "Block untill keystroke";
                    for (0..16) |key_nr| {
                        const key: u8 = @truncate(key_nr);
                        if (self.input.get(key)) {
                            self.register.set(x, key);
                            return;
                        }
                    }

                    self.PC -= 2;
                },
                else => {
                    g.error_msg = "Reached an instruction that doesnt exist on chip8";
                    g.paused = true; // stop execution
                    self.PC -= 2; // set PC back to the instruction that doesnt exist
                },
            }
        },
        else => {
            g.error_msg = "Reached an instruction that doesnt exist on chip8";
            self.last_instruction = "Unknown";
            g.paused = true; // stop execution
            self.PC -= 2; // set PC back to the instruction that doesnt exist
            std.log.err("couldnt run opcode. Opcode unknown: {x}", .{instruction});
        },
    }
}

pub fn execute_one_instruction(self: *Chip8) void {
    const instruction = self.fetch();
    self.decode_and_execute(instruction);
}

fn get_disp_arr_index(y_cord: usize, x_cord: usize) usize {
    return y_cord * g.cols + x_cord;
}

/// This function runs the program untill it hits a drawinstruction or time since last frame is 1 second, then returns
/// Input keys are updated each frame - not every instruction
pub fn run_untill_timeout(self: *Chip8) void {
    var instruction_counter: i32 = 0;

    // checking g.paused because, if an error occurs during execution, g.paused gets set to save the current state
    while (instruction_counter < g.instructions_pr_frame and !g.paused) {
        const instruction = self.fetch();
        self.decode_and_execute(instruction);
        self.delay_timer.update();
        self.sound_timer.update();

        instruction_counter += 1;
    }
    self.input.update();
}
