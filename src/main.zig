const std = @import("std");
const jazz = @import("root.zig");

const Matrix = jazz.Matrix;

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(allocator.deinit() == .ok);
    const gpa = allocator.allocator();

    const m = 512;
    const n = 1024;
    const k = 512;
    const buffer1 = try gpa.alloc(f32, m * n);
    defer gpa.free(buffer1);
    const a: Matrix(f32, m, n) = .{ .data = buffer1[0 .. m * n] };

    const buffer2 = try gpa.alloc(f32, n * k);
    defer gpa.free(buffer2);
    const b: Matrix(f32, n, k) = .{ .data = buffer2[0 .. n * k] };

    for (0..m * n) |i| {
        buffer1[i] = @floatFromInt(i);
    }

    for (0..n * k) |i| {
        buffer2[i] = @floatFromInt(i);
    }

    const buffer3 = try gpa.alloc(f32, m * k);
    defer gpa.free(buffer3);
    const c: Matrix(f32, m, k) = .{ .data = buffer3[0 .. m * k] };
    jazz.mul(a, b, c);

    // var i: usize = 0;
    // for (0..m) |_| {
    //     for (0..k) |_| {
    //         std.debug.print("{d} ", .{c.data[i]});
    //         i += 1;
    //     }
    //
    //     std.debug.print("\n", .{});
    // }
}
