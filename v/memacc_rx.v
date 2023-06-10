//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, c.fan                                                      
//                                                                                
// Redistribution and use in source and binary forms, with or without             
// modification, are permitted provided that the following conditions are met:    
//                                                                                
// 1. Redistributions of source code must retain the above copyright notice, this 
//    list of conditions and the following disclaimer.                            
//                                                                                
// 2. Redistributions in binary form must reproduce the above copyright notice,   
//    this list of conditions and the following disclaimer in the documentation   
//    and/or other materials provided with the distribution.                      
//                                                                                
// 3. Neither the name of the copyright holder nor the names of its               
//    contributors may be used to endorse or promote products derived from        
//    this software without specific prior written permission.                    
//                                                                                
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"    
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE      
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE   
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL     
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR     
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER     
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.           
//////////////////////////////////////////////////////////////////////////////////

/**
 * memory access result check
 */

`include "instructions.v"

module memacc_rx(
   input                clk         ,
   input                rst_n       ,
   input                ren_i       ,  // I'm reading the mem
   input    [1:0]       scope_i     ,  // are you reading word, half word, or byte?
   input                signed_i    ,  
   input    [1:0]       addr_lsb2_i ,  // least 2 bits of the address
   // from mem / cache
   input    [31:0]      rdata_i     ,
   input                rdata_miss_i,
   // input                rillegal_i  , // future
   // to wb
   output reg [31:0]    data_o     ,
   output reg           data_valid_o  ,
   // to stall the pipeline
   output reg           stall_req_o 
   );
   
   reg signbit_r;
   always @(*) begin
      case (scope_i) 
         2'b00 :
            case (addr_lsb2_i)
               2'b00 :  
                  signbit_r <= signed_i ? rdata_i[31] : 1'b0;
               2'b01 :
                  signbit_r <= signed_i ? rdata_i[23] : 1'b0;
               2'b10 :
                  signbit_r <= signed_i ? rdata_i[15] : 1'b0;
               2'b11 :
                  signbit_r <= signed_i ? rdata_i[7] : 1'b0;
            endcase
         2'b01 :
            if (addr_lsb2_i[1])
               signbit_r <= signed_i ? rdata_i[15] : 1'b0;
            else
               signbit_r <= signed_i ? rdata_i[31] : 1'b0;
         default :
            signbit_r <= 1'b0;
      endcase
   end

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         data_valid_o <= 1'b0;
         data_o <= 32'b0;
         stall_req_o <= 1'b0;
      end
      else if (rdata_miss_i) begin
         data_valid_o <= 1'b0;
         data_o <= 32'b0;
         stall_req_o <= 1'b1;
      end
      else begin
         data_valid_o <= 1'b1;
         case (scope_i) // big endian
            2'b00 : 
               case (addr_lsb2_i)
                  2'b00 :  begin
                     data_o <= {{24{signbit_r}}, rdata_i[31:24]};
                  end
                  2'b01 :
                     data_o <= {{24{signbit_r}}, rdata_i[23:16]};
                  2'b10 :
                     data_o <= {{24{signbit_r}}, rdata_i[15:8]};
                  2'b11 :
                     data_o <= {{24{signbit_r}}, rdata_i[7:0]};
               endcase
            2'b01 : 
               if (addr_lsb2_i[1])
                  data_o <= {{16{signbit_r}}, rdata_i[15:0]};
               else
                  data_o <= {{16{signbit_r}}, rdata_i[31:16]};
            2'b11 : 
               data_o <= rdata_i;
            default : 
               ; // won't happen
         endcase
         stall_req_o <= 1'b0;
      end
   end

endmodule