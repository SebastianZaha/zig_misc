const assert = @import("std").debug.assert;
const terminal = @import("terminal.zig");

// GDT segment selectors.
pub const KERNEL_CODE = 0x08;
pub const KERNEL_DATA = 0x10;
pub const USER_CODE   = 0x18;
pub const USER_DATA   = 0x20;
pub const TSS_DESC    = 0x28;

// Access permission values.
const KERNEL = 0x90;
const USER   = 0xF0;
const CODE   = 0x0A;
const DATA   = 0x02;

// Segment flags.
const PROTECTED = (1 << 2);
const BLOCKS_4K = (1 << 3);

// Structure representing an entry in the GDT.
const GDTEntry = packed struct {
    limit_lo:  u16,
    base_lo:   u16,
    base_mid:   u8,
    access:     u8,
    limit_hi: u4,
    flags:      u4,
    base_hi:  u8,
};

// GDT descriptor register.
const GDTRegister = packed struct {
    /// Size of the GDT, MINUS ONE! The GDT can be between 1 and 65536 bytes.
    size: u16,
    /// Linear address of the table (PAGING APPLIES)
    offset: u32
};

test "Struct size" {
    assert(@sizeOf(GDTEntry) == 8);
}

// Generate a GDT entry structure.
fn makeEntry(base: u32, limit: u32, access: u8, flags: u4) GDTEntry {
    return GDTEntry { 
        .limit_lo  = @intCast(u16, limit & 0xFFFF),
        .base_lo   = @intCast(u16, base & 0xFFFF),
        .base_mid   = @intCast(u8, (base & 0xFF0000) >> 16),
        .access     = @intCast(u8, access),
        .limit_hi = @intCast(u4, limit >> 16),
        .flags      = @intCast(u4, flags),
        .base_hi  = @intCast(u8, base >> 24),
    };
}

// Fill in the GDT
const numEntries = 5;
export var gdtr: GDTRegister = undefined;

// Load the GDT structure in the system registers.
pub fn initialize() void {
    terminal.write("Initializing the GDT\n");

    var gdt = [numEntries]GDTEntry {
        makeEntry(0, 0, 0, 0),
        makeEntry(0, 0xFFFFF, KERNEL | CODE, PROTECTED | BLOCKS_4K),
        makeEntry(0, 0xFFFFF, KERNEL | DATA, PROTECTED | BLOCKS_4K),
        makeEntry(0, 0xFFFFF, USER   | CODE, PROTECTED | BLOCKS_4K),
        makeEntry(0, 0xFFFFF, USER   | DATA, PROTECTED | BLOCKS_4K),
    };

    // GDT descriptor register pointing at the GDT.
    gdtr = GDTRegister {
        .size = (numEntries * @sizeOf(GDTEntry)) - 1,
        .offset = @ptrToInt(&gdt),
    };

    asm volatile(
        \\lgdt gdtr
        \\movw $0x10, %%ax
        \\movw %%ax, %%ds
        \\movw %%ax, %%es
        \\movw %%ax, %%fs
        \\movw %%ax, %%gs
        \\movw %%ax, %%ss
        \\jmp $0x08, $.set_code_selector
        \\.set_code_selector:
        ::: "ax"
    );
}
