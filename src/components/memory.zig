const std = @import("std");
const Memory = @This();
const rom_parser = @import("rom_parser.zig");

const max_bytes: usize = 0x1000;

mem: [max_bytes]u8 = [_]u8{0} ** max_bytes,
font_start_addr: u16 = 0x50,
current_program_path: [512]u8 = [_]u8{0} ** 512,

pub fn init() Memory {
    return Memory{};
}

///Reloads memory from the file
pub fn reset(self: *Memory) void {
    const path = std.mem.trimRight(u8, &self.current_program_path, "\x00");
    if (path.len > 0) {
        rom_parser.loadRom(path, self.mem[0x200..]);
    }
}

pub fn loadProgram(self: *Memory, program: []const u8) void {
    const program_start_addr: usize = 0x0200;
    std.mem.copyForwards(u8, self.mem[program_start_addr..], program);
    self.loadFont();
}

///Loads a program from file
pub fn loadProgramFile(self: *Memory, program_path: []const u8) void {
    const program_start_addr: usize = 0x0200;
    self.current_program_path = [_]u8{0} ** 512;

    rom_parser.loadRom(program_path, self.mem[program_start_addr..]);
    self.loadFont();

    std.mem.copyForwards(u8, self.current_program_path[0..], program_path);
}

pub fn setAddr(self: *Memory, index: u16, data: u8) void {
    if (index >= max_bytes) return;
    self.mem[index] = data;
}

pub fn loadAddr(self: *const Memory, index: u16) u8 {
    if (index >= max_bytes) return 0;
    return self.mem[index];
}

///Loads font data into Self
fn loadFont(self: *Memory) void {
    std.mem.copyForwards(u8, self.mem[self.font_start_addr..], &font); //starts at 0x50 and ends at 0x9F
}

const font = [80]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};
