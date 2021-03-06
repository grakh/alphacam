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
     
     If frmMain.OptionButton4.Value Then
     
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

Public Sub CountGeo(Geos, NG, CountG)

    Dim geoLenght As Double
    Dim NamberGeo, N, namberG As Integer

For N = 1 To Geos.Count
        ' N = N + 1
' MsgBox ("Count = " & NG(N))
        namberG = NG(N)
        CountG(NamberGeo) = N * 2
        geoLenght = geoLenght + Geos(namberG).Length * 2
        If geoLenght > frmMain.TextBox7.Text Then

                NamberGeo = NamberGeo + 1
                geoLenght = 0
                ' MsgBox ("Count = " & N)

        End If
    Next N
End Sub

Public Function OrderGeo(Geos, PathXYLen) As Integer()


Dim GeoCol As Collection
Dim tempArr() As Integer
Dim var As Collection

    
    
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


If frmMain.OptionButton1.Value Then
    
     Set GeoCol = SetCollectionY(Geos)
     ReDim tempArr(GeoCol.Count)
     Set var = SortX(GeoCol, PathXYLen)
    
ElseIf frmMain.OptionButton2.Value Then
 
    Set GeoCol = SetCollectionX(Geos)
    ReDim tempArr(GeoCol.Count)
    Set var = SortY(GeoCol, PathXYLen)

End If

    For B = 1 To var.Count

        tempArr(B) = var(B).Name
        
    Next B
     
    
    OrderGeo = tempArr
    
End Function

