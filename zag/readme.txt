

zig build qemu


older
    zig build-exe .\ostut.zig -target i386-freestanding -T linker.ld
    & 'D:\Program Files\qemu\qemu-system-i386.exe' -kernel ./ostut 
