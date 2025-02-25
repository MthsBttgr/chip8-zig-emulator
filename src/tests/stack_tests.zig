const std = @import("std");
const testing = std.testing;
const Stack = @import("../components/stack.zig");

test "Stack initialization" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    try testing.expect(stack.stack.items.len == 0); // Initially, stack should be empty
    try testing.expect(stack.stack.capacity >= 4); // Initial capacity should be at least 4 (as set in init)
}

test "Stack deinitialization" {
    var stack = Stack.init(std.heap.page_allocator);
    stack.deinit(); // Call deinit, expect no crash or error

    // Similar to memory deinit test, we rely on zig test not reporting memory leaks.
}

test "Stack push - single element" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0x1234);
    try testing.expect(stack.stack.items.len == 1);
    try testing.expectEqual(stack.stack.items[0], 0x1234);
}

test "Stack push - multiple elements" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0x1111);
    stack.push(0x2222);
    stack.push(0x3333);

    try testing.expect(stack.stack.items.len == 3);
    try testing.expectEqual(stack.stack.items[0], 0x1111);
    try testing.expectEqual(stack.stack.items[1], 0x2222);
    try testing.expectEqual(stack.stack.items[2], 0x3333);
}

test "Stack pop - single element" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0x5678);
    const popped_value = stack.pop();

    try testing.expectEqual(popped_value, 0x5678);
    try testing.expect(stack.stack.items.len == 0); // Stack should be empty after pop
}

test "Stack pop - multiple elements - LIFO order" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0xAAAA);
    stack.push(0xBBBB);
    stack.push(0xCCCC);

    const popped1 = stack.pop();
    const popped2 = stack.pop();
    const popped3 = stack.pop();

    try testing.expectEqual(popped1, 0xCCCC); // Last pushed is popped first
    try testing.expectEqual(popped2, 0xBBBB);
    try testing.expectEqual(popped3, 0xAAAA);
    try testing.expect(stack.stack.items.len == 0); // Stack should be empty after all pops
}

test "Stack reset - clears stack" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0x9999);
    stack.push(0x8888);
    stack.push(0x7777);

    stack.reset();

    try testing.expect(stack.stack.items.len == 0); // Stack should be empty after reset
}

test "Stack push and pop - interleaved operations" {
    var stack = Stack.init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(0x1000);
    stack.push(0x2000);
    const popped1 = stack.pop();
    stack.push(0x3000);
    const popped2 = stack.pop();
    const popped3 = stack.pop();

    try testing.expectEqual(popped1, 0x2000);
    try testing.expectEqual(popped2, 0x3000);
    try testing.expectEqual(popped3, 0x1000);
    try testing.expect(stack.stack.items.len == 0);
}
