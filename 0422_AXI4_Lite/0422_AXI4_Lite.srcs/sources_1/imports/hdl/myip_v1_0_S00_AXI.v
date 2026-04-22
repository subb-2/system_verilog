
`timescale 1 ns / 1 ps

module myip_v1_0_S00_AXI #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // ** 파라미터 이름으로 되어있는 것을 숫자로 변경 
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input  wire                S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input  wire                S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input  wire [     4-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input  wire [       2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input  wire                S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire                S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input  wire [    32-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    input  wire [(32/8)-1 : 0] S_AXI_WSTRB, // 몇 바이트 저장할지 알려주는 역할 
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input  wire                S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire                S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [       1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire                S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input  wire                S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input  wire [     4-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input  wire [       2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input  wire                S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire                S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [    32-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [       1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire                S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input  wire                S_AXI_RREADY
);

    // AXI4LITE signals
    reg [ 4-1 : 0] axi_awaddr;
    reg            axi_awready;
    reg            axi_wready;
    reg [   1 : 0] axi_bresp;
    reg            axi_bvalid;
    reg [ 4-1 : 0] axi_araddr;
    reg            axi_arready;
    reg [32-1 : 0] axi_rdata;
    reg [   1 : 0] axi_rresp;
    reg            axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit 32
    // 2 is used for addressing 32/64 bit registers/memories
    // 2 = 2 for 32 bits (n downto 2)
    // 2 = 3 for 64 bits (n downto 3)
	// ** 이것도 모두 이름으로 되어있는 것을 숫자로 변경 
    localparam integer ADDR_LSB = (32 / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 4
    reg     [32-1:0] slv_reg0;
    reg     [32-1:0] slv_reg1;
    reg     [32-1:0] slv_reg2;
    reg     [32-1:0] slv_reg3;
    wire             slv_reg_rden;
    wire             slv_reg_wren;
    reg     [32-1:0] reg_data_out;
    integer          byte_index;
    reg              aw_en;

    // I/O Connections assignments

	//wire로 연결되어있으니까? 
	//하나 하나가 포드라고 생각하기 
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;
    // Implement axi_awready generation : aw_ready를 생성한다.
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin //동기 리셋 
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
			// CPU 쪽에서 주소와 데이터를 동시에 보내는 것으로 추측 가능 
			// aw_en = write 시작 flag
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
				//write transaction 동작이 끝났으면,
				//중간에 받는 것을 막겠다.
				//write transaction 끝날 때까지 en = 0 
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching ** 주소 값을 임시 저장 
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 
	// 둘 다 1일 때, 저장 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR; // 앞에 코드에서 aw_ready = 1 과 동시 실행 
            end
        end
    end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    // de-asserted when reset is low. 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
			// 주소와 데이터가 왔고, aw_en = 1 이면,
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                // slave is ready to accept write data when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_wready <= 1'b1;
            end else begin 
				//딱 한 클락만 1이 됨 
                axi_wready <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
	// Write strobes = 몇 바이트 저장할지 
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied. // 리셋일 때 clear 됨 
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
	//주소와 데이터 모두 handshaking이 일어났을 때 저장하겠다.
	//wready = 1 이 실행되고 다음 클락에 이것이 실행될 것 같음 
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[2+1:2])
                    2'h0:
                    for (
                        byte_index = 0;
                        byte_index <= (32 / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 0
						// 
                        slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h1:
                    for (
                        byte_index = 0;
                        byte_index <= (32 / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 1
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h2:
                    for (
                        byte_index = 0;
                        byte_index <= (32 / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 2
                        slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h3:
                    for (
                        byte_index = 0;
                        byte_index <= (32 / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 3
                        slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_awready, S_AXI_AWVALID, axi_wready and S_AXI_WVALID are asserted.  
	// 주소, 데이터가 다 끝났을 때 응답 
    // This marks the acceptance of address and indicates the status of 
    // write transaction.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
			//주소와 데이터 handshaking 일어나고 bvalid는 아직일 때 
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;  // 'OKAY' response 
            end                   // work error responses in future
	      else
	        begin
				//B 의 handshaking이 일어났을 때 다시 0으로 내리기 
                if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when  : 한 클럭 동안에만 
    // S_AXI_ARVALID is asserted. axi_arready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when S_AXI_ARVALID is 
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1'b1;
                // Read address latching
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Implement axi_rvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                // Valid read data is available at the read data bus
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // 'OKAY' response
            end else if (axi_rvalid && S_AXI_RREADY) begin
                // Read data is accepted by the master
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        // Address decoding for reading registers
        case (axi_araddr[2+1:2])
            2'h0   : reg_data_out <= slv_reg0;
            2'h1   : reg_data_out <= slv_reg1;
            2'h2   : reg_data_out <= slv_reg2;
            2'h3   : reg_data_out <= slv_reg3;
            default : reg_data_out <= 0;
        endcase
    end

    // Output register or memory read data
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            // When there is a valid read address (S_AXI_ARVALID) with 
            // acceptance of read address by the slave (axi_arready), 
            // output the read dada 
            if (slv_reg_rden) begin
				//실제 밖으로 내보내는 순간 
				//데이터랑 rvalid랑 동시에 나감
				//rvalid 관련 코드 조건과 동일 
                axi_rdata <= reg_data_out;  // register read data
            end
        end
    end

    // Add user logic here

    // User logic ends

endmodule
