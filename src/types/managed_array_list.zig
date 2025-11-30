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

        pub fn append(self: *Self, item_: T) Error!void {
            try self.list.append(self.allocator, item_);
        }

        pub fn appendSlice(self: *Self, items_: []const T) Error!void {
            try self.list.appendSlice(self.allocator, items_);
        }

        pub fn insert(self: *Self, i_: usize, item_: T) Error!void {
            try self.list.insert(self.allocator, i_, item_);
        }

        pub fn pop(self: *Self) ?T {
            return self.list.pop();
        }

        pub fn orderedRemove(self: *Self, i_: usize) T {
            return self.list.orderedRemove(i_);
        }

        pub fn swapRemove(self: *Self, i_: usize) T {
            return self.list.swapRemove(i_);
        }

        pub fn resize(self: *Self, new_len_: usize) Error!void {
            try self.list.resize(self.allocator, new_len_);
        }

        pub fn ensureTotalCapacity(self: *Self, new_capacity_: usize) Error!void {
            try self.list.ensureTotalCapacity(self.allocator, new_capacity_);
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.list.clearRetainingCapacity();
        }

        pub fn clone(self: *const Self) Error!Self {
            return .{
                .list = try self.list.clone(self.allocator),
                .allocator = self.allocator,
            };
        }

        pub fn toOwnedSlice(self: *Self) Error![]T {
            return self.list.toOwnedSlice(self.allocator);
        }

        pub fn len(self: *const Self) usize {
            return self.list.items.len;
        }

        pub fn getLast(self: *Self) T {
            return self.list.getLast();
        }

        pub fn items(self: *const Self) []T {
            return self.list.items;
        }
    };
}

const testing = std.testing;
test "Basic Tests" {
    var allocator = testing.allocator;

    var list = ManagedArrayList(i32).init(allocator);
    defer list.deinit();

    try testing.expectEqual(@as(usize, 0), list.len());
    try testing.expectEqual(@as(usize, 0), list.items().len);
    try testing.expectEqual(@as(usize, 0), list.list.capacity);

    try list.ensureTotalCapacity(10);
    try testing.expect(10 <= list.list.capacity);

    try list.append(10);
    try testing.expectEqual(@as(usize, 1), list.len());
    try testing.expectEqual(@as(i32, 10), list.items()[0]);

    try list.append(20);
    try testing.expectEqual(@as(usize, 2), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 20 }, list.items());

    try list.appendSlice(&.{ 30, 40, 50 });
    try testing.expectEqual(@as(usize, 5), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 20, 30, 40, 50 }, list.items());

    try list.insert(1, 15);
    try testing.expectEqual(@as(usize, 6), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 15, 20, 30, 40, 50 }, list.items());

    const popped_item = list.pop();
    try testing.expectEqual(@as(i32, 50), popped_item);
    try testing.expectEqual(@as(usize, 5), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 15, 20, 30, 40 }, list.items());

    const removed_item = list.orderedRemove(2);
    try testing.expectEqual(@as(i32, 20), removed_item);
    try testing.expectEqual(@as(usize, 4), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 15, 30, 40 }, list.items());

    const swap_removed = list.swapRemove(1);
    try testing.expectEqual(@as(i32, 15), swap_removed);
    try testing.expectEqual(@as(usize, 3), list.len());
    try testing.expectEqualSlices(i32, &.{ 10, 40, 30 }, list.items());

    const last_value = list.getLast();
    try testing.expectEqual(@as(i32, 30), last_value);

    const capacity_before_clear = list.list.capacity;
    list.clearRetainingCapacity();
    try testing.expectEqual(@as(usize, 0), list.len());
    try testing.expect(list.list.capacity == capacity_before_clear);

    try list.append(100);
    try testing.expectEqualSlices(i32, &.{100}, list.items());

    var list_clone: ManagedArrayList(i32) = try list.clone();
    defer list_clone.deinit();
    try testing.expectEqualSlices(i32, list_clone.items(), list.items());
    list_clone.items()[0] = 101;
    try testing.expectEqualSlices(i32, &.{100}, list.items());
    try testing.expectEqualSlices(i32, &.{101}, list_clone.items());

    const owned = try list.toOwnedSlice();
    defer allocator.free(owned);
    try testing.expectEqual(@as(usize, 0), list.len());
    try testing.expectEqualSlices(i32, &.{100}, owned);
    try testing.expect(owned.ptr != list.items().ptr);
}
