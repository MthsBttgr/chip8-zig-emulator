const std = @import("std");
const testing = std.testing;
const g = @import("../globals.zig");
const Chip8 = @import("../chip-8.zig");

// Helper function to quickly set up memory with an instruction
fn setupInstructionInMemory(chip8: *Chip8, address: u16, instruction: u16) void {
    chip8.memory.setAddr(address, @truncate(instruction >> 8));
    chip8.memory.setAddr(address + 1, @truncate(instruction & 0xFF));
}

test "Chip8 initialization" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    try testing.expect(chip8.PC == 0x0200);
    try testing.expect(chip8.I_reg == 0);
    try testing.expect(chip8.last_instruction.len == 0);
}

test "Chip8 reset" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    // Modify some state
    chip8.PC = 0x0500;
    chip8.I_reg = 0x1234;
    chip8.last_instruction = "Some instruction";
    chip8.stack.push(0x0300);
    chip8.register.V0 = 0xAA;
    chip8.display_arr[0] = 1;

    chip8.reset();

    try testing.expect(chip8.PC == 0x0200);
    try testing.expect(chip8.I_reg == 0);
    try testing.expect(chip8.last_instruction.len == 0);
    try testing.expect(chip8.stack.items().len == 0);
    try testing.expect(chip8.register.V0 == 0);
    for (chip8.display_arr) |pixel| {
        try testing.expectEqual(pixel, 0);
    }
}

test "Chip8 fetch instruction" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const instruction: u16 = 0xA123;
    setupInstructionInMemory(&chip8, 0x0200, instruction);

    const fetched_instruction = chip8.fetch();

    try testing.expectEqual(fetched_instruction, instruction);
    try testing.expectEqual(chip8.PC, 0x0202);
}

test "Chip8 peek instruction" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const instruction: u16 = 0xB456;
    setupInstructionInMemory(&chip8, 0x0200, instruction);

    const peeked_instruction = chip8.peek();

    try testing.expectEqual(peeked_instruction, instruction);
    try testing.expectEqual(chip8.PC, 0x0200); // PC should not change
}

test "Chip8 load program" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const program = [_]u8{ 0x00, 0xE0, 0xA2, 0x2A };
    const program_name = "Test Program";

    chip8.loadProgram(&program, program_name);

    try testing.expect(chip8.PC == 0x0200);
    try testing.expect(chip8.I_reg == 0);
    try testing.expect(chip8.last_instruction.len == 0);
    try testing.expect(chip8.stack.items().len == 0);
    for (chip8.display_arr) |pixel| {
        try testing.expectEqual(pixel, 0);
    }
    for (0..program.len) |i| {
        try testing.expectEqual(chip8.memory.loadAddr(0x200 + @as(u16, @intCast(i))), program[i]);
    }
}

// --- Decode and Execute Tests ---

test "decodeAndExecute - 0x00E0 - CLS" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.display_arr[0] = 1;
    chip8.display_arr[100] = 1;

    chip8.decodeAndExecute(0x00E0);

    for (chip8.display_arr) |pixel| {
        try testing.expectEqual(pixel, 0);
    }
    try testing.expectEqualStrings(chip8.last_instruction, "Clear sreen");
}

test "decodeAndExecute - 0x00EE - RET" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.stack.push(0x0500);
    chip8.decodeAndExecute(0x00EE);

    try testing.expectEqual(chip8.PC, 0x0500);
    try testing.expectEqualStrings(chip8.last_instruction, "return from subroutine: 0x00EE");
}

test "decodeAndExecute - 0x1NNN - JP addr" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.decodeAndExecute(0x1ABC);

    try testing.expectEqual(chip8.PC, 0x0ABC);
    try testing.expectEqualStrings(chip8.last_instruction, "jump: 0x1NNN");
}

test "decodeAndExecute - 0x2NNN - CALL addr" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    chip8.PC = 0x0250;

    chip8.decodeAndExecute(0x2300);

    try testing.expectEqual(chip8.PC, 0x0300);
    const return_addr = chip8.stack.pop();
    try testing.expectEqual(return_addr, 0x0250);
    try testing.expectEqualStrings(chip8.last_instruction, "jump to subroutine: 0x2NNN");
}

test "decodeAndExecute - 0x3XNN - SE Vx, byte - Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V1 = 0x10;
    chip8.decodeAndExecute(0x3110);

    try testing.expectEqual(chip8.PC, 0x0200 + 2);
    try testing.expectEqualStrings(chip8.last_instruction, "Skip if VX == NN: 0x3XNN");
}

test "decodeAndExecute - 0x3XNN - SE Vx, byte - No Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V1 = 0x11;
    chip8.decodeAndExecute(0x3110);

    try testing.expectEqual(chip8.PC, 0x0200);
    try testing.expectEqualStrings(chip8.last_instruction, "Skip if VX == NN: 0x3XNN");
}

test "decodeAndExecute - 0x4XNN - SNE Vx, byte - Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V2 = 0x12;
    chip8.decodeAndExecute(0x4210);

    try testing.expectEqual(chip8.PC, 0x0200 + 2);
    try testing.expectEqualStrings(chip8.last_instruction, "Skib if VX != NN: 0x4XNN");
}

test "decodeAndExecute - 0x4XNN - SNE Vx, byte - No Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V2 = 0x10;
    chip8.decodeAndExecute(0x4210);

    try testing.expectEqual(chip8.PC, 0x0200);
    try testing.expectEqualStrings(chip8.last_instruction, "Skib if VX != NN: 0x4XNN");
}

test "decodeAndExecute - 0x5XY0 - SE Vx, Vy - Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V3 = 0x20;
    chip8.register.V4 = 0x20;
    chip8.decodeAndExecute(0x5340);

    try testing.expectEqual(chip8.PC, 0x0200 + 2);
    try testing.expectEqualStrings(chip8.last_instruction, "Skip if VX == VY: 0x5XY0");
}

test "decodeAndExecute - 0x5XY0 - SE Vx, Vy - No Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V3 = 0x20;
    chip8.register.V4 = 0x21;
    chip8.decodeAndExecute(0x5340);

    try testing.expectEqual(chip8.PC, 0x0200);
    try testing.expectEqualStrings(chip8.last_instruction, "Skip if VX == VY: 0x5XY0");
}

test "decodeAndExecute - 0x9XY0 - SNE Vx, Vy - Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V5 = 0x30;
    chip8.register.V6 = 0x31;
    chip8.decodeAndExecute(0x9560);

    try testing.expectEqual(chip8.PC, 0x0200 + 2);
    try testing.expectEqualStrings(chip8.last_instruction, "skip if VX != VY: 0x9XY0");
}

test "decodeAndExecute - 0x9XY0 - SNE Vx, Vy - No Skip" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V5 = 0x30;
    chip8.register.V6 = 0x30;
    chip8.decodeAndExecute(0x9560);

    try testing.expectEqual(chip8.PC, 0x0200);
    try testing.expectEqualStrings(chip8.last_instruction, "skip if VX != VY: 0x9XY0");
}

test "decodeAndExecute - 0x6XNN - LD Vx, byte" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.decodeAndExecute(0x6742);

    try testing.expectEqual(chip8.register.V7, 0x42);
    try testing.expectEqualStrings(chip8.last_instruction, "Set register X: 0x6XNN");
}

test "decodeAndExecute - 0x7XNN - ADD Vx, byte - No Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V8 = 0x10;
    chip8.decodeAndExecute(0x7805);

    try testing.expectEqual(chip8.register.V8, 0x15);
    try testing.expectEqualStrings(chip8.last_instruction, "ADD to register x: 0x7XNN");
}

test "decodeAndExecute - 0x7XNN - ADD Vx, byte - Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V9 = 0xFF;
    chip8.decodeAndExecute(0x7901);

    try testing.expectEqual(chip8.register.V9, 0x00);
    try testing.expectEqualStrings(chip8.last_instruction, "ADD to register x: 0x7XNN");
}

test "decodeAndExecute - 0x8XY0 - LD Vx, Vy" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.VA = 0x55;
    chip8.register.VB = 0xAA;
    chip8.decodeAndExecute(0x8AB0);

    try testing.expectEqual(chip8.register.VA, 0xAA);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VY: 0x8XY0");
}

test "decodeAndExecute - 0x8XY1 - OR Vx, Vy - VF cleared" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.clear_VF_after_logic_instructions = true;

    chip8.register.VC = 0b01010101;
    chip8.register.VD = 0b10101010;
    chip8.register.VF = 1;

    chip8.decodeAndExecute(0x8CD1);

    try testing.expectEqual(chip8.register.VC, 0b11111111);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX | VY: 0x8XY1");
}

test "decodeAndExecute - 0x8XY2 - AND Vx, Vy - VF cleared" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.clear_VF_after_logic_instructions = true;

    chip8.register.VA = 0b11110000;
    chip8.register.VB = 0b10101010;
    chip8.register.VF = 1;

    chip8.decodeAndExecute(0x8AB2);

    try testing.expectEqual(chip8.register.VA, 0b10100000);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX & VY: 0x8XY1"); // Note: Typo in original instruction string
}

test "decodeAndExecute - 0x8XY3 - XOR Vx, Vy - VF cleared" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.clear_VF_after_logic_instructions = true;

    chip8.register.V0 = 0b11001100;
    chip8.register.V1 = 0b10101010;
    chip8.register.VF = 1;

    chip8.decodeAndExecute(0x8013);

    try testing.expectEqual(chip8.register.V0, 0b01100110);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX ^ VY: 0x8XY3");
}

test "decodeAndExecute - 0x8XY4 - ADD Vx, Vy - No Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V2 = 0x10;
    chip8.register.V3 = 0x20;
    chip8.decodeAndExecute(0x8234);

    try testing.expectEqual(chip8.register.V2, 0x30);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX + VY <- with overflow: 0x8XY4");
}

test "decodeAndExecute - 0x8XY4 - ADD Vx, Vy - Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V2 = 0xFF;
    chip8.register.V3 = 0x01;
    chip8.decodeAndExecute(0x8234);

    try testing.expectEqual(chip8.register.V2, 0x00);
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX + VY <- with overflow: 0x8XY4");
}

test "decodeAndExecute - 0x8XY5 - SUB Vx, Vy - No Borrow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V4 = 0x30;
    chip8.register.V5 = 0x10;
    chip8.decodeAndExecute(0x8455);

    try testing.expectEqual(chip8.register.V4, 0x20);
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX - VY: 0x8XY5");
}

test "decodeAndExecute - 0x8XY5 - SUB Vx, Vy - Borrow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V4 = 0x10;
    chip8.register.V5 = 0x30;
    chip8.decodeAndExecute(0x8455);

    try testing.expectEqual(chip8.register.V4, 0xE0);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VX - VY: 0x8XY5");
}

test "decodeAndExecute - 0x8XY7 - SUBN Vx, Vy - No Borrow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V6 = 0x10;
    chip8.register.V7 = 0x30;
    chip8.decodeAndExecute(0x8677);

    try testing.expectEqual(chip8.register.V6, 0x20);
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VY - VX: 0x8XY7");
}

test "decodeAndExecute - 0x8XY7 - SUBN Vx, Vy - Borrow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V6 = 0x30;
    chip8.register.V7 = 0x10;
    chip8.decodeAndExecute(0x8677);

    try testing.expectEqual(chip8.register.V6, 0xE0);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = VY - VX: 0x8XY7");
}

test "decodeAndExecute - 0x8XY6 - SHR Vx - VF = LSB, VX = VX >> 1" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.set_VX_to_VY_before_shift = false;

    chip8.register.V8 = 0b10101011;
    chip8.decodeAndExecute(0x8896);

    try testing.expectEqual(chip8.register.V8, 0b01010101);
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "Shift VX Right: 0x8XYE"); // Note: Typo in original instruction string
}

test "decodeAndExecute - 0x8XYE - SHL Vx - VF = MSB, VX = VX << 1" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.set_VX_to_VY_before_shift = false;

    chip8.register.VA = 0b10101011;
    chip8.decodeAndExecute(0x8AEE);

    try testing.expectEqual(chip8.register.VA, 0b01010110);
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "Shift VX left: 0x8XY6"); // Note: Typo in original instruction string
}

test "decodeAndExecute - 0xA000 - LD I, addr" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.decodeAndExecute(0xA123);

    try testing.expectEqual(chip8.I_reg, 0x123);
    try testing.expectEqualStrings(chip8.last_instruction, "Set I register: 0xANNN");
}

test "decodeAndExecute - 0xB000 - JP V0, addr - treat_jump_as_BNNN = true" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.treat_jump_as_BNNN = true;

    chip8.register.V0 = 0x10;
    chip8.decodeAndExecute(0xB200);

    try testing.expectEqual(chip8.PC, 0x210);
    try testing.expectEqualStrings(chip8.last_instruction, "PC = NNN + V0 <- Jump with offset: 0xBNNN");
}

test "decodeAndExecute - 0xB000 - JP Vx, addr - treat_jump_as_BNNN = false" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.treat_jump_as_BNNN = false;

    chip8.register.V3 = 0x20;
    chip8.decodeAndExecute(0xB300);

    try testing.expectEqual(chip8.PC, 0x320);
    try testing.expectEqualStrings(chip8.last_instruction, "PC = NNN + VX <- Jump with offset: 0xBXNN");
}

test "decodeAndExecute - 0xC000 - RND Vx, byte" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.decodeAndExecute(0xC4FF);

    try testing.expect(chip8.register.V4 >= 0);
    try testing.expect(chip8.register.V4 <= 255);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = {random nr} & nn: 0xCXNN");
}

test "decodeAndExecute - 0xDXYN - DRW Vx, Vy, nibble - No collision" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const sprite = [_]u8{ 0xF0, 0x80 };
    chip8.I_reg = 0x200;
    chip8.memory.loadProgram(&sprite, "test_sprite");

    chip8.register.V0 = 2;
    chip8.register.V1 = 3;
    chip8.register.VF = 1; // should be reset to 0

    chip8.decodeAndExecute(0xD012);

    try testing.expectEqual(chip8.display_arr[3 * 64 + 2], 1);
    try testing.expectEqual(chip8.display_arr[3 * 64 + 3], 1);
    try testing.expectEqual(chip8.display_arr[3 * 64 + 4], 1);
    try testing.expectEqual(chip8.display_arr[3 * 64 + 5], 1);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "Draw screen: 0xDXYN");
}

test "decodeAndExecute - 0xDXYN - DRW Vx, Vy, nibble - Collision" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const sprite = [_]u8{0xFF};
    chip8.I_reg = 0x300;
    chip8.memory.loadProgram(&sprite, "test_sprite");

    chip8.register.V0 = 5;
    chip8.register.V1 = 5;
    chip8.display_arr[5 * 64 + 5] = 1; // pre-set pixel for collision
    chip8.register.VF = 0; // should be set to 1

    chip8.decodeAndExecute(0xD011);

    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "Draw screen: 0xDXYN");
}

test "decodeAndExecute - 0xF007 - LD Vx, DT" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.delay_timer.set(0x2A);
    chip8.decodeAndExecute(0xF207);

    try testing.expectEqual(chip8.register.V2, 0x2A);
    try testing.expectEqualStrings(chip8.last_instruction, "VX = delay timer: 0xFX07");
}

test "decodeAndExecute - 0xF015 - LD DT, Vx" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V3 = 0x3B;
    chip8.decodeAndExecute(0xF315);

    try testing.expectEqual(chip8.delay_timer.val, 0x3B);
    try testing.expectEqualStrings(chip8.last_instruction, "delay timer = VX: 0xFX15");
}

test "decodeAndExecute - 0xF018 - LD ST, Vx" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V4 = 0x4C;
    chip8.decodeAndExecute(0xF418);

    try testing.expectEqual(chip8.sound_timer.val, 0x4C);
    try testing.expectEqualStrings(chip8.last_instruction, "sound timer = VX: 0xFX18");
}

test "decodeAndExecute - 0xF029 - LD F, Vx" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V5 = 0x05;
    chip8.decodeAndExecute(0xF529);

    try testing.expectEqual(chip8.I_reg, chip8.memory.font_start_addr + (5 * 5));
    try testing.expectEqualStrings(chip8.last_instruction, "Points I reg to character nr VX: 0xFX29");
}

test "decodeAndExecute - 0xF033 - LD B, Vx" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V6 = 123;
    chip8.I_reg = 0x500;
    chip8.decodeAndExecute(0xF633);

    try testing.expectEqual(chip8.memory.loadAddr(0x500), 1);
    try testing.expectEqual(chip8.memory.loadAddr(0x501), 2);
    try testing.expectEqual(chip8.memory.loadAddr(0x502), 3);
    try testing.expectEqualStrings(chip8.last_instruction, "Store VX as decimal in memory: 0xFX33");
}

test "decodeAndExecute - 0xF055 - LD [I], Vx - No increment I" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.increment_I_on_store_load = false;

    chip8.register.V0 = 0x10;
    chip8.register.V1 = 0x20;
    chip8.register.V2 = 0x30;
    chip8.I_reg = 0x600;
    chip8.decodeAndExecute(0xF255);

    try testing.expectEqual(chip8.memory.loadAddr(0x600), 0x10);
    try testing.expectEqual(chip8.memory.loadAddr(0x601), 0x20);
    try testing.expectEqual(chip8.memory.loadAddr(0x602), 0x30);
    try testing.expectEqual(chip8.I_reg, 0x600);
    try testing.expectEqualStrings(chip8.last_instruction, "Store reg 0..X in mem: 0xFX55");
}

test "decodeAndExecute - 0xF055 - LD [I], Vx - Increment I" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.increment_I_on_store_load = true;

    chip8.register.V0 = 0x10;
    chip8.register.V1 = 0x20;
    chip8.register.V2 = 0x30;
    chip8.I_reg = 0x600;
    chip8.decodeAndExecute(0xF255);

    try testing.expectEqual(chip8.memory.loadAddr(0x600), 0x10);
    try testing.expectEqual(chip8.memory.loadAddr(0x601), 0x20);
    try testing.expectEqual(chip8.memory.loadAddr(0x602), 0x30);
    try testing.expectEqual(chip8.I_reg, 0x603);
    try testing.expectEqualStrings(chip8.last_instruction, "Store reg 0..X in mem: 0xFX55");
}

test "decodeAndExecute - 0xF065 - LD Vx, [I] - No Increment I" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.increment_I_on_store_load = false;

    chip8.I_reg = 0x700;
    chip8.memory.setAddr(0x700, 0xAA);
    chip8.memory.setAddr(0x701, 0xBB);
    chip8.memory.setAddr(0x702, 0xCC);
    chip8.decodeAndExecute(0xF265);

    try testing.expectEqual(chip8.register.V0, 0xAA);
    try testing.expectEqual(chip8.register.V1, 0xBB);
    try testing.expectEqual(chip8.register.V2, 0xCC);
    try testing.expectEqual(chip8.I_reg, 0x700);
    try testing.expectEqualStrings(chip8.last_instruction, "Store mem in reg 0..X : 0xFX65");
}

test "decodeAndExecute - 0xF065 - LD Vx, [I] - Increment I" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.increment_I_on_store_load = true;

    chip8.I_reg = 0x700;
    chip8.memory.setAddr(0x700, 0xAA);
    chip8.memory.setAddr(0x701, 0xBB);
    chip8.memory.setAddr(0x702, 0xCC);
    chip8.decodeAndExecute(0xF265);

    try testing.expectEqual(chip8.register.V0, 0xAA);
    try testing.expectEqual(chip8.register.V1, 0xBB);
    try testing.expectEqual(chip8.register.V2, 0xCC);
    try testing.expectEqual(chip8.I_reg, 0x703);
    try testing.expectEqualStrings(chip8.last_instruction, "Store mem in reg 0..X : 0xFX65");
}

test "decodeAndExecute - 0xF075 - LD R, Vx" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.register.V0 = 0x11;
    chip8.register.V1 = 0x22;
    chip8.register.V2 = 0x33;
    chip8.decodeAndExecute(0xF275);

    try testing.expectEqual(chip8.flag_registers[0], 0x11);
    try testing.expectEqual(chip8.flag_registers[1], 0x22);
    try testing.expectEqual(chip8.flag_registers[2], 0x33);
    try testing.expectEqualStrings(chip8.last_instruction, "store reg 0..x in flag reg: 0xFX75");
}

test "decodeAndExecute - 0xF085 - LD Vx, R" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.flag_registers[0] = 0xAA;
    chip8.flag_registers[1] = 0xBB;
    chip8.flag_registers[2] = 0xCC;
    chip8.decodeAndExecute(0xF285);

    try testing.expectEqual(chip8.register.V0, 0xAA);
    try testing.expectEqual(chip8.register.V1, 0xBB);
    try testing.expectEqual(chip8.register.V2, 0xCC);
    try testing.expectEqualStrings(chip8.last_instruction, "store flag reg in reg 0..x: 0xFX85");
}

test "decodeAndExecute - 0xF01E - ADD I, Vx - No Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.I_reg = 0x0100;
    chip8.register.V7 = 0x0020;
    chip8.decodeAndExecute(0xF71E);

    try testing.expectEqual(chip8.I_reg, 0x0120);
    try testing.expectEqual(chip8.register.VF, 0);
    try testing.expectEqualStrings(chip8.last_instruction, "VF = 1 IF I-reg overflows from 0xFFF: 0xFX1E");
}

test "decodeAndExecute - 0xF01E - ADD I, Vx - Overflow" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    chip8.I_reg = 0x0FFF;
    chip8.register.V7 = 0x0001;
    chip8.decodeAndExecute(0xF71E);

    try testing.expectEqual(chip8.I_reg, 0x1000); // Zig wraps around u16? should be 0
    try testing.expectEqual(chip8.register.VF, 1);
    try testing.expectEqualStrings(chip8.last_instruction, "VF = 1 IF I-reg overflows from 0xFFF: 0xFX1E");
}

test "ExecuteOneInstruction - Fetches and executes instruction" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();

    const instruction: u16 = 0x600A; // LD V0, 0x0A
    setupInstructionInMemory(&chip8, 0x0200, instruction);

    chip8.executeOneInstruction();

    try testing.expectEqual(chip8.register.V0, 0x0A);
    try testing.expectEqual(chip8.PC, 0x0202);
}

// Function that mirrors chip8 fn, but doesnt use raylib
fn run_untill_timeout_no_input(self: *Chip8) void {
    var instruction_counter: i32 = 0;

    // checking g.paused because, if an error occurs during execution, g.paused gets set to save the current state
    while (instruction_counter < g.instructions_pr_frame and !g.paused) {
        const instruction = self.fetch();
        self.decodeAndExecute(instruction);
        self.delay_timer.update();
        self.sound_timer.update();

        instruction_counter += 1;
    }
}

test "run_untill_timeout - Executes multiple instructions" {
    var chip8 = try Chip8.init(std.heap.page_allocator);
    defer chip8.deinit();
    g.instructions_pr_frame = 3;

    const instructions = [_]u16{ 0x6001, 0x6102, 0x6203, 0x6304 };
    var addr: u16 = 0x0200;
    for (instructions) |instr| {
        setupInstructionInMemory(&chip8, addr, instr);
        addr += 2;
    }

    const initial_pc = chip8.PC;
    run_untill_timeout_no_input(&chip8);

    try testing.expectEqual(chip8.register.V0, 0x01);
    try testing.expectEqual(chip8.register.V1, 0x02);
    try testing.expectEqual(chip8.register.V2, 0x03);
    try testing.expectEqual(chip8.register.V3, 0x00); // not executed due to limit
    try testing.expectEqual(chip8.PC, initial_pc + (3 * 2));
}
