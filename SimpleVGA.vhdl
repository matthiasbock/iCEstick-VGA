library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity SimpleVGA is
    port(
        Clock12MHz: in std_logic;
        
        HSync: out std_logic;
        VSync: out std_logic;
        Pixel: out std_logic

        -- HX8K board:
        -- Clock: J3: PIO3_26
        -- Pixel: P1: PIO3_46 (blue)
        -- HSync: P2: PIO3_48 (grey)
        -- VSync: R1: PIO3_50 (white)

        -- iCEstick:
        -- Clock: FPGA pin 21
        -- Pixel: FPGA pin 62, J3 pin 3
        -- HSync: FPGA pin 61, J3 pin 4
        -- VSync: FPGA pin 60, J3 pin 5
    );
end entity;

architecture vga of SimpleVGA
is
    constant maxX : integer := 799;
    constant maxY : integer := 524;

    constant HSyncDuration : integer := 96;
    constant leftPorch     : integer := 48;
    constant rightPorch    : integer := 16;

    constant VSyncDuration : integer := 2;
    constant topPorch      : integer := 33;
    constant bottomPorch   : integer := 10;

    signal Counter : integer range 0 to 11999 := 0;
    signal ClockVGA : std_logic := '0';
    
    signal Reset : std_logic := '1';
begin

    process(Clock12MHz, Reset)
    begin
        if (Reset='1')
        then
            Counter <= 0;
            ClockVGA <= '0';
            Reset <= '0';
        elsif (Clock12MHz'event and Clock12MHz='1')
        then
            if (Counter < 11999) then
                Counter <= Counter + 1;
            else
                Counter <= 0;
                if (ClockVGA = '0')
                then
                    ClockVGA <= '1';
                else
                    ClockVGA <= '0';
                end if;
            end if;
        end if;
    end process;

    process(ClockVGA)
        variable x: integer range 0 to maxX := 0;
        variable y: integer range 0 to maxY := 0;
    begin
        if (ClockVGA'event and ClockVGA='1')
        then
            -- default pixel value
            Pixel <= '0';

            -- HSync pulse before left porch
            -- HSync is active low
            if (x < HSyncDuration)
            then
                HSync <= '0'; -- Sync pulse
            else
                HSync <= '1'; -- Sync pulse off
            end if;
            
            -- VSync pulse before top porch
            -- VSync is active low
            if (y < VSyncDuration) then
                VSync <= '0';
            else
                VSync <= '1';

                if (x >= HSyncDuration+leftPorch and x < maxX-rightPorch) then
                    if ( ((x mod 80) > 39) xor ((y mod 60) > 29) ) then
                        Pixel <= '1';
                    else
                        -- Pixel value is zero while not in visible area
                        Pixel <= '0';
                    end if;
                end if;

            end if;

            -- move the cursor
            if (x = maxX) then
                x := 0;
                if (y = maxY) then
                    y := 0;
                else
                    y := y + 1;
                end if;
            else
                x := x + 1;
            end if;
        end if;
    end process;
    
end vga;
