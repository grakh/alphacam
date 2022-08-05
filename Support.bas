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

Public Sub CountGeo(Geos, NG, CountG, GeoMax)

    Dim geoLenght, GeoMaxCount As Double
    Dim NamberGeo, N, namberG, temp, delta, countP As Integer
    Dim flag As Boolean
    flag = frmMain.OptionButton2.Value
    NamberGeo = 1

    delta = Round(Geos(1).MaxYL - Geos(1).MinYL) - 1
    If flag Then delta = Round(Geos(1).MaxYL - Geos(1).MinYL) - 1 Else delta = Round(Geos(1).MaxXL - Geos(1).MinXL) - 1
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
               
               GeoMaxCount = GeoMaxCount + GeoMax / countP
                NamberGeo = NamberGeo + 1
                geoLenght = 0
                
        End If
        
        If temp >= Round(GeoMax - delta) Then GeoMaxCount = GeoMax / countP
    Next N
End Sub

Public Function OrderGeo(Geos, PathXYLen) As Integer()


Dim GeoCol As Collection
Dim tempArr() As Integer
Dim delta As Integer
Dim var As Collection
Dim check As Boolean


delta = Round(Geos(1).MaxYL - Geos(1).MinYL) - 1
    
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
    
     Set GeoCol = SetCollectionY(Geos, delta)
     ReDim tempArr(GeoCol.Count)
     Set var = SortX(GeoCol, PathXYLen, delta)
    
Else:
 
    Set GeoCol = SetCollectionX(Geos, delta)
    ReDim tempArr(GeoCol.Count)
    Set var = SortY(GeoCol, PathXYLen, delta)

End If

    For B = 1 To var.Count

        tempArr(B) = var(B).Name
        
    Next B
     
    
    OrderGeo = tempArr
    
End Function

