//! Reset and clock control registers

/// Clock control register
pub const cr: *volatile Cr = @ptrFromInt(0x4002_3800 + 0x00);
pub const Cr = packed struct(u32) {
    hsion: bool = true,
    hsirdy: bool = true,
    reserved2: u1 = 0,
    hsitrim: u5 = 16,
    hsical: u8,
    hseon: bool = false,
    hserdy: bool = false,
    hsebyp: bool = false,
    csson: bool = false,
    reserved23_20: u4 = 0,
    pllon: bool = false,
    pllrdy: bool = false,
    plli2son: bool = false,
    plli2srdy: bool = false,
    reserved31_28: u4 = 0,
};

/// PLL configuration register
pub const pllcfgr: *volatile PllCfgr = @ptrFromInt(0x4002_3800 + 0x04);
pub const PllCfgr = packed struct(u32) {
    pllm: u6 = 16,
    plln: u9 = 192,
    reserved15: u1 = 0,
    pllp: DivisionFactor = .@"2",
    reserved21_18: u4 = 0,
    pllsrc: ClockSource = .hsi,
    reserved23: u1 = 0,
    pllq: u4 = 4,
    reserved31_28: u4 = 0,

    /// Main PLL division factor for main system clock
    pub const DivisionFactor = enum(u2) {
        @"2",
        @"4",
        @"6",
        @"8",

        /// Get the division factor
        pub fn factor(this: @This()) u32 {
            return (@as(u32, @intFromEnum(this)) + 1) * 2;
        }
    };

    /// Main PLL(PLL) and audio PLL (PLLI2S) entry clock source
    pub const ClockSource = enum(u1) { hsi, hse };
};

/// Clock configuration register
pub const cfgr: *volatile Cfgr = @ptrFromInt(0x4002_3800 + 0x08);
pub const Cfgr = packed struct(u32) {
    sw: SystemClockSource = .hsi,
    sws: SystemClockSource = .hsi,
    hpre: AhbPrescaler = .not_divided,
    reserved9_8: u2 = 0,
    ppre1: ApbPrescaler = .not_divided,
    ppre2: ApbPrescaler = .not_divided,
    rtcpre: u5 = 0,
    mco1: McoOutputClock(.@"1") = .hsi,
    i2ssrc: I2sClockSource = .plli2s,
    mco1pre: McoPrescaler = .not_divided,
    mco2pre: McoPrescaler = .not_divided,
    mco2: McoOutputClock(.@"2") = .sysclk,

    /// Set and cleared by software to select the system clock source
    pub const SystemClockSource = enum(u2) { hsi, hse, pll };

    /// Set and cleared by software. This bit allows to select the I2S clock source between
    /// the PLLI2S clock and the external clock
    pub const I2sClockSource = enum(u1) { plli2s, i2s_ckin };

    /// Set and cleared by software to control AHB clock division factor
    pub const AhbPrescaler = enum(u4) {
        not_divided,
        @"2" = 0b1000,
        @"4",
        @"8",
        @"16",
        @"64",
        @"128",
        @"256",
        @"512",
    };

    /// Set and cleared by software to control APB low-speed clock division factor
    pub const ApbPrescaler = enum(u3) {
        not_divided,
        @"2" = 0b100,
        @"4",
        @"8",
        @"16",
    };

    /// Set and cleared by software to configure the prescaler of the MCO1
    pub const McoPrescaler = enum(u3) {
        not_divided,
        @"2" = 0b100,
        @"3",
        @"4",
        @"5",
    };

    /// Microcontroller clock output
    pub fn McoOutputClock(comptime mco: enum { @"1", @"2" }) type {
        return switch (mco) {
            .@"1" => enum(u2) { hsi, lse, hse, pll },
            .@"2" => enum(u2) { sysclk, plli2s, hse, pll },
        };
    }
};

/// Peripheral clock enable register
pub const ahb1enr: *volatile Ahb1Enr = @ptrFromInt(0x4002_3800 + 0x30);
pub const Ahb1Enr = packed struct(u32) {
    gpioaen: bool = false,
    gpioben: bool = false,
    gpiocen: bool = false,
    gpioden: bool = false,
    gpioeen: bool = false,
    gpiofen: bool = false,
    gpiogen: bool = false,
    gpiohen: bool = false,
    gpioien: bool = false,
    reserved11_9: u3 = 0,
    crcen: bool = false,
    reserved17_13: u5 = 0,
    bkpsramen: bool = false,
    reserved19: u1 = 0,
    ccmdataramen: bool = true,
    dma1en: bool = false,
    dma2en: bool = false,
    reserved24_23: u2 = 0,
    ethmacen: bool = false,
    ethmactxen: bool = false,
    ethmacrxen: bool = false,
    ethmacptpen: bool = false,
    otghsen: bool = false,
    otghsulpien: bool = false,
    reserved31: u1 = 0,
};

/// Peripheral clock enable register
pub const apb1enr: *volatile Apb1Enr = @ptrFromInt(0x4002_3800 + 0x34);
pub const Apb1Enr = packed struct(u32) {
    tim2en: bool = false,
    tim3en: bool = false,
    tim4en: bool = false,
    tim5en: bool = false,
    tim6en: bool = false,
    tim7en: bool = false,
    tim12en: bool = false,
    tim13en: bool = false,
    tim14en: bool = false,
    reserved10_9: u2 = 0,
    wwdgen: bool = false,
    reserved13_12: u2 = 0,
    spi2en: bool = false,
    spi3en: bool = false,
    reserved16: u1 = 0,
    usart2en: bool = false,
    usart3en: bool = false,
    uart4en: bool = false,
    uart5en: bool = false,
    i2c1en: bool = false,
    i2c2en: bool = false,
    i2c3en: bool = false,
    reserved24: u1 = 0,
    can1en: bool = false,
    can2en: bool = false,
    reserved27: u1 = 0,
    pwren: bool = false,
    dacen: bool = false,
    reserved31_30: u2 = 0,
};
