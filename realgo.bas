/' endlich ein gescheites go


	gemacht
		freiheiten eines steins berechnen und bei anzeige dadurch teilen*4
		starke verbindung anzeigen durch doppellinie
		anzahl freiheiten auf die steine drucken
		anzahl freiheiten von gruppen berechnen und auf die steine drucken
		nur andersfarbige steine fangen, gleichfarbige nicht
		stein nur setzen wenns geht
		näheste freiheit zum mauszeiger suchen
		save/load zum testen
		verbindungen zum rand
		bei killstones auch con killen
		territorium berechnen
		einflussbereich, freiheiten, verbindungen, etc alles ein/ausblendbar
		calcarea direkt auf brett zeichnen
		schwache verbindungen kappen durch kürzere
		schwache verbindungen zählen für gruppierung ja/nein
		schwache verbindungen zählen für gebiet ja/nein
		auswahlmenü für alle schalter
		schwache verbindung kappen: dritte möglichkeit: beide
		input/print von koordinaten, sodass man über telefon/mail spielen kann

	evtl
		freiheiten als schwarze und weiße freiheiten anzeigen
		stein der beim schlagen selber 0 freiheiten hat, überlebt
			dazu einfach zuerst nur freiheiten vom gegner checken und evtl killen, dann erst eigene
		ko regel: wenn vorher ein einzelner stein geschlagen wurde,
			kann der nicht sofort im nächsten zug ersetzt werden,
			d.h. setzen in den kreis ist nicht möglich
		opengl als anzeige
			multisample
			linien von verbindungen dick
			zoom/pan möglich
			freiheiten als gaussbuckel darstellen, evtl mit variabler breite
		steine ausblenden (für area besser sichtbar)

	todo
		spielen per email
		beispielbrett wo man auswirkugen aller schalter sieht
		starke randverbindungen
		cut für randverbindungen
		fullscreen/fenster auswahl

'/

Const BS = 13			' board size

Const BX = 400			' board offset on screen
Const BY = 20

Const MAXSTONES = BS^2		' maxiumum number of stones

Const RR = 23			' radius stone
Const DD = 2*RR+1		' diameter stone

Const BAS = BS*DD		' board array size
Const SAS = 1+RR+RR+1+RR+RR+1		' stone array size

'color numbers
Enum colors
CBOARD		' board beige
CBLACK		' black stone
CWHITE		' white stone
CINF			' influence area (grey)
CLIB			' liberties circle (red)
CBOARDLINES		' darker beige for grid lines on board
CBACKGROUND		' the background
NCOLORS
End Enum

Dim Shared As Integer col(NCOLORS) = { _
RGB(230,188,104), _
RGB(0,0,0), _
RGB(255,255,255), _
RGB(128,128,128), _
RGB(200,0,0), _
RGB(210,168,84), _
RGB(128,0,0) _
}

Type stone
	As Integer x, y		' 0=not there, positions start at 1*RR
	As Integer f			' liberties
End Type

Dim Shared As stone stones(MAXSTONES)		' stone positions

Dim Shared As Integer maxlib		' number of liberties of a stone

Dim Shared As UByte ba(BAS,BAS)		' board array
Dim Shared As UByte bb(BAS,BAS)		' board array for area calc
Dim Shared As UByte sa(SAS,SAS)		' stone array

Dim Shared As UByte con(MAXSTONES,MAXSTONES)		' connection matrix, 0=no connection 1=weak 2=strong

Dim Shared As Integer stonenr		' move number, starts with 1=black


Const QUSIZE = 10000		' queue for flood fill

Type queue
	As Integer fp, bp
	As Integer x(QUSIZE), y(QUSIZE)
End Type

Dim Shared As queue qu


Dim Shared As Integer showinf, showlib, showweak, showstrong, shownum		' toggle switches for display
Dim Shared As Integer showarea

Dim Shared As Integer togglecut, togglegrp, togglearea		' toggle switches for variations

Dim Shared As Integer lastmovex, lastmovey


Declare Sub main
main
End


' draw a line from stone position to stone position for area calculation
'
Sub linedda (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, c As Integer)
	Dim As Integer dx, dy, sx, sy, er, e2

	DX = Abs(X2 - X1):SX = -1:If X1 < X2 Then SX = 1
	DY = Abs(Y2 - Y1):SY = -1:If Y1 < Y2 Then SY = 1
	ER = -DY:If DX > DY Then ER = DX
	ER = Int(ER / 2)
	Do
		bb(X1,Y1) = c
		If X1 = X2 And Y1 = Y2 Then Exit Do
		E2 = ER
		If E2 > -DX Then ER = ER - DY:X1 = X1 + SX
		If E2 < DY Then ER = ER + DX:Y1 = Y1 + SY
	Loop
End Sub


' queue out front. return 0 when empty
'
Function queueout (ByRef x As Integer, ByRef y As Integer) As Integer
	If qu.fp=qu.bp Then Return 0
	qu.fp -= 1
	If qu.fp<0 Then qu.fp+=QUSIZE
	x = qu.x(qu.fp)
	y = qu.y(qu.fp)
	Return 1
End Function


' put sth in back of queue
'
Sub queuein (x As Integer, y As Integer)
	qu.bp -= 1
	If qu.bp<0 Then qu.bp+=QUSIZE
	qu.x(qu.bp) = x
	qu.y(qu.bp) = y
End Sub


' flood fill with queue for area calculation. return colors encountered
'
Function ffr (x As Integer, y As Integer, c As Integer) As Integer
	Dim As Integer t

	queuein (x, y)
	t = 0
	Do
		If queueout (x, y)=0 Then Exit Do			 ' byref! exit when empty queue
		If x>=0 And x<BAS And y>=0 And y<BAS And bb(x,y)<>c Then
			If bb(x,y)=CBLACK Then t Or= 1 : Continue Do
			If bb(x,y)=CWHITE Then t Or= 2 : Continue Do
			bb(x,y) = c
			queuein (x+1, y)
			queuein (x, y+1)
			queuein (x-1, y)
			queuein (x, y-1)
		EndIf
	Loop
	Return t
End Function


' return stone color from stone number
'
Function stonecolor (s As Integer) As Integer
	If s Mod 2=0 Then Return CWHITE Else Return CBLACK
End Function


' return empty board color at position
'
Function boardcolor (x As Integer, y As Integer) As Integer
	If x<RR Or x>BAS-RR-1 Or y<RR Or y>BAS-RR-1 Then Return CBOARD
	If (x+RR+1) Mod DD=0 Or (y+RR+1) Mod DD=0 Then Return CBOARDLINES
	Return CBOARD
End Function


' make empty board
'
Sub initboard ()
	Dim As Integer x, y, c

	For y = 0 To BAS-1
		For x = 0 To BAS-1
			c = boardcolor (x,y)
			If x<RR Or y<RR Then c = CINF
			If x>BAS-RR-1 Or y>BAS-RR-1 Then c = CINF
			ba(x,y) = c
		Next
	Next
End Sub


' draw the board with contents
'
Sub drawboard ()
	Dim As Integer x, y, c

	For y = 0 To BAS-1
		For x = 0 To BAS-1
			c = ba(x,y)
			If c=CINF And showinf=0 Or c=CLIB And showlib=0 Then
				PSet(BX+x,BY+y),col(boardcolor(x,y))
			Else
				PSet(BX+x,BY+y),col(c)
			EndIf
		Next
	Next
End Sub


' set pixel in stone array
'
Function drawpixel (x As Integer, y As Integer, c As Integer) As Integer
	Dim As Integer t

	t = 0
	If x>=0 And x<SAS And y>=0 And y<SAS Then
		If c=CWHITE Then
			If sa(x,y)=CBLACK Then t = 1
		ElseIf sa(x,y)=0 Then
			sa(x,y) = c
		EndIf
	EndIf
	Return t
End Function


' unfilled circle
'
Function drawcircle (mx As Integer, my As Integer, r As Integer, c As Integer) As Integer
	Dim As Integer x, y, t

	t = 0
	For x = -r To r
		y = Int(Sqr(r^2-x^2)+.5)
		t += drawpixel (mx+x, my+y, c)
		t += drawpixel (mx+x, my-y, c)
	Next
	For y = -r To r
		x = Int(Sqr(r^2-y^2)+.5)
		t += drawpixel (mx+x, my+y, c)
		t += drawpixel (mx-x, my+y, c)
	Next
	Return t
End Function


' filled circle
'
Function fillcircle (mx As Integer, my As Integer, r As Integer, c As Integer) As Integer
	Dim As Integer x, y, t, nx, ny

	t = 0
	For x = -r To r
		ny = Int(Sqr(r^2-x^2)+.5)
		For y = 0 To ny
			drawpixel (mx+x, my+y, c)
			drawpixel (mx+x, my-y, c)
		Next
	Next
	For y = -r To r
		nx = Int(Sqr(r^2-y^2)+.5)
		For x = 0 To nx
			drawpixel (mx+x, my+y, c)
			drawpixel (mx-x, my+y, c)
		Next
	Next
	Return t
End Function


' calc the stone array with stone, influence and libs
'
Sub makestone ()
	Dim As Integer x, y, r, mx, my, nr, nx, ny, t
	Dim As Integer col, c

	mx = DD
	my = DD
	r = RR

	fillcircle (mx, my, r, CBLACK)		' the stone (later black or white)

	For ny = 0 To 2*r-1
		nx = Int(Sqr((2*r+1)^2-ny^2)+0.5)
		For x = nx-1 To nx+1
			t = drawcircle (mx+x, my+ny, r, CWHITE)		' place stone as close as possible without collision...
			If t=0 Then nx = x : Exit For
		Next
		For x = 0 To nx
			If x=nx Then c = CLIB Else c = CINF		' ...gives position of liberty, rest is influence
			drawpixel (mx+x, my+ny, c)
			drawpixel (mx+x, my+ny, c)
			drawpixel (mx-x, my+ny, c)
			drawpixel (mx+x, my-ny, c)
			drawpixel (mx-x, my-ny, c)
			drawpixel (mx+ny, my+x, c)
			drawpixel (mx-ny, my+x, c)
			drawpixel (mx+ny, my-x, c)
			drawpixel (mx-ny, my-x, c)
		Next
	Next

	maxlib = 0				' count liberties
	For y = 0 To SAS-1
		For x = 0 To SAS-1
			If sa(x,y)=CLIB Then maxlib += 1
		Next
	Next
End Sub


' determine if stone placement is possible at a position
'
Function setpossible (mx As Integer, my As Integer) As Integer
	Dim As Integer c
	If mx>=0 And mx<BAS And my>=0 And my<BAS Then
		c = ba(mx,my)
		If c=CBOARD Or c=CBOARDLINES Or c=CLIB Then Return 1
	EndIf
	Return 0
End Function


' draws a stone on screen or copies it into board array
'
Sub drawstone (mx As Integer, my As Integer, cp As Integer, sn As Integer)
	Dim As Integer x, y, c
	Dim As Integer px, py, d

	For y = 0 To SAS-1
		py = my+y-DD
		If py>=0 And py<BAS Then
			For x = 0 To SAS-1
				px = mx+x-DD
				If px>=0 And px<BAS Then
					c = sa(x,y)
					If c>0 Then
						d = ba(px,py)
						If Not ((c=CLIB Or c=CINF) And Not (d=CBOARD Or d=CBOARDLINES Or d=CLIB)) Then
							If c=CBLACK Then c = stonecolor (sn)
							If cp=0 Then
								If c=CINF And showinf=0 Or c=CLIB And showlib=0 Then
									PSet(BX+px,BY+py),col(boardcolor(px,py))
								Else
									PSet(BX+px,BY+py),col(c)
								EndIf
							Else
								ba(px,py) = c
							EndIf
						EndIf
					EndIf
				EndIf
			Next
		EndIf
	Next
End Sub


' init board and draw all stones anew from positions in stones array
'
Sub redrawboard ()
	Dim As Integer x, y, t

	initboard ()
	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then drawstone (x, y, 1, t)
	Next
End Sub


' calc individual lib for a stone
'
Function checklib (s As Integer) As Integer
	Dim As Integer x, y, mx, my, r, px, py

	mx = stones(s).x
	my = stones(s).y

	r = 0
	For y = 0 To SAS-1
		py = my-DD+y
		If py>=0 And py<BAS Then
			For x = 0 To SAS-1
				px = mx-DD+x
				If px>=0 And px<BAS Then
					If sa(x,y)=CLIB And ba(px,py)=CLIB Then r += 1
				EndIf
			Next
		EndIf
	Next
	Return r
End Function


' calc individual libs for all stones
'
Sub checklibs ()
	Dim As Integer t, x, y, r

	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			r = checklib (t)
			stones(t).f = r
		EndIf
	Next
End Sub


' put values in con depending on stone distances
'
Sub makeconnections ()
	Dim As Integer t, d, x, y, x2, y2
	Dim As Double dx, dy, w

	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			For d = 0 To MAXSTONES-1
				If (t Mod 2=d Mod 2) And t<>d Then
					x2 = stones(d).x
					y2 = stones(d).y
					If x2>0 Then
						dx = x2-x
						dy = y2-y
						w = Sqr(dx^2+dy^2)
						dx /= w
						dy /= w
						If w<Sqr(2)*DD Then
							con(t,d) = 2
						ElseIf w<2*DD Then
							con(t,d) = 1
						EndIf
					EndIf
				EndIf
			Next
		EndIf
	Next
End Sub


' draw connection lines according to con
'
Sub drawconnections ()
	Dim As Integer t, d, x, y, x2, y2
	Dim As Double dx, dy
	Dim As Double w

	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			For d = 0 To MAXSTONES-1
				x2 = stones(d).x
				y2 = stones(d).y
				If x2>0 Then
					If con(t,d)=2 Then
						If showstrong Then
							dx = x2-x
							dy = y2-y
							w = Sqr(dx^2+dy^2)
							dx /= w
							dy /= w
							Line(BX+x+dy*5,BY+y-dx*5)-(BX+x2+dy*5,BY+y2-dx*5),col(stonecolor(d))
						Else
							If showweak Then Line(BX+x,BY+y)-(BX+x2,BY+y2),col(stonecolor(d))
						EndIf
					ElseIf con(t,d)=1 Then
						If showweak Then Line(BX+x,BY+y)-(BX+x2,BY+y2),col(stonecolor(d))
					EndIf
				EndIf
			Next
			If showweak Then
				If x<RR+DD Then
					Line(BX+x,BY+y)-(BX,BY+y),col(stonecolor(t))
				EndIf
				If x>=BAS-RR-DD Then
					Line(BX+x,BY+y)-(BX+BAS-1,BY+y),col(stonecolor(t))
				EndIf
				If y<RR+DD Then
					Line(BX+x,BY+y)-(BX+x,BY),col(stonecolor(t))
				EndIf
				If y>=BAS-RR-DD Then
					Line(BX+x,BY+y)-(BX+x,BY+BAS-1),col(stonecolor(t))
				EndIf
			EndIf
		EndIf
	Next
End Sub


' are the two lines with these endpoints intersecting
'
Function cutting (x0 As Integer, y0 As Integer, x1 As Integer, y1 As Integer, a0 As Integer, b0 As Integer, a1 As Integer, b1 As Integer) As Integer
	Dim As Integer partial
	Dim As Double denom, xy, ab

	partial = 0
	denom = (b0 - b1) * (x0 - x1) - (y0 - y1) * (a0 - a1)
	If denom=0 Then
		xy = -1
		ab = -1
	Else
		xy = (a0 * (y1 - b1) + a1 * (b0 - y1) + x1 * (b1 - b0)) / denom
		If xy>0 And xy<1 Then partial = 1
		If partial Then
			ab = (y1 * (x0 - a1) + b1 * (x1 - x0) + y0 * (a1 - x1)) / denom
		EndIf
	EndIf
	If partial And ab>0 And ab<1 Then
		ab = 1-ab
		xy = 1-xy
		Return 1
	Else
		Return 0
	EndIf
End Function


' removes weak connections from con matrix when they are cut by shorter ones
'
Sub cutconnections ()
	Dim As Integer t1, t2, d1, d2
	Dim As Integer x1, y1, x2, y2, dx, dy, dd1, dd2
	Dim As Integer x3, y3, x4, y4

	For t1 = 0 To MAXSTONES-1
		x1 = stones(t1).x
		y1 = stones(t1).y
		If x1>0 Then
			For d1 = 0 To MAXSTONES-1
				x2 = stones(d1).x
				y2 = stones(d1).y
				If x2>0 And con(t1,d1)>0 Then
					dx = x2-x1
					dy = y2-y1
					dd1 = dx^2+dy^2
					For t2 = 0 To MAXSTONES-1
						x3 = stones(t2).x
						y3 = stones(t2).y
						If x3>0 Then
							For d2 = 0 To MAXSTONES-1
								x4 = stones(d2).x
								y4 = stones(d2).y
								If x4>0 And con(t2,d2)>0 Then
									dx = x4-x3
									dy = y4-y3
									dd2 = dx^2+dy^2
									If cutting (x1,y1,x2,y2,x3,y3,x4,y4) Then
										If togglecut=1 Then
											If dd2<dd1 Then con(t1,d1) = 0 : con(d1,t1) = 0
										ElseIf togglecut=2 Then
											con(t1,d1) = 0 : con(d1,t1) = 0
											con(t2,d2) = 0 : con(d2,t2) = 0
										EndIf
									EndIf
								EndIf
							Next
						EndIf
					Next
				EndIf
			Next
		EndIf
	Next
End Sub


' find groups through con matrix and sum up their individual libs
'
Sub grouplibs ()
	Dim As Integer t, d, x, y, s, gnr, gef
	Dim As Integer grp(MAXSTONES)

	'Clear grp(0),,MAXSTONES*SizeOf(grp)

	gnr = 1
	For t = 0 To MAXSTONES-1
		If stones(t).x>0 And grp(t)=0 Then		' stone gets a new grp number
			grp(t) = gnr
			Do
				gef = 0
				For y = 0 To MAXSTONES-1		' copy grp number to connected stones
					For x = 0 To MAXSTONES-1
						If grp(x)=gnr And con(x,y)>1-togglegrp And grp(y)=0 Then
							grp(y) = gnr
							gef = 1
						EndIf
					Next
				Next
			Loop While gef>0		' until no more found
			gnr += 1
		EndIf
	Next

	For t = 1 To gnr-1
		s = 0
		For d = 0 To MAXSTONES-1		' sum all with same grp number
			If grp(d)=t Then
				s += stones(d).f
			EndIf
		Next
		For d = 0 To MAXSTONES-1		' set liberties to sum
			If grp(d)=t Then
				stones(d).f = s
			EndIf
		Next
	Next
End Sub


' print libs number on stones
'
Sub drawlibs ()
	Dim As Integer t, x, y, r
	Dim As String s
	Dim As Double f

	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			r = stones(t).f
			f = r/maxlib*4
			If f<1 Then
				s = "."+Str(r)
			Else
				s = Str(Int(f))
			EndIf
			Color col(stonecolor(t+1))		' the other color
			Draw String (BX+x-3,BY+y-3),s
		EndIf
	Next
End Sub


' kills a stone and its connections
'
Sub killstone (t As Integer)
	Dim As Integer d
	stones(t).x = 0
	stones(t).y = 0
	For d = 0 To MAXSTONES-1
		con(d,t) = 0
		con(t,d) = 0
	Next
End Sub


' remove stones with 0 group libs, redraw board if necessary
'
Sub killstones ()
	Dim As Integer t, gef

	gef = 0
	For t = 0 To MAXSTONES-1
		If stones(t).x>0 And stones(t).f=0 Then killstone (t) : gef = 1
	Next
	If gef Then redrawboard ()
End Sub


' search nearest position to set a stone
'
Sub searchnearest (ByRef mx As Integer, ByRef my As Integer)
	Dim As Integer x, y, vx, vy
	Dim As Double d, m

	m = RR+1
	For y = -RR To RR
		For x = -RR To RR
			d = Sqr(x^2+y^2)
			If d<RR And d<m And setpossible (mx+x, my+y) Then vx = x : vy = y : m = d
		Next
	Next
	If m<RR+1 Then
		mx += vx
		my += vy
	EndIf
End Sub


' calc players territorium
'
Sub calcarea ()
	Dim As Integer x, y, t, d, x2, y2, gef, mx, my, sb, sw

	For y = 0 To BAS-1			' empty board
		For x = 0 To BAS-1
			bb(x,y) = CBOARD
		Next
	Next

	For t = 0 To MAXSTONES-1		' draw connection lines
		For d = 0 To MAXSTONES-1
			If con(t,d)>1-togglearea Then
				x = stones(t).x
				y = stones(t).y
				x2 = stones(d).x
				y2 = stones(d).y
				linedda (x, y, x2, y2, stonecolor (t))
			EndIf
		Next
	Next

	For t = 0 To MAXSTONES-1		' draw stones (one pixel at position) and lines to edges of board
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			bb(x,y) = stonecolor (t)
			If x<RR+DD Then
				linedda (x, y, 0, y, stonecolor (t))
			EndIf
			If y<RR+DD Then
				linedda (x, y, x, 0, stonecolor (t))
			EndIf
			If x>=BAS-RR-DD Then
				linedda (x, y, BAS-1, y, stonecolor (t))
			EndIf
			If y>=BAS-RR-DD Then
				linedda (x, y, x, BAS-1, stonecolor (t))
			EndIf
		EndIf
	Next

	Do
		gef = 0					' find empty pixel
		For y = 0 To BAS-1
			For x = 0 To BAS-1
				If bb(x,y)=CBOARD Then mx = x : my = y : gef = 1 : Exit For
			Next
			If gef Then Exit For
		Next
		If gef=0 Then Exit Do	' exit if whole board is colored

		t = ffr (mx, my, NCOLORS)		' fill that pixel and connected area with neutral color

		For y = 0 To BAS-1			' depending on encountered colors replace neutral with actual color
			For x = 0 To BAS-1
				If bb(x,y)=NCOLORS Then
					If t=1 Then
						bb(x,y) = CBLACK
					ElseIf t=2 Then
						bb(x,y) = CWHITE
					Else
						bb(x,y) = CINF
					EndIf
				EndIf
			Next
		Next
	Loop

	For y = 0 To BAS-1		' count pixels
		For x = 0 To BAS-1
			If bb(x,y)=CBLACK Then sb += 1
			If bb(x,y)=CWHITE Then sw += 1
		Next
	Next

	Line (2*8,2*8)-(20*8,7*8),col(CBOARD),bf
	Locate 4,4 : Color col(CBLACK),col(CBOARD) : Print Using "b ###.###";sb/(DD^2)
	Locate 6,4 : Color col(CWHITE),col(CBOARD) : Print Using "w ###.###";sw/(DD^2)

	For y = 0 To BAS-1			' draw area colors on board
		For x = 0 To BAS-1
			If (x+y) Mod 2=0 Then
				t = bb(x,y)
				If t<>CINF Then PSet(BX+x,BY+y),col(t)
			EndIf
		Next
	Next
End Sub


' load stones
'
Sub loadstones ()
	Dim As Integer t
	Open "stones.txt" For Input As #1
	Input #1,stonenr
	For t = 0 To MAXSTONES-1
		Input #1,stones(t).x,stones(t).y
	Next
	Close #1
End Sub


' save stones
'
Sub savestones ()
	Dim As Integer t
	Open "stones.txt" For Output As #1
	Print #1,stonenr
	For t = 0 To MAXSTONES-1
		Print #1,stones(t).x,stones(t).y
	Next
	Close #1
End Sub


' return nearest stone
'
Function findneareststone (mx As Integer, my As Integer) As Integer
	Dim As Integer t, dx, dy, m, x, y
	Dim As Double d, dm

	m = 0
	dm = 2*DD
	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			dx = mx-x
			dy = my-y
			d = Sqr(dx^2+dy^2)
			If d<2*DD And d<dm Then dm = d : m = t
		EndIf
	Next
	Return m
End Function


' draw the menu for the switches
'
Sub drawmenu ()
	Dim As String ts(2), tc(3)

	ts(0) = "off" : ts(1) = "on"
	tc(0) = "none" : tc(1) = "longer" : tc(2) = "both"

	Color col(CBOARD),col(CBACKGROUND)

	Locate 16,3 : Print "f) show territory: ";ts(showarea)

	Locate 20,3 : Print "1) show influence: ";ts(showinf)
	Locate 22,3 : Print "2) show liberties: ";ts(showlib)
	Locate 24,3 : Print "3) show numbers: ";ts(shownum)
	Locate 26,3 : Print "4) show weak connections: ";ts(showweak)
	Locate 28,3 : Print "5) show strong connections: ";ts(showstrong)

	Locate 32,3 : Print "8) connection cutting: ";tc(togglecut)
	Locate 34,3 : Print "9) weak connection groups: ";ts(togglegrp)
	Locate 36,3 : Print "0) weak connection area: ";ts(togglearea)
	
	Locate 40,3 : Print Using "last move: #### ####";lastmovex;lastmovey
End Sub


' adds a stone to the board
'
Sub setstone (x As Integer, y As Integer)
	drawstone (x, y, 1, stonenr)
	stones(stonenr).x = x
	stones(stonenr).y = y
	stonenr += 1
	lastmovex = x
	lastmovey = y
End Sub


' main
'
Sub main ()
	Dim As Integer x, y, wheel, button, lbuttoncnt, t, wantinput
	Dim As String i

	ScreenRes 1100,650,32,2
	ScreenSet 1,0

	showinf = 1
	showlib = 1
	showweak = 1
	showstrong = 1
	shownum = 1
	showarea = 0
	togglecut = 1
	togglegrp = 1
	togglearea = 1

	initboard ()
	makestone ()

	stonenr = 1
	Do
		Color col(CWHITE),col(CBACKGROUND)
		Cls
		drawmenu ()
		drawboard ()

		GetMouse x,y,wheel,button
		x -= BX
		y -= BY
		If button=0 Then lbuttoncnt = 0
		If button=1 Then lbuttoncnt += 1

		searchnearest (x, y)		' byref!

		If setpossible (x, y)=1 Then
			If lbuttoncnt=0 Then
				If wantinput=0 Then drawstone (x, y, 0, stonenr)		' draw hovering stone
			Else
				setstone (x, y)		' add stone
			EndIf
		EndIf

		makeconnections ()
		If togglecut>0 Then cutconnections ()
		drawconnections ()

		checklibs ()
		grouplibs ()

		killstones ()

		If shownum Then drawlibs ()

		If showarea Then calcarea ()


		If wantinput Then		' manual input of coordinates of stone to set
			Flip
			ScreenSet
			Color col(stonecolor(stonenr)),col(CBOARD)
			Line(2*8,42*8)-(30*8,46*8),col(CBOARD),bf
			Locate 44,4 : Input "input x,y: ",x,y
			setstone (x, y)
			wantinput = 0
			ScreenSet 1,0
		EndIf


		i = Inkey
		If i=Chr(27) Then Exit Do

		If i="s" Then savestones ()
		If i="l" Then loadstones () : redrawboard ()
		If i="m" Then stonenr += 1
		If i="k" Then
			t = findneareststone (x, y)
			If t>0 Then killstone (t) : redrawboard ()
		EndIf
		If i="i" Then wantinput = 1

		If i="f" Then showarea Xor=1

		If i="1" Then showinf Xor= 1
		If i="2" Then showlib Xor= 1
		If i="3" Then shownum Xor= 1
		If i="4" Then showweak Xor= 1
		If i="5" Then showstrong Xor= 1

		If i="8" Then togglecut += 1 : togglecut Mod= 3
		If i="9" Then togglegrp Xor= 1
		If i="0" Then togglearea Xor= 1

		Flip
	Loop
End Sub
