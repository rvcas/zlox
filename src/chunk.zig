const std = @import("std");
const value = @import("value.zig");

const ArrayList = std.ArrayList;

const Value = value.Value;

const OpCode = enum(u8) {
    constant,
    ret,
};

pub const Chunk = struct {
    code: ArrayList(u8),
    constants: ArrayList(Value),
    lines: ArrayList(usize),

    pub fn init(allocator: *std.mem.Allocator) Chunk {
        return .{
            .code = ArrayList(u8).init(allocator),
            .constants = ArrayList(Value).init(allocator),
            .lines = ArrayList(usize).init(allocator),
        };
    }

    pub fn deinit(self: *const Chunk) void {
        self.code.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn write(self: *Chunk, byte: u8, line: usize) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    pub fn writeOpCode(self: *Chunk, op: OpCode, line: usize) !void {
        try self.write(@enumToInt(op), line);
    }

    pub fn addConstant(self: *Chunk, val: Value) !u8 {
        const index = @intCast(u8, self.constants.items.len);

        try self.constants.append(val);

        return index;
    }

    pub fn disassemble(self: *Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});

        var offset: usize = 0;
        while (offset < self.code.items.len) {
            offset = self.disassembleInstruction(offset);
        }
    }

    pub fn disassembleInstruction(self: *Chunk, offset: usize) usize {
        std.debug.print("{d:0>4} ", .{offset});

        if (offset > 0 and self.lines.items[offset] == self.lines.items[offset - 1]) {
            std.debug.print("   | ", .{});
        } else {
            std.debug.print("{d: >4} ", .{self.lines.items[offset]});
        }

        const instruction = @intToEnum(OpCode, self.code.items[offset]);

        return switch (instruction) {
            .constant => self.constantInstruction("constant", offset),
            .ret => simpleInstruction("ret", offset),
        };
    }

    fn simpleInstruction(name: []const u8, offset: usize) usize {
        std.debug.print("{s}\n", .{name});

        return offset + 1;
    }

    fn constantInstruction(self: *Chunk, name: []const u8, offset: usize) usize {
        const constant = self.code.items[offset + 1];

        std.debug.print("{s: <16} {d: >4} '{d}'\n", .{ name, constant, self.constants.items[constant] });

        return offset + 2;
    }
};

const testing = std.testing;

test "chunk init" {
    const chunk = Chunk.init(testing.allocator);
    defer chunk.deinit();

    try testing.expectEqual(chunk.code.items.len, 0);
    try testing.expectEqual(chunk.code.capacity, 0);
}

test "chunk write" {
    var chunk = Chunk.init(testing.allocator);
    defer chunk.deinit();

    try chunk.writeOpCode(.ret, 123);

    try testing.expectEqual(chunk.code.items.len, 1);
}
