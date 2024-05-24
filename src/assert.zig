const std = @import("std");
const lib = @import("./lib.zig");

pub fn assert(ok: bool) void {
    if (!ok) {
        unreachable;
    }
}

pub fn assertStatic(comptime ok: bool) void {
    if (!ok) {
        @compileError("assertion failed");
    }
}

pub fn expect(ok: bool) error{AssertionFailed}!void {
    if (!ok) {
        return error.AssertionFailed;
    }
}

pub fn expectEqual(left: anytype, right: @TypeOf(left)) error{AssertionFailed}!void {
    if (!lib.common.equal(left, right)) {
        std.debug.print("left: {!} != right: {!}\n", .{ left, right });

        return error.AssertionFailed;
    }
}

test {
    std.testing.refAllDecls(@This());
}
