// To verify that the adder adds, we also need to check that it 
// does not add when rstn is 0, and hence rstn should also be 
// randomized along with a and b.
class Packet;
  rand bit 		rstn;
  rand bit[7:0] data_in;
  bit [31:0] crc_out;
  //rand bit 			valid;
  bit 			valid; //for setting valid always to 1 in generator
  
  // Print contents of the data packet
  function void print(string tag="");
    $display ("T=%0t data=0x%0h crc=0x%0h", $time, data_in, crc_out);
  endfunction
  
  // This is a utility function to allow copying contents in 
  // one Packet variable to another.
  function void copy(Packet tmp);
	  //your code here
    this.rstn = tmp.rstn;
    this.data_in    = tmp.data_in;
    this.valid    = tmp.valid;
    this.crc_out  = tmp.crc_out;
  endfunction



endclass
