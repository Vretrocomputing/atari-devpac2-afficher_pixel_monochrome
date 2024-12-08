; Afficher des pixels en assembleur sur Atari ST
; Par Vretrocomputing, 2024.

	move.w	#4,-(sp)	;Getrez
	trap	#14		;XBIOS
	addq.l	#2,sp

	cmp.w	#2,d0		;Haute résolution ?
	beq	rezok		;Oui

; La résolution est incorrecte
	move.l	#message,-(sp)	;Message d'erreur
	move.w	#9,-(sp)	;Cconws
	trap	#1		;GEMDOS
	addq.l	#6,sp

	bra	pausexit	;Attendre une touche et quitter

rezok:
	DC.W	$a00a		;Line A 10 : Cacher la souris

	move.w	#3,-(sp)	;Logbase
	trap	#14		;XBIOS
	addq.l	#2,sp

	move.l	d0,a3		;Adresse du framebuffer

; Effacer tout l'écran

	move.l	a3,a1		;Destination
	moveq	#0,d1		;Données vides
	move.w	#32000/4-1,d0
copie:
	move.l	d1,(a1)+
	dbra	d0,copie

; Afficher des pixels

	move.w	#%1010101010101010,(a3)
	move.w	#%1110101010101010,2(a3)
	move.w	#%0101010101010101,80(a3)
	move.w	#%1010101010101010,80*2(a3)

	move.w	#%1111111111111111,80*4(a3)
	move.w	#%1000000000000001,80*5(a3)
	move.w	#%1111111111111111,80*6(a3)

	bsr	pause

	;move.w	#%0010000000000000,80*5(a3)
	or.w	#%0010000000000000,80*5(a3)

	bsr	pause

	and.w	#~%0010000000000000,80*6(a3)

	bsr	pause

	eor.w	#%0111000000000000,80*6(a3)
	bsr	pause
	eor.w	#%0111000000000000,80*6(a3)

	bsr	pause

; Afficher un pixel selon ses coordonnées (x,y).
; On peut le déplacer avec les flèches du clavier.

; Coordonnées initiales
	move.w	#17,d3		;x
	move.w	#8,d4		;y

	bsr	setpixel

; Attendre l'appui sur une touche

wait:
	move.w	#8,-(sp)	;Cnecin
	trap	#1		;GEMDOS
	addq.l	#2,sp

	;Ici : d0.b = code ASCII

	cmp.b	#$1b,d0		;Escape ?
	beq	exit

	swap	d0		;Inverser scancode et code ASCII

	cmp.b	#$4d,d0		;Flèche Droite ?
	beq	right

	cmp.b	#$4b,d0		;Flèche Gauche ?
	beq	left

	cmp.b	#$50,d0		;Flèche Bas ?
	beq	down

	cmp.b	#$48,d0		;Flèche Haut ?
	beq	up

	bra	wait		;Touche inconnue

right:
	addq.w	#1,d3		;x = x + 1
	bsr	setpixel
	bra	wait

left:
	subq.w	#1,d3		;x = x - 1
	bsr	setpixel
	bra	wait

down:
	addq.w	#1,d4		;y = y + 1
	bsr	setpixel
	bra	wait

up:
	subq.w	#1,d4		;y = y - 1
	bsr	setpixel
	bra	wait

; Attendre l'appui sur une touche
pause:
	move.w	#8,-(sp)	;Cnecin
	trap	#1		;GEMDOS
	addq.l	#2,sp

	rts

; Attendre l'appui sur une touche et quitter
pausexit:
	bsr	pause
exit:
	clr.w	-(sp)		;Pterm0
	trap	#1		;GEMDOS

; Afficher un pixel
; a3 = framebuffer
; d3.w = x
; d4.w = y
; Modifie : d0/d1/a0
setpixel:
	move.l	a3,a0		;Adresse du framebuffer

	move.w	d4,d0		;y
	mulu	#80,d0		;Offset de la ligne
	add.l	d0,a0		;Ajouter à l'adresse

	move.w	d3,d0		;x
	lsr.w	#4,d0		;x/16 = numéro du groupe de 16 pixels
	lsl.w	#1,d0		;x/16*2 = offset du groupe de 16 pixels
	add.w	d0,a0		;Ajouter à l'adresse

	move.w	d3,d1		;x
	and.w	#%1111,d1	;x MOD 16 = numéro de pixel depuis la gauche

	move.w	#%1000000000000000,d0	;Pixel de gauche
	lsr.w	d1,d0			;Décaler vers la droite

	or.w	d0,(a0)		;Afficher le pixel

	rts

message:
	DC.B	"Ce programme ne fonctionne",13,10
	DC.B	"qu'en haute résolution.",13,10,0
