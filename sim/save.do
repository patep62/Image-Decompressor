mem save -o SRAM.mem -f mti -data hex -addr hex -startaddress 0 -endaddress 262143 -wordsperline 8 /TB/SRAM_component/SRAM_data

if {[file exists $rtl/RAM0.ver]} {
    file delete $rtl/RAM0.ver
}
mem save -o RAM0.mem -f mti -data hex -addr decimal -wordsperline 1 /TB/UUT/DRAM_inst0/altsyncram_component/m_default/altsyncram_inst/mem_data

if {[file exists $rtl/RAM1.ver]} {
    file delete $rtl/RAM1.ver
}
mem save -o RAM1.mem -f mti -data hex -addr decimal -wordsperline 1 /TB/UUT/DRAM_inst1/altsyncram_component/m_default/altsyncram_inst/mem_data

if {[file exists $rtl/RAM3.ver]} {
    file delete $rtl/RAM3.ver
}
mem save -o RAM2.mem -f mti -data hex -addr decimal -wordsperline 1 /TB/UUT/DRAM_inst2/altsyncram_component/m_default/altsyncram_inst/mem_data