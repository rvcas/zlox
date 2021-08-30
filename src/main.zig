const std = @import("std");

const chunk = @import("chunk.zig");
const Chunk = chunk.Chunk;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var ch = Chunk.init(&arena.allocator);
    defer ch.deinit();

    const constant = try ch.addConstant(1.2);

    try ch.writeOpCode(.constant, 123);
    try ch.write(constant, 123);

    try ch.writeOpCode(.ret, 123);

    ch.disassemble("test chunk");
}

test {
    std.testing.refAllDecls(@This());
}
