//
//
//
//
//
//    I. ORCz
//
//
//      .g8""8q. `7MM"""Mq.   .g8"""bgd
//    .dP'    `YM. MM   `MM..dP'     `M
//    dM'      `MM MM   ,M9 dM'       `M"""MMV
//    MM        MM MMmmdM9  MM         '  AMV
//    MM.      ,MP MM  YM.  MM.          AMV
//    `Mb.    ,dP' MM   `Mb.`Mb.     ,' AMV  ,
//      `"bmmd"' .JMML. .JMM. `"bmmmd' AMMmmmM
//
//
//
//    II. Copyright (c) 2025-present Rocco Ruscitti
//
//    III. License
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//
//
//
//
//

const std = @import("std");

pub fn ManagedArrayList(comptime T: type) type {
    return struct {
        const Self = @This();

        list: std.ArrayListUnmanaged(T) = .{},
        allocator: std.mem.Allocator,

        pub const Error = std.mem.Allocator.Error;

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit(self.allocator);
            self.* = undefined;
        }

        // --- Adding Items ---

        pub fn append(self: *Self, item: T) Error!void {
            try self.list.append(self.allocator, item);
        }

        pub fn appendSlice(self: *Self, items: []const T) Error!void {
            try self.list.appendSlice(self.allocator, items);
        }

        pub fn insert(self: *Self, i: usize, item: T) Error!void {
            try self.list.insert(self.allocator, i, item);
        }

        // --- Removing Items ---

        /// Removes and returns the last item. Asserts that the list is not empty.
        pub fn pop(self: *Self) ?T {
            return self.list.pop();
        }

        /// Removes item at index `i` and returns it. Shifts all subsequent items to the left.
        pub fn orderedRemove(self: *Self, i: usize) T {
            return self.list.orderedRemove(i);
        }

        /// Removes item at index `i` by swapping it with the last item. Faster than
        /// orderedRemove but does not preserve order. Returns the removed item.
        pub fn swapRemove(self: *Self, i: usize) T {
            return self.list.swapRemove(i);
        }

        // --- Capacity and Size Management ---

        /// Ensures there is capacity for at least `new_capacity` items.
        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) Error!void {
            try self.list.ensureTotalCapacity(self.allocator, new_capacity);
        }

        /// Resizes the list to `new_len`. If `new_len` is larger than the current
        /// length, the new items will be `undefined`.
        pub fn resize(self: *Self, new_len: usize) Error!void {
            try self.list.resize(self.allocator, new_len);
        }

        /// Removes all items from the list, but keeps the underlying memory allocation.
        pub fn clearRetainingCapacity(self: *Self) void {
            self.list.clearRetainingCapacity();
        }

        // --- Accessors ---

        /// Returns a pointer to the last element. Panics if the list is empty.
        pub fn getLast(self: *Self) T {
            return self.list.getLast();
        }

        /// Returns the number of items in the list.
        pub fn len(self: *const Self) usize {
            return self.list.items.len;
        }

        /// Creates a new, separate slice containing all items from the list.
        /// The caller is responsible for freeing the slice's memory.
        pub fn toOwnedSlice(self: *Self) Error![]T {
            return self.list.toOwnedSlice(self.allocator);
        }

        /// Returns a slice of the items. Same as accessing the `.items` field.
        pub fn toSlice(self: *const Self) []T {
            return self.list.items;
        }
    };
}

const testing = std.testing;
test "Basic Tests" {
    var allocator = testing.allocator;

    var list = ManagedArrayList(i32).init(allocator);
    defer list.deinit();

    // 1. Initial State
    try testing.expectEqual(@as(usize, 0), list.len());
    try testing.expectEqual(@as(usize, 0), list.toSlice().len);

    // 2. Append
    try list.append(10);
    try testing.expectEqual(@as(usize, 1), list.len());
    try testing.expectEqual(@as(i32, 10), list.toSlice()[0]);

    try list.append(20);
    try testing.expectEqual(@as(usize, 2), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 20 }, list.toSlice());
    try testing.expectEqualSlices(i32, &.{ 10, 20 }, list.list.items);
    std.debug.print("{any}Watch\n", .{list.toSlice()});
    std.debug.print("{any}Watch\n", .{list.list.items});

    // 3. Append Slice
    try list.appendSlice(&.{ 30, 40, 50 });
    try testing.expectEqual(@as(usize, 5), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 20, 30, 40, 50 }, list.toSlice());

    // 4. Insert
    try list.insert(1, 15); // Insert in the middle
    try testing.expectEqualSlices(i32, &.{ 10, 15, 20, 30, 40, 50 }, list.toSlice());
    try testing.expectEqual(@as(usize, 6), list.len());

    // 5. Pop
    const popped_item = list.pop();
    try testing.expectEqual(@as(i32, 50), popped_item);
    try testing.expectEqual(@as(usize, 5), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 15, 20, 30, 40 }, list.toSlice());

    // 6. Ordered Remove
    const removed_item = list.orderedRemove(2); // Remove '20'
    try testing.expectEqual(@as(i32, 20), removed_item);
    try testing.expectEqual(@as(usize, 4), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 15, 30, 40 }, list.toSlice()); // Order is preserved

    // 7. Swap Remove
    const swap_removed = list.swapRemove(1); // Remove '15', swaps last element '40' into its place
    try testing.expectEqual(@as(i32, 15), swap_removed);
    try testing.expectEqual(@as(usize, 3), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 40, 30 }, list.toSlice()); // Order is NOT preserved

    // 8. Get Last & Modify
    const last_ptr = list.getLast();
    try testing.expectEqual(@as(i32, 30), last_ptr);

    // 9. Ensure Capacity and Clear
    const capacity_before_clear = list.list.capacity;
    list.clearRetainingCapacity();
    try testing.expectEqual(@as(usize, 0), list.len());
    // Ensure the underlying allocation was kept
    try testing.expect(list.list.capacity == capacity_before_clear);

    // 10. Re-using after clearing
    try list.append(100);
    try testing.expectEqualSlices(i32, &.{100}, list.toSlice());

    // 11. toOwnedSlice
    const owned = try list.toOwnedSlice();
    defer allocator.free(owned); // Caller owns the memory
    try testing.expectEqualSlices(i32, &.{100}, owned);
    try testing.expect(owned.ptr != list.toSlice().ptr); // It's a copy, not a view
}
