; File names and file name lengths for each option.
; Max file name length is still 8 (plus extention, not saved)
fnoff	EQU $c800			;File name save offset
floff	EQU $c800+(8*9)+1	;File name lengths. Add one for good measure.

; MENU HANDLING FUNCTIONS

; Translate IBM colors to VIC-II colors
cga_color:
		.BYTE 0,6,5,15,2,4,9,12,11,14,3,13,10,11,7,1

show_menu:
; Validate image file (lol no)
		JSR validate
; Ignore first int (I'm not entirely sure what it is supposed to do anyway)
		JSR getint
; Get second int, translate to IBM colors, stove away
		JSR getint
		TAX
		LDA cga_color,x
		STA bp
; Get third int, left shift and add second int.
		JSR getint
		TAX
		LDA cga_color,x
		ASL
		ASL
		ASL
		ASL
		ADC bp
; Set foreground and background
		JSR set_color

; Load and show menu options
; Only file names are saved. Options are printed and forgotten.

	subroutine menuops

		LDY #0
		STY opno			; Start at option number 0

.next
		JSR getint			; Read X corredinate of option
		STA chrcol
		DEC chrcol
		JSR getint			; Read Y coordinate of option
		STA chrlin
		DEC chrlin

		; Calculate where in fnoff to save file name.
		LDA opno
		ASL
		ASL
		ASL
		ADC #<fnoff
		STA pc_tmp
		LDA #>fnoff
		STA pc_tmp+1
		
		;Read text to put
		JSR getstr
		; If length is 0, do not put string.
		BEQ .readonly

		PHA
		; Show option info
		LDA #" "
		JSR putc
		LDA opno
		ADC #"1"
		JSR putc
		LDA #":"
		JSR putc
		LDA #" "
		JSR putc
		PLA
		JSR puts
		JSR getstr			;Read file name
.skip
		LDY opno
		STA floff,y			; Save file name length
		INY
		STY opno			; Increment option number.
		CPY #9				; Read total of 8 options.
		BNE .next

		RTS

.readonly
		JSR getstr
		LDA #0
		BEQ .skip

get_choice: subroutine
		GETKEY_BLOCK		; Read user choice, 1 to 9.
		SEC
		SBC #"0"
		BEQ get_choice
		CMP #10
		BCS get_choice
		TAY
		DEY
		TYA
		LDA floff,y
		BEQ get_choice
		; Store file name length
		STA fname_len

		; File names are static length 8 base 0. Calc offset.
		TYA
		ASL
		ASL
		ASL
		TAY
		; Check if file name is "EXIT"
		JSR cmp_exit
		BCS .end

		; Copy file name to fname variable
		LDA fname_len
		JSR fname_copy
		CLC
.end:
		RTS

; Compare with "EXIT" string. String starts at Y bytes offset from fnoff.
; Exactly 4 bytes are compared.
; Returns with carry set if string matches. Changes X, Y and A.
cmp_exit: subroutine cmp_exit
		LDX #4
.loop:
		LDA fnoff,y
		CMP .exit_str-1,x
		BNE .not_exit
		INY
		DEX
		BEQ .loop
		SEC
		RTS
.not_exit
		CLC
		RTS
.exit_str
		.BYTE "TIXE"

; Copy file name after choice is made, from file name table to file name var.
; Changes A, X and Y.
fname_copy: subroutine fname_copy
		LDX #0
.more
		LDA fnoff,y
		STA fname,x
		INY
		INX
		CPX fname_len
		BNE .more
		RTS
