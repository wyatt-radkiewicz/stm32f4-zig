/* stm32f4-zig linker script */
MEMORY {
    flash (rx) : org = 0x08000000, len = 1M
    sram (!rx) : org = 0x20000000, len = 128K
}

SECTIONS {
    .vectors : {
        *(.text._vectors)
    } >flash

    .text : {
        *(*text*)
    } >flash

    .rodata : {
        KEEP(*(*rodata*))
    } >flash

    .exidx : {
        KEEP(*(*exidx*))
    } >flash

    .extab : {
        KEEP(*(*extab*))
    } >flash

    _data_src = ADDR(.extab) + SIZEOF(.extab);
    .data : AT(_data_src) {
        *(.data*)
    } >sram
    _data_dst = ADDR(.data);
    _data_len = SIZEOF(.data);

    _bss_addr = _data_dst + _data_len;
    .bss (NOLOAD) : {
        *(.bss*)
    } >sram
    _bss_len = SIZEOF(.bss);
}
