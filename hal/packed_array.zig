//! Packed array implementation
const std = @import("std");

/// Simple bit packed array construct
pub fn PackedArray(comptime T: type, comptime len: usize, comptime default: ?T) type {
    // Get types
    const elem_size = @bitSizeOf(T);
    const ElemInt = std.meta.Int(.unsigned, elem_size);
    const BackingInt = std.meta.Int(.unsigned, elem_size * len);

    // Helper function for getting the elem as an integer
    const asInt = struct {
        pub inline fn helper(elem: T) ElemInt {
            return switch (@typeInfo(T)) {
                .@"enum" => @intFromEnum(elem),
                else => @bitCast(elem),
            };
        }
    }.helper;

    // Get the default items array
    const default_items = if (default) |elem| comptime blk: {
        var items: BackingInt = 0;
        for (0..len) |i| {
            items |= @as(BackingInt, asInt(elem)) << i * elem_size;
        }
        break :blk items;
    } else 0;

    // Return the struct
    return packed struct(BackingInt) {
        items: BackingInt = default_items,

        const elem_mask: BackingInt = (1 << elem_size) - 1;

        // Initialize every element to elem
        pub inline fn splat(elem: T) @This() {
            var this = @This(){ .items = 0 };
            inline for (0..len) |i| {
                this.items |= @as(BackingInt, asInt(elem)) << i * elem_size;
            }
            return this;
        }

        // Get an element
        pub inline fn at(this: @This(), n: usize) T {
            return @bitCast(@as(ElemInt, @truncate(this.items >> n * elem_size)));
        }

        // Set an element
        pub inline fn set(this: *@This(), n: usize, elem: T) void {
            const pos = @as(std.math.Log2Int(BackingInt), @intCast(n)) * 2;
            this.items &= ~(elem_mask << pos);
            this.items |= @as(BackingInt, asInt(elem)) << pos;
        }
    };
}
