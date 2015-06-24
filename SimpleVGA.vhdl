library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

use LEDBoardFont.all;

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
        nCS1, nCS2, SCLK1, SCLK2 : out std_logic;
        SDATA1 : in  std_logic;
        SDATA2 : out std_logic
        -- iCEstick:
        -- nCS  : FPGA pin 112, J1 pin 3 = PIO0_02
        -- SCLK : FPGA pin 113, J1 pin 4 = PIO0_03
        -- SDATA: FPGA pin 114, J1 pin 5 = PIO0_04

    );
end entity;

architecture vga of SimpleVGA is
    -- global reset
    signal Reset            : std_logic := 'Z';

    -- main clock
    component PLL
        port(
            REFERENCECLK      : in  std_logic;              -- Driven by core logic
            PLLOUTCORE        : out std_logic;              -- PLL output to core logic
            PLLOUTGLOBAL      : out std_logic;              -- PLL output to global network
            RESET             : in  std_logic               -- Driven by core logic
        );
    end component;

    signal PixelClock       : std_logic := 'Z';

    -- Beam parameters / VGA signals
    constant resolutionX    : integer := 800;
    constant resolutionY    : integer := 600;

    constant HSyncDuration  : integer := 120;
    constant leftPorch      : integer := 63;
    constant rightPorch     : integer := 57;

    constant VSyncDuration  : integer := 6;
    constant topPorch       : integer := 22;
    constant bottomPorch    : integer := 38;

    constant beamMaxX : integer := HSyncDuration + leftPorch + resolutionX + rightPorch;
    constant beamMaxY : integer := VSyncDuration + topPorch + resolutionY + bottomPorch;
    
    -- Current beam position
    signal beamX: integer range 0 to beamMaxX := 0;
    signal beamY: integer range 0 to beamMaxY := 0;
    
    -- Screen configuration
    constant Columns    : integer := 80;
    constant Rows       : integer := 50;

    constant PixelsPerColumn : integer := resolutionX / Columns; -- 800 / 80 = 10
    constant PixelsPerRow    : integer := resolutionY / Rows;    -- 600 / 50 = 12
    
    type ScreenContent is array(0 to 12) of integer range 0 to 255;
    signal Content : ScreenContent := (48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 49, 50);
    
begin
    -- Global clock
    Clock50MHz: PLL
    port map(
              REFERENCECLK  => Clock12MHz,
              PLLOUTCORE    => PixelClock,
              PLLOUTGLOBAL  => open,
              RESET         => Reset
            );

    -- Reset processor
    process(Clock12MHz, Reset)
    begin
        if (Clock12MHz'event and Clock12MHz='1')
        then
            if (Reset = 'Z')
            then
                Reset <= '0';
            else
                Reset <= '1';
            end if;
        end if;
    end process;
    
    -- Pixel clock processor
    -- sensitivity: PixelClock
    -- updates:     VGA control signals, Pixel
    process(PixelClock)
        -- Current pixel position on screen
        variable visibleX : integer range 0 to resolutionX := 0;
        variable visibleY : integer range 0 to resolutionY := 0;
        
        -- Current character position on screen
        variable Column      : integer := 0;
        variable Row         : integer := 0;
        variable CurrentChar : integer range 0 to 255 := 0;

        -- Current position within character
        variable CharX       : integer range 0 to 9  := 0;
        variable CharY       : integer range 0 to 11 := 0;
    begin
        if (PixelClock'event and PixelClock='1')
        then
            Pixel <= '0';
        
            -- HSync pulse before left porch
            -- HSync is active low
            if (beamX < HSyncDuration)
            then
                HSync <= '0'; -- HSync pulse
            else
                HSync <= '1'; -- HSync pulse off
            end if;
            
            -- VSync pulse lines before top porch lines
            -- VSync is active low
            if (beamY < VSyncDuration) then
                VSync <= '0'; -- VSync pulse
            else
                VSync <= '1'; -- VSync pulse off

                -- if beam is within visible rectangle
                if (beamY >= VSyncDuration+topPorch and beamY < beamMaxY-bottomPorch
                and beamX >= HSyncDuration+leftPorch and beamX < beamMaxX-rightPorch) then

                    -- Calculate current position on screen
                    visibleX := beamX - HSyncDuration - leftPorch;
                    visibleY := beamY - VSyncDuration - topPorch;
                    
                    -- Calculate current character position
                    Column := visibleX / PixelsPerColumn;
                    CharX  := visibleX mod PixelsPerColumn;
                    
                    Row    := visibleY / PixelsPerRow;
                    CharY  := visibleY mod PixelsPerRow;

                    -- only display text in first row
                    -- otherwise display chess board pattern
                    if (Row = 0 and Column < Content'length)
                    then
                        CurrentChar := Content(Column);
                        Pixel <= Font(CurrentChar, CharX, CharY, PixelsPerColumn, PixelsPerRow);
                    else
                        Pixel <= ChessBoardPixel(visibleX, visibleY);
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
    

    -- SPI interface

    process(Clock12MHz)
        variable counter : integer := 0;
        variable SlaveSelect : boolean := false;
    begin
        if (SlaveSelect)
        then
            -- query the slave with 12 MHz
            if (counter > 1)
            then
                SCLK1 <= Clock12MHz;
            else
                SCLK1 <= '1';
            end if;
        else
            SCLK1 <= '1';
        end if;

        if (Clock12MHz'event and Clock12MHz='1')
        then
            if (SlaveSelect)
            then
                -- sample a bit at the rising edge of the clock
                -- (assuming Clock12MHz equals SCLK)
                -- the first two clock ticks are omitted for delay (see above)
                -- the following three bits are always zero
                -- don't sample after but including the final clock tick
                if (counter > 4 and counter <= 17)
                then
                    SDATA2 <= SDATA1;
                    if (SDATA1 = '1')
                    then
                        Content(counter-5) <= 49; -- "1"
                    else
                        Content(counter-5) <= 48; -- "0"
                    end if;
                else
                    SDATA2 <= '0';
                end if;

                -- disable slave select
                -- after 17 clock ticks, the first of which
                -- is omitted to delay between the falling edge of CS
                -- and the first falling edge of SCLK
                -- making it 16 clock ticks in total
                -- corresponding to 16 bits transferred
                if (counter >= 17)
                then
                    SlaveSelect := false;
                    nCS1 <= '1';
                    counter := 0;
                else
                    counter := counter + 1;
                end if;
            else
                -- recover from undefined states
                nCS1 <= '1';
                
                -- enable slave select
                if (counter >= 50)
                then
                    SlaveSelect := true;
                    nCS1 <= '0';
                    counter := 0;
                else
                    counter := counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    nCS2 <= nCS1;
    SCLK2 <= SCLK1;
    
--    process(SCLK, SDATA)
--    begin
--        if (SCLK'event and SCLK='0')
--        then
            -- read SDATA
--        end if;
--    end process;

end vga;
