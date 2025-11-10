//! Interrupt hal
const std = @import("std");

const regs = @import("regs.zig");

/// Interrupt service routine function type
pub const Isr = fn () callconv(.{ .arm_interrupt = .{} }) void;

/// Default priority grouping
pub const priogrp = 3;

/// Interrupt service request
pub const Irq = enum(u8) {
    stack,
    reset,
    nmi,
    hard_fault,
    mem_manage,
    bus_fault,
    usage_fault,
    svc = 11,
    debug_mon,
    pend_sv = 14,
    systick,
    wwdg,
    pvd,
    tamp_stamp,
    rtc_wkup,
    flash,
    rcc,
    exti0,
    exti1,
    exti2,
    exti3,
    exti4,
    dma1_stream0,
    dma1_stream1,
    dma1_stream2,
    dma1_stream3,
    dma1_stream4,
    dma1_stream5,
    dma1_stream6,
    adc,
    can1_tx,
    can1_rx0,
    can1_rx1,
    can1_sce,
    exti9_5,
    tim1_brk_tim9,
    tim1_up_tim10,
    tim1_trg_com_tim11,
    tim1_cc,
    tim2,
    tim3,
    tim4,
    i2c1_ev,
    i2c1_er,
    i2c2_ev,
    i2c2_er,
    spi1,
    spi2,
    usart1,
    usart2,
    usart3,
    exti15_10,
    rtc_alarm,
    otg_fs_wkup,
    tim8_brk_tim12,
    tim8_up_tim13,
    tim8_trg_com_tim14,
    tim8_cc,
    dma1_stream7,
    fsmc,
    sdio,
    tim5,
    spi3,
    uart4,
    uart5,
    tim6_dac,
    tim7,
    dma2_stream0,
    dma2_stream1,
    dma2_stream2,
    dma2_stream3,
    dma2_stream4,
    eth,
    eth_wkup,
    can2_tx,
    can2_rx0,
    can2_rx1,
    can2_sce,
    otg_fs,
    dma2_stream5,
    dma2_stream6,
    dma2_stream7,
    usart6,
    i2c3_ev,
    i2c3_er,
    otg_hs_ep1_out,
    otg_hs_ep1_in,
    otg_hs_wkup,
    otg_hs,
    dcmi,
    cryp,
    hash_rng,
    fpu,
    _,

    /// Get a pointer to the priority of the instruction
    pub fn prio(this: @This(), comptime bits: u3) ?*volatile Priority(bits) {
        return switch (@intFromEnum(this)) {
            4...15 => |n| @ptrCast(&regs.cpu.shpr[n - 4]),
            16...239 => |n| @ptrCast(&regs.cpu.nvic.ipr[n - 16]),
            else => null,
        };
    }

    /// Irq priority - bits specifies how many bits should be allocated to the group
    pub fn Priority(comptime bits: u3) type {
        return packed struct(u8) {
            subprio: std.meta.Int(.unsigned, 7 - bits) = 0,
            group: std.meta.Int(.unsigned, bits + 1) = 0,
        };
    }
};
