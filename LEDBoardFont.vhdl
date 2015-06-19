library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package LEDBoardFont is
    function Font(
                    Char        : Character;
                    CharX       : integer;
                    CharY       : integer;
                    CharWidth   : integer;
                    CharHeight  : integer
                ) return std_logic;
end LEDBoardFont;

package body LEDBoardFont is

    function Font(
                    Char        : Character;
                    CharX       : integer;
                    CharY       : integer;
                    CharWidth   : integer;
                    CharHeight  : integer
                ) return std_logic is
                
        -- The characters of this font are represented as matrices of 8x8 pixels.
        -- Each pixel can be on/'1' or off/'0'.
        -- Each character on the screen has 10x12 pixels, leading to spacing between the chars.
        type BitMask is array (0 to 7) of std_logic_vector(0 to 7); 

        constant MaskL : BitMask :=
           ("11000000",
            "11000000",
            "11000000",
            "11000000",
            "11000000",
            "11000000",
            "11000000",
            "11111111");
        constant Mask0 : Bitmask :=
           ("01111110",
            "11000011",
            "11000111",
            "11011011",
            "11100011",
            "11000011",
            "11000011",
            "01111110");
        constant Mask1 : BitMask :=
           ("00001100",
            "00011100",
            "00111100",
            "01101100",
            "00001100",
            "00001100",
            "00001100",
            "11111111");
        constant Mask2 : BitMask :=
           ("01111110",
            "11000011",
            "10000011",
            "00000011",
            "01111110",
            "11000000",
            "11000000",
            "11111111");
--0111110
--1100011
--0000011

        -- muss ins Rastermass passen
        variable x : integer := CharX mod CharWidth;
        variable y : integer := CharY mod CharHeight;
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
            
            x := x - 1;
            y := y - 2;
            
            if (Char = 'L') then
                return MaskL(y)(x);

            elsif (Char = '0') then
                return Mask0(y)(x);

            elsif (Char = '1') then
                return Mask1(y)(x);

            elsif (Char = '2') then
                return Mask2(y)(x);

            else
                return '0';
            end if;
        end if;

    end Font;

end LEDBoardFont;
