`include "uvm_macros.svh"
import uvm_pkg::*;

/////////// Interface //////////

interface intf(input logic pclk, input logic presetn);
	logic pready;
	logic [7:0] prdata;
	logic pslverr;
	logic [7:0] pwdata;
	logic [4:0] paddr;
	logic psel;
	logic penable;
	logic pwrite;
endinterface 

///////// Transaction //////////

class apb_transaction extends uvm_sequence_item;
	`uvm_object_utils(apb_transaction)
	logic pready;
	logic [7:0] prdata;
	logic pslverr;
	rand bit [7:0] pwdata;
	rand bit [4:0] paddr;
	rand bit psel;
	rand bit penable;
	rand bit pwrite;
	function new(string name="apb_transaction");
		super.new(name);
	endfunction 
endclass


//////// Sequence /////////

class apb_sequence extends uvm_sequence#(apb_transaction);
	`uvm_object_utils(apb_sequence)
	
	function new(string name = "apb_sequence");
		super.new(name);
	endfunction 
	
	task body();
		
		/////////write operation /////////

		repeat (33) begin 
			apb_transaction trans;	
			trans = apb_transaction :: type_id :: create("trans");
			start_item(trans);
			assert(trans.randomize() with{
				trans.pwrite == 1;
				trans.penable == 1;
				trans.psel == 1;
			});
			finish_item(trans);
		end


		/////// Read Operation ///////////
		repeat (33) begin 
			apb_transaction trans;	
			trans = apb_transaction :: type_id :: create("trans");
			start_item(trans);
			assert(trans.randomize() with{
				trans.pwrite == 0;
				trans.penable == 1;
				trans.psel == 1;
			});
			finish_item(trans);
		end
	endtask
endclass


//////////////// Sequencer ////////////////

class apb_sequencer extends uvm_sequencer#(apb_transaction);
	`uvm_component_utils(apb_sequencer)
	function new(string name ="apb_sequencer", uvm_component parent);
		super.new(name,parent);
	endfunction 
endclass

////////// Driver //////////////

class apb_driver extends uvm_driver#(apb_transaction);
	`uvm_component_utils(apb_driver)
	virtual intf vif;
	function new(string name ="apb_driver", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf) :: get(this,"*","vif",vif))
			`uvm_fatal("Dirver Interface","Virtual interface was not given")
	endfunction	

	task run_phase(uvm_phase phase);
		forever begin
			apb_transaction trans;
			seq_item_port.get_next_item(trans);
			@(posedge vif.pclk);
			vif.penable = 0;
			vif.pwrite = trans.pwrite;
			vif.paddr = trans.paddr;
			vif.pwdata = trans.pwdata;
			vif.psel = trans.psel;
			@(posedge vif.pclk);
			vif.penable = trans.penable;
			do @(posedge vif.pclk); while (!vif.pready);
			vif.psel    = 0;
			vif.penable = 0;
			seq_item_port.item_done();
		end
	endtask
endclass

/////////// Monitor /////////

class apb_monitor extends uvm_monitor;
	`uvm_component_utils(apb_monitor)
	
	uvm_analysis_port#(apb_transaction) ap;
	virtual intf vif;
	
	function new(string name = "apb_monitor" , uvm_component parent);
		super.new(name,parent);
		ap = new("ap",this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf) :: get(this,"*","vif",vif))
			`uvm_fatal("Monitor Interface","Virtual interface was not given")
	endfunction
	
	task run_phase(uvm_phase phase);
		forever begin
			@(posedge vif.pclk);
			if(vif.penable && vif.psel && vif.pready) begin
			apb_transaction trans;
			trans = apb_transaction :: type_id :: create("trans",this);
			trans.pready = vif.pready;
			trans.prdata = vif.prdata;
			trans.pslverr = vif.pslverr;
			trans.psel = vif.psel;
			trans.pwdata = vif.pwdata;
			trans.penable = vif.penable;
			trans.paddr = vif.paddr;
			trans.pwrite = vif.pwrite;
			ap.write(trans);
			end
		end
	endtask
endclass

////////////// Scoreboard ////////////

class apb_sb extends uvm_scoreboard;
	`uvm_component_utils(apb_sb)
	uvm_analysis_imp#(apb_transaction,apb_sb) sb_imp;
	
	logic [7:0] mem [31:0];
	function new(string name="apb_sb", uvm_component parent);
		super.new(name,parent);
	endfunction 
	
	function void  build_phase(uvm_phase phase);
		super.build_phase(phase);
		sb_imp = new("sb_imp", this);
		for(int i = 0; i < 32; i++) begin
			mem[i] = 8'h0;
		end
	endfunction

	function void write(apb_transaction trans);
		if(trans.pwrite) begin
			mem[trans.paddr] = trans.pwdata;
			`uvm_info("Write data","Data was Written Successfully",UVM_MEDIUM)
		end else if(!trans.pwrite) begin
			if(mem[trans.paddr] == trans.prdata) 
				`uvm_info("read data","Match",UVM_MEDIUM)
			else
				`uvm_info("read data","Mismatch",UVM_MEDIUM)
		end
		`uvm_info("Remaining Data",$sformatf("Pready = %0b, Pslverr = %0b",trans.pready,trans.pslverr),UVM_MEDIUM)
		
	endfunction
		
endclass

///////// Agent ////////// 

class apb_agent extends uvm_agent;
	`uvm_component_utils(apb_agent)
	apb_driver dri;
	apb_monitor mon;
	apb_sequencer sequ;
	virtual intf vif;
	function new(string name ="apb_agent", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf)::get(this,"*","vif",vif))
			`uvm_fatal("AGENT_IF","Virtual interface not set")
		mon = apb_monitor :: type_id :: create("mon",this);
		mon.vif = vif;
		if(get_is_active() == UVM_ACTIVE) begin
			sequ = apb_sequencer :: type_id :: create("sequ",this);
			dri = apb_driver :: type_id :: create("dri",this);
			dri.vif = vif;
		end
	endfunction
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(get_is_active() == UVM_ACTIVE)
			dri.seq_item_port.connect(sequ.seq_item_export);
	endfunction
endclass


/////////////// Environment ///////////

class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)
	apb_agent age;
	apb_sb sb;
	
	function new(string name ="apb_env", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		age = apb_agent :: type_id :: create("age",this);
		sb = apb_sb :: type_id :: create("sb",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		age.mon.ap.connect(sb.sb_imp);
	endfunction  
endclass

//////////// Top /////////////

class apb_test extends uvm_test;
	`uvm_component_utils(apb_test);
	apb_env env;
	apb_sequence seq;
	function new(string name="apb_test", uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = apb_env :: type_id :: create ("env",this);
		seq = apb_sequence :: type_id :: create("seq",this);
		uvm_config_db#(uvm_active_passive_enum)::set(null,"env.age","is_active",UVM_ACTIVE);
	endfunction 

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
			seq.start(env.age.sequ);
			#1000;
		phase.drop_objection(this);
	endtask
endclass

////////// Top //////

module Verification_of_APB_Slave();
	logic pclk;
	logic presetn;
	intf vif(pclk, presetn);

	APB_Slave dut(
		.pclk(pclk),
		.presetn(presetn),
		.pready(vif.pready),
		.prdata(vif.prdata),
		.pslverr(vif.pslverr),
		.psel(vif.psel),
		.penable(vif.penable),
		.paddr(vif.paddr),
		.pwrite(vif.pwrite),
		.pwdata(vif.pwdata)
	);
	always #5 pclk = ~pclk;
	initial begin
			pclk = 0; presetn=0;
			uvm_config_db#(virtual intf) :: set(null,"*","vif",vif);
			run_test("apb_test");
	end
	initial begin
		
			#10; presetn=1;
	end
endmodule
