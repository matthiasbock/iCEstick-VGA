library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity SimpleVGA is
    port(
        Clock12MHz: in std_logic;
        
        HSync: out std_logic;
        VSync: out std_logic;
        Pixel: out std_logic;

        -- HX8K board:
        -- Clock: J3: PIO3_26
        -- Pixel: P1: PIO3_46 (blue)
        -- HSync: P2: PIO3_48 (grey)
        -- VSync: R1: PIO3_50 (white)

        -- iCEstick:
        -- Clock: FPGA pin 21
        -- Pixel: FPGA pin 62, J3 pin 3 = PIO2_17
        -- HSync: FPGA pin 61, J3 pin 4 = PIO2_16
        -- VSync: FPGA pin 60, J3 pin 5 = PIO2_15

        -- additional mirror pins for debugging
        HSyncDebug, VSyncDebug, PixelDebug : out std_logic
        -- iCEstick:
        -- Pixel: FPGA pin 112, J1 pin 3 = PIO0_02
        -- HSync: FPGA pin 113, J1 pin 4 = PIO0_03
        -- VSync: FPGA pin 114, J1 pin 5 = PIO0_04

    );
end entity;

architecture vga of SimpleVGA
is
    constant resolutionX : integer := 799;
    constant resolutionY : integer := 599;

    constant HSyncDuration  : integer := 96;
    constant leftPorch      : integer := 48;
    constant rightPorch     : integer := 16;

    constant VSyncDuration  : integer := 2;
    constant topPorch       : integer := 33;
    constant bottomPorch    : integer := 10;

    signal PixelClock       : std_logic := 'Z';
    signal Reset            : std_logic := 'Z';

    component PixelClock_PLL
        port(
            REFERENCECLK      : in  std_logic;              -- Driven by core logic
            PLLOUTCORE        : out std_logic;              -- PLL output to core logic
            PLLOUTGLOBAL      : out std_logic;              -- PLL output to global network
            RESET             : in  std_logic               -- Driven by core logic
        );
    end component;

    constant beamMaxX : integer := HSyncDuration + leftPorch + resolutionX + rightPorch;
    constant beamMaxY : integer := VSyncDuration + topPorch + resolutionY + bottomPorch;
    
    signal beamX: integer range 0 to beamMaxX := 0;
    signal beamY: integer range 0 to beamMaxY := 0;
    
begin

    VGAClock: PixelClock_PLL
    port map(
              REFERENCECLK  => Clock12MHz,
              PLLOUTCORE    => PixelClock,
              PLLOUTGLOBAL  => open,
              RESET         => Reset
            );

    process(Clock12MHz, Reset)
    begin
        if (Clock12MHz'event and Clock12MHz='1')
        then
            if (Reset = 'Z')
            then
                Reset <= '0';
                beamX <= 0;
                beamY <= 0;
            else
                Reset <= '1';
            end if;
        end if;
    end process;

    process(PixelClock)
        variable visibleX: integer range 0 to resolutionX := 0;
        variable visibleY: integer range 0 to resolutionY := 0;
    begin
        if (PixelClock'event and PixelClock='1')
        then
            visibleX := beamX - HSyncDuration - leftPorch;
            visibleY := beamY - VSyncDuration - topPorch;
            
            -- default pixel value
            Pixel <= '0';

            -- HSync pulse before left porch
            -- HSync is active low
            if (beamX < HSyncDuration)
            then
                HSync <= '0'; -- Sync pulse
            else
                HSync <= '1'; -- Sync pulse off
            end if;
            
            -- VSync pulse before top porch
            -- VSync is active low
            if (beamY < VSyncDuration) then
                VSync <= '0';
            else
                VSync <= '1';

                -- if beam is within visible rectangle
                -- draw a test pattern to screen
                if (beamX >= HSyncDuration+leftPorch and beamX < beamMaxX-rightPorch) then
                    if ( ((visibleX mod 80) > 39) xor ((visibleY mod 60) > 29) ) then
                        Pixel <= '1';
                    else
                        -- Pixel value is zero while not in visible area
                        Pixel <= '0';
                    end if;
                end if;

            end if;

            -- move the (virtual) beam
            if (beamX = beamMaxX) then
                beamX <= 0;
                if (beamY = beamMaxY) then
                    beamY <= 0;
                else
                    beamY <= beamY + 1;
                end if;
            else
                beamX <= beamX + 1;
            end if;
        end if;
    end process;
    
    HSyncDebug <= HSync;
    VSyncDebug <= VSync;
    PixelDebug <= Pixel;
    
end vga;
