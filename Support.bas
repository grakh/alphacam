Attribute VB_Name = "Support"
Public Sub InOutXY(Geos, NG)

For N = 1 To Geos.Count

        NG(N) = N
        
    Next N
End Sub

Public Sub InOutReversX(Geos, NG)

    Dim geoLenght As Double
    Dim I, N As Integer

For N = Geos.Count To 1 Step -1
        I = I + 1
        NG(I) = N
      ' MsgBox ("N = " & I & ", Count = " & NG(N))
    Next N
End Sub

Public Sub InOutReversY(Geos, NG)

    Dim geoLenght As Double
    Dim I, N As Integer

    For N = Geos.Count To 1 Step -1
        I = I + 1
        NG(I) = N
        ' MsgBox ("N = " & I & ", Count = " & NG(N))
    Next N
    
End Sub

Public Sub InOutAutoClose(Drw, Geos, LyrIN, LyrOUT, GeoIn, GeoInOut, NG)

    Dim namberG As Integer
    Dim InX, InY, OutX, OutY, delta As Double
    Dim IO() As Double
    Dim Tog As Double
    
    If frmMain.ToggleButton1.Value Then Tog = 0.5 Else Tog = -2
    
    delta = frmMain.TextBox3.Value
    If delta >= 0 Then
        InX = delta
        InY = 0
    Else:
        InX = 0
        InY = Abs(delta)
    End If
    
    delta = frmMain.TextBox5.Value
    If delta >= 0 Then
        OutX = delta
        OutY = 0
    Else:
        OutX = 0
        OutY = Abs(delta)
    End If
    
    
 For N = 1 To Geos.Count
 
     namberG = NG(N)
     LyrIN.Visible = True
     
     IO = inOut(Geos(namberG), InX, InY, OutX, OutY)
     
     ' If frmMain.OptionButton4.Value Then
     If False Then
          Set GeoIn = Drw.AutoClose( _
            Geos(namberG).MaxXL - (Geos(namberG).MaxXL - Geos(namberG).MinXL) / 2, _
            Geos(namberG).MaxYL - (Geos(namberG).MaxYL - Geos(namberG).MinYL) / 2, 0.001)
          GeoIn.SetLayer (LyrIN)
          GeoIn.SetStartPoint Geos(namberG).MaxXL - InX, Geos(namberG).MaxYL - InY
          GeoIn.ToolInOut = acamINSIDE
          GeoInOut.Add (GeoIn)
          GeoIn.CW = True
    
        
            LyrIN.Visible = False
            LyrOUT.Visible = True
    
        
           Set GeoIn = Drw.AutoClose( _
            Geos(namberG).MaxXL - (Geos(namberG).MaxXL - Geos(namberG).MinXL) / 2, _
            Geos(namberG).MaxYL - (Geos(namberG).MaxYL - Geos(namberG).MinYL) / 2, 0.001)
           GeoIn.SetLayer (LyrOUT)
           GeoIn.SetStartPoint Geos(namberG).MaxXL - OutX, Geos(namberG).MaxYL - OutY
           GeoIn.ToolInOut = acamOUTSIDE
           GeoIn.CW = False
           GeoInOut.Add (GeoIn)
     
     Else:
     
          Set GeoIn = Drw.AutoClose(IO(0) + Tog, IO(1) + Tog, 0.001)
          GeoIn.SetLayer (LyrIN)
          GeoIn.SetStartPoint IO(0), IO(1)
          GeoIn.ToolInOut = acamINSIDE
          GeoInOut.Add (GeoIn)
          GeoIn.CW = True
    
        
            LyrIN.Visible = False
            LyrOUT.Visible = True
    
        
           Set GeoIn = Drw.AutoClose(IO(0) + Tog, IO(1) + Tog, 0.001)
           GeoIn.SetLayer (LyrOUT)
           GeoIn.SetStartPoint IO(2), IO(3)
           GeoIn.ToolInOut = acamOUTSIDE
           GeoIn.CW = False
           GeoInOut.Add (GeoIn)
        
    End If
        
    
    LyrOUT.Visible = False
    
    Next N
End Sub

Public Sub CountGeo(Drw, Geos, NG, CountG, GeoMax, iHOC, Measurement, GeoMin)

    Dim geoLenght, GeoMaxCountAs As Double
    Dim NamberGeo, N, namberG, temp, delta, countP As Integer
    Dim flag As Boolean

    Dim p1 As Path, p2 As Path
    Dim e1 As Element, e2 As Element
    Dim group As Integer
    Dim Namb As Long
    Dim XInt, YInt
    Dim E, Ex, Ey, Leng As Double
    Dim deltaMeasure, deltaMeasureX, deltaMeasureY As Double
    deltaMeasure = frmMain.TextBox12.Value
    If deltaMeasure >= 0 Then
        deltaMeasureY = deltaMeasure
        deltaMeasureX = 0
    Else:
        deltaMeasureY = 0
        deltaMeasureX = Abs(deltaMeasure)
    End If
 
    flag = frmMain.OptionButton2.Value
    flagM = frmMain.CheckBox3.Value
    
    NamberGeo = 1
   CountG(0) = 0

    iHOC.Visible = True
     Drw.SetLayer (iHOC)
     


    delta = 10 'Round(Geos(1).MaxYL - Geos(1).MinYL) - 1
    If flag Then delta = Round(Geos(1).MaxYL - Geos(1).MinYL - 2) Else _
       delta = Round(Geos(1).MaxXL - Geos(1).MinXL - 2)
       
    countP = CInt(frmMain.TextBox6.Value)
    
    GeoMaxCount = Round(((GeoMax - GeoMin) / countP) + GeoMin - delta)
    tempGMCount = Round((GeoMax - GeoMin) / countP)
  ' MsgBox ("GeoMax = " & GeoMax & " GeoMin = " & GeoMin & " GeoMaxCount = " & GeoMaxCount)
  
For N = 1 To Geos.Count
        ' N = N + 1
        

        namberG = NG(N)
      If flag Then temp = Round(Geos(namberG).MinYL) Else temp = Round(Geos(namberG).MinXL)

        CountG(NamberGeo) = N * 2
        geoLenght = geoLenght + Geos(namberG).Length * 2
        ' MsgBox ("temp = " & temp & " GeoMax = " & GeoMaxCount & " delta = " & delta)

        If geoLenght >= CInt(frmMain.TextBox7.Text) Or temp >= GeoMaxCount Or N = Geos.Count Or temp >= (GeoMax - delta) Then
        
        
       ' h = (Geos(namberG).MaxXL - Geos(namberG).MinXL + Geos(namberG).MaxYL - Geos(namberG).MinYL) / 80


         'Set p2 = Drw.Create2DLine(Geos(namberG).MinXL, Geos(namberG).MinYL, Geos(namberG).MaxXL, Geos(namberG).MaxYL)
         'Set e2 = p2.GetFirstElem
      
        'For Each e1 In Geos(namberG).Elements
            'nam = Geos(namberG).Intersect(p2, x1#, y1#, x2#, y2#)
        'Next e1
        
        ' MsgBox ("x1 = " & x1# & " y1 = " & y1# & " x2 = " & x2# & " y2 = " & y2#)
                
        'If y1# < y2# Then Set p1 = Drw.CreateCircle(2, x1#, y1#) Else
        ' Ex = (Geos(namberG).MaxXL + Geos(namberG).MinXL) / 2
        ' Ey = (Geos(namberG).MaxYL + Geos(namberG).MinYL) / 2
        ' Set p2 = Drw.Create2DLine(Geos(namberG).MinXL, Geos(namberG).MinYL, Ex, Ey)
        Namb = Geos(namberG).IntersectWithLine(Geos(namberG).MinXL + deltaMeasureX, _
            Geos(namberG).MinYL + deltaMeasureY, Geos(namberG).MaxXL, _
            Geos(namberG).MaxYL, True, XInt, YInt)
            Ex = XInt(0)
            Ey = YInt(0)
        For X = 0 To Namb - 1
            If XInt(X) < Ex Then
                Ex = XInt(X)
                Ey = YInt(X)
            End If
        Next X
        
        Measurement.Add CountG(NamberGeo), Array(Ex, Ey)
If flagM Then
        Set p2 = Drw.Create2DLine(Ex, Ey, Ex + 5, Ey + 5)
        Set p1 = Drw.CreateCircle(2, Ex, Ey)
        ' MsgBox ("keys = " & NamberGeo)
    group = Drw.GetNextGroupNumberForGeometries
    p2.group = group
    p1.group = group
End If
  ' MsgBox ("key = " & Measurement.Exists(6) & " x = " & Measurement.Item(6)(0) & " y = " & Measurement.Item(6)(1))
 
               GeoMaxCount = GeoMaxCount + tempGMCount
                NamberGeo = NamberGeo + 1
                geoLenght = 0
                ' MsgBox ("GeoMaxCount = " & GeoMaxCount)
                ' GeoIhoc.SetLayer (iHOC)
        End If
        
        If temp >= (GeoMax - delta) Then GeoMaxCount = Round(((GeoMax - GeoMin) / countP) + GeoMin - delta)
    Next N
    ' MsgBox ("M = " & Measurement.Count)
    iHOC.Visible = False
End Sub

Public Function OrderGeo(Geos, PathXYLen) As Integer()


Dim GeoCol As Collection
Dim tempArr() As Integer
Dim deltaX, deltaY As Integer
Dim var As Collection
Dim check As Boolean

    flag = frmMain.OptionButton1.Value


    deltaY = Round(Geos(1).MaxYL - Geos(1).MinYL - 2)
    deltaX = Round(Geos(1).MaxXL - Geos(1).MinXL - 2)
    
'With CreateObject("System.Collections.SortedList")
'For Each it In GeoCol
'    .Add it.Ind, .Count
'Next

'For J = .Count - 1 To 0 Step -1
'c00 = c00 & vbLf & .GetByIndex(J)
'Next

'MsgBox c00
'End With

' MsgBox "Count = " & GeoCol.Count
If frmMain.CheckBox1.Value Then check = frmMain.OptionButton1.Value Else check = frmMain.OptionButton2.Value
' If frmMain.CheckBox1.Value = False And CInt(frmMain.TextBox6.Value) > 1 Then check = Not check

If check Then
    
     Set GeoCol = SetCollectionY(Geos, deltaY)
     ReDim tempArr(GeoCol.Count)
     Set var = SortX(GeoCol, PathXYLen, deltaX)
    
Else:
 
    Set GeoCol = SetCollectionX(Geos, deltaX)
    ReDim tempArr(GeoCol.Count)
    Set var = SortY(GeoCol, PathXYLen, deltaY)

End If

    For B = 1 To var.Count

        tempArr(B) = var(B).Name
        
    Next B
     
    
    OrderGeo = tempArr
    
End Function

