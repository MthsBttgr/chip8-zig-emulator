const std = @import("std");
const testing = std.testing;
const Memory = @import("../components/memory.zig");

test "Memory initialization" {
    var mem = try Memory.init(std.heap.page_allocator);
    defer mem.deinit();

    try testing.expect(mem.mem.items.len == 0x1000); // Check if memory buffer is allocated with correct size
    try testing.expect(mem.font_start_addr == 0x50); // Check if font_start_addr is initialized
    try testing.expect(std.mem.eql(u8, mem.current_program[0..], &[_]u8{0} ** 64)); // Check if current_program is initialized to zeros
}

test "Memory deinitialization" {
    var mem = try Memory.init(std.heap.page_allocator);
    mem.deinit(); // Call deinit, we expect no crash or error

    // We can't directly check if memory is deallocated in Zig's testing,
    // but if there are no memory leaks reported by zig test, it's considered successful.
    // For more advanced memory leak detection, you might need external tools.
}

test "Memory load_program - loads program and font, stores program name" {
    var mem = try Memory.init(std.heap.page_allocator);
    defer mem.deinit();

    const program: []const u8 = &[_]u8{ 0x10, 0x20, 0x30 };
    const program_name: []const u8 = "MyGame";

    mem.load_program(program, program_name);

    // Check if program is loaded at 0x200
    try testing.expectEqual(mem.load_addr(0x200), 0x10);
    try testing.expectEqual(mem.load_addr(0x201), 0x20);
    try testing.expectEqual(mem.load_addr(0x202), 0x30);

    // Check if font is loaded (basic check, first font byte)
    try testing.expectEqual(mem.load_addr(mem.font_start_addr), 0xF0);

    // Check if program name is stored
    const loaded_name = std.mem.trimRight(u8, &mem.current_program, "\x00");
    try testing.expectEqualStrings(loaded_name, program_name);
}

test "Memory set_addr and load_addr - set and get memory at address" {
    var mem = try Memory.init(std.heap.page_allocator);
    defer mem.deinit();

    const address: u16 = 0x300;
    const data: u8 = 0xAB;

    mem.set_addr(address, data);
    const loaded_data = mem.load_addr(address);

    try testing.expectEqual(loaded_data, data);
}
