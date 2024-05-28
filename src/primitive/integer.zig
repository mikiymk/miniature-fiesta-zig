//! (lib.primitive.integer)
//!
//! 整数型の操作する関数を与えます。
//!
//! # 整数型について
//!
//! 整数型に含まれる型は以下にリストされます。
//!
//! - ビットサイズの指定された符号あり整数型 (`i0`から`i65535`)
//! - ビットサイズの指定された符号なし整数型 (`u0`から`u65535`)
//! - ポインタサイズの符号あり整数型 (`isize`)
//! - ポインタサイズの符号なし整数型 (`usize`)
//! - コンパイル時整数型 (`comptime_int`)
//!
//! 符号あり整数型は2の補数表現で表されます。
//!
//! ## 整数型の暗黙的な型変換
//!
//! 1つの整数型(A)がもう1つの整数型(B)の値をすべて表現できるとき、B型の値はA型の値として使用できます。
//!
//! # 整数型の演算について
//!
//! ## 足し算 (`+`)
//!
//! 二つの整数の和を返します。
//! 結果がその整数型で表せない場合、未定義動作になります。
//!
//! - コンパイル時に値がわかっている場合、コンパイルエラー
//! - コンパイル時に値がわからず、ランタイム安全性が有効な場合、パニック
//! - コンパイル時に値がわからず、ランタイム安全性が無効な場合、ラッピング動作
//!

const std = @import("std");
const lib = @import("../lib.zig");
const assert = lib.assert;

/// このデータ構造は Zig 言語コード生成で使用されるため、コンパイラー実装と同期を保つ必要があります。
pub const Signedness = std.builtin.Signedness;

pub const OverflowError = error{IntegerOverflow};
pub const DivZeroError = error{DivideByZero};

const negation_error_message = "符号反転は符号あり整数型である必要があります。";

// 定数

pub const POINTER_SIZE = sizeOf(usize);

// 整数型を作る関数

/// 符号とビット数から整数型を返します。
pub fn Integer(signedness: Signedness, bits: u16) type {
    return @Type(.{ .Int = .{
        .signedness = signedness,
        .bits = bits,
    } });
}

/// 整数型を受け取り、同じビット数の符号あり整数を返します。
pub fn Signed(T: type) type {
    return Integer(.signed, sizeOf(T));
}

/// 整数型を受け取り、同じビット数の符号なし整数を返します。
pub fn Unsigned(T: type) type {
    return Integer(.unsigned, sizeOf(T));
}

/// ビット数をnビット増やした同じ符号の整数を返します。
fn Extend(T: type, n: u16) type {
    return Integer(signOf(T), sizeOf(T) + n);
}

test "符号とビットサイズから整数型を作成する" {
    const IntType: type = Integer(.signed, 16);
    try assert.expectEqual(IntType, i16);
}

// 整数型の種類を調べる関数

/// 型が符号あり整数型かどうかを判定します。
///
/// 符号あり整数型(`i0`から`i65535`、 または`isize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isSignedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .signed,
        else => false,
    };
}

/// 型が符号なし整数型かどうかを判定します。
///
/// 符号なし整数型(`u0`から`u65535`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isUnsignedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => |i| i.signedness == .unsigned,
        else => false,
    };
}

/// 型がビットサイズの整数型かどうかを判定します。
///
/// ビットサイズの指定された整数型(`i0`から`i65535`、 または`u0`から`u65535`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isBitSizedInteger(T: type) bool {
    const info = @typeInfo(T);

    return switch (info) {
        .Int => T != usize and T != isize,
        else => false,
    };
}

/// 型がポインタサイズの整数型かどうかを判定します。
///
/// ポインタサイズの整数型(`isize`、 または`usize`)の場合は`true`、 それ以外の場合は`false`を返します。
pub fn isPointerSizedInteger(T: type) bool {
    return T == usize or T == isize;
}

/// 型が実行時整数(`comptime_int`以外の整数型)かどうかを判定します。
pub fn isRuntimeInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .Int;
}

/// 型がコンパイル時整数(`comptime_int`)かどうかを判定します。
pub fn isComptimeInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .ComptimeInt;
}

/// 型が整数かどうかを判定します。
pub fn isInteger(T: type) bool {
    const info = @typeInfo(T);

    return info == .Int or info == .ComptimeInt;
}

/// 整数型の符号を調べます。
pub fn signOf(T: type) Signedness {
    assert.assert(isRuntimeInteger(T));

    return @typeInfo(T).Int.signedness;
}

/// 整数型のビットサイズを調べます。
pub fn sizeOf(T: type) u16 {
    assert.assert(isRuntimeInteger(T));

    return @typeInfo(T).Int.bits;
}

test "型を調べる関数" {
    const expect = assert.expect;

    try expect(isSignedInteger(i32));
    try expect(!isSignedInteger(u32));
    try expect(!isSignedInteger(f32));
    try expect(isSignedInteger(isize));
    try expect(!isSignedInteger(usize));
    try expect(!isSignedInteger(comptime_int));

    try expect(!isUnsignedInteger(i32));
    try expect(isUnsignedInteger(u32));
    try expect(!isUnsignedInteger(f32));
    try expect(!isUnsignedInteger(isize));
    try expect(isUnsignedInteger(usize));
    try expect(!isUnsignedInteger(comptime_int));

    try expect(isBitSizedInteger(i32));
    try expect(isBitSizedInteger(u32));
    try expect(!isBitSizedInteger(f32));
    try expect(!isBitSizedInteger(isize));
    try expect(!isBitSizedInteger(usize));
    try expect(!isBitSizedInteger(comptime_int));

    try expect(!isPointerSizedInteger(i32));
    try expect(!isPointerSizedInteger(u32));
    try expect(!isPointerSizedInteger(f32));
    try expect(isPointerSizedInteger(isize));
    try expect(isPointerSizedInteger(usize));
    try expect(!isPointerSizedInteger(comptime_int));

    try expect(!isComptimeInteger(i32));
    try expect(!isComptimeInteger(u32));
    try expect(!isComptimeInteger(f32));
    try expect(!isComptimeInteger(isize));
    try expect(!isComptimeInteger(usize));
    try expect(isComptimeInteger(comptime_int));

    try expect(isInteger(i32));
    try expect(isInteger(u32));
    try expect(!isInteger(f32));
    try expect(isInteger(isize));
    try expect(isInteger(usize));
    try expect(isInteger(comptime_int));

    try expect(sizeOf(i32) == 32);
    try expect(sizeOf(u32) == 32);
    _ = sizeOf(usize);

    try expect(isInteger(c_char));
    try expect(isInteger(c_short));
    try expect(isInteger(c_ushort));
    try expect(isInteger(c_int));
    try expect(isInteger(c_uint));
    try expect(isInteger(c_long));
    try expect(isInteger(c_ulong));
    try expect(isInteger(c_longlong));
    try expect(isInteger(c_ulonglong));
}

// 整数型の最大値と最小値を求める関数

/// 与えられた整数型の表現できる最大の整数を返します。
pub fn max(T: type) T {
    assert.assert(isRuntimeInteger(T));

    return switch (comptime signOf(T)) {
        .unsigned => ~@as(T, 0),
        .signed => ~@as(Unsigned(T), 0) >> 1,
    };
}

/// 与えられた整数型の表現できる最小の整数を返します。
pub fn min(T: type) T {
    assert.assert(isRuntimeInteger(T));

    return switch (comptime signOf(T)) {
        .unsigned => 0,
        .signed => ~max(T),
    };
}

test "最大値と最小値" {
    const expect = assert.expectEqual;

    try expect(max(u8), 0xff);
    try expect(min(u8), 0);

    try expect(max(i8), 0x7f);
    try expect(min(i8), -0x80);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合はエラーを返します。
pub fn cast(T: type, value: anytype) OverflowError!T {
    assert.assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    if (max(T) < value or value < min(T)) {
        return OverflowError.IntegerOverflow;
    }

    return @intCast(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は剰余の値を返します。
pub fn castTruncate(T: type, value: anytype) T {
    assert.assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    return @truncate(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は最大値・最小値に制限されます。
pub fn castSaturation(T: type, value: anytype) T {
    assert.assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    if (max(T) < value) {
        return max(T);
    } else if (value < min(T)) {
        return min(T);
    }

    return @intCast(value);
}

/// 値を指定した型に変換します。
/// 値が型の上限より大きい場合は未定義動作になります。
pub fn castUnsafe(T: type, value: anytype) T {
    assert.assert(isRuntimeInteger(T) and isRuntimeInteger(@TypeOf(value)));

    return @intCast(value);
}

test "型キャスト" {
    const expect = assert.expectEqual;

    const foo1: u9 = 1;
    const foo2: u16 = 0xfff;
    const foo3: i8 = -1;
    const foo4: i9 = -1;

    try expect(cast(u8, foo1), 1);
    try expect(cast(u8, foo2), error.IntegerOverflow);
    try expect(cast(u8, foo3), error.IntegerOverflow);
    try expect(cast(u8, foo4), error.IntegerOverflow);

    try expect(castTruncate(u8, foo1), 1);
    try expect(castTruncate(u8, foo2), 0xff);
    // try expect(castTruncate(u8, foo3), 0xff); // build error
    // try expect(castTruncate(u8, foo4), 0xff); // build error

    try expect(castSaturation(u8, foo1), 1);
    try expect(castSaturation(u8, foo2), 0xff);
    try expect(castSaturation(u8, foo3), 0);
    try expect(castSaturation(u8, foo4), 0);
}

/// 値のビットを符号あり整数型として返します。
pub fn asSigned(T: type, value: T) Signed(T) {
    assert.assert(isUnsignedInteger(T));

    return @bitCast(value);
}

/// 値のビットを符号なし整数型として返します。
pub fn asUnsigned(T: type, value: T) Unsigned(T) {
    assert.assert(isSignedInteger(T));

    return @bitCast(value);
}

test "ビット型変換" {
    const expect = assert.expectEqual;

    try expect(asSigned(u8, 0x80), -0x80);
    try expect(asSigned(u8, 0xff), -1);

    try expect(asUnsigned(i8, -1), 0xff);
    try expect(asUnsigned(i8, -0x80), 0x80);
}

// 符号反転

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合はエラーを返します。
pub fn negation(T: type, value: T) OverflowError!T {
    assert.assert(isSignedInteger(T));

    if (value == min(T)) {
        return OverflowError.IntegerOverflow;
    }

    return -%value;
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn negationWrapping(T: type, value: T) T {
    assert.assert(isSignedInteger(T));

    return -%value;
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は剰余の値を返します。
pub fn negationExtend(T: type, value: T) Extend(T, 1) {
    assert.assert(isSignedInteger(T));

    return -%@as(Extend(T, 1), value);
}

/// 整数型の符号を反転させた値を返します。
/// 結果の値が型の上限より大きい場合は未定義動作になります。
pub fn negationUnsafe(T: type, value: T) T {
    assert.assert(isSignedInteger(T));

    return -value;
}

test "符号反転 符号あり" {
    const expect = assert.expectEqual;

    const num: i8 = 1;

    try expect(-num, -1);
    try expect(-%num, -1);

    try expect(negation(i8, num), -1);
    try expect(negationWrapping(i8, num), -1);
    try expect(negationExtend(i8, num), -1);
    try expect(negationUnsafe(i8, num), -1);
}

test "符号反転 符号あり オーバーフロー" {
    const expect = assert.expectEqual;

    const num: i8 = -0x80;

    // try expect(-num, 0x80); // build error
    try expect(-%num, -0x80);

    try expect(negation(i8, num), error.IntegerOverflow);
    try expect(negationWrapping(i8, num), -0x80);
    try expect(negationExtend(i8, num), 0x80);
    // try expect(negationUnsafe(i8, num), -0x80); // panic
}

test "足し算 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 2;
    const right: u8 = 2;

    try expect(left + right, 4);
    try expect(left +% right, 4);
    try expect(left +| right, 4);
    try expect(@addWithOverflow(left, right)[0], 4);
    try expect(@addWithOverflow(left, right)[1], 0);
}

test "足し算 符号なし 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: u8 = 0xff;
    const right: u8 = 1;

    // try expect(left + right, 0x100); // build error
    try expect(left +% right, 0);
    try expect(left +| right, 0xff);
    try expect(@addWithOverflow(left, right)[0], 0);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "足し算 符号あり" {
    const expect = assert.expectEqual;

    const left: i8 = 2;
    const right: i8 = 2;

    try expect(left + right, 4);
    try expect(left +% right, 4);
    try expect(left +| right, 4);
    try expect(@addWithOverflow(left, right)[0], 4);
    try expect(@addWithOverflow(left, right)[1], 0);
}

test "足し算 符号あり 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = 0x7f;
    const right: i8 = 1;

    // try expect(left + right, 0x80); // build error
    try expect(left +% right, -0x80);
    try expect(left +| right, 0x7f);
    try expect(@addWithOverflow(left, right)[0], -0x80);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "足し算 符号あり 下にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = -1;

    // try expect(left + right, -0x81); // build error
    try expect(left +% right, 0x7f);
    try expect(left +| right, -0x80);
    try expect(@addWithOverflow(left, right)[0], 0x7f);
    try expect(@addWithOverflow(left, right)[1], 1);
}

test "引き算 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 5;
    const right: u8 = 3;

    try expect(left - right, 2);
    try expect(left -% right, 2);
    try expect(left -| right, 2);
    try expect(@subWithOverflow(left, right)[0], 2);
    try expect(@subWithOverflow(left, right)[1], 0);
}

test "引き算 符号なし 下にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: u8 = 3;
    const right: u8 = 5;

    // try expect(left - right, -2); // build error
    try expect(left -% right, 0xfe);
    try expect(left -| right, 0);
    try expect(@subWithOverflow(left, right)[0], 0xfe);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "引き算 符号あり" {
    const expect = assert.expectEqual;

    const left: i8 = 3;
    const right: i8 = 5;

    try expect(left - right, -2);
    try expect(left -% right, -2);
    try expect(left -| right, -2);
    try expect(@subWithOverflow(left, right)[0], -2);
    try expect(@subWithOverflow(left, right)[1], 0);
}

test "引き算 符号あり 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = 0x7f;
    const right: i8 = -1;

    // try expect(left - right, 0x80); // build error
    try expect(left -% right, -0x80);
    try expect(left -| right, 0x7f);
    try expect(@subWithOverflow(left, right)[0], -0x80);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "引き算 符号あり 下にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = 1;

    // try expect(left - right, -0x81); // build error
    try expect(left -% right, 0x7f);
    try expect(left -| right, -0x80);
    try expect(@subWithOverflow(left, right)[0], 0x7f);
    try expect(@subWithOverflow(left, right)[1], 1);
}

test "掛け算 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 4;
    const right: u8 = 3;

    try expect(left * right, 12);
    try expect(left *% right, 12);
    try expect(left *| right, 12);
    try expect(@mulWithOverflow(left, right)[0], 12);
    try expect(@mulWithOverflow(left, right)[1], 0);
}

test "掛け算 符号なし 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: u8 = 0x10;
    const right: u8 = 0x10;

    // try expect(left * right, 0x100); // build error
    try expect(left *% right, 0);
    try expect(left *| right, 0xff);
    try expect(@mulWithOverflow(left, right)[0], 0);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "掛け算 符号あり" {
    const expect = assert.expectEqual;

    const left: i8 = -2;
    const right: i8 = 4;

    try expect(left * right, -8);
    try expect(left *% right, -8);
    try expect(left *| right, -8);
    try expect(@mulWithOverflow(left, right)[0], -8);
    try expect(@mulWithOverflow(left, right)[1], 0);
}

test "掛け算 符号あり 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = 0x40;
    const right: i8 = 2;

    // try expect(left * right, 0x80); // build error
    try expect(left *% right, -0x80);
    try expect(left *| right, 0x7f);
    try expect(@mulWithOverflow(left, right)[0], -0x80);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "掛け算 符号あり 下にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = -0x80;
    const right: i8 = 2;

    // try expect(left * right, -0x100); // build error
    try expect(left *% right, 0);
    try expect(left *| right, -0x80);
    try expect(@mulWithOverflow(left, right)[0], 0);
    try expect(@mulWithOverflow(left, right)[1], 1);
}

test "割り算 符号なし 余りなし" {
    const expect = assert.expectEqual;

    const left: u8 = 6;
    const right: u8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    try expect(@divExact(left, right), 2);
}

test "割り算 符号なし 余りあり" {
    const expect = assert.expectEqual;

    const left: u8 = 7;
    const right: u8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号なし ゼロ除算" {
    // const expect = assert.expectEqual;

    // const left: u8 = 6;
    // const right: u8 = 0;

    // try expect(left / right, 2); // build error
    // try expect(@divTrunc(left, right), 2); // build error
    // try expect(@divFloor(left, right), 2); // build error
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号あり" {
    const expect = assert.expectEqual;

    const left: i8 = 6;
    const right: i8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    try expect(@divExact(left, right), 2);
}

test "割り算 符号あり オーバーフロー" {
    // const expect = assert.expectEqual;

    // const left: i8 = -0x80;
    // const right: i8 = -1;

    // try expect(left / right, 0x80); // build error
    // try expect(@divTrunc(left, right), 0x80); // build error
    // try expect(@divFloor(left, right), 0x80); // build error
    // try expect(@divExact(left, right), 0x80); // build error
}

test "割り算 符号あり 余りあり 正÷正" {
    const expect = assert.expectEqual;

    const left: i8 = 7;
    const right: i8 = 3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号あり 余りあり 正÷負" {
    const expect = assert.expectEqual;

    const left: i8 = 7;
    const right: i8 = -3;

    try expect(left / right, -2);
    try expect(@divTrunc(left, right), -2);
    try expect(@divFloor(left, right), -3);
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号あり 余りあり 負÷正" {
    const expect = assert.expectEqual;

    const left: i8 = -7;
    const right: i8 = 3;

    try expect(left / right, -2);
    try expect(@divTrunc(left, right), -2);
    try expect(@divFloor(left, right), -3);
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号あり 余りあり 負÷負" {
    const expect = assert.expectEqual;

    const left: i8 = -7;
    const right: i8 = -3;

    try expect(left / right, 2);
    try expect(@divTrunc(left, right), 2);
    try expect(@divFloor(left, right), 2);
    // try expect(@divExact(left, right), 2); // build error
}

test "割り算 符号あり ゼロ除算" {
    // const expect = assert.expectEqual;

    // const left: i8 = -6;
    // const right: i8 = 0;

    // try expect(left / right, 2); // build error
    // try expect(@divTrunc(left, right), 2); // build error
    // try expect(@divFloor(left, right), 2); // build error
    // try expect(@divExact(left, right), 2); // build error
}

test "余り算 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 8;
    const right: u8 = 3;

    try expect(left % right, 2);
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), 2);
}

test "余り算 符号なし ゼロ除算" {
    // const expect = assert.expectEqual;

    // const left: u8 = 8;
    // const right: u8 = 0;

    // try expect(left % right, 2); // build error
    // try expect(@rem(left, right), 2); // build error
    // try expect(@mod(left, right), 2); // build error
}

test "余り算 符号あり 正÷正" {
    const expect = assert.expectEqual;

    const left: i8 = 8;
    const right: i8 = 3;

    try expect(left % right, 2);
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), 2);
}

test "余り算 符号あり 正÷負" {
    const expect = assert.expectEqual;

    const left: i8 = 8;
    const right: i8 = -3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), 2);
    try expect(@mod(left, right), -1);
}

test "余り算 符号あり 負÷正" {
    const expect = assert.expectEqual;

    const left: i8 = -8;
    const right: i8 = 3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), -2);
    try expect(@mod(left, right), 1);
}

test "余り算 符号あり 負÷負" {
    const expect = assert.expectEqual;

    const left: i8 = -8;
    const right: i8 = -3;

    // try expect(left % right, 2); // build error
    try expect(@rem(left, right), -2);
    try expect(@mod(left, right), -2);
}

test "余り算 符号あり ゼロ除算" {
    // const expect = assert.expectEqual;

    // const left: i8 = 8;
    // const right: i8 = 0;

    // try expect(left % right, 2); // build error
    // try expect(@rem(left, right), 2); // build error
    // try expect(@mod(left, right), 2); // build error
}

test "左ビットシフト 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 0b00000111;
    const right: u3 = 3;

    try expect(left << right, 0b00111000);
    try expect(left <<| right, 0b00111000);
    try expect(@shlExact(left, right), 0b00111000);
    try expect(@shlWithOverflow(left, right), .{ 0b00111000, 0 });
}

test "左ビットシフト 符号なし オーバーフロー" {
    const expect = assert.expectEqual;

    const left: u8 = 0b00000111;
    const right: u3 = 6;

    try expect(left << right, 0b11000000);
    try expect(left <<| right, 0b11111111);
    // try expect(@shlExact(left, right), 0b1_11000000); // build error
    try expect(@shlWithOverflow(left, right), .{ 0b11000000, 1 });
}

test "左ビットシフト 符号あり 正の数" {
    const expect = assert.expectEqual;

    const left: i8 = asSigned(u8, 0b00000111);
    const right: u3 = 3;

    try expect(left << right, asSigned(u8, 0b00111000));
    try expect(left <<| right, asSigned(u8, 0b00111000));
    try expect(@shlExact(left, right), asSigned(u8, 0b00111000));
    try expect(@shlWithOverflow(left, right), .{ asSigned(u8, 0b00111000), 0 });
}

test "左ビットシフト 符号あり 負の数" {
    const expect = assert.expectEqual;

    const left: i8 = asSigned(u8, 0b11111001);
    const right: u3 = 3;

    try expect(left << right, asSigned(u8, 0b11001000));
    try expect(left <<| right, asSigned(u8, 0b11001000));
    try expect(@shlExact(left, right), asSigned(u8, 0b11001000));
    try expect(@shlWithOverflow(left, right), .{ asSigned(u8, 0b11001000), 0 });
}

test "左ビットシフト 符号あり 正の数 オーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = asSigned(u8, 0b00000111);
    const right: u3 = 6;

    try expect(left << right, asSigned(u8, 0b11000000));
    try expect(left <<| right, asSigned(u8, 0b01111111));
    // try expect(@shlExact(left, right), asSigned(u8, 0b1_11000000)); // build error
    try expect(@shlWithOverflow(left, right), .{ asSigned(u8, 0b11000000), 1 });
}

test "左ビットシフト 符号あり 負の数 オーバーフロー" {
    const expect = assert.expectEqual;

    const left: i8 = asSigned(u8, 0b11111001);
    const right: u3 = 6;

    try expect(left << right, asSigned(u8, 0b01000000));
    try expect(left <<| right, asSigned(u8, 0b10000000));
    // try expect(@shlExact(left, right), asSigned(u8, 0b111110_01000000)); // build error
    try expect(@shlWithOverflow(left, right), .{ asSigned(u8, 0b01000000), 1 });
}

test "右ビットシフト 符号なし" {
    const expect = assert.expectEqual;

    const left: u8 = 0b10111000;
    const right: u3 = 3;

    try expect(left >> right, 0b00010111);
    try expect(@shrExact(left, right), 0b00010111);
}

test "右ビットシフト 符号なし オーバーフロー" {
    const expect = assert.expectEqual;

    const left: u8 = 0b10111000;
    const right: u3 = 6;

    try expect(left >> right, 0b00000010);
    // try expect(@shrExact(left, right), 0b00000010); // build error
}

test "右ビットシフト 符号あり 正の数" {
    const expect = assert.expectEqual;

    const left: i8 = asSigned(u8, 0b10111000);
    const right: u3 = 3;

    try expect(left >> right, asSigned(u8, 0b11110111));
    try expect(@shrExact(left, right), asSigned(u8, 0b11110111));
}

pub fn IntegerWrap(Int: type) type {
    assert.assertStatic(isInteger(Int));

    return struct {
        pub const Value = Int;
        pub const signedness = signOf(Int);
        pub const bits = sizeOf(Int);

        const Self = @This();

        value: Int,

        /// 二つの整数を足した結果を返します。
        /// 結果の値が型の上限より大きい場合はエラーを返します。
        pub fn add(self: Self, other: Self) OverflowError!Self {
            const result, const carry = @addWithOverflow(self.value, other.value);
            if (carry == 1) {
                return OverflowError.IntegerOverflow;
            }

            return .{ .value = result };
        }

        /// 二つの整数を足した結果を返します。
        /// 結果の値が型の上限より大きい場合は剰余の値を返します。
        pub fn addWrapping(self: Self, other: Self) Self {
            return .{ .value = self.value +% other.value };
        }

        /// 二つの整数を足した結果を返します。
        /// 結果の値が値が型の上限より大きい場合は最大値・最小値に制限されます。
        pub fn addSaturation(self: Self, other: Self) Self {
            return .{ .value = self.value +| other.value };
        }

        /// 二つの整数を足した結果を返します。
        /// 結果の値が値が型の上限より大きい場合は未定義動作になります。
        pub fn addUnsafe(self: Self, other: Self) Self {
            return .{ .value = self.value + other.value };
        }

        /// 二つの整数を足した結果を返します。
        /// 結果の値が値が型の上限より大きい場合はタプルの2番目の値に1を返します。
        pub fn addOverflow(self: Self, other: Self) struct { Self, u1 } {
            const result, const carry = @addWithOverflow(self.value, other.value);

            return .{ .{ .value = result }, carry };
        }

        pub const AddExtend = IntegerWrap(Integer(signedness, bits + 1));

        /// 二つの整数を足した結果を返します。
        /// すべての結果の値が収まるように結果の型を拡張します。
        pub fn addExtend(self: Self, other: Self) AddExtend {
            const result_value = @as(AddExtend.Value, self.value) + other.value;

            return .{ .value = result_value };
        }
    };
}

pub const U8 = IntegerWrap(u8);
pub const U16 = IntegerWrap(u16);
pub const U32 = IntegerWrap(u32);
pub const U64 = IntegerWrap(u64);
pub const U128 = IntegerWrap(u128);
pub const USize = IntegerWrap(usize);

pub const I8 = IntegerWrap(i8);
pub const I16 = IntegerWrap(i16);
pub const I32 = IntegerWrap(i32);
pub const I64 = IntegerWrap(i64);
pub const I128 = IntegerWrap(i128);
pub const ISize = IntegerWrap(isize);

test "整数ラッパーの足し算 符号なし" {
    const expect = assert.expectEqual;

    const left: U8 = .{ .value = 2 };
    const right: U8 = .{ .value = 2 };

    try expect(left.add(right), .{ .value = 4 });
    try expect(left.addWrapping(right), .{ .value = 4 });
    try expect(left.addSaturation(right), .{ .value = 4 });
    try expect(left.addUnsafe(right), .{ .value = 4 });
    try expect(left.addOverflow(right), .{ .{ .value = 4 }, 0 });
    try expect(left.addExtend(right), .{ .value = 4 });
}

test "整数ラッパーの足し算 符号なし 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: U8 = .{ .value = 0xff };
    const right: U8 = .{ .value = 1 };

    try expect(left.add(right), OverflowError.IntegerOverflow);
    try expect(left.addWrapping(right), .{ .value = 0 });
    try expect(left.addSaturation(right), .{ .value = 0xff });
    // try expect(left.addUnsafe(right), .{ .value = 0 }); // panic
    try expect(left.addOverflow(right), .{ .{ .value = 0 }, 1 });
    try expect(left.addExtend(right), .{ .value = 0x100 });
}

test "整数ラッパーの足し算 符号あり" {
    const expect = assert.expectEqual;

    const left: I8 = .{ .value = 2 };
    const right: I8 = .{ .value = 2 };

    try expect(left.add(right), .{ .value = 4 });
    try expect(left.addWrapping(right), .{ .value = 4 });
    try expect(left.addSaturation(right), .{ .value = 4 });
    try expect(left.addUnsafe(right), .{ .value = 4 });
    try expect(left.addOverflow(right), .{ .{ .value = 4 }, 0 });
    try expect(left.addExtend(right), .{ .value = 4 });
}

test "整数ラッパーの足し算 符号あり 上にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: I8 = .{ .value = 0x7f };
    const right: I8 = .{ .value = 1 };

    try expect(left.add(right), OverflowError.IntegerOverflow);
    try expect(left.addWrapping(right), .{ .value = -0x80 });
    try expect(left.addSaturation(right), .{ .value = 0x7f });
    // try expect(left.addUnsafe(right), .{ .value = 0 }); // panic
    try expect(left.addOverflow(right), .{ .{ .value = -0x80 }, 1 });
    try expect(left.addExtend(right), .{ .value = 0x80 });
}

test "整数ラッパーの足し算 符号あり 下にオーバーフロー" {
    const expect = assert.expectEqual;

    const left: I8 = .{ .value = -0x80 };
    const right: I8 = .{ .value = -1 };

    try expect(left.add(right), OverflowError.IntegerOverflow);
    try expect(left.addWrapping(right), .{ .value = 0x7f });
    try expect(left.addSaturation(right), .{ .value = -0x80 });
    // try expect(left.addUnsafe(right), .{ .value = 0 }); // panic
    try expect(left.addOverflow(right), .{ .{ .value = 0x7f }, 1 });
    try expect(left.addExtend(right), .{ .value = -0x81 });
}
