; display processor module
; copyright 1976 d. kruglinski
;
; initialization
stack	equ	0ffh	;stack addr
cintc	equ	0fffbh	;rtc control address
gstrt	equ	100h	;start address
kintc	equ	0ffc0h	;kbrd int control addr
tick	equ	3fh	;system time
top	equ	40h	;display file start addr
xyout	equ	0fffch	;crt output addr
	org	gstrt
init:	lxi	d,0	;zero xy (in de always)
	lxi	h,table
	shld	incpt	;init increment pointer
	lxi	sp,stack        ;init stack pointer
	mvi	a,10h
	sta	kintc	;turn on kb int
	mvi	a,80h
	sta	cintc	;turn on rtc interrupt
	ei
	lhld	top
	shld	pntr	;init instruction pointer
; opcode decoding
mloop:	lhld	pntr	;address of opcode
	mov	c,m
	mvi	b,0	;opcode in bc
	lxi	h,jmtab	;base of jump table
	dad	b	;add opcode
	mov	c,m
	inx	h
	mov	h,m
	mov	l,c	;addr of routine in hl
	pchl		;jump to it
; jump table for opcode processing
jmtab:	dw	mbeam	;0
	dw	mdisp	;2
	dw	lvec	;4
	dw	svec	;6
	dw	param	;8
	dw	jump	;a
	dw	jumps	;c
	dw	rets	;e
	dw	exec	;10h
	dw	sync	;12h
; move beam - don't display point
mbeam:	lhld	pntr
	inx	h
	mov	d,m	;get x coord
	inx	h
	mov	e,m	;get y coord
	inx	h
	shld	pntr	;restore pointer
	jmp	mloop	;get another instruction
; move beam and display point
mdisp:	lhld	pntr
	inx	h
	mov	d,m
	inx	h
	mov	e,m
	inx	h
	shld	pntr
	xchg		;xy to hl
	shld	xyout	;write to crt
	xchg		;sy to de
	jmp	mloop
; set orientation and scale
param:	lhld	pntr
	inx	h
	mov	c,m
	inx	h
	shld	pntr
	mov	l,c	;new orent & scale in hl
	mvi	h,0
	lxi	b,table	;address of increment table
	dad	b	;add orent & scale
	shld	incpt	;store in increment pointer
	jmp	mloop	;get another instruction
; jump to a new location in display file
jump:	lhld	pntr
	inx	h
	mov	a,m	;1st half of address
	inx	h
	mov	h,m	;2nd half of address
	mov	l,a
	shld	pntr	;store in instruction pointer
	jmp	mloop
; jump to subroutine
jumps:	lhld	pntr
	inx	h
	mov	c,m
	inx	h
	mov	b,m	;new address in bc
	inx	h
	push	h	;store old pointer in stack
	mov	h,b
	mov	l,c
	shld	pntr	;address in instruction pointer
	jmp	mloop
; return from subroutine
rets:	pop	h	;restore pointer from stack
	shld	pntr
	jmp	mloop
; short vector mode
svec:	lhld	pntr	;current instr index
	inx	h
next:	mov	b,m	;short vector instruction
	inx	h
	shld	pntr	;restore pointer
	mov	a,b
	ani	7h	;mask direction bits
	mov	c,a	;offset in c
	mov	a,b	;orig inst in a
	mvi	b,0	;zero in b
	lhld	incpt	;increment pointer
	dad	b	;add direction offset
	mov	b,m	;x increment
	inx	h
	inx	h
	mov	c,m	;y increment
	xchg		;xy in hl
	mov	e,a	;original instr
	ani	70h	;length bits
	rrc
	rrc
	rrc
	rrc		;shift right 4
	mov	d,a	;in d
	mov	a,e	;original instr
	ani	8h	;on/off bit
	jnz	floop	;jump if "off"
	shld	xyout	;initial dot to crt
nloop:	mov	a,b	;x increment
	add	h
	mov	h,a
	mov	a,c
	add	l
	mov	l,a	;new xy in hl
	shld	xyout	;write to crt
	dcr	d
	jnz	nloop	;loop if not done
	jmp	ckesc	;check "escape"
floop:	mov	a,b	;x increment
	add	h	;add to x
	mov	h,a
	mov	a,c	;y increment
	add	l	;add to y
	mov	l,a	;new xy in hl
	dcr	d
	jnz	floop	;loop if not done
ckesc:	mov	a,e	;original instruction
	xchg		;xy to de
	rlc		;set carry if "escape"
	jc	mloop	;main loop if so
	lhld	pntr
	jmp	next	;get more data if not
; long vector mode
lvec:	lhld	pntr
	inx	h
	mov	b,m	;new x pos
	inx	h
	mov	a,m	;new y pos
	inx	h
	shld	pntr
;
	mvi	c,0f8h	;special mask for -
	sub	e	;del y in a
	jc	plusy	;test sign of del
	mvi	c,0	;special mask for +
plusy:	rlc
	rlc
	rlc		;divide by 32
	mov	h,a	;save in h
	ani	0f8h	;save 1st 5 bits
	mov	l,a	;l.o. yinc
	mov	a,h	;restore
	ani	7h	;save last 3 bits
	xra	c	;xor special mask
	mov	h,a	;h.o. yinc
	shld	yinc	;store
;
	mov	a,b	;x pos
	mvi	c,0f8h
	sub	d	;del x in a
	jc	plusx
	mvi	c,0
plusx:	rlc
	rlc
	rlc
	mov	h,a
	ani	0f8h
	mov	l,a	;l.o. xinc
	mov	a,h
	ani	7h
	xra	c
	mov	h,a	;h.o. xinc
	shld	xinc
;
	mov	b,d	;x in bc (h.o.)
	mvi	c,0
	mov	d,e	;y in de (h.o.)
	mvi	e,0
	mvi	a,20h	;32 points in vect
;
lloop:	lhld	yinc
	dad	d
	xchg		;new y in de
	lhld		xinc
	dad	b
	mov	b,h	;new x in bc
	mov	c,l
	mov	l,d	;xy in hl (h.o.)
	shld	xyout	;write to crt
	dcr	a
	jnz	lloop
;
	xchg		;restore xy to de
	jmp	mloop
; transfer control to executive
exec:	lhld	pntr	;bump pointer
	inx	h
	shld	pntr
	mvi	h,80h	;beam to screen center
	mvi	l,80h
	shld	xyout
	rst	3	;xfer to loc 18h
	jmp	mloop	;next instruction
; synchronize with real-time clock
sync:	lhld	pntr	;bump pointer
	inx	h
	shld	pntr
	mvi	h,80h	;beam to screen center
	mvi	l,80h
	shld	xyout
	lxi	h,tick
	mov	a,m	;old time in a
sloop:	cmp	m	;old = new?
	jz	sloop	;yes - keep trying
	jmp	mloop	;no - next instr
; table for vector orientation and scaling
table:	db	0
	db	2
	db	2
	db	2
	db	0
	db	-2
	db	-2
	db	-2
	db	0
	db	2
	db	2
	db	2
	db	0
	db	-2
	db	-2
	db	-2
	db	0
	db	3
	db	3
	db	3
	db	0
	db	-3
	db	-3
	db	-3
	db	0
	db	3
	db	3
	db	3
	db	0
	db	-3
	db	-3
	db	-3
	db	0
	db	4
	db	4
	db	4
	db	0
	db	-4
	db	-4
	db	-4
	db	0
	db	4
	db	4
	db	4
	db	0
	db	-4
	db	-4
	db	-4
	db	0
; the following are storage cells not to be in prom
; working storage
pntr:	dw	0	;pointer to next instr
xinc:	dw	0	;lvec only
yinc:	dw	0	;lvec only
incpt:	dw	0	;pointer to increment in table
	end
