; space war gravity table

	org	00e00h

c	equ	258000.0    ; empirically determined to match table 4 in BYTE

y	set	1
	rept	32
x	set	1
	rept	32
r	set	sqrt(x^2+y^2)
yaccf	set	c*y/r^3
yacci	set	int(yaccf+0.5)	
	if	yacci>999
	dw	999
	else
	dw	yacci
	endif
x	set	x+1
	endm
y	set	y+1
	endm
