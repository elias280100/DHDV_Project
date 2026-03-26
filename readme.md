##Ethernet 2 frame transmission and reception inlcuding Frame Check Sequence (FCS) using a Cyclic Redundancy Check 32 (CRC32)

#Total assignment
the folder named code contains 4 folders
- crc32
    contains simulation and source files of the CRC32
- frame_rx
    contains simulation and source files of Ethernet frame Rx
- frame_tx
    contains simulation and source files of Ethernet frame Tx
- final
    contains simulation and source files of the entire project.

#Build
For building each module run the command **make** in the sim path of the respective module

#View simulation
- crc32
    run the command **gtkwave CRC_Gen.vcd** in the sim path
- frame_rx
    run the command **gtkwave Ethernet_frame_rx.vcd** in the sim path
- frame_tx
    run the command **gtkwave Ethernet_frame.vcd** in the sim path
- final
    run the command **gtkwave Final.vcd** in the sim path


