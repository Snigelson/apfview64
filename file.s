loadaddr	EQU $5000

; FILE HANDLING FUNCTIONS
; These are rather specific.

; FIRST FILE IS /ALWAYS/ APERTURE.A?F
; This also happens to be 12 characters long; maximum file length.
; If for some reason thus should change, don't forget to add padding.
fname:
		.byte "APERTURE.A?F"
; Actually, this is file length-4. Suffix is added when loading.
fname_len:
		.byte 8

; Validate header. Actually just skips header.
validate:
		JSR getchr
		BCC validate
		JSR ungetc
		RTS

; Ugly but it needs to be done.
ungetc: subroutine ungetc
		LDA foff
		SEC
		SBC #1
		STA foff
		BCS .done
		DEC foff+1
.done
		RTS

; Read an integer terminated by comma or newline.
; Rerturns in A
getint: subroutine getint
		LDA #0
		STA intbuf
		JSR getchr
.readmore
		CMP #","
		BEQ .done
		SEC
		SBC #"0"

		; Multiply by 10 before add.
		; Carry is no problem in this implementation since
		; all integers will be < 256
		TAX
		LDA intbuf
		ASL
		ASL
		ASL
		ADC intbuf
		ADC intbuf
		STX intbuf
		ADC intbuf
		STA intbuf
		JSR getchr
		BCC .readmore
		JSR ungetc		;new line found
.done
		LDA intbuf
		RTS

;Get a quoted string. Will read until a quotation mark is found.
;Length is returned in A. String pointer is saved at pc_tmp
; X,Y,A is changed.
getstr: subroutine getstr
		JSR getchr
		CMP #$22 		; ASCII quotation mark
		BNE getstr

		LDA #0
		STA chrnum
.loop
		JSR getchr
		CMP #$22		; ASCII quotation mark
		BEQ .the_end
		LDY chrnum
		STA (pc_tmp),y
		INC chrnum
		BNE .loop
.the_end
;Write a zero string terminator.
		TYA
		LDY chrnum
		STA (pc_tmp),y
		TYA
		RTS

; Returns Y=0, X unchanged, A read character.
; Carry flag indicates new line was started.
; A=0 indicates end of file
getchr: subroutine getchr
		LDA foff
		CMP fileend
		BEQ .eof_found_maybe
.eof_not_found:
		LDY #$00
		LDA (foff),y
		INC foff
		BNE gc_skip_16
		INC foff+1
gc_skip_16:
		;set flag and redo if line feed found
		CMP #10 ;"\n"
		BEQ	gc_setflg
		CLC
gc_end:
		RTS
gc_setflg:
		JSR getchr
		SEC
		RTS

.eof_found_maybe:
		LDA foff+1
		CMP fileend+1
		BNE .eof_not_found
		LDA #0
		RTS

load_apf:
; Correct file name, add "??P?" at end
		LDY #"P"
		SKIP_2

load_amf:
; Correct file name, add "??M?" at end
		LDY #"M"

load_common:
; Correct file name, add ".A?F" at end
		LDX fname_len
		LDA #"."
		STA fname,x
		INX
		LDA #"A"
		STA fname,x
		INX
		TYA
		STA fname,x
		INX
		LDA #"F"
		STA fname,x
		JSR load_real
		RTS

load_real:
; (when X/Y is an address, X holds LSB and Y holds MSB)
		;SETNAM
		LDA fname_len
		CLC
		ADC #4
		LDX <#fname
		LDY >#fname
		JSR $ffbd
		
		;SETLFS
		LDA #$01
		LDX #$08
		LDY #$00
		JSR $ffba
		
		;LOAD
		LDA #0

		LDX #<loadaddr
		LDY #>loadaddr
		JSR	$ffd5
		BCC lf_end

; We end up here if loading failed. Print error message.
		JSR print_text_load_err
		SEC
		RTS

lf_end:
		STX fileend
		STY fileend+1

; Set foff to start of file
		LDA #<loadaddr
		STA foff
		LDA #>loadaddr
		STA foff+1

		RTS
