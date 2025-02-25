const std = @import("std");
const Memory = @This();
const rom_parser = @import("rom_parser.zig");

const max_bytes: usize = 0x1000;

mem: std.ArrayList(u8),
font_start_addr: u16 = 0x50,
current_program: [64]u8 = [_]u8{0} ** 64,

pub fn init(allocator: std.mem.Allocator) !Memory {
    const arr = try allocator.alloc(u8, max_bytes);
    return .{
        .mem = std.ArrayList(u8).fromOwnedSlice(allocator, arr),
    };
}

pub fn deinit(self: Memory) void {
    self.mem.deinit();
}

///Reloads memory from the file
pub fn reset(self: *Memory) void {
    const name = std.mem.trimRight(u8, &self.current_program, "\x00");
    if (name.len > 0) {
        const program = rom_parser.load_rom(name, self.mem.allocator);
        self.load_program(program, name);

        self.mem.allocator.free(program);
    }
}

///Loads a program into Self
pub fn load_program(self: *Memory, program: []const u8, program_name: []const u8) void {
    const program_start_addr: usize = 0x0200;
    self.current_program = [_]u8{0} ** 64;

    self.mem.replaceRange(program_start_addr, program.len, program) catch unreachable;
    self.load_font();

    std.mem.copyForwards(u8, self.current_program[0..], program_name);
}

pub fn set_addr(self: *Memory, index: u16, data: u8) void {
    self.mem.items[index] = data;
}

pub fn load_addr(self: *const Memory, index: u16) u8 {
    return self.mem.items[index];
}

///Loads font data into Self
fn load_font(self: *Memory) void {
    std.mem.copyForwards(u8, self.mem.items[self.font_start_addr..], &font); //starts at 0x50 and ends at 0x9F
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
