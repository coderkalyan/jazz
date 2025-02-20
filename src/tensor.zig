const std = @import("std");

pub const Dimension = struct {
    len: usize,
    stride: usize,
};

pub fn Tensor(comptime T: type, comptime rank: usize, comptime dimensions: [rank]Dimension) type {
    var tensor = struct {
        pub const Self = @This();
        pub const ElementType = T;
        pub const Inner = dimensions[1..];

        comptime size: usize = undefined,
        comptime shape: [rank]usize = undefined,
        comptime stride: [rank]usize = undefined,

        data: *[Self.size]T,

        pub fn Permute(comptime indices: [rank]usize) type {
            // verify permute indices are unique and in bounds
            comptime var sorted: [rank]usize = undefined;
            @memcpy(&sorted, &indices);
            std.mem.sort(&sorted, {}, std.sort.asc(usize));

            for (1..rank) |i| {
                if (sorted[i] != i) @compileError("unexpected permute index");
            }

            comptime var permuted: [rank]Dimension = undefined;
            for (indices, 0..) |j, i| {
                permuted[i] = j;
            }

            return Tensor(T, rank, indices);
        }

        pub fn Transpose(comptime i: usize, j: usize) type {
            comptime var indices: [rank]usize = undefined;
            for (0..rank) |k| {
                indices[k] = if (k == i) j else if (k == j) i else k;
            }

            return Permute(indices);
        }

        pub fn fill(self: Self, value: T) void {
            @memset(self.data, value);
        }

        pub fn permute(self: Self, comptime indices: [rank]usize) Permute(indices) {
            return .{ .data = self.data };
        }

        pub fn transpose(self: Self, comptime pair: struct { i: usize = 1, j: usize = 0 }) Transpose(pair.i, pair.j) {
            return .{ .data = self.data };
        }

        //     pub fn offset(indices: []usize) usize {
        //     std.debug.assert(indices.len <= rank);
        //
        // }
    };

    for (dimensions, 0..) |dimension, i| {
        tensor.size *= dimension.len;
        tensor.shape[i] = dimension.len;
        tensor.strides[i] = dimension.stride;
    }

    return tensor;
}

pub fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return Tensor(T, &.{ .{ rows, cols }, .{ cols, 1 } });
}

pub const Order = enum {
    row_major,
    column_major,
};

pub fn ordered(comptime order: Order, comptime rank: usize, comptime lens: [rank]usize) [rank]Dimension {
    switch (order) {
        .row_major => {
            var dimensions: [rank]Dimension = undefined;
            var stride: usize = 1;

            var i = rank;
            while (i > 0) {
                i -= 1;
                dimensions[i] = .{ .len = lens[i], .stride = stride };
                stride *= lens[i];
            }

            const DummyTensor = Tensor(void, rank, dimensions);
            std.debug.assert(stride == DummyTensor.size);

            return dimensions;
        },
        .column_major => {
            var dimensions: [rank]Dimension = undefined;
            var stride: usize = 1;

            var i = 0;
            while (i < rank) {
                dimensions[i] = .{ .len = lens[i], .stride = stride };
                stride *= lens[i];
                i += 1;
            }

            const DummyTensor = Tensor(void, rank, dimensions);
            std.debug.assert(stride == DummyTensor.size);

            return dimensions;
        },
    }
}
