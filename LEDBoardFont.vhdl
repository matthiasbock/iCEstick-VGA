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
        type BitMask is array (0 to 7) of std_logic_vector(0 to 7); 
        constant MaskL : BitMask :=("11000000",
                                    "11000000",
                                    "11000000",
                                    "11000000",
                                    "11000000",
                                    "11000000",
                                    "11000000",
                                    "11111111");
    begin
        if (Char = 'L'
        and CharX > 0 and CharY > 1
        and CharX < 9 and CharY < 10)
        then
            return MaskL(CharY-1)(CharX-2);
        else
            return '0';
        end if;
    end Font;
end LEDBoardFont;
