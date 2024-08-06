const std = @import("std");
const mime = @import("mime");
const Mime = mime.Mime;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const testing = std.testing;
const test_allocator = std.testing.allocator;
const mem = std.mem;

test "html smoke test" {
    const mime_type = mime.extension_map.get(".html").?;
    try std.testing.expectEqualStrings("text/html", @tagName(mime_type));
}

test "bogus extension" {
    try std.testing.expect(mime.extension_map.get(".sillybogo") == null);
}


test "Valid mime type" {
    // See more at https://mimesniff.spec.whatwg.org/#example-valid-mime-type-string
    const valid_case = [_][]const u8{
        "text/html",
        // text_plain_uppercase
        "TEXT/PLAIN",
        // text_plain_charset_utf8
        "text/plain; charset=utf-8",
        // text_plain_charset_utf8_uppercase
        "TEXT/PLAIN; CHARSET=UTF-8",
        // text_plain_charset_utf8_quoted
        "text/plain; charset=\"utf-8\"",
        // charset_utf8_extra_spaces
        "text/plain  ;  charset=utf-8  ;  foo=bar",
        // text_plain_charset_utf8_extra
        "text/plain; charset=utf-8; foo=bar",
        // text_plain_charset_utf8_extra_uppercase
        "TEXT/PLAIN; CHARSET=UTF-8; FOO=BAR",
        // subtype_space_before_params
        "text/plain ; charset=utf-8",
        // params_space_before_semi
        "text/plain; charset=utf-8 ; foo=bar",
    };
    var arena = ArenaAllocator.init(test_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    for (valid_case) |valid_type| {
        const mime_type = Mime.parse(arena_allocator, valid_type);
        try testing.expect(mime_type != null);
    }
}

test "Invalid mime type" {
    // See more at https://mimesniff.spec.whatwg.org/#example-valid-mime-type-string
    const invalid_case = [_][]const u8{
        // empty
        "",
        // slash_only
        "/",
        // slash_only_space
        " / ",
        // slash_only_space_before_params
        " / foo=bar",
        // slash_only_space_after_params
        "/html; charset=utf-8",
        "text/html;",
        // error_type_spaces
        "te xt/plain",
        // error_type_lf
        "te\nxt/plain",
        // error_type_cr
        "te\rxt/plain",
        // error_subtype_spaces
        "text/plai n",
        // error_subtype_crlf
        "text/\r\nplain",
        // error_param_name_crlf,
        "text/plain;\r\ncharset=utf-8",
        // error_param_value_quoted_crlf
        "text/plain;charset=\"\r\nutf-8\"",
        // error_param_space_before_equals
        "text/plain; charset =utf-8",
        // error_param_space_after_equals
        "text/plain; charset= utf-8",
    };
    var arena = ArenaAllocator.init(test_allocator);
    const arena_allocator = arena.allocator();
    defer arena.deinit();
    for (invalid_case) |invalid_str| {
        const invalid_type = Mime.parse(arena_allocator, invalid_str);
        try testing.expect(invalid_type == null);
    }
}

test "parse and params" {
    var arena = ArenaAllocator.init(test_allocator);
    const arena_allocator = arena.allocator();
    defer arena.deinit();
    var mime_type = Mime.parse(arena_allocator, "text/plain; charset=utf-8; foo=bar");

    try testing.expect(mem.eql(u8, mime_type.?.essence, "text/plain; charset=utf-8; foo=bar"));
    try testing.expect(mem.eql(u8, mime_type.?.basetype, "text"));
    try testing.expect(mem.eql(u8, mime_type.?.subtype, "plain"));

    const charset = mime_type.?.getParam("charset");
    try testing.expect(charset != null);
    try testing.expectEqualStrings("utf-8", charset.?);

    const foo = mime_type.?.getParam("foo");
    try testing.expect(foo != null);

    try testing.expectEqualStrings("bar", foo.?);
    const bar = mime_type.?.getParam("bar");
    try testing.expect(bar == null);
}
