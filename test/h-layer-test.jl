
#make sure the representation of things greater than 1 works ok.
@test bits(Posit{16,0}(0x4000_0000_0000_0000), " ") == "0 10 0000000000000"
@test bits(Posit{16,1}(0x4000_0000_0000_0000), " ") == "0 10 0 000000000000"
@test bits(Posit{16,0}(0x7FFF_0000_0000_0000), " ") == "0 111111111111111"
@test bits(Posit{16,2}(0x7FFB_0000_0000_0000), " ") == "0 1111111111110 11"
@test bits(Posit{16,2}(0x7FFD_0000_0000_0000), " ") == "0 11111111111110 1"
@test bits(Posit{16,2}(0x7FFF_0000_0000_0000), " ") == "0 111111111111111"

#and as Valid.
@test bits(Valid{16,0}(0x4000_0000_0000_0000), " ") == "0 10 000000000000 0"
@test bits(Valid{16,1}(0x4000_0000_0000_0000), " ") == "0 10 0 00000000000 0"
@test bits(Valid{16,0}(0x7FFF_0000_0000_0000), " ") == "0 11111111111111 1"
@test bits(Valid{16,2}(0x7FF7_0000_0000_0000), " ") == "0 111111111110 11 1"
@test bits(Valid{16,2}(0x7FFB_0000_0000_0000), " ") == "0 1111111111110 1 1"
@test bits(Valid{16,2}(0x7FFD_0000_0000_0000), " ") == "0 11111111111110 1"
@test bits(Valid{16,2}(0x7FFF_0000_0000_0000), " ") == "0 11111111111111 1"

#test special values 0 and infinity.
@test bits(Posit{16,0}(0x0000_0000_0000_0000), " ") == "0 000000000000000"
@test bits(Valid{16,0}(0x0000_0000_0000_0000), " ") == "0 00000000000000 0"
@test bits(Posit{16,1}(0x0000_0000_0000_0000), " ") == "0 000000000000000"
@test bits(Valid{16,1}(0x0000_0000_0000_0000), " ") == "0 00000000000000 0"
@test bits(Posit{16,2}(0x0000_0000_0000_0000), " ") == "0 000000000000000"
@test bits(Valid{16,2}(0x0000_0000_0000_0000), " ") == "0 00000000000000 0"
@test bits(Posit{16,0}(0x8000_0000_0000_0000), " ") == "1 000000000000000"
@test bits(Valid{16,0}(0x8000_0000_0000_0000), " ") == "1 00000000000000 0"
@test bits(Posit{16,1}(0x8000_0000_0000_0000), " ") == "1 000000000000000"
@test bits(Valid{16,1}(0x8000_0000_0000_0000), " ") == "1 00000000000000 0"
@test bits(Posit{16,2}(0x8000_0000_0000_0000), " ") == "1 000000000000000"
@test bits(Valid{16,2}(0x8000_0000_0000_0000), " ") == "1 00000000000000 0"