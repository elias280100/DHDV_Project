typedef class test;
module tb;
  
  clk_if 	m_clk_if 	();
  crc_if 	m_crc_if	();
  CRC32 	u0 			(m_crc_if, m_clk_if);


//Wavefrom dump
    initial begin
        // Dump für GTKWave/ModelSim
        $dumpfile("CRC_Gen.vcd");
        $dumpvars(0, tb);
    end

  initial begin
    test t0;

    t0 = new;
    t0.e0.m_crc_vif = m_crc_if;
    t0.e0.m_clk_vif = m_clk_if;
    t0.run();
    
    // Once the main stimulus is over, wait for some time
    // until all transactions are finished and then end 
    // simulation. Note that $finish is required because
    // there are components that are running forever in 
    // the background like clk, monitor, driver, etc
    //#50 $finish;
    #50 $finish;
  end
endmodule
