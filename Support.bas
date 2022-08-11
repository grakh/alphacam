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
    Dim InX, InY, OutX, OutY As Double
    
    InX = frmMain.TextBox2.Text
    InY = frmMain.TextBox3.Text
    OutX = frmMain.TextBox4.Text
    OutY = frmMain.TextBox5.Text
    
 For N = 1 To Geos.Count
 
     namberG = NG(N)
     LyrIN.Visible = True
     
     ' If frmMain.OptionButton4.Value Then
     If False Then
          Set GeoIn = Drw.AutoClose( _
            Geos(namberG).MaxXL - (Geos(namberG).MaxXL - Geos(namberG).MinXL) / 2, _
            Geos(namberG).MaxYL - (Geos(namberG).MaxYL - Geos(namberG).MinYL) / 2, 0.01)
          GeoIn.SetLayer (LyrIN)
          GeoIn.SetStartPoint Geos(namberG).MaxXL - InX, Geos(namberG).MaxYL - InY
          GeoIn.ToolInOut = acamINSIDE
          GeoInOut.Add (GeoIn)
          GeoIn.CW = True
    
        
            LyrIN.Visible = False
            LyrOUT.Visible = True
    
        
           Set GeoIn = Drw.AutoClose( _
            Geos(namberG).MaxXL - (Geos(namberG).MaxXL - Geos(namberG).MinXL) / 2, _
            Geos(namberG).MaxYL - (Geos(namberG).MaxYL - Geos(namberG).MinYL) / 2, 0.01)
           GeoIn.SetLayer (LyrOUT)
           GeoIn.SetStartPoint Geos(namberG).MaxXL - OutX, Geos(namberG).MaxYL - OutY
           GeoIn.ToolInOut = acamOUTSIDE
           GeoIn.CW = False
           GeoInOut.Add (GeoIn)
     
     Else:
     
          Set GeoIn = Drw.AutoClose(Geos(namberG).MaxXL - InX - 3, Geos(namberG).MaxYL - InY - 3, 0.01)
          GeoIn.SetLayer (LyrIN)
          GeoIn.SetStartPoint Geos(namberG).MaxXL - InX, Geos(namberG).MaxYL - InY
          GeoIn.ToolInOut = acamINSIDE
          GeoInOut.Add (GeoIn)
          GeoIn.CW = True
    
        
            LyrIN.Visible = False
            LyrOUT.Visible = True
    
        
           Set GeoIn = Drw.AutoClose(Geos(namberG).MaxXL - OutX - 3, Geos(namberG).MaxYL - OutY - 3, 0.01)
           GeoIn.SetLayer (LyrOUT)
           GeoIn.SetStartPoint Geos(namberG).MaxXL - OutX, Geos(namberG).MaxYL - OutY
           GeoIn.ToolInOut = acamOUTSIDE
           GeoIn.CW = False
           GeoInOut.Add (GeoIn)
        
    End If
        
    
    LyrOUT.Visible = False
    
    Next N
End Sub

Public Sub CountGeo(Drw, Geos, NG, CountG, GeoMax, iHOC, Measurement)

    Dim geoLenght, GeoMaxCountAs As Double
    Dim NamberGeo, N, namberG, temp, delta, countP As Integer
    Dim flag As Boolean

    Dim p1 As Path, p2 As Path
    Dim e1 As Element, e2 As Element
    Dim group As Integer
    Dim Namb As Long
    Dim XInt, YInt
    Dim E, Ex, Ey As Double
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
    NamberGeo = 1


    iHOC.Visible = True
     Drw.SetLayer (iHOC)
     


    delta = 10 'Round(Geos(1).MaxYL - Geos(1).MinYL) - 1
    If flag Then delta = Round(Geos(1).MaxYL - Geos(1).MinYL - 2) Else _
        delta = Round(Geos(1).MaxXL - Geos(1).MinXL - 2)
    countP = CInt(frmMain.TextBox6.Value)
    
    GeoMaxCount = GeoMax / countP
  ' MsgBox ("geoMax = " & geoMax & " GeoMaxCount = " & GeoMaxCount)
  
For N = 1 To Geos.Count
        ' N = N + 1
        

        namberG = NG(N)
      If flag Then temp = Round(Geos(namberG).MinYL) Else temp = Round(Geos(namberG).MinXL)

        CountG(NamberGeo) = N * 2
        geoLenght = geoLenght + Geos(namberG).Length * 2
        ' MsgBox ("temp = " & temp & " GeoMax = " & GeoMaxCount)

        If geoLenght > CInt(frmMain.TextBox7.Text) Or temp >= Round(GeoMaxCount - delta) Then
        
        
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
        
        Set p2 = Drw.Create2DLine(Ex, Ey, Ex + 2, Ey + 2)
        Measurement.Add CountG(NamberGeo), Array(Ex, Ey)
        
        Set p1 = Drw.CreateCircle(2, Ex, Ey)
        ' MsgBox ("keys = " & CountG(NamberGeo))
group = Drw.GetNextGroupNumberForGeometries
p2.group = group
p1.group = group
  ' MsgBox ("key = " & Measurement.Exists(6) & " x = " & Measurement.Item(6)(0) & " y = " & Measurement.Item(6)(1))
 
               GeoMaxCount = GeoMaxCount + GeoMax / countP
                NamberGeo = NamberGeo + 1
                geoLenght = 0
                ' GeoIhoc.SetLayer (iHOC)
        End If
        
        If temp >= Round(GeoMax) Then GeoMaxCount = GeoMax / countP
    Next N
    
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

