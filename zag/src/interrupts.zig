const gdt = @import("gdt.zig");
const terminal = @import("terminal.zig");
const x86 = @import("arch_x86.zig");

pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE   = 0xEE;

// Structure representing an entry in the 
const IDTEntry = packed struct {
    offset_lo: u16, // offset bits 0..15
    selector:  u16, // a code segment selector in GDT or LDT
    zero:      u8,  // unused, set to 0
    flags:     u8,
    offset_hi: u16, // offset bits 16..31
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base:  *[256]IDTEntry,
};

// Interrupt Descriptor Table.
var idt: [256]IDTEntry = undefined;

// IDT descriptor register pointing at the 
const idtr = IDTRegister {
    .limit = 256 * @sizeOf(IDTEntry),
    .base  = &idt,
};

////
// Setup an IDT entry.
//
// Arguments:
//     index: Index of the gate.
//     flags: Type and attributes.
//     function: Address of the ISR.
//
fn setGate(index: u8, flags: u8, function: fn() callconv(.Naked) void) void {
    const intOffset = @ptrToInt(function);

    idt[index].offset_lo  = @truncate(u16, intOffset);
    idt[index].offset_hi  = @truncate(u16, intOffset >> 16);
    idt[index].flags      = flags;
    idt[index].zero       = 0;
    idt[index].selector   = gdt.KERNEL_CODE;
}


// Interrupt Service Routines defined externally in assembly.
extern fn  isr0()void; extern fn  isr1()void; extern fn  isr2()void; extern fn  isr3()void;
extern fn  isr4()void; extern fn  isr5()void; extern fn  isr6()void; extern fn  isr7()void;
extern fn  isr8()void; extern fn  isr9()void; extern fn isr10()void; extern fn isr11()void;
extern fn isr12()void; extern fn isr13()void; extern fn isr14()void; extern fn isr15()void;
extern fn isr16()void; extern fn isr17()void; extern fn isr18()void; extern fn isr19()void;
extern fn isr20()void; extern fn isr21()void; extern fn isr22()void; extern fn isr23()void;
extern fn isr24()void; extern fn isr25()void; extern fn isr26()void; extern fn isr27()void;
extern fn isr28()void; extern fn isr29()void; extern fn isr30()void; extern fn isr31()void;
extern fn isr32()void; extern fn isr33()void; extern fn isr34()void; extern fn isr35()void;
extern fn isr36()void; extern fn isr37()void; extern fn isr38()void; extern fn isr39()void;
extern fn isr40()void; extern fn isr41()void; extern fn isr42()void; extern fn isr43()void;
extern fn isr44()void; extern fn isr45()void; extern fn isr46()void; extern fn isr47()void;
extern fn isr128()void;

// Context saved by Interrupt Service Routines.
pub const Context = packed struct {
    registers: Registers,  // General purpose registers.

    interrupt_n: u32,  // Number of the interrupt.
    error_code:  u32,  // Associated error code (or 0).

    // CPU status:
    eip:    u32,
    cs:     u32,
    eflags: u32,
    esp:    u32,
    ss:     u32,

    pub inline fn setReturnValue(self: *volatile Context, value: var) void {
        self.registers.eax = if (@typeOf(value) == bool) @boolToInt(value)
                             else                        @intCast(u32, value);
    }
};

// Structure holding general purpose registers as saved by PUSHA.
pub const Registers = packed struct {
    edi: u32, esi: u32, ebp: u32, esp: u32,
    ebx: u32, edx: u32, ecx: u32, eax: u32,

    pub fn init() Registers {
        return Registers {
            .edi = 0, .esi = 0, .ebp = 0, .esp = 0,
            .ebx = 0, .edx = 0, .ecx = 0, .eax = 0,
        };
    }
};

// Pointer to the current saved context.
pub export var context: *volatile Context = undefined;

////
// Install the Interrupt Service Routines in the 
//
fn isr_install() void {
    // Exceptions.
    setGate(0,  INTERRUPT_GATE, isr0);
    setGate(1,  INTERRUPT_GATE, isr1);
    setGate(2,  INTERRUPT_GATE, isr2);
    setGate(3,  INTERRUPT_GATE, isr3);
    setGate(4,  INTERRUPT_GATE, isr4);
    setGate(5,  INTERRUPT_GATE, isr5);
    setGate(6,  INTERRUPT_GATE, isr6);
    setGate(7,  INTERRUPT_GATE, isr7);
    setGate(8,  INTERRUPT_GATE, isr8);
    setGate(9,  INTERRUPT_GATE, isr9);
    setGate(10, INTERRUPT_GATE, isr10);
    setGate(11, INTERRUPT_GATE, isr11);
    setGate(12, INTERRUPT_GATE, isr12);
    setGate(13, INTERRUPT_GATE, isr13);
    setGate(14, INTERRUPT_GATE, isr14);
    setGate(15, INTERRUPT_GATE, isr15);
    setGate(16, INTERRUPT_GATE, isr16);
    setGate(17, INTERRUPT_GATE, isr17);
    setGate(18, INTERRUPT_GATE, isr18);
    setGate(19, INTERRUPT_GATE, isr19);
    setGate(20, INTERRUPT_GATE, isr20);
    setGate(21, INTERRUPT_GATE, isr21);
    setGate(22, INTERRUPT_GATE, isr22);
    setGate(23, INTERRUPT_GATE, isr23);
    setGate(24, INTERRUPT_GATE, isr24);
    setGate(25, INTERRUPT_GATE, isr25);
    setGate(26, INTERRUPT_GATE, isr26);
    setGate(27, INTERRUPT_GATE, isr27);
    setGate(28, INTERRUPT_GATE, isr28);
    setGate(29, INTERRUPT_GATE, isr29);
    setGate(30, INTERRUPT_GATE, isr30);
    setGate(31, INTERRUPT_GATE, isr31);

    // IRQs.
    setGate(32, INTERRUPT_GATE, isr32);
    setGate(33, INTERRUPT_GATE, isr33);
    setGate(34, INTERRUPT_GATE, isr34);
    setGate(35, INTERRUPT_GATE, isr35);
    setGate(36, INTERRUPT_GATE, isr36);
    setGate(37, INTERRUPT_GATE, isr37);
    setGate(38, INTERRUPT_GATE, isr38);
    setGate(39, INTERRUPT_GATE, isr39);
    setGate(40, INTERRUPT_GATE, isr40);
    setGate(41, INTERRUPT_GATE, isr41);
    setGate(42, INTERRUPT_GATE, isr42);
    setGate(43, INTERRUPT_GATE, isr43);
    setGate(44, INTERRUPT_GATE, isr44);
    setGate(45, INTERRUPT_GATE, isr45);
    setGate(46, INTERRUPT_GATE, isr46);
    setGate(47, INTERRUPT_GATE, isr47);

    // Syscalls.
    setGate(128, SYSCALL_GATE, isr128);
}


// PIC ports.
const PIC1_CMD  = 0x20;
const PIC1_DATA = 0x21;
const PIC2_CMD  = 0xA0;
const PIC2_DATA = 0xA1;
// PIC commands:
const ISR_READ  = 0x0B;  // Read the In-Service Register.
const EOI       = 0x20;  // End of Interrupt.
// Initialization Control Words commands.
const ICW1_INIT = 0x10;
const ICW1_ICW4 = 0x01;
const ICW4_8086 = 0x01;

// Interrupt Vector offsets of exceptions.
const EXCEPTION_0  = 0;
const EXCEPTION_31 = EXCEPTION_0 + 31;
// Interrupt Vector offsets of IRQs.
const IRQ_0  = EXCEPTION_31 + 1;
const IRQ_15 = IRQ_0 + 15;
// Interrupt Vector offsets of syscalls.
const SYSCALL = 128;

// Registered interrupt handlers.
var handlers = []fn()void { unhandled } ** 48;
// Registered IRQ subscribers.
var irq_subscribers = []MailboxId { MailboxId.Kernel } ** 16;

////
// Default interrupt handler.
//
fn unhandled() noreturn {
    const n = isr.context.interrupt_n;
    if (n >= IRQ_0) {
        tty.panic("unhandled IRQ number {d}", n - IRQ_0);
    } else {
        tty.panic("unhandled exception number {d}", n);
    }
}

////
// Call the correct handler based on the interrupt number.
//
export fn interruptDispatch() void {
    const n = @intCast(u8, isr.context.interrupt_n);

    switch (n) {
        // Exceptions.
        EXCEPTION_0 ... EXCEPTION_31 => {
            handlers[n]();
        },

        // IRQs.
        IRQ_0 ... IRQ_15 => {
            const irq = n - IRQ_0;
            if (spuriousIRQ(irq)) return;

            handlers[n]();
            endOfInterrupt(irq);
        },

        // Syscalls.
        SYSCALL => {
            const syscall_n = isr.context.registers.eax;
            if (syscall_n < syscall.handlers.len) {
                syscall.handlers[syscall_n]();
            } else {
                syscall.invalid();
            }
        },

        else => unreachable
    }

    // If no user thread is ready to run, halt here and wait for interrupts.
    if (scheduler.current() == null) {
        x86.sti();
        x86.hlt();
    }
}

////
// Check whether the fired IRQ was spurious.
//
// Arguments:
//     irq: The number of the fired IRQ.
//
// Returns:
//     true if the IRQ was spurious, false otherwise.
//
inline fn spuriousIRQ(irq: u8) bool {
    // Only IRQ 7 and IRQ 15 can be spurious.
    if (irq != 7) return false;
    // TODO: handle spurious IRQ15.

    // Read the value of the In-Service Register.
    x86.outb(PIC1_CMD, ISR_READ);
    const in_service = x86.inb(PIC1_CMD);

    // Verify whether IRQ7 is set in the ISR.
    return (in_service & (1 << 7)) == 0;
}

////
// Signal the end of the IRQ interrupt routine to the PICs.
//
// Arguments:
//     irq: The number of the IRQ being handled.
//
inline fn endOfInterrupt(irq: u8) void {
    if (irq >= 8) {
        // Signal to the Slave PIC.
        x86.outb(PIC2_CMD, EOI);
    }
    // Signal to the Master PIC.
    x86.outb(PIC1_CMD, EOI);
}

////
// Register an interrupt handler.
//
// Arguments:
//     n: Index of the interrupt.
//     handler: Interrupt handler.
//
pub fn register(n: u8, handler: fn()void) void {
    handlers[n] = handler;
}

////
// Register an IRQ handler.
//
// Arguments:
//     irq: Index of the IRQ.
//     handler: IRQ handler.
//
pub fn registerIRQ(irq: u8, handler: fn()void) void {
    register(IRQ_0 + irq, handler);
    maskIRQ(irq, false);  // Unmask the IRQ.
}

////
// Mask/unmask an IRQ.
//
// Arguments:
//     irq: Index of the IRQ.
//     mask: Whether to mask (true) or unmask (false).
//
pub fn maskIRQ(irq: u8, mask: bool) void {
    // Figure out if master or slave PIC owns the IRQ.
    const port = if (irq < 8) u16(PIC1_DATA) else u16(PIC2_DATA);
    const old = x86.inb(port);  // Retrieve the current mask.

    // Mask or unmask the interrupt.
    const shift = @intCast(u3, irq % 8);  // TODO: waiting for Andy to fix this.
    if (mask) {
        x86.outb(port, old |  (u8(1) << shift));
    } else {
        x86.outb(port, old & ~(u8(1) << shift));
    }
}

////
// Notify the subscribed thread that the IRQ of interest has fired.
//
fn notifyIRQ() void {
    const irq = isr.context.interrupt_n - IRQ_0;
    const subscriber = irq_subscribers[irq];

    switch (subscriber) {
        MailboxId.Port => {
            send(&(Message.to(subscriber, 0, irq)
                          .as(MailboxId.Kernel)));
        },
        else => unreachable,
    }
    // TODO: support other types of mailboxes.
}

////
// Subscribe to an IRQ. Every time it fires, the kernel
// will send a message to the given mailbox.
//
// Arguments:
//     irq: Number of the IRQ to subscribe to.
//     mailbox_id: Mailbox to send the message to.
//
pub fn subscribeIRQ(irq: u8, mailbox_id: *const MailboxId) void {
    // TODO: validate.
    irq_subscribers[irq] = mailbox_id.*;
    registerIRQ(irq, notifyIRQ);
}

////
// Remap the PICs so that IRQs don't override software interrupts.
//
fn remapPIC() void {
    // ICW1: start initialization sequence.
    x86.outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
    x86.outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);

    // ICW2: Interrupt Vector offsets of IRQs.
    x86.outb(PIC1_DATA, IRQ_0);      // IRQ 0..7  -> Interrupt 32..39
    x86.outb(PIC2_DATA, IRQ_0 + 8);  // IRQ 8..15 -> Interrupt 40..47

    // ICW3: IRQ line 2 to connect master to slave PIC.
    x86.outb(PIC1_DATA, 1 << 2);
    x86.outb(PIC2_DATA, 2);

    // ICW4: 80x86 mode.
    x86.outb(PIC1_DATA, ICW4_8086);
    x86.outb(PIC2_DATA, ICW4_8086);

    // Mask all IRQs.
    x86.outb(PIC1_DATA, 0xFF);
    x86.outb(PIC2_DATA, 0xFF);
}


pub fn initialize() void {
    terminal.write("Setting up PIC, ISR, Interrupt Descriptor Table\n");
    remapPIC();
    isrInstall();
    x86.lidt(@ptrToInt(&idtr));
}
