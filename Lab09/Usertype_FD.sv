//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2022 ICLAB Fall Course
//   Lab09      : FD
//   Author     : Po-Kang Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : Usertype_FD.sv
//   Module Name : usertype
//   Release version : v1.0 (Release Date: Nov-2022)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic  [3:0] { No_action	        = 4'd0,
                            Take		        = 4'd1,
							Deliver		        = 4'd2,
							Order   		    = 4'd4, 
							Cancel   	        = 4'd8 
							}  Action ;
							
typedef enum logic  [3:0] { No_Err       		= 4'b0000, //No error
                            No_Food             = 4'b0001, //No food
							D_man_busy          = 4'b0010, //Delivery man busy
						    No_customers	    = 4'b0100, //No customers  
							Res_busy	        = 4'b1000, //Restaurant is busy
							Wrong_cancel        = 4'b1010, //Wrong cancel
							Wrong_res_ID        = 4'b1011, //Wrong Restaurant ID
							Wrong_food_ID       = 4'b1100  //Wrong Food ID
							}  Error_Msg ;

typedef enum logic  [1:0]	{ None              = 2'b00,
							Normal      	    = 2'b01,
							VIP                 = 2'b11
							}  Customer_status ;				

typedef enum logic  [1:0] { No_food      	    = 2'd0,
							FOOD1	       	    = 2'd1,
							FOOD2       	    = 2'd2,
							FOOD3 			    = 2'd3
							}  Food_id ;


typedef logic [7:0] Delivery_man_id;
typedef logic [7:0] Restaurant_id;
typedef logic [3:0] servings_of_food; 
typedef logic [7:0] limit_of_orders;
typedef logic [7:0] servings_of_FOOD; 

typedef struct packed {
    Customer_status		ctm_status; //Customer status
	Restaurant_id   	res_ID;     //restaurant ID
	Food_id				food_ID;    //food ID
	servings_of_food    ser_food;   //servings of food
} Ctm_Info; //Customer info

typedef struct packed {
	Ctm_Info 	ctm_info1; //customer1 info
	Ctm_Info 	ctm_info2; //customer2 info
} D_man_Info; //Delivery man info

typedef struct packed {
	limit_of_orders		limit_num_orders; //limit of total number of orders
	servings_of_FOOD	ser_FOOD1; //Servings of FOOD1
	servings_of_FOOD	ser_FOOD2; //Servings of FOOD2
	servings_of_FOOD	ser_FOOD3; //Servings of FOOD3	
} res_info; //restaurant info

typedef struct packed {
	Food_id				d_food_ID;    //food ID
	servings_of_food    d_ser_food;   //servings of food
} food_ID_servings; //food ID & servings of food

typedef union packed{ 
	Delivery_man_id		[5:0]	d_id;
    Action		    	[11:0]	d_act;
	Ctm_Info        	[2:0]	d_ctm_info;
	Restaurant_id		[5:0]   d_res_id;
	food_ID_servings	[7:0]   d_food_ID_ser;
} DATA;

//################################################## Don't revise the code above

//#################################
// Type your user define type here
//#################################
// typedef struct packed {
// 	D_man_Info golden_d_man_info;
// 	res_info   golden_res_info;
// } OUT_INFO;



typedef enum logic [2:0] {
	B_IDLE            = 3'b000,
	B_C_IN_VALID      = 3'b001,
	B_ARREADY         = 3'b010,
	B_RVALID          = 3'b011,
	B_AWREADY         = 3'b100,
	B_WVALID          = 3'b101,
	B_FINISH          = 3'b110
} bridge_state;

typedef enum logic [3:0] {
	FD_IDLE            = 4'b0000,
	FD_ACT_VALID       = 4'b0001,
	FD_ID_VALID        = 4'b0010,
	FD_RES_VALID       = 4'b0011,
	FD_FOOD_VALID      = 4'b0100,
	FD_CUS_VALID       = 4'b0101,
	FD_RD_C_IN_VALID   = 4'b0110,
	FD_DRAM_READ       = 4'b0111,
	FD_ERR_MSG         = 4'b1000,
	FD_EXECUTE         = 4'b1001,
	FD_WR_C_IN_VALID   = 4'b1010,
	FD_DRAM_WRITE      = 4'b1011,
	FD_FINISH          = 4'b1100
} fd_state;


typedef logic [1:0] Restaurant_id_1_0;
typedef logic [5:0] Restaurant_id_7_2;

typedef struct packed {
	Restaurant_id_1_0  	res_ID_1_0; //restaurant ID
	Food_id				food_ID;    //food ID
	servings_of_food    ser_food;   //servings of food
	Customer_status		ctm_status; //Customer status
	Restaurant_id_7_2  	res_ID_7_2; //restaurant ID
} Ctm_Info_dram; //Customer info in DRAM format

typedef struct packed {
	Ctm_Info_dram 	ctm_info2; //customer1 info
	Ctm_Info_dram 	ctm_info1; //customer2 info
} D_man_Info_dram; //Delivery man info in DRAM format

typedef struct packed {
	servings_of_FOOD	ser_FOOD3; //Servings of FOOD3	
	servings_of_FOOD	ser_FOOD2; //Servings of FOOD2
	servings_of_FOOD	ser_FOOD1; //Servings of FOOD1
	limit_of_orders		limit_num_orders; //limit of total number of orders
} res_info_dram; //restaurant info in DRAM format

typedef struct packed {
	D_man_Info_dram 	d_man_info; //customer info
	res_info_dram	 	res_info; 	//res info
} dram_data; //Delivery man info in DRAM format


//################################################## Don't revise the code below
endpackage
import usertype::*; //import usertype into $unit

`endif

