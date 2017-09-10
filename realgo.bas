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
		beispielbrett wo man auswirkugen aller schalter sieht
		starke randverbindungen
		cut für randverbindungen
		con komplett durch conl ersetzen
		spielen per email (nur linux)
		spielen per shared file folder (auch windows)
		opengl als anzeige
		opengl: rand von board mit z=1 background color quads abschneiden

	evtl
		freiheiten als schwarze und weiße freiheiten anzeigen
		stein der beim schlagen selber 0 freiheiten hat, überlebt
			dazu einfach zuerst nur freiheiten vom gegner checken und evtl killen, dann erst eigene
		ko regel: wenn vorher ein einzelner stein geschlagen wurde,
			kann der nicht sofort im nächsten zug ersetzt werden,
			d.h. setzen in den kreis ist nicht möglich
			dazu muss im savefile gespeichert werden wo das war
		steine ausblenden (für area besser sichtbar)
		cut mit d1=d2 könnte auch bleiben. evtl schalter dafür
		fullscreen/fenster auswahl
		config file mit schaltern, email namen, save file name, fullscreen/window, etc.

	todo
		brettgröße auswahl
		opengl: zoom/pan möglich
		opengl: freiheiten als gaussbuckel darstellen, evtl mit variabler breite
			das wäre auch die lösung für transparentes inf

'/

#Include "windows.bi"
#Include "win/mmsystem.bi"
#Include "gl/gl.bi"
#Include "gl/glu.bi"
#Include "fbgfx.bi"
#Include "string.bi"
#Include "dir.bi"


Const PI = 6.283185307

Const SCRX = 1100		' screen size
Const SCRY = 650

Const BS = 13			' board size

Const BX = 400			' board offset on screen
Const BY = 20

Const MAXSTONES = BS^2		' maxiumum number of stones

Const MAXCONS = MAXSTONES*3		' maximum number of connections

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

Dim Shared As Integer stonenr		' move number, starts with 1=black

Dim Shared As Integer maxlib		' number of liberties of a stone

Dim Shared As UByte ba(BAS,BAS)		' board array
Dim Shared As UByte bb(BAS,BAS)		' board array for area calc
Dim Shared As UByte sa(SAS,SAS)		' stone array

Type connection
	As Integer c		' color 1=black 2=white
	As Integer s		' 0=not there, strength 1=weak 2=strong
	As Integer t, d	' stone numbers, 0=edge
	As Integer x1, y1, x2, y2
End Type
Dim Shared As connection conl(MAXCONS)		' connection lines
Dim Shared As Integer nconl		' counter

Const QUSIZE = 10000		' queue for flood fill

Type queue
	As Integer fp, bp		' front back pointers
	As Integer x(QUSIZE), y(QUSIZE)		' pixel to fill
End Type
Dim Shared As queue qu

Dim Shared As Integer showinf, showlib, showweak, showstrong, shownum		' toggle switches for display
Dim Shared As Integer showarea

Dim Shared As Integer togglecut, togglegrp, togglearea		' toggle switches for variations

Dim Shared As Integer lastmovex, lastmovey	' coos of last stone set

Dim Shared As Integer spieler, gametype

Const SENDSERVER1 = "smtp.web.de"
Const SENDUSER1 = "realgoplayer@web.de"
Const SENDPASS1 = "realgoplayer1234"
Const SENDSERVER2 = "smtp.gmx.de"
Const SENDUSER2 = "realgoplayer@gmx.de"
Const SENDPASS2 = "realgoplayer1234"
Const GETMAILRC1 = "getmailrcweb"
Const GETMAILDIR1 = "/home/yourname/Maildirweb/new"
Const GETMAILRC2 = "getmailrcgmx"
Const GETMAILDIR2 = "/home/yourname/Maildirgmx/new"

Const SHAREDFILE1 = "sharedfile1.txt"
Const SHAREDFILE2 = "sharedfile2.txt"

Const SAVEFILE = "stones.txt"

Const LBOARD = 0				' opengl depth layers
Const LBOARDLINES = 0.1
Const LLIB = 0.2
Const LINF = 0.3
Const LSTONE = 0.4
Const LAREA = 0.5
Const LNUM = 0.6


Declare Sub main
main
End


' print a text at a screen position using opengl calllists
'
Sub mytextout (x As Double, y As Double, z As Double, s As String)
	glRasterPos3d (x, y, z)
	glListBase (1000)
	glCallLists (Len(s), GL_UNSIGNED_BYTE, StrPtr(s))
End Sub


' glcolor translation of rgb values
'
Sub mycolor (c As Integer)
	glColor3d ( ((CUInt(col(c)) Shr 16) And 255)/255, ((CUInt(col(c)) Shr 8) And 255)/255, ((CUInt(col(c)) Shr 0) And 255)/255 )
End Sub


' draw a circle with gl triangle
'
Sub mycircle (x As Double, y As Double, z As Double, r As Double)
	Dim As Integer n, t

	n = 32

	glBegin (GL_TRIANGLE_FAN)
	For t = 0 To n-1
		glVertex3d (x+r*Cos(t*PI/n)+0.5, y+r*Sin(t*PI/n)+0.5, z)
	Next
	glEnd ()
End Sub


' draw a thick line as quad
'
Sub myline (x1 As Double, y1 As Double, x2 As Double, y2 As Double, c As Integer)
	Dim As Double dx, dy, d, ex, ey, fx, fy

	mycolor (c)
	dx = x2-x1
	dy = y2-y1
	d = Sqr(dx^2+dy^2)
	If d=0 Then
		dx = 1 : dy = 1
	Else
		dx /= d
		dy /= d
	EndIf
	ex = dx : ey = dy
	fx = -dy : fy = dx
	Const LW = 1.2
	glBegin (GL_QUADS)
	glVertex3d (x1-LW*ex-LW*fx, y1-LW*ey-LW*fy, LSTONE)
	glVertex3d (x2+LW*ex-LW*fx, y2+LW*ey-LW*fy, LSTONE)
	glVertex3d (x2+LW*ex+LW*fx, y2+LW*ey+LW*fy, LSTONE)
	glVertex3d (x1-LW*ex+LW*fx, y1-LW*ey+LW*fy, LSTONE)
	glEnd ()
End Sub


' draw a box
'
Sub mybox (x1 As Double, y1 As Double, x2 As Double, y2 As Double, z As Double, c As Integer)
	mycolor (c)
	glBegin (GL_QUADS)
	glVertex3d (x1, y1, z)
	glVertex3d (x2, y1, z)
	glVertex3d (x2, y2, z)
	glVertex3d (x1, y2, z)
	glEnd ()
End Sub


' draw a line from stone position to stone position for area calculation
'
Sub linedd (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, c As Integer)
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


' draw the board
'
Sub drawboard ()
	Dim As Integer t, c

	mybox (BX, BY, BX+BS*DD, BY+BS*DD, LBOARD, CBOARD)

	mybox (BX-DD, BY-DD, BX, BY+BS*DD+DD, 1, CBACKGROUND)
	mybox (BX+BS*DD, BY-DD, BX+BS*DD+DD, BY+BS*DD+DD, 1, CBACKGROUND)
	mybox (BX, BY-DD, BX+BS*DD, BY, 1, CBACKGROUND)
	mybox (BX, BY+BS*DD, BX+BS*DD, BY+BS*DD+DD, 1, CBACKGROUND)

	For t = 1 To BS
		mybox (BX+t*DD-RR-1, BY+RR, BX+t*DD-RR, BY+RR+(BS-1)*DD+1, LBOARDLINES, CBOARDLINES)
		mybox (BX+RR, BY+t*DD-RR-1, BX+RR+(BS-1)*DD+1, BY+t*DD-RR, LBOARDLINES, CBOARDLINES)
	Next

	If showinf Then c = CINF Else c = CBOARD

	mybox (BX, BY, BX+RR, BY+BS*DD, LINF, c)
	mybox (BX+BS*DD-RR, BY, BX+BS*DD, BY+BS*DD, LINF, c)
	mybox (BX, BY, BX+BS*DD, BY+RR, LINF, c)
	mybox (BX, BY+BS*DD-RR, BX+BS*DD, BY+BS*DD, LINF, c)
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


' draws a stone on screen
'
Sub drawstone (mx As Integer, my As Integer, sn As Integer)
	If showlib And showinf Then
		mycolor (CLIB) : mycircle (BX+mx, BY+my, LLIB, 2*RR+1.5)
		mycolor (CINF) : mycircle (BX+mx, BY+my, LINF, 2*RR+0.5)
	ElseIf showlib Then
		mycolor (CLIB) : mycircle (BX+mx, BY+my, LLIB, 2*RR+1.5)
		mycolor (CBOARD) : mycircle (BX+mx, BY+my, LINF, 2*RR+0.5)
	ElseIf showinf Then
		mycolor (CINF) : mycircle (BX+mx, BY+my, LINF, 2*RR+0.5)
	EndIf
	mycolor (stonecolor(sn)) : mycircle (BX+mx, BY+my, LSTONE, RR)
End Sub


' draw all stones from the stone list
'
Sub drawstones ()
	Dim As Integer t, x, y
	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then drawstone (x, y, t)
	Next
End Sub


' copies a stone into board array
'
Sub copystone (mx As Integer, my As Integer, sn As Integer)
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
							ba(px,py) = c
						EndIf
					EndIf
				EndIf
			Next
		EndIf
	Next
End Sub


' init board and copy all stones anew from positions in stones array
'
Sub redrawboard ()
	Dim As Integer x, y, t

	initboard ()
	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then copystone (x, y, t)
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


' add a line to conl
'
Sub newconl (c As Integer, s As Integer, t As Integer, d As Integer, x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer)
	conl(nconl).c = c
	conl(nconl).s = s
	conl(nconl).t = t
	conl(nconl).d = d
	conl(nconl).x1 = x1
	conl(nconl).y1 = y1
	conl(nconl).x2 = x2
	conl(nconl).y2 = y2
	nconl += 1
End Sub


' put values in con depending on stone distances
'
Sub makeconnections ()
	Dim As Integer t, d, x, y, x2, y2
	Dim As Double dx, dy, w

	nconl = 0
	For t = 0 To MAXSTONES-1
		x = stones(t).x
		y = stones(t).y
		If x>0 Then
			For d = t+1 To MAXSTONES-1
				If t Mod 2=d Mod 2 Then
					x2 = stones(d).x
					y2 = stones(d).y
					If x2>0 Then
						dx = x2-x
						dy = y2-y
						w = Sqr(dx^2+dy^2)
						If w<Sqr(2)*DD Then
							newconl (stonecolor(t), 2, t, d, x, y, x2, y2)
						ElseIf w<2*DD Then
							newconl (stonecolor(t), 1, t, d, x, y, x2, y2)
						EndIf
					EndIf
				EndIf
			Next
			Const RA = (2+Sqr(19))/5	' solution of a quadratic eq. for the distance of the two cutting stones
			If x<RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, 0, y)
			ElseIf x<RR+DD Then
				newconl (stonecolor(t), 1, t, 0, x, y, 0, y)
			EndIf
			If x>=BAS-RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, BAS-1, y)
			ElseIf x>=BAS-RR-DD Then
				newconl (stonecolor(t), 1, t, 0, x, y, BAS-1, y)
			EndIf
			If y<RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, x, 0)
			ElseIf y<RR+DD Then
				newconl (stonecolor(t), 1, t, 0, x, y, x, 0)
			EndIf
			If y>=BAS-RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, x, BAS-1)
			ElseIf y>=BAS-RR-DD Then
				newconl (stonecolor(t), 1, t, 0, x, y, x, BAS-1)
			EndIf
		EndIf
	Next
End Sub


' draw connection lines according to con
'
Sub drawconnections ()
	Dim As Integer t, x, y, x2, y2
	Dim As Double dx, dy, w

	For t = 0 To nconl-1
		x = conl(t).x1
		y = conl(t).y1
		x2 = conl(t).x2
		y2 = conl(t).y2
		If conl(t).s=2 Then
			If showstrong Then
				dx = x2-x
				dy = y2-y
				w = Sqr(dx^2+dy^2)
				dx /= w
				dy /= w
				myline (BX+x+dy*5, BY+y-dx*5, BX+x2+dy*5, BY+y2-dx*5, conl(t).c)
				myline (BX+x-dy*5, BY+y+dx*5, BX+x2-dy*5, BY+y2+dx*5, conl(t).c)
			Else
				If showweak Then myline (BX+x, BY+y, BX+x2, BY+y2, conl(t).c)
			EndIf
		ElseIf conl(t).s=1 Then
			If showweak Then myline (BX+x, BY+y, BX+x2, BY+y2, conl(t).c)
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
	Dim As Integer a, b
	Dim As Integer t1, t2, d1, d2
	Dim As Integer x1, y1, x2, y2
	Dim As Integer x3, y3, x4, y4
	Dim As Integer dx, dy, dd1, dd2

	For a = 0 To nconl-1
		x1 = conl(a).x1
		y1 = conl(a).y1
		x2 = conl(a).x2
		y2 = conl(a).y2
		dx = x2-x1
		dy = y2-y1
		dd1 = dx^2+dy^2
		t1 = conl(a).t
		d1 = conl(a).d
		For b = a+1 To nconl-1
			x3 = conl(b).x1
			y3 = conl(b).y1
			x4 = conl(b).x2
			y4 = conl(b).y2
			dx = x4-x3
			dy = y4-y3
			dd2 = dx^2+dy^2
			t2 = conl(b).t
			d2 = conl(b).d

			If cutting (x1,y1,x2,y2,x3,y3,x4,y4) Then
				If togglecut=1 Then
					If dd2<=dd1 Then conl(a).s = 0
					If dd1<=dd2 Then conl(b).s = 0
				ElseIf togglecut=2 Then
					conl(a).s = 0
					conl(b).s = 0
				EndIf
			EndIf

		Next
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
				For d = 0 To nconl-1		' copy grp number to connected stones
					x = conl(d).t
					y = conl(d).d
					If y>0 And conl(d).s>1-togglegrp Then
						If grp(x)=gnr And grp(y)=0 Then grp(y) = gnr : gef = 1
						If grp(y)=gnr And grp(x)=0 Then grp(x) = gnr : gef = 1
					EndIf
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
			mycolor (stonecolor(t+1))		' the other color
			mytextout (BX+x-Len(s)*8/2+1, BY+y-5, LNUM, s)
		EndIf
	Next
End Sub


' kills a stone
'
Sub killstone (t As Integer)
	stones(t).x = 0
	stones(t).y = 0
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


' return a nicely formatted floating point number string
'
Function myformat (n As Double) As String
	Dim As String s
	s = Str(Int(n))+"."+Str(Int(n*1000)-Int(n)*1000)
	Return Space(7-Len(s))+s
End Function


' calc players territorium
'
Sub calcarea ()
	Dim As Integer x, y, t, d, x2, y2, gef, mx, my, sb, sw

	For y = 0 To BAS-1			' empty board
		For x = 0 To BAS-1
			bb(x,y) = CBOARD
		Next
	Next

	For t = 0 To nconl-1		' draw connection lines
		If conl(t).s>1-togglearea Then
			x = conl(t).x1
			y = conl(t).y1
			x2 = conl(t).x2
			y2 = conl(t).y2
			linedd (x, y, x2, y2, conl(t).c)
		EndIf
	Next

	For t = 0 To MAXSTONES-1		' draw stones (one pixel at position)
		x = stones(t).x
		y = stones(t).y
		If x>0 Then bb(x,y) = stonecolor (t)
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

	mybox (20, 36*16+4, 200, 39*16+4, 0.1, CBOARD)
	mycolor (CBLACK) : mytextout (30, 38*16, 0.2, "b "+myformat(sb/(DD^2)))
	mycolor (CWHITE) : mytextout (30, 37*16, 0.2, "w "+myformat(sw/(DD^2)))

	For y = 0 To BAS-1			' draw area colors on board
		For x = 0 To BAS-1
			If (x+y) Mod 2=0 Then
				t = bb(x,y)
				If t<>CINF Then mybox (BX+x, BY+y, BX+x+1, BY+y+1, LAREA, t)
			EndIf
		Next
	Next
End Sub


' load stones
'
Sub loadstones ()
	Dim As Integer t
	Open SAVEFILE For Input As #1
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
	Open SAVEFILE For Output As #1
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

	mycolor (CBOARD)

	mytextout (30, 35*16, 0, "f) show territory: "+ts(showarea))

	mytextout (30, 33*16, 0, "1) show influence: "+ts(showinf))
	mytextout (30, 32*16, 0, "2) show liberties: "+ts(showlib))
	mytextout (30, 31*16, 0, "3) show numbers: "+ts(shownum))
	mytextout (30, 30*16, 0, "4) show weak connections: "+ts(showweak))
	mytextout (30, 29*16, 0, "5) show strong connections: "+ts(showstrong))

	mytextout (30, 27*16, 0, "8) connection cutting: "+tc(togglecut))
	mytextout (30, 26*16, 0, "9) weak connection groups: "+ts(togglegrp))
	mytextout (30, 25*16, 0, "0) weak connection area: "+ts(togglearea))

	mytextout (30, 23*16, 0, "last move: "+Str(lastmovex)+" "+Str(lastmovey))
End Sub


' adds a stone to the board
'
Sub setstone (x As Integer, y As Integer)
	copystone (x, y, stonenr)
	stones(stonenr).x = x
	stones(stonenr).y = y
	stonenr += 1
	lastmovex = x
	lastmovey = y
End Sub


' get all files in the current directory. return 0 when empty
'
Function GetFiles (Array() As String) As Integer
	Dim As String s
	Dim As Integer attr, i
	ReDim Array(0)

	s = Dir("*",, @attr)
	Do Until s=""
		If (attr And fbHidden)=0 Then
			i += 1
			ReDim Preserve Array(i)
			Array(i) = s
		EndIf
		s = Dir("",, @attr)
	Loop
	Return UBound(Array)
End Function


' send mail or write shared file
'
Sub senden (x As Integer, y As Integer)
	If gametype=1 Then
		x += 100
		y += 100
		If spieler=1 Then
			Exec ("sendemail", "-f "+SENDUSER1+" -t "+SENDUSER1+" -u subject -m message "+Str(x)+","+Str(y)+" -s "+SENDSERVER1+":587 -o tls=yes -xu "+SENDUSER1+" -xp "+SENDPASS1)
		ElseIf spieler=2 Then
			Exec ("sendemail", "-f "+SENDUSER2+" -t "+SENDUSER2+" -u subject -m message "+Str(x)+","+Str(y)+" -s "+SENDSERVER2+":587 -o tls=yes -xu "+SENDUSER2+" -xp "+SENDPASS2)
		EndIf
	ElseIf gametype=2 Then
		If spieler=1 Then
			Open SHAREDFILE1 For Output As #1
			Print #1,x,y
			Close #1
		ElseIf spieler=2 Then
			Open SHAREDFILE2 For Output As #1
			Print #1,x,y
			Close #1
		EndIf
	EndIf
End Sub


' get mail or read shared file
'
Function empfangen (ByRef x As Integer, ByRef y As Integer) As Integer
	Dim As String dateien()
	Dim As String a
	Dim As Integer t
	Static As Double tim

	If Timer-tim<3 Then Return 0		' check not faster than every 3 seconds
	tim = Timer

	If gametype=1 Then
		If spieler=1 Then
			Exec ("getmail", "-r "+GETMAILRC2)
		ElseIf spieler=2 Then
			Exec ("getmail", "-r "+GETMAILRC1)
		EndIf
		t = GetFiles (dateien())
		If t=0 Then Return 0
		Open dateien(1) For Input As #1
		While Not EOF(1)
			Line Input #1,a
			If Mid(a,1,7)="message" Then x = Val(Mid(a,9,3)) : y = Val(Mid(a,13,3))
		Wend
		Close #1
		Kill dateien(1)
		x -= 100
		y -= 100
		Return 1
	ElseIf gametype=2 Then
		x = 0 : y = 0
		If spieler=1 Then
			Open SHAREDFILE2 For Input As #1
			Input #1,x,y
			Close #1
			Kill SHAREDFILE2
		ElseIf spieler=2 Then
			Open SHAREDFILE1 For Input As #1
			Input #1,x,y
			Close #1
			Kill SHAREDFILE1
		EndIf
		If x>0 And y>0 Then Return 1
		Return 0
	EndIf
End Function


' display start menu and wait for choice
'
Sub startmenu ()
	Dim As String i

	gametype = 0
	Do
		glClear (GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT)

		mycolor (CBOARD)
		mytextout (450, 30*16, 0, "RealGo")
		mytextout (400, 24*16, 0, "1) start email game as black")
		mytextout (400, 23*16, 0, "2) start email game as white")
		mytextout (400, 21*16, 0, "3) start shared file game as black")
		mytextout (400, 20*16, 0, "4) start shared file game as white")
		mytextout (400, 18*16, 0, "5) start single computer game")

		i = Inkey
		If i="1" Then gametype = 1 : spieler = 1
		If i="2" Then gametype = 1 : spieler = 2
		If i="3" Then gametype = 2 : spieler = 1
		If i="4" Then gametype = 2 : spieler = 2
		If i="5" Then gametype = 3 : spieler = 0

		Flip
	Loop While gametype=0
End Sub


' input stuff on opengl screen
'
Function myinput (ByRef x As Integer, ByRef y As Integer) As Integer
	Dim As String i, s
	Dim As Integer t

	glDisable (GL_DEPTH_TEST)
	Do
		mybox (30, 22*16+4, 200, 20*16+4, 0.1, CBOARD)
		mycolor (stonecolor (stonenr))
		mytextout (38, 21*16, 0.1, "input x,y: "+s)
		i = Inkey
		If i=Chr(13) Then Exit Do
		If i=Chr(8) Then s = Left(s,Len(s)-1) : Continue Do
		If Asc(i)>=32 And Asc(i)<128 Then s += i
		Flip
	Loop
	glEnable (GL_DEPTH_TEST)
	t = InStr(s,",")
	If t=0 Then Return 0
	x = Val(Mid(s,1,t))
	y = Val(Mid(s,t+1,Len(s)))
	Return 1
End Function


' main
'
Sub main ()
	Dim As Integer x,y,wheel,button,lbuttoncnt
	Dim As Integer t, wantinput
	Dim As String i
	Dim As HWND hwnd
	Dim As HDC hdc
	Dim As HGLRC hglrc
	Dim As HFONT hfont

	ScreenRes SCRX,SCRY,32,,FB.GFX_OPENGL Or FB.GFX_MULTISAMPLE

	ScreenControl (FB.GET_WINDOW_HANDLE, Cast (Integer, hwnd))
	hdc = GetDC (hwnd)
	hglrc = wglCreateContext (hdc)
	wglMakeCurrent (hdc, hglrc)
	hfont = CreateFont (16, 8, 0, 0, FW_DONTCARE, 0, 0, 0, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS, _
	CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FIXED_PITCH, @"Fixedsys")
	SelectObject (hdc, hfont)
	'SelectObject (hdc, GetStockObject (SYSTEM_FONT))
	wglUseFontBitmaps (hdc, 0, 255, 1000)
	DeleteObject (hfont)

	glViewport (0, 0, SCRX, SCRY)
	glMatrixMode (GL_PROJECTION)
	glLoadIdentity ()
	glOrtho (0, SCRX, 0, SCRY, -1, 1)
	glMatrixMode (GL_MODELVIEW)
	glLoadIdentity ()

	glClearColor (0.5, 0, 0, 1)		' background color
	glEnable (GL_DEPTH_TEST)

	startmenu ()

	If gametype=1 Then
		If spieler=1 Then ChDir (GETMAILDIR2)
		If spieler=2 Then ChDir (GETMAILDIR1)
	EndIf

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
		glClear (GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT)

		drawmenu ()
		drawboard ()
		drawstones ()

		GetMouse x,y,wheel,button
		x -= BX
		y = SCRY-y-BY
		If button=0 Then lbuttoncnt = 0
		If button=1 Then lbuttoncnt += 1

		searchnearest (x, y)		' byref!

		If setpossible (x, y)=1 Then
			If lbuttoncnt=1 Then
				If gametype=3 Then
					setstone (x, y)		' add stone
				Else
					If spieler=1 And stonenr Mod 2=1 Or spieler=2 And stonenr Mod 2=0 Then
						setstone (x, y)
						senden (x, y)
					EndIf
				EndIf
			Else
				If wantinput=0 Then drawstone (x, y, stonenr)		' draw hovering stone
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


		If gametype=1 Or gametype=2 Then
			If spieler=1 And stonenr Mod 2=0 Or spieler=2 And stonenr Mod 2=1 Then
				If empfangen (x, y)=1 Then
					setstone (x, y)
				EndIf
			EndIf
		EndIf


		If wantinput Then		' manual input of coordinates of stone to set
			If myinput (x, y)<>0 Then		' byref!
				setstone (x, y)
			EndIf
			wantinput = 0
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
