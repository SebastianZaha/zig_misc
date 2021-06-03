
////
// Halt the CPU.
//
pub inline fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

////
// Disable interrupts.
//
pub inline fn clear_interrupt_flag() void {
    asm volatile ("cli");
}

////
// Enable interrupts.
//
pub inline fn set_interrupt_flag() void {
    asm volatile ("sti");
}

////
// Completely stop the computer.
//
pub inline fn stop() noreturn {
    clear_interrupt_flag();
    halt();
}

////
// Read a byte from a port.
//
// Arguments:
//     port: Port from where to read.
//
// Returns:
//     The read byte.
//
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]" : [result] "={al}" (-> u8)
                                                  : [port]   "N{dx}" (port));
}

////
// Write a byte on a port.
//
// Arguments:
//     port: Port where to write the value.
//     value: Value to be written.
//
pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]" : : [value] "{al}" (value),
                                               [port]  "N{dx}" (port));
}
