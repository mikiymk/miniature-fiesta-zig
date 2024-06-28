const zig_test = @import("../zig_test.zig");
const assert = zig_test.assert;
const consume = zig_test.consume;

test "整数リテラル 10進数" {
    _ = 42; // 10進数の整数
    _ = 1234567812345678123456781234567812345678123456781234567812345678; // リテラルは上限がない
    _ = 1_000_999; // _で区切ることができる

}

test "整数リテラル 2進数" {
    _ = 0b0110; // "0b" で始めると2進数
    _ = 0b1100_0011; // _で区切ることができる
}

test "整数リテラル 8進数" {
    _ = 0o704; // "0o" で始めると8進数
    _ = 0o567_123; // _で区切ることができる
}

test "整数リテラル 16進数" {
    _ = 0x1f2e; // "0x" で始めると16進数
    _ = 0x1F2E; // 大文字も使用できる
    _ = 0xabcd_ABCD; // _で区切ることができる
}

test "小数リテラル 10進数" {
    _ = 42.1; // 小数点付き数
    _ = 42e5; // 指数付き数
    _ = 42E5; // 大文字の指数付き数
    _ = 42e-5; // 負の指数付き数
    _ = 42.2e5; // 小数点と指数付き数
    _ = 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647; // リテラルは上限がない
    _ = 3.1415_9265; // _で区切ることができる

}

test "小数リテラル 16進数" {
    _ = 0x1f2e.3d4c; // "0x" で始めると16進数
    _ = 0xabcp10; // pで指数を区切る
    _ = 0x1a_2bP-3; // _で区切ることができる
}

test "文字リテラル" {
    _ = 'a'; // ''で囲うと文字リテラル
    _ = '😃'; // 1つのUnicodeコードポイントを表す

    _ = '\n'; // 改行
    _ = '\r'; // キャリッジリターン
    _ = '\t'; // タブ
    _ = '\\'; // バックスラッシュ
    _ = '\''; // 単引用符
    _ = '\"'; // 二重引用符
    _ = '\x64'; // 1バイト文字
    _ = '\u{1F604}'; // Unicodeコードポイント

}

test "文字列リテラル" {
    _ = "abc"; // ""で囲うと文字列リテラル
    _ = "dog\r\nwolf"; // エスケープシーケンス

}

test "文字列リテラル 複数行" {
    // \\から後ろは複数行文字列リテラル
    _ =
        \\abc
        \\def
    ;
    // エスケープシーケンス
    _ =
        \\a\tbc
    ;
}

test "列挙型リテラル" {
    _ = .enum_literal;
}

test "構造体型リテラル" {
    _ = .{};
}

test "エラーリテラル" {
    consume(error.Error);
}

test "リテラルの型" {
    try assert.expectEqual(@TypeOf(42), comptime_int);
    try assert.expectEqual(@TypeOf(0b0101), comptime_int);
    try assert.expectEqual(@TypeOf(0o42), comptime_int);
    try assert.expectEqual(@TypeOf(0x42), comptime_int);

    try assert.expectEqual(@TypeOf(42.5), comptime_float);

    try assert.expectEqual(@TypeOf('a'), comptime_int);

    try assert.expectEqual(@TypeOf("abc"), *const [3:0]u8);
    try assert.expectEqual(@TypeOf(
        \\abc
    ), *const [3:0]u8);

    try assert.expectEqual(@TypeOf(.enum_literal), @TypeOf(.enum_literal));

    try assert.expectEqual(@TypeOf(.{}), @TypeOf(.{}));

    try assert.expectEqual(error{Error}, @TypeOf(error.Error));
}
