; BITMAP HANDLING FUNCTIONS

bm_start	EQU $2000

plot_image:
		; Validate file, read sk.
		JSR validate
		JSR getint
		STA sk
; RESET VARS
; FIRST LINE IS 199th. Go magic numbers go!
		LDA #199
		STA curlin
		LDY #$07
		STA bp
		INY
		STY bw
		LDA #$43
		STA bp+1

		LDA #40
		STA curcol		; curcol is not current column, but number
						; of bytes left to plot on line.

		LDX #$00
		STX buf
		STX sn
		STX mode

	subroutine img_plot
; DO STUFF
.plot_redo:
		JSR getchr
		BEQ .plot_end	; End of file?

		SEC
		SBC #$20	; ASCII offset to writable chars
		TAX			; X contains number of pixels to write

		LDA #$1		; Invert mode for each char read
		EOR mode
		STA mode

; If no characters to write, do nothing. This will happen occationaly.
		TXA
		BEQ .plot_redo

		LDA buf			; Load old buffer.
		LDY bw			; Pixels left to shift into A before plotting.
.plot_loop:
		ASL				; A contains data to plot. Shift A to the left,
		ORA mode		; and set the rightmost bit depending on mode.
		DEY
		BNE .plot_skip

; Plot buffer contents
.plot_buf:
		STA (bp),y		; Y is always 0 here, so write pixels to bp.
		DEC curcol
		BEQ .new_line	; New line reached?
		LDA #8			; Add 8 to bp, because of how bitmap data is stored.
		CLC
		ADC bp
		STA bp
		BCC .plot_done
		INC bp+1		; Bla bla, carry and stuff.
.plot_done:
		LDY #8

.plot_skip:
		DEX
		BNE .plot_loop

		STY bw			; Store away pixels left and buffer
		STA buf
		JMP .plot_redo	; Read next character

.plot_end:
		RTS				; Phew.


; Writes buffer to screen, resets it and updates the counters appropriately.
; Leaves X unchanged, assumes Y=0 and takes byte to write in A.
; Changes Y and A.

.new_line:
; WOO! New line calculation!

		TXA
		PHA

; Clear current column counter
		LDA #40
		STA curcol

; Reverse staggered interlacing line order someting
		LDA curlin
		CMP sk
		BGE no_sn_inc

; Increase interlacing offset
		INC sn
		LDA #200
		SBC sn
		SKIP_2
no_sn_inc:
		; Carry always set here. Also skipped when branch not taken.
		SBC sk
		STA curlin

; bp = offset = 320*(curlin/8)+(curlin%8)
;             = 320*(curlin>>3)+(curlin&7)

		LDX #<bm_start
		STX bp
		LDY #>bm_start
		LSR
		LSR
		LSR
		BEQ skip320
		TAX
		LDA bp
bp_40:
		INY
		CLC
		ADC #(320-256)
		BCC no_16inc_bp
		INY
no_16inc_bp:
		DEX
		BNE bp_40
		STA bp
skip320:
		STY bp+1
		LDA curlin
		AND #7
		CLC
		ADC bp
		STA bp




		PLA
		TAX
		JMP .plot_done






; Clear bitmap screen
clr_bmscr: subroutine clr_bmscr
		LDX #$20
		STX temp+1
		LDA #$00
		STA temp
		TAY
.loop:
		STA (temp),y
		INY
		BNE .loop
		CPX #$3e
		BEQ .end
		INX
		STX temp+1
		BNE .loop
.end:
		LDA #$F0
		JSR set_color
		RTS

; Set foregroud and background colors of bitmap.
; Colors in A.
set_color: subroutine set_color
		LDX #$04
		STX temp+1
		LDY #$00
		STY temp
.loop:
		STA (temp),y
		INY
		BNE .loop
		CPX #$07
		BEQ .end
		INX
		STX temp+1
		BNE .loop
.end:
		LSR
		LSR
		LSR
		LSR
		STA $d020
		RTS


bitmap_enable:
		; Bitmap location
		LDA $D018
		ORA #%00001000
		STA $D018
		; Enable bitmap
		LDA $D011
		ORA #%00100000
		STA $D011
		RTS
