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
	STEPBYTE2	EQU	H'061'
	STEPBYTE3	EQU	H'062'
	STEPBYTE4	EQU	H'063'
	
DRIVE_CODE CODE
 
DRIVE
	BANKSEL PORTB
	MOVLW H'000'
	SUBWF STEPBYTE4,0	; SKIP BYTE IF IT IS 0
	BTFSC STATUS,Z
	GOTO EVALBYTE3
	; 
UPPERLOOP2
	CALL STEP
	DECFSZ STEPBYTE4,1
	GOTO UPPERLOOP2
	
EVALBYTE3
	MOVLW H'000'
	SUBWF STEPBYTE3,0	; SKIP BYTE IF IT IS 0
	BTFSC STATUS,Z
	GOTO EVALBYTE2
	;
UPPERLOOP1
	CALL STEP
	DECFSZ STEPBYTE3,1
	GOTO UPPERLOOP1
	
	
EVALBYTE2
	MOVLW H'000'
	SUBWF STEPBYTE2,0	; SKIP BYTE IF IT IS 0
	BTFSC STATUS,Z
	GOTO EVALBYTE1
	;
LOWERLOOP2
	CALL STEP
	DECFSZ STEPBYTE2,1
	GOTO UPPERLOOP1
	
EVALBYTE1
	MOVLW H'000'
	SUBWF STEPBYTE1,0	; SKIP BYTE IF IT IS 0
	BTFSC STATUS,Z
	GOTO EVALBYTE2
	;
LOWERLOOP1
	CALL STEP
	DECFSZ STEPBYTE1,1
	GOTO LOWERLOOP1
	RETURN
	
	
STEP
	BSF PORTB,3	    ; SET OUTPUT HIGH FOR PULSE WIDTH
	CALL DELAY	    ; CALL DELAY FOR PULSE WIDTH
	BTFSS PIR1,TMR1IF   ; POLL COMPLETION OF TMR1
	GOTO $-1
	BCF T1CON,0	    ; TURN OFF TIMER
	BCF PORTB,3	    ; CLEAR OUTPUT FOR PULSE WIDTH
	CALL DELAY	    ; CALL SAME DELAY FOR ~50% DC 
	BTFSS PIR1,TMR1IF
	GOTO $-1
	BCF T1CON,0	    ; TURN OFF TIMER
	RETURN

	
DELAY
	BANKSEL TMR1H
	MOVLW H'0FD'
	MOVWF TMR1H
	BANKSEL TMR1L
	MOVLW H'0E8'
	MOVWF TMR1L	    ; LOAD TMR REGISTERS TO PRODUCE A 25K COUNT
	BANKSEL T1CON
	MOVLW H'034'    ; 1:8 PRESCALE WITH INSTRUCTION CLK AS SOURCE 
	MOVWF T1CON
	BSF T1CON,0	    ; ENABLE TIMER 1
	BCF PIR1,TMR1IF
	RETURN
	
	
    
    