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
    
    -- Current pixel position on screen
    signal visibleX : integer range 0 to resolutionX := 0;
    signal visibleY : integer range 0 to resolutionY := 0;
    
    -- Current character position on screen
    signal Column : integer := 0;
    signal Row    : integer := 0;
    signal OutputEnabled     : bit := '0';
    signal TextOutputEnabled : bit := '0';

    type ScreenContent is array(0 to 9) of integer range 0 to 255;
    constant Content : ScreenContent := (48, 49, 50, 51, 52, 53, 54, 55, 56, 57);
    
    signal CurrentChar : integer range 0 to 255;
    signal CharX       : integer range 0 to 7;
    signal CharY       : integer range 0 to 11;
    signal TextPixel   : std_logic;
    
    -- Character to pixel mapping
    component LEDBoardFont is
        port(
            Ord         : in integer range 0 to 255;
            CharX       : in integer;
            CharY       : in integer;
            CharWidth   : in integer;
            CharHeight  : in integer;
            Pixel       : out std_logic
        );
    end component;
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
                beamX <= 0;
                beamY <= 0;
            else
                Reset <= '1';
            end if;
        end if;
    end process;
    
    -- Pixel clock processor
    -- sensitivity: PixelClock
    -- updates:     VGA control signals, visibleX/Y, Column/Row, CharX/Y, CurrentChar, OutputEnabled, TextOutputEnabled
    process(PixelClock)
        variable vx : integer range 0 to resolutionX-1;
        variable vy : integer range 0 to resolutionY-1;
        variable c  : integer range 0 to Columns-1;
        variable r  : integer range 0 to Rows-1;
    begin
        if (PixelClock'event and PixelClock='1')
        then
            -- HSync pulse before left porch
            -- HSync is active low
            if (beamX < HSyncDuration)
            then
                HSync <= '0'; -- HSync pulse
                OutputEnabled <= '0';
            else
                HSync <= '1'; -- HSync pulse off
            end if;
            
            -- VSync pulse lines before top porch lines
            -- VSync is active low
            if (beamY < VSyncDuration) then
                VSync <= '0'; -- VSync pulse
                OutputEnabled <= '0';
            else
                VSync <= '1'; -- VSync pulse off

                -- if beam is within visible rectangle
                if (beamY >= VSyncDuration+topPorch and beamY < beamMaxY-bottomPorch
                and beamX >= HSyncDuration+leftPorch and beamX < beamMaxX-rightPorch) then

                    OutputEnabled <= '1';

                    -- using variables here to encourage the synthesizer to re-use calculated values
                    vx := beamX - HSyncDuration - leftPorch;
                    vy := beamY - VSyncDuration - topPorch;
                    
                    -- Calculate current position on screen
                    visibleX <= vx;
                    visibleY <= vy;
                    
                    -- Calculate current character position
                    c := vx / PixelsPerColumn;
                    Column <= c;
                    CharX  <= vx mod PixelsPerColumn;
                    
                    r := vy / PixelsPerRow;
                    Row    <= r;
                    CharY  <= vy mod PixelsPerRow;

                    -- only display text in first row
                    -- otherwise display chess board pattern
                    if (r = 0 and c < Content'length)
                    then
                        CurrentChar <= 50; --Content(c);
                        TextOutputEnabled <= '1';
                    else
                        TextOutputEnabled <= '0';
                    end if;
                else
                    OutputEnabled <= '0';
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

    CharacterDisplay: LEDBoardFont
    port map(
        Ord         => CurrentChar,
        CharX       => CharX,
        CharY       => CharY,
        CharWidth   => PixelsPerColumn,
        CharHeight  => PixelsPerRow,
        Pixel       => TextPixel
	);
    
    -- Choose between chess board test pattern
    -- and text output
    process(
        PixelClock,
        OutputEnabled,
        TextOutputEnabled,
        visibleX,
        visibleY
        )
    
        function ChessBoardPixel(x : integer; y : integer) return std_logic is
        begin
            if ((x mod 80 > 39) xor (y mod 60 > 29))
            then
                return '1';
            else
                return '0';
            end if;
        end;

    begin
        if (PixelClock'event and PixelClock='0')
        then
            if (OutputEnabled = '1')
            then
                if (TextOutputEnabled = '1')
                then
                    Pixel <= TextPixel;
                else
                    Pixel <= ChessBoardPixel(visibleX, visibleY);
                end if;
            else
                Pixel <= '0';
            end if;
        end if;
    end process;
    
    -- clone signals for oscilloscope probe, i.e. for debugging
    HSyncDebug <= HSync;
    VSyncDebug <= VSync;
    PixelDebug <= TextPixel;
    
end vga;
