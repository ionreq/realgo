/' endlich ein gescheites go

	keys
		ESC	quit
		LMB	place stone
		RMB	pan
		wheel	zoom
		p		show pixels
		i		input coordinates to place stone
		t		show territory
		f		fullscreen/windowed toggle
		s		save game to file
		l		load game from file
		k		kill stone near mouse
		m		increase move (change color, pass)
		1-5	show influence, liberties, numbers, weak, strong connections
		8-0	connection cutting, groups and territory switches


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
		opengl: pan möglich
		opengl: zoom
		brettgröße auswahl
		linien in verschiedener dicke, nicht doppelt (probiert, erkennt man schlecht)
		linien auch bei +0.5 wie kreismittelpunkte
		kreisradius noch +0.5 (in zoom sieht mans)
		pixel board als textur anzeigbar
		vier distanzen d4 ("weak" <2*DD), d3 ("near" <sqr(3)*DD), d2 ("strong" <sqr(2)*DD), d1 ("touching" =DD)
		für alle vier distanzen einen kreis malen wie für freiheiten makestone(), nichts berechnen
		d1 und d3 schalter für grouping, territory
		fullscreen/fenster auswahl
		mögliche connections in echtzeit anzeigen
		"close" distanz, die einen pixel mehr als stone circumference hat
			"touching" dann raus, und "near" ist dann natürlich für die "close" distanz
		geheime taste zum anzeigen von ar()

	evtl
		freiheiten als schwarze und weiße freiheiten anzeigen
		stein der beim schlagen selber 0 freiheiten hat, überlebt
			dazu einfach zuerst nur freiheiten vom gegner checken und evtl killen, dann erst eigene
		ko regel: wenn vorher ein einzelner stein geschlagen wurde,
			kann der nicht sofort im nächsten zug ersetzt werden,
			d.h. setzen in den kreis ist nicht möglich
			dazu muss im savefile gespeichert werden wo das war
		steine ausblenden (für area besser sichtbar)
		cut mit gleicher distanz könnte auch bleiben. evtl schalter dafür
		config file mit schaltern, email namen, save file name, fullscreen/window, etc.
		opengl: freiheiten als gaussbuckel darstellen, evtl mit variabler breite
			das wäre auch die lösung für transparentes inf
		alles auf hexgitter
		schalter für no grouping (bei keiner distanz)
		schalter für own connection cutting
			dann muss man sich aber in der cutting() routine was für die = fälle überlegen,
			da die immer auftreten wenn von einem stein mehr als eine connection abgehen
		connections gehen von rand zu rand, nicht von mittelpunkt zu mittelpunkt
			stein selber cuttet auch, d.h. connections gehen nicht durch steine, d3 ist grenzfall
		hovering stone: freiheiten, geschlagene gruppen, alles anzeigen (irgendwie eingefärbt zb)

	todo
		mainloop so machen, dass nicht jedesmal area neu berechnet wird
		makestone noch für den rand (nix mehr solution of equation, das werden tests)

'/

#Include "windows.bi"
#Include "win/mmsystem.bi"
#Include "gl/gl.bi"
#Include "gl/glu.bi"
#Include "fbgfx.bi"
#Include "string.bi"
#Include "dir.bi"


Const PI = 6.283185307

Const WINX = 72*16	' window size
Const WINY = 72*9

Dim Shared As Integer SCRX, SCRY		' screen size

Const LL = 300		' width of menu viewport, board is SCRX-LL

Dim Shared As Integer BS			' board size

Dim Shared As Integer MAXSTONES	' maxiumum number of stones

Dim Shared As Integer MAXCONS		' maximum number of connections

Const RR = 23			' radius stone
Const DD = 2*RR		' diameter stone

Dim Shared As Integer BAS		' board array size
Const SAS = 2*(2*DD+3)+1		' stone array size
Const MAXCNT = RR*13				' maximum expected number of liberties for that radius (about 2*RR*PI)

Dim Shared As UByte ar(SAS,SAS), sa(2*(RR+1)+1,2*(RR+1)+1)		' stone array (with influence and without)

'color numbers
Enum colors
CBOARD			' board beige
CBOARDLINES		' darker beige for grid lines on board
CBLACK			' black stone
CWHITE			' white stone
CBACKGROUND		' the background
CSTONE			' stone
CCIRC				' circumference
CCLOSECIRC		' close
CINF				' influence area (gray)
CLIB				' liberties circle (red) (<=d1)
CCLOSE			' close (<=d1)
CLD2				' <d2
CED2				' =d2
CLD3				' <d3
CED3				' =d3
CLD4				' <d4
CED4				' =d4
NCOLORS
End Enum

Dim Shared As Integer col(NCOLORS) = { _
RGB(230,188,104), _
RGB(210,168,84), _
RGB(0,0,0), _
RGB(255,255,255), _
RGB(128,0,0), _
RGB(0,0,0), _
RGB(100,100,100), _
RGB(200,200,0), _
RGB(128,128,128), _
RGB(200,0,0), _
RGB(200,200,0), _
RGB(0,200,0), _
RGB(0,100,0), _
RGB(200,0,0), _
RGB(100,0,0), _
RGB(0,200,200), _
RGB(0,100,100) _
}

Const FCOLLISION = 1		' for testcircle()
Const FTOUCHING = 2
Const FCLOSE = 4

Type stone
	As Integer x, y		' 0=not there, positions start at 1*RR
	As Integer f			' liberties
End Type
Dim Shared As stone stones(MAXSTONES)		' stone positions

Dim Shared As Integer stonenr		' move number, starts with 1=black

Dim Shared As Integer maxlib		' number of liberties of a stone

Dim Shared As UByte ba(BAS,BAS)		' board array
Dim Shared As UByte bb(BAS,BAS)		' board array for area calc

Type connection
	As Integer c		' color 1=black 2=white
	As Integer s		' 0=not there, strength 4=weak 3=near 2=strong 1=touching
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

Dim Shared As Integer showinf, showlib, showcon, shownum, showhov		' toggle switches for display
Dim Shared As Integer showarea

Dim Shared As Integer togglecut, togglegrp, toggleter		' toggle switches for variations

Dim Shared As Integer lastmovex, lastmovey	' coos of last stone set

Dim Shared As Integer spieler, gametype		' for email/shared folder game

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

Const SHAREDFILE1 = "sharedfile1.txt"		' files in shared folder
Const SHAREDFILE2 = "sharedfile2.txt"

Const SAVEFILE = "stones.txt"		' save file name of a game

Const LBOARD = 0				' opengl depth layers
Const LBOARDLINES = 0.1
Const LLIB = 0.2
Const LINF = 0.3
Const LSTONE = 0.4
Const LCON = 0.5
Const LAREA = 0.6
Const LNUM = 0.7
Const LEDGE = 0.8

Dim Shared As Double panx = -20, pany = -20, zoom = 1			' board panning and zooming
Dim Shared As Integer togglefullscreen

Const VSCREEN = 0		' viewports
Const VMENU = 1
Const VBOARD = 2


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

	n = 32/zoom
	If n<16 Then n = 16
	If n>256 Then n = 256

	glBegin (GL_TRIANGLE_FAN)
	For t = 0 To n-1
		glVertex3d (x+r*Cos(t*PI/n)+0.5, y+r*Sin(t*PI/n)+0.5, z)
	Next
	glEnd ()
End Sub


' draw a thick line as quad
'
Sub myline (x1 As Double, y1 As Double, x2 As Double, y2 As Double, LW As Double, lt As Integer, c As Integer)
	Dim As Integer t
	Dim As Double dx, dy, d, ex, ey, fx, fy
	Dim As Double nx1, ny1, nx2, ny2

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
	x1 += 0.5 : y1 += 0.5
	x2 += 0.5 : y2 += 0.5

	If lt=2 Then

		Const U = 5
		nx1 = x1 - fx*U : ny1 = y1 - fy*U
		nx2 = x2 - fx*U : ny2 = y2 - fy*U
		glBegin (GL_QUADS)
		glVertex3d (nx1-LW*ex-LW*fx, ny1-LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex-LW*fx, ny2+LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex+LW*fx, ny2+LW*ey+LW*fy, LCON)
		glVertex3d (nx1-LW*ex+LW*fx, ny1-LW*ey+LW*fy, LCON)
		glEnd ()
		nx1 = x1 + fx*U : ny1 = y1 + fy*U
		nx2 = x2 + fx*U : ny2 = y2 + fy*U
		glBegin (GL_QUADS)
		glVertex3d (nx1-LW*ex-LW*fx, ny1-LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex-LW*fx, ny2+LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex+LW*fx, ny2+LW*ey+LW*fy, LCON)
		glVertex3d (nx1-LW*ex+LW*fx, ny1-LW*ey+LW*fy, LCON)
		glEnd ()

	ElseIf lt=1 Then

		nx1 = x1 + (RR-0.5)*ex : ny1 = y1 + (RR-0.5)*ey
		nx2 = x1 + (RR+0.5)*ex : ny2 = y1 + (RR+0.5)*ey
		glBegin (GL_QUADS)
		glVertex3d (nx1-LW*ex-LW*fx, ny1-LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex-LW*fx, ny2+LW*ey-LW*fy, LCON)
		glVertex3d (nx2+LW*ex+LW*fx, ny2+LW*ey+LW*fy, LCON)
		glVertex3d (nx1-LW*ex+LW*fx, ny1-LW*ey+LW*fy, LCON)
		glEnd ()

	ElseIf lt=4 Then

		For t = 0 To Int(d) Step 6
			nx1 = x1 + t*ex : ny1 = y1 + t*ey
			nx2 = x1 + (t+1)*ex : ny2 = y1 + (t+1)*ey

			glBegin (GL_QUADS)
			glVertex3d (nx1-LW*ex-LW*fx, ny1-LW*ey-LW*fy, LCON)
			glVertex3d (nx2+LW*ex-LW*fx, ny2+LW*ey-LW*fy, LCON)
			glVertex3d (nx2+LW*ex+LW*fx, ny2+LW*ey+LW*fy, LCON)
			glVertex3d (nx1-LW*ex+LW*fx, ny1-LW*ey+LW*fy, LCON)
			glEnd ()
		Next

	Else
		glBegin (GL_QUADS)
		glVertex3d (x1-LW*ex-LW*fx, y1-LW*ey-LW*fy, LCON)
		glVertex3d (x2+LW*ex-LW*fx, y2+LW*ey-LW*fy, LCON)
		glVertex3d (x2+LW*ex+LW*fx, y2+LW*ey+LW*fy, LCON)
		glVertex3d (x1-LW*ex+LW*fx, y1-LW*ey+LW*fy, LCON)
		glEnd ()
	EndIf

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


' choose opengl viewport
'
Sub viewport (v As Integer)
	If v=VSCREEN Then
		glViewport (0, 0, SCRX, SCRY) : glMatrixMode (GL_PROJECTION) : glLoadIdentity ()
		glOrtho (0, SCRX, 0, SCRY, -1, 1) : glMatrixMode (GL_MODELVIEW) : glLoadIdentity ()
	ElseIf v=VMENU Then
		glViewport (0, 0, LL, SCRY) : glMatrixMode (GL_PROJECTION) : glLoadIdentity ()
		glOrtho (0, LL, 0, SCRY, -1, 1) : glMatrixMode (GL_MODELVIEW) : glLoadIdentity ()
	ElseIf v=VBOARD Then
		glViewport (LL, 0, SCRX-LL, SCRY) : glMatrixMode (GL_PROJECTION) : glLoadIdentity ()
		glOrtho ((SCRX-LL)/2+panx-(SCRX-LL)/2*zoom, (SCRX-LL)/2+panx+(SCRX-LL)/2*zoom, SCRY/2+pany-SCRY/2*zoom, SCRY/2+pany+SCRY/2*zoom, -1, 1) : glMatrixMode (GL_MODELVIEW) : glLoadIdentity ()
	EndIf
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
		If x>=0 And x<BAS And y>=0 And y<BAS Then
			If bb(x,y)<>c Then
				If bb(x,y)=CBLACK Then t Or= 1 : Continue Do
				If bb(x,y)=CWHITE Then t Or= 2 : Continue Do
				bb(x,y) = c
				queuein (x+1, y)
				queuein (x, y+1)
				queuein (x-1, y)
				queuein (x, y-1)
			EndIf
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
	If (x+RR) Mod DD=0 Or (y+RR) Mod DD=0 Then Return CBOARDLINES
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

	mybox (0, 0, BAS, BAS, LBOARD, CBOARD)

	mybox (-DD, -DD, 0, BAS+DD, LEDGE, CBACKGROUND)
	mybox (BAS, -DD, BAS+DD, BAS+DD, LEDGE, CBACKGROUND)
	mybox (0, -DD, BAS, 0, LEDGE, CBACKGROUND)
	mybox (0, BAS, BAS, BAS+DD, LEDGE, CBACKGROUND)

	For t = 1 To BS
		mybox (t*DD-RR, RR, t*DD-RR+1, RR+(BS-1)*DD+1, LBOARDLINES, CBOARDLINES)
		mybox (RR, t*DD-RR, RR+(BS-1)*DD+1, t*DD-RR+1, LBOARDLINES, CBOARDLINES)
	Next

	If showinf Then c = CINF Else c = CBOARD

	mybox (0, 0, RR, BAS, LINF, c)
	mybox (BAS-RR, 0, BAS, BAS, LINF, c)
	mybox (0, 0, BAS, RR, LINF, c)
	mybox (0, BAS-RR, BAS, BAS, LINF, c)
End Sub


' distance squared
'
Function dist (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer) As Integer
	Return (x2-x1)^2+(y2-y1)^2
End Function


' are two circles touching or overlapping
'
Function testcircle (mx As Integer, my As Integer, mx2 As Integer, my2 As Integer) As Integer
	Dim As Integer x, y, dx, dy, t, nx, ny, a, b, d

	dx = mx2-mx
	dy = my2-my
	d = dx^2+dy^2
	If d<(2*RR-4)^2 Then Return FCOLLISION
	If d>(2*RR+4)^2 Then Return 0
	t = 0
	For y = -RR-1 To RR+1
		For x = -RR-1 To RR+1
			nx = RR+1+dx+x
			ny = RR+1+dy+y
			If nx>=0 And nx<2*(RR+1)+1 And ny>=0 And ny<2*(RR+1)+1 Then
				a = sa(RR+1+x,RR+1+y)
				b = sa(nx,ny)
				If a=CSTONE And (b=CSTONE Or b=CCIRC) Then Return FCOLLISION
				If a=CCIRC And b=CCIRC Then t Or= FTOUCHING
				If a=CCIRC And (b=CCIRC Or b=CCLOSECIRC) Then t Or= FCLOSE
			EndIf
		Next
	Next
	Return t
End Function


' make stone array with tests for all the distances
'
Sub makestone ()
	Dim As Integer x, y, t, d, a, b, r, d0, d1, d2, d3, d4, ny, nx
	Dim As Double w, w1, w2
	Dim As Integer t1, t2, t3, t4, qx, qy, c, mx, my
	Dim As Integer xp(-MAXCNT To 2*MAXCNT), yp(-MAXCNT To 2*MAXCNT), cnt

	mx = (SAS-1)/2
	my = (SAS-1)/2

	For x = -RR To RR						' stone with circumference
		y = Int(Sqr(RR^2-x^2)+0.5)
		For t = -y To y
			If sa(RR+1+x,RR+1+t)=0 Then sa(RR+1+x,RR+1+t) = CSTONE
			If sa(RR+1+t,RR+1+x)=0 Then sa(RR+1+t,RR+1+x) = CSTONE
		Next
		sa(RR+1+x,RR+1+y) = CCIRC
		sa(RR+1+x,RR+1-y) = CCIRC
		sa(RR+1+y,RR+1+x) = CCIRC
		sa(RR+1-y,RR+1+x) = CCIRC
	Next

	For x = -RR-1 To RR+1		' draw close circumference (stone circumference +1 pixel)
		For y = -RR-1 To RR+1
			If sa(RR+1+x,RR+1+y)=0 And x^2+y^2<=(RR+1.5)^2 Then sa(RR+1+x,RR+1+y) = CCLOSECIRC
		Next
	Next

	For x = -(2*RR+2) To 2*RR+2		' influence and liberty curve via collision with second stone
		For y = -(2*RR+2) To 2*RR+2
			nx = mx+x
			ny = my+y
			t = testcircle (mx,my,nx,ny)
			If (t And FTOUCHING) And Not (x=0 And y=0) Then
				ar(nx,ny) = CLIB
				xp(cnt) = x : yp(cnt) = y
				cnt+=1
			ElseIf (t And FCOLLISION) Then
				ar(nx,ny) = CINF
			ElseIf (t And FCLOSE) Then
				ar(nx,ny) = CCLOSE
			EndIf
		Next
	Next

	maxlib = cnt

	For y = -RR-1 To RR+1
		For x = -RR-1 To RR+1
			If sa(RR+1+x,RR+1+y)>0 Then
				ar(mx+x,my+y) = sa(RR+1+x,RR+1+y)
			EndIf
		Next
	Next

	For t = cnt-1 To 2 Step -1		' sort coos of liberties by their angle
		For d = 0 To t-1
			w1 = ATan2(yp(d),xp(d))
			w2 = ATan2(yp(d+1),xp(d+1))
			If w1>w2 Then
				Swap xp(d), xp(d+1)
				Swap yp(d), yp(d+1)
			EndIf
		Next
	Next

	For t = 0 To cnt-1
		xp(t-cnt) = xp(t) : yp(t-cnt) = yp(t)
		xp(t+cnt) = xp(t) : yp(t+cnt) = yp(t)
	Next

	For qy = 0 To (SAS-1)/2-1
		For qx = 0 To (SAS-1)/2-1

			If qx>=qy Then				' only first octant
				w = Sqr(qx^2+qy^2)

				t = Int((ATan2(qy,qx)/PI+0.5)*cnt)

				c = 0

				If w<Sqr(2)*2*RR-3 Then

					c = CLD2

				ElseIf w<Sqr(2)*2*RR+4 Then		' sqr(2) distance

					nx = mx+qx
					ny = my+qy
					Const U = 6
					For t1 = U To -U Step -1
						If testcircle (mx,my,nx-xp(t-cnt/8-t1),ny-yp(t-cnt/8-t1))=FCOLLISION Then t1+=1 : Exit For
					Next
					For t2 = U To -U Step -1
						If testcircle (mx,my,nx-xp(t+cnt/8+t2),ny-yp(t+cnt/8+t2))=FCOLLISION Then t2+=1 : Exit For
					Next
					For t3 = U To -U Step -1
						If testcircle (nx,ny,mx+xp(t+cnt/8+t3),my+yp(t+cnt/8+t3))=FCOLLISION Then t3+=1 : Exit For
					Next
					For t4 = U To -U Step -1
						If testcircle (nx,ny,mx+xp(t-cnt/8-t4),my+yp(t-cnt/8-t4))=FCOLLISION Then t4+=1 : Exit For
					Next
					d0 = dist(mx,my,nx,ny)
					d1 = dist(nx-xp(t-cnt/8-t1),ny-yp(t-cnt/8-t1),nx-xp(t+cnt/8+t2),ny-yp(t+cnt/8+t2))
					d2 = dist(mx+xp(t-cnt/8-t4),my+yp(t-cnt/8-t4),mx+xp(t+cnt/8+t3),my+yp(t+cnt/8+t3))
					d3 = dist(nx-xp(t-cnt/8-t1),ny-yp(t-cnt/8-t1),mx+xp(t-cnt/8-t4),my+yp(t-cnt/8-t4))
					d4 = dist(mx+xp(t+cnt/8+t3),my+yp(t+cnt/8+t3),nx-xp(t+cnt/8+t2),ny-yp(t+cnt/8+t2))
					c = CLD2
					If d1<d0 Or d2<d0 Or d3<d0 Or d4<d0 Then c = CLD3
					If d0=d1 And d1=d2 And d2=d3 And d3=d4 Then c = CED2

				ElseIf w<Sqr(3)*2*RR-3 Then

					c = CLD3

				ElseIf w<Sqr(3)*2*RR+4 Then		' sqr(3) distance

					nx = mx+qx
					ny = my+qy
					Const U = 10
					For t1 = U To -U Step -1
						If testcircle (mx,my,nx-xp(t-cnt/12-t1),ny-yp(t-cnt/12-t1))=FCOLLISION Then t1+=1 : Exit For
					Next
					For t2 = U To -U Step -1
						If testcircle (mx,my,nx-xp(t+cnt/12+t2),ny-yp(t+cnt/12+t2))=FCOLLISION Then t2+=1 : Exit For
					Next
					For t3 = U To -U Step -1
						If testcircle (nx,ny,mx+xp(t+cnt/12+t3),my+yp(t+cnt/12+t3))=FCOLLISION Then t3+=1 : Exit For
					Next
					For t4 = U To -U Step -1
						If testcircle (nx,ny,mx+xp(t-cnt/12-t4),my+yp(t-cnt/12-t4))=FCOLLISION Then t4+=1 : Exit For
					Next
					d1 = testcircle(nx-xp(t-cnt/12-t1),ny-yp(t-cnt/12-t1),nx-xp(t+cnt/12+t2),ny-yp(t+cnt/12+t2))
					d2 = testcircle(mx+xp(t-cnt/12-t4),my+yp(t-cnt/12-t4),mx+xp(t+cnt/12+t3),my+yp(t+cnt/12+t3))
					d3 = testcircle(nx-xp(t-cnt/12-t1),ny-yp(t-cnt/12-t1),mx+xp(t-cnt/12-t4),my+yp(t-cnt/12-t4))
					d4 = testcircle(mx+xp(t+cnt/12+t3),my+yp(t+cnt/12+t3),nx-xp(t+cnt/12+t2),ny-yp(t+cnt/12+t2))
					c = CLD3
					If (d1 And FCOLLISION) Or (d2 And FCOLLISION) Or (d3 And FCOLLISION) Or (d4 And FCOLLISION) Then c=CLD4
					If (d1 And FCLOSE) Or (d2 And FCLOSE) Or (d3 And FCLOSE) Or (d4 And FCLOSE) Then c=CED3

				ElseIf w<2*2*RR-3 Then

					c = CLD4

				ElseIf w<2*2*RR+4 Then		' DD distance

					nx = mx+qx
					ny = my+qy
					d=0
					For a = -3 To 3
						d Or= testcircle (nx,ny, mx+xp(t+a), my+yp(t+a))
					Next
					If (d And FCOLLISION) Then c = CLD4 Else If (d And FTOUCHING) Then c = CED4

				EndIf

				If ar(mx+qx,my+qy)=0 Then
					ar(mx+qx,my+qy) = c			' the other octants
					ar(mx-qx,my+qy) = c
					ar(mx-qx,my-qy) = c
					ar(mx+qx,my-qy) = c
					ar(mx+qy,my+qx) = c
					ar(mx+qy,my-qx) = c
					ar(mx-qy,my-qx) = c
					ar(mx-qy,my+qx) = c
				EndIf
			EndIf

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
		mycolor (CLIB) : mycircle (mx, my, LLIB, 2*RR+0.5)
		mycolor (CINF) : mycircle (mx, my, LINF, 2*RR-0.5)
	ElseIf showlib Then
		mycolor (CLIB) : mycircle (mx, my, LLIB, 2*RR+0.5)
		mycolor (CBOARD) : mycircle (mx, my, LINF, 2*RR-0.5)
	ElseIf showinf Then
		mycolor (CINF) : mycircle (mx, my, LINF, 2*RR-0.5)
	EndIf
	mycolor (stonecolor(sn)) : mycircle (mx, my, LSTONE, RR)
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

	For y = -2*RR To 2*RR
		py = my+y
		If py>=0 And py<BAS Then
			For x = -2*RR To 2*RR
				px = mx+x
				If px>=0 And px<BAS Then
					c = ar((SAS-1)/2+x,(SAS-1)/2+y)
					If c=CCLOSECIRC Then c = CINF
					If c=CSTONE Or c=CCIRC Or c=CINF Or c=CLIB Then
						d = ba(px,py)
						If Not ((c=CLIB Or c=CINF) And Not (d=CBOARD Or d=CBOARDLINES Or d=CLIB)) Then
							If c=CSTONE Then c = stonecolor (sn)
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
	For y = -2*RR To 2*RR
		py = my+y
		If py>=0 And py<BAS Then
			For x = -2*RR To 2*RR
				px = mx+x
				If px>=0 And px<BAS Then
					If ar((SAS-1)/2+x,(SAS-1)/2+y)=CLIB And ba(px,py)=CLIB Then r += 1
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
	Dim As Integer t, d, x, y, x2, y2, dx, dy, c

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
						If dx^2+dy^2<(2*DD+3)^2 Then
							c = ar((SAS-1)/2+dx,(SAS-1)/2+dy)
							If c>0 Then
								If c<=CCLOSE Then
									newconl (stonecolor(t), 1, t, d, x, y, x2, y2)
								ElseIf c<CED2 Then
									newconl (stonecolor(t), 2, t, d, x, y, x2, y2)
								ElseIf c<CED3 Then
									newconl (stonecolor(t), 3, t, d, x, y, x2, y2)
								ElseIf c<CED4 Then
									newconl (stonecolor(t), 4, t, d, x, y, x2, y2)
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			Next

			Const RA = (2+Sqr(19))/5	' solution of a quadratic eq. for the distance of the two cutting stones

			If x=RR Then
				newconl (stonecolor(t), 1, t, 0, x, y, 0, y)			' left edge
			ElseIf x<RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, 0, y)
			ElseIf x<Sqr(3)/2*DD+RR Then
				newconl (stonecolor(t), 3, t, 0, x, y, 0, y)
			ElseIf x<RR+DD Then
				newconl (stonecolor(t), 4, t, 0, x, y, 0, y)
			EndIf

			If x=BAS-1-RR Then
				newconl (stonecolor(t), 1, t, 0, x, y, BAS-1, y)		' right edge
			ElseIf x>BAS-1-RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, BAS-1, y)
			ElseIf x>BAS-1-(Sqr(3)/2*DD+RR) Then
				newconl (stonecolor(t), 3, t, 0, x, y, BAS-1, y)
			ElseIf x>BAS-1-(RR+DD) Then
				newconl (stonecolor(t), 4, t, 0, x, y, BAS-1, y)
			EndIf

			If y=RR Then
				newconl (stonecolor(t), 1, t, 0, x, y, x, 0)		' bottom edge
			ElseIf y<RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, x, 0)
			ElseIf y<Sqr(3)/2*DD+RR Then
				newconl (stonecolor(t), 3, t, 0, x, y, x, 0)
			ElseIf y<RR+DD Then
				newconl (stonecolor(t), 4, t, 0, x, y, x, 0)
			EndIf

			If y=BAS-1-RR Then
				newconl (stonecolor(t), 1, t, 0, x, y, x, BAS-1)		' top edge
			ElseIf y>BAS-1-RA*DD Then
				newconl (stonecolor(t), 2, t, 0, x, y, x, BAS-1)
			ElseIf y>BAS-1-(Sqr(3)/2*DD+RR) Then
				newconl (stonecolor(t), 3, t, 0, x, y, x, BAS-1)
			ElseIf y>BAS-1-RR-DD Then
				newconl (stonecolor(t), 4, t, 0, x, y, x, BAS-1)
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
		If conl(t).s=1 Then
			myline (x, y, x2, y2, 1.5, 1, CINF)			' touching, gray short line
		ElseIf conl(t).s=2 Then
			myline (x, y, x2, y2, 1.2, 2, conl(t).c)	' strong, double line
		ElseIf conl(t).s=3 Then
			myline (x, y, x2, y2, 1, 3, conl(t).c)		' near, normal line
		ElseIf conl(t).s=4 Then
			myline (x, y, x2, y2, 1, 4, conl(t).c)		' weak, dashed line
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
		If xy>=0 And xy<=1 Then partial = 1
		If partial Then
			ab = (y1 * (x0 - a1) + b1 * (x1 - x0) + y0 * (a1 - x1)) / denom
		EndIf
	EndIf
	If partial And ab>=0 And ab<=1 Then
		ab = 1-ab
		xy = 1-xy
		Return 1
	Else
		Return 0
	EndIf
End Function


' removes connections from con list when they are cut by shorter ones
'
Sub cutconnections ()
	Dim As Integer x1, y1, x2, y2, x3, y3, x4, y4
	Dim As Integer a, b, dx, dy, dd1, dd2

	For a = 0 To nconl-1
		x1 = conl(a).x1 : y1 = conl(a).y1
		x2 = conl(a).x2 : y2 = conl(a).y2
		dx = x2-x1 : dy = y2-y1
		dd1 = dx^2+dy^2
		For b = a+1 To nconl-1
			x3 = conl(b).x1 : y3 = conl(b).y1
			x4 = conl(b).x2 : y4 = conl(b).y2
			dx = x4-x3 : dy = y4-y3
			dd2 = dx^2+dy^2
			If conl(a).c<>conl(b).c Then		' cutting only for opponent, not for own connections
				If cutting (x1,y1,x2,y2,x3,y3,x4,y4) Then
					If togglecut=1 Then
						If dd2<=dd1 Then conl(a).s = 0
						If dd1<=dd2 Then conl(b).s = 0
					ElseIf togglecut=2 Then
						conl(a).s = 0
						conl(b).s = 0
					EndIf
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

	gnr = 1
	For t = 0 To MAXSTONES-1
		If stones(t).x>0 And grp(t)=0 Then		' stone gets a new grp number
			grp(t) = gnr
			Do
				gef = 0
				For d = 0 To nconl-1		' copy grp number to connected stones
					x = conl(d).t
					y = conl(d).d
					If y>0 And conl(d).s>0 And conl(d).s<=togglegrp+1 Then
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
			mytextout (x-(Len(s)*8/2+1)*zoom, y-5*zoom, LNUM, s)
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
	Dim As String s, t
	s = Str(Int(n))
	s = Space(3-Len(s))+s
	t = Str(Int(n*1000)-Int(n)*1000)
	t = String(3-Len(t),"0")+t
	Return s+"."+t
End Function


' calc players territorium
'
Sub calcarea ()
	Dim As Integer x, y, t, d, x2, y2, gef, mx, my, sb, sw, st

	For y = 0 To BAS-1			' empty board
		For x = 0 To BAS-1
			bb(x,y) = CBOARD
		Next
	Next

	For t = 0 To nconl-1		' draw connection lines
		If conl(t).s>0 And conl(t).s<=toggleter+1 Then
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
		st = 64
		Do
			For y = 0 To BAS-1 Step st
				For x = 0 To BAS-1 Step st
					If bb(x,y)=CBOARD Then mx = x : my = y : gef = 1 : Exit For
				Next
				If gef Then Exit For
			Next
			If gef Then Exit Do
			If st=1 Then Exit Do
			st /= 4
		Loop
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

	viewport (VMENU)
	mybox (20, 36*16+4, 200, 39*16+4, 0.1, CBOARD)
	mycolor (CBLACK) : mytextout (30, 38*16, 0.2, "b "+myformat(sb/(DD^2)))
	mycolor (CWHITE) : mytextout (30, 37*16, 0.2, "w "+myformat(sw/(DD^2)))

	viewport (VBOARD)
	For y = 0 To BAS-1			' draw area colors on board
		For x = 0 To BAS-1
			If (x+y) Mod 2=0 Then
				t = bb(x,y)
				If t<>CINF Then mybox (x, y, x+1, y+1, LAREA, t)
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
	Dim As String ts(2), tc(3), tt(4)

	ts(0) = "off" : ts(1) = "on"
	tc(0) = "none" : tc(1) = "longer" : tc(2) = "both"
	tt(0) = "close" : tt(1) = "strong" : tt(2) = "near" : tt(3) = "weak"

	mycolor (CBOARD)

	mytextout (30, 33*16, 0, "1) show influence: "+ts(showinf))
	mytextout (30, 32*16, 0, "2) show liberties: "+ts(showlib))
	mytextout (30, 31*16, 0, "3) show numbers: "+ts(shownum))
	mytextout (30, 30*16, 0, "4) show connections: "+ts(showcon))
	mytextout (30, 29*16, 0, "5) hovering connections: "+ts(showhov))

	mytextout (30, 27*16, 0, "8) connection cutting: "+tc(togglecut))
	mytextout (30, 26*16, 0, "9) connection groups: "+tt(togglegrp))
	mytextout (30, 25*16, 0, "0) connection territory: "+tt(toggleter))

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

		i = InKey
		If i="1" Then gametype = 1 : spieler = 1
		If i="2" Then gametype = 1 : spieler = 2
		If i="3" Then gametype = 2 : spieler = 1
		If i="4" Then gametype = 2 : spieler = 2
		If i="5" Then gametype = 3 : spieler = 0

		Flip
	Loop While gametype=0

	BS = 0
	Do
		glClear (GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT)

		mycolor (CBOARD)
		mytextout (450, 30*16, 0, "RealGo")
		mytextout (430, 24*16, 0, "0) 9x9 board")
		mytextout (430, 22*16, 0, "1) 11x11 board")
		mytextout (430, 20*16, 0, "3) 13x13 board")
		mytextout (430, 18*16, 0, "5) 15x15 board")
		mytextout (430, 16*16, 0, "7) 17x17 board")
		mytextout (430, 14*16, 0, "9) 19x19 board")

		i = InKey
		If i="0" Then BS = 9
		If i="1" Then BS = 11
		If i="3" Then BS = 13
		If i="5" Then BS = 15
		If i="7" Then BS = 17
		If i="9" Then BS = 19

		Flip
	Loop While BS=0
End Sub


' input stuff on opengl screen
'
Function myinput (ByRef x As Integer, ByRef y As Integer) As Integer
	Dim As String i, s
	Dim As Integer t

	viewport (VMENU)
	glDisable (GL_DEPTH_TEST)
	Do
		mybox (30, 22*16+4, 200, 20*16+4, 0.1, CBOARD)
		mycolor (stonecolor (stonenr))
		mytextout (38, 21*16, 0.1, "input x,y: "+s)
		i = InKey
		If i=Chr(13) Then Exit Do
		If i=Chr(8) Then s = Left(s,Len(s)-1) : Continue Do
		If Asc(i)>=32 And Asc(i)<128 Then s += i
		Flip
	Loop
	glEnable (GL_DEPTH_TEST)
	t = InStr(s,",")
	If t=0 Then Return 0
	x = Val(Mid(s,1,t-1))
	y = Val(Mid(s,t+1,Len(s)-t))
	Return 1
End Function


' show board pixels
'

Dim Shared As UByte Ptr texdat
Dim Shared As Integer texname

Sub showtexture ()
	Dim As UByte Ptr a
	Dim As Integer x, y, c

	a = texdat
	For y = 0 To BAS-1
		For x = 0 To BAS-1
			c = col(ba(x,y))
			*a = (c Shr 16) And 255 : a += 1
			*a = (c Shr 8) And 255 : a += 1
			*a = c And 255 : a += 1
		Next
	Next

	glEnable (GL_TEXTURE_2D)

	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
	glPixelStorei (GL_PACK_ALIGNMENT, 1)
	glPixelStorei (GL_UNPACK_ALIGNMENT, 1)
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGB8, BAS, BAS, 0, GL_RGB, GL_UNSIGNED_BYTE, texdat)

	glColor3f (1,1,1)
	glBegin (GL_TRIANGLE_STRIP)
	glTexCoord2f (0, 0) : glVertex2f (0, 0)
	glTexCoord2f (1, 0) : glVertex2f (BAS, 0)
	glTexCoord2f (0, 1) : glVertex2f (0, BAS)
	glTexCoord2f (1, 1) : glVertex2f (BAS, BAS)
	glEnd ()

	glDisable (GL_TEXTURE_2D)
End Sub


' open graphics display
'
Sub openscreen ()
	Dim As HWND hwnd
	Dim As HDC hdc
	Dim As HGLRC hglrc
	Dim As HFONT hfont
	Dim As Integer mode

	'Screen 0
	If togglefullscreen Then
		mode = ScreenList(24)
		While mode<>0
			SCRX = HiWord(mode)
			SCRY = LoWord(mode)
			mode = ScreenList()
		Wend
		'SCRX = 1366
		'SCRY = 768
		ScreenRes SCRX,SCRY,24,,FB.GFX_OPENGL Or FB.GFX_MULTISAMPLE Or FB.GFX_FULLSCREEN
	Else
		SCRX = WINX
		SCRY = WINY
		ScreenRes SCRX,SCRY,24,,FB.GFX_OPENGL Or FB.GFX_MULTISAMPLE
	EndIf

	ScreenControl (FB.GET_WINDOW_HANDLE, Cast (Integer, hwnd))
	'MoveWindow (hwnd, 0, 0, SCRX, SCRY, 1)
	hdc = GetDC (hwnd)
	hglrc = wglCreateContext (hdc)
	wglMakeCurrent (hdc, hglrc)
	hfont = CreateFont (16, 8, 0, 0, FW_DONTCARE, 0, 0, 0, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS, _
	CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FIXED_PITCH, @"Fixedsys")
	SelectObject (hdc, hfont)
	'SelectObject (hdc, GetStockObject (SYSTEM_FONT))
	wglUseFontBitmaps (hdc, 0, 255, 1000)
	DeleteObject (hfont)

	glClearColor (0.5, 0, 0, 1)		' background color
	glEnable (GL_DEPTH_TEST)
End Sub


' main
'
Sub main ()
	Dim As Integer mx, my, wheel, button, lbuttoncnt, rbuttoncnt
	Dim As Integer x, y, t, wantinput, oldmx, oldmy, owheel
	Dim As Integer hovering, showtex, showar
	Dim As String i

	openscreen ()

	viewport (VSCREEN)
	startmenu ()

	MAXSTONES = BS^2
	ReDim stones(MAXSTONES)

	MAXCONS = MAXSTONES*3
	ReDim conl(MAXCONS)

	BAS = BS*DD+1
	ReDim ba(BAS,BAS), bb(BAS,BAS)

	If gametype=1 Then
		If spieler=1 Then ChDir (GETMAILDIR2)
		If spieler=2 Then ChDir (GETMAILDIR1)
	EndIf

	showinf = 0
	showlib = 1
	showcon = 1
	showhov = 1
	shownum = 1
	showarea = 0
	togglecut = 1
	togglegrp = 3
	toggleter = 3

	initboard ()
	makestone ()

	stonenr = 1

	texdat = Allocate (3*BAS*BAS)
	glGenTextures (1, @texname)
	glBindTexture (GL_TEXTURE_2D, texname)

	Do
		glClear (GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT)

		viewport (VMENU)
		drawmenu ()

		viewport (VBOARD)
		If showtex Then
			showtexture ()
		Else
			drawboard ()
			drawstones ()
		EndIf

		oldmx = mx : oldmy = my : owheel = wheel
		GetMouse mx,my,wheel,button
		mx = mx-LL
		my = (SCRY-1)-my
		If button=0 Then lbuttoncnt = 0 : rbuttoncnt = 0
		If button=1 Then lbuttoncnt += 1
		If button=2 Then rbuttoncnt += 1
		If wheel<owheel Then zoom *= 1.1
		If wheel>owheel Then zoom /= 1.1

		If rbuttoncnt>0 Then
			panx += (oldmx-mx)*zoom
			pany += (oldmy-my)*zoom
		EndIf
		x = (mx-(SCRX-LL)/2)*zoom + (SCRX-LL)/2 + panx
		y = (my-SCRY/2)*zoom + SCRY/2 + pany

		searchnearest (x, y)		' byref! sets x and y

		hovering = 0
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
				If wantinput=0 Then
					drawstone (x, y, stonenr)		' draw hovering stone
					If showhov Then
						stones(stonenr).x = x
						stones(stonenr).y = y
						hovering = 1
					EndIf
				EndIf
			EndIf
		EndIf

		makeconnections ()
		If togglecut>0 Then cutconnections ()
		If showcon Then drawconnections ()

		If hovering=1 Then
			stones(stonenr).x = 0
			stones(stonenr).y = 0
			makeconnections ()
			If togglecut>0 Then cutconnections ()
		EndIf

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
			If myinput (x, y)<>0 Then		' byref! sets x and y
				setstone (x, y)
			EndIf
			wantinput = 0
		EndIf


		i = InKey
		If i=Chr(27) Then Exit Do

		If i="s" Then savestones ()
		If i="l" Then loadstones () : redrawboard ()
		If i="m" Then stonenr += 1
		If i="k" Then
			t = findneareststone (x, y)
			If t>0 Then killstone (t) : redrawboard ()
		EndIf
		If i="i" Then wantinput = 1
		If i="p" Then showtex Xor= 1

		If i="f" Then
			togglefullscreen Xor= 1
			openscreen ()
		EndIf
		
		If i="a" Then showar Xor= 1
		If showar Then
			For x = 0 To SAS-1
				For y = 0 To SAS-1
					mybox (x*4, y*4, x*4+4, y*4+4, 1, ar(x,y))
				Next
			Next
		EndIf

		If i="t" Then showarea Xor=1

		If i="1" Then showinf Xor= 1
		If i="2" Then showlib Xor= 1
		If i="3" Then shownum Xor= 1
		If i="4" Then showcon Xor= 1
		If i="5" Then showhov Xor= 1

		If i="8" Then togglecut += 1 : togglecut Mod= 3
		If i="9" Then togglegrp += 1 : togglegrp Mod= 4
		If i="0" Then toggleter += 1 : toggleter Mod= 4

		Flip
	Loop

End Sub
