;***************************************************************************
;
;	    Filename: StepperDrive.ASM
;	    Date: 11/21/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: An include file for stepping an output at a 50% duty
;			    cycle based on a set time delay. works for 4 byte 
;			    timing
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 11/21/2024
;
;*************************************************************************
    
; GPR Reservations  
	STEPBYTE1	EQU	H'060'
	STEPBYTE2	EQU	H'O61'
	STEPBYTE3	EQU	H'063'
	STEPBYTE4	EQU	H'064'
	
DRIVE_CODE CODE
 
DRIVE
 
	
	
    
    