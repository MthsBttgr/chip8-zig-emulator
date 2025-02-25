const std = @import("std");
const testing = std.testing;
const Registers = @import("../components/register.zig").Registers;
const g = @import("../globals.zig"); // Assuming globals.zig is in the parent directory of register.zig

test "Registers initialization - all registers are zero" {
    const registers = Registers{};

    try testing.expectEqual(registers.V0, 0);
    try testing.expectEqual(registers.V1, 0);
    try testing.expectEqual(registers.V2, 0);
    try testing.expectEqual(registers.V3, 0);
    try testing.expectEqual(registers.V4, 0);
    try testing.expectEqual(registers.V5, 0);
    try testing.expectEqual(registers.V6, 0);
    try testing.expectEqual(registers.V7, 0);
    try testing.expectEqual(registers.V8, 0);
    try testing.expectEqual(registers.V9, 0);
    try testing.expectEqual(registers.VA, 0);
    try testing.expectEqual(registers.VB, 0);
    try testing.expectEqual(registers.VC, 0);
    try testing.expectEqual(registers.VD, 0);
    try testing.expectEqual(registers.VE, 0);
    try testing.expectEqual(registers.VF, 0);
}

test "Registers reset - sets all registers to zero" {
    var registers = Registers{};

    // Set some registers to non-zero values
    registers.V0 = 0x10;
    registers.V5 = 0xAA;
    registers.VF = 0xFF;

    registers.reset();

    try testing.expectEqual(registers.V0, 0);
    try testing.expectEqual(registers.V1, 0);
    try testing.expectEqual(registers.V2, 0);
    try testing.expectEqual(registers.V3, 0);
    try testing.expectEqual(registers.V4, 0);
    try testing.expectEqual(registers.V5, 0);
    try testing.expectEqual(registers.V6, 0);
    try testing.expectEqual(registers.V7, 0);
    try testing.expectEqual(registers.V8, 0);
    try testing.expectEqual(registers.V9, 0);
    try testing.expectEqual(registers.VA, 0);
    try testing.expectEqual(registers.VB, 0);
    try testing.expectEqual(registers.VC, 0);
    try testing.expectEqual(registers.VD, 0);
    try testing.expectEqual(registers.VE, 0);
    try testing.expectEqual(registers.VF, 0);
}

test "Registers set and get - valid register numbers" {
    var registers = Registers{};

    // Test setting and getting each register
    for (0..16) |reg_nr| {
        const value: u8 = @truncate(reg_nr * 10 + 5); // Some arbitrary value based on register number
        registers.set(@intCast(reg_nr), value);
        const read_value = registers.get(@intCast(reg_nr));
        try testing.expectEqual(read_value, value);
    }

    // Check specific registers again with different values
    registers.set(3, 0x55);
    try testing.expectEqual(registers.get(3), 0x55);
    registers.set(12, 0xCC);
    try testing.expectEqual(registers.get(12), 0xCC);
}

test "Registers get - sets error_msg and paused on invalid register number" {
    var registers = Registers{};
    g.error_msg = ""; // Reset error message before test
    g.paused = false; // Reset paused state before test

    // Test get with invalid register numbers (outside 0-15 range)

    // Test get with number < 0 (using large u16 to represent negative conceptually)
    _ = registers.get(@as(u16, 0xFFFF));
    try testing.expectEqualStrings(g.error_msg, "Read of non-existing register");
    try testing.expect(g.paused);

    // Reset globals for next test
    g.error_msg = "";
    g.paused = false;

    // Test get with number > 15
    _ = registers.get(16);
    try testing.expectEqualStrings(g.error_msg, "Read of non-existing register");
    try testing.expect(g.paused);
}

test "Registers set - sets error_msg and paused on invalid register number" {
    var registers = Registers{};
    g.error_msg = ""; // Reset error message before test
    g.paused = false; // Reset paused state before test

    // Test set with invalid register numbers (outside 0-15 range)

    // Test set with number < 0 (using large u16 to represent negative conceptually)
    registers.set(@as(u16, 0xFFFF), 0x12);
    try testing.expectEqualStrings(g.error_msg, "Access of non-existing register");
    try testing.expect(g.paused);

    // Reset globals for next test
    g.error_msg = "";
    g.paused = false;

    // Test set with number > 15
    registers.set(16, 0x34);
    try testing.expectEqualStrings(g.error_msg, "Access of non-existing register");
    try testing.expect(g.paused);
}

test "Registers get_nullterminated_string - formats string correctly" {
    var registers = Registers{};

    // Test for different registers and values
    registers.set(0, 0x0A);
    const str1 = registers.get_nullterminated_string(0);
    try testing.expectEqualStrings("V0 = 0x0A", std.mem.trimRight(u8, &str1, "\x00"));

    registers.set(9, 0xFF);
    const str2 = registers.get_nullterminated_string(9);
    try testing.expectEqualStrings("V9 = 0xFF", std.mem.trimRight(u8, &str2, "\x00"));

    registers.set(15, 0x00);
    const str3 = registers.get_nullterminated_string(15);
    try testing.expectEqualStrings("VF = 0x00", std.mem.trimRight(u8, &str3, "\x00"));

    registers.set(10, 0x12);
    const str4 = registers.get_nullterminated_string(10);
    try testing.expectEqualStrings("VA = 0x12", std.mem.trimRight(u8, &str4, "\x00"));
}
