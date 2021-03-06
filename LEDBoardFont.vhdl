library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package LEDBoardFont is
    function Font(
        Ord         : integer range 0 to 255;
        CharX       : integer;
        CharY       : integer;
        CharWidth   : integer;
        CharHeight  : integer
        ) return std_logic;

    function Digit(i : integer range 0 to 9) return integer;
        
    function ChessBoardPixel(x : integer; y : integer) return std_logic;

end LEDBoardFont;

package body LEDBoardFont is

    -- The characters of this font are represented as matrices of 8x8 pixels.
    -- Each pixel can be on/'1' or off/'0'.
    -- Each character on the screen has 10x12 pixels, leading to spacing between the chars.
    type BitMask is array (0 to 7) of bit_vector(0 to 7); 

    constant MaskL : BitMask :=
       ("11000000",
        "11000000",
        "11000000",
        "11000000",
        "11000000",
        "11000000",
        "11000000",
        "11111111");

    type BitMaskArray1 is array(0 to 9) of BitMask;

    constant MaskDigits : BitMaskArray1 :=
      (
       ("01111110",
        "11000011",
        "11000111",
        "11011011",
        "11100011",
        "11000011",
        "11000011",
        "01111110"),
       ("00001100",
        "00011100",
        "00111100",
        "01101100",
        "00001100",
        "00001100",
        "00001100",
        "11111111"),
       ("01111110",
        "11000011",
        "10000011",
        "00000011",
        "01111110",
        "11000000",
        "11000000",
        "11111111"),
       ("01111110",
        "11000011",
        "10000011",
        "00111110",
        "00000011",
        "00000011",
        "11000011",
        "00111100"),
       ("00001100",
        "00011000",
        "00110000",
        "01100100",
        "11001100",
        "11111111",
        "00001100",
        "00001100"),
       ("11111111",
        "11000000",
        "11000000",
        "11111100",
        "00000011",
        "11000011",
        "11000011",
        "00111100"),
       ("00111100",
        "11000011",
        "11000000",
        "11111100",
        "11000011",
        "11000011",
        "11000011",
        "00111100"),
       ("11111111",
        "00000011",
        "00000110",
        "00001100",
        "00011000",
        "00110000",
        "01100000",
        "11000000"),
       ("00111100",
        "11000011",
        "11000011",
        "00111100",
        "11000011",
        "11000011",
        "11000011",
        "00111100"),
       ("00111100",
        "11000011",
        "11000011",
        "00111111",
        "00000011",
        "11000011",
        "11000011",
        "00111100")
      );

    -- Set output pixel according to current character
    -- and the position within the character
    function Font(
        Ord         : integer range 0 to 255;
        CharX       : integer;
        CharY       : integer;
        CharWidth   : integer;
        CharHeight  : integer
        ) return std_logic is

        -- muss ins Rastermass passen
        variable x : integer range 0 to 9  := CharX mod CharWidth;
        variable y : integer range 0 to 11 := CharY mod CharHeight;
    begin
        -- first and last column are off
        -- top and bottom two lines are off
        if (x = 0
         or x = CharWidth-1
         or y < 2  -- 0 or 1
         or y > 9) -- 10 or 11
        then
            return '0';
        else
            -- strip margins
            x := x - 1;
            y := y - 2;
            
            if (Ord > 47 and Ord < 48+MaskDigits'length)
            then
                return std_logic( MaskDigits(Ord-48)(y)(x) );
            else
                return '0';
            end if;
        end if;
    end Font;

    -- return the ordinal of the given integer's corresponding ASCII character
    function Digit(i : integer range 0 to 9)
        return integer is
    begin
        return 48+i;
    end;
    
    function ChessBoardPixel(x : integer; y : integer) return std_logic is
    begin
        if ((x mod 80 > 39) xor (y mod 60 > 29))
        then
            return '1';
        else
            return '0';
        end if;
    end;
        
end LEDBoardFont;
