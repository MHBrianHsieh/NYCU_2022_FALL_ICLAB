######################################################
#                                                    #
#  Silicon Perspective, A Cadence Company            #
#  FirstEncounter IO Assignment                      #
#                                                    #
######################################################

Version: 2

#Example:  
#Pad: I_CLK 		W

#define your iopad location here

Pad: O_VALID          E
Pad: O_VALUE          E
Pad: PF1              E    PFILL
Pad: VDDP2            E
Pad: GNDP2            E
Pad: VDDC2            E
Pad: GNDC2            E


Pad: I_MATRIXSIZE0    S
Pad: I_MATRIXSIZE1    S
Pad: I_MATRIX         S
Pad: VDDP3            S
Pad: GNDP3            S
Pad: VDDC3            S
Pad: GNDC3            S

Pad: VDDC1            W
Pad: GNDC1            W
Pad: I_VALID2         W
Pad: I_IMATIDX        W
Pad: I_WMATIDX        W
Pad: VDDP1            W
Pad: GNDP1            W

Pad: VDDC0            N
Pad: GNDC0            N
Pad: VDDP0            N
Pad: GNDP0            N
Pad: I_CLK            N
Pad: I_RESET          N
Pad: I_VALID          N

Pad: PCLR SE PCORNER
Pad: PCUL NW PCORNER
Pad: PCUR NE PCORNER
Pad: PCLL SW PCORNER
