Attribute VB_Name = "Functions"

Public Function SortY(tempArr, GeoCol)
    Dim S, K As Integer
    Dim tmpColX, tmpColY As Collection
    Dim YDim() As Integer
    Dim XTemp As Integer
    
    ReDim YDim(GeoCol.Count + 1)

   Set tmpColX = GeoCol
   Set tmpColY = New Collection


    For J = 1 To tmpColX.Count
        Temp = tmpColX(1).Y
        For I = 1 To tmpColX.Count
            If tmpColX(I).Y < Temp Then
                Temp = tmpColX(I).Y
            End If
        Next I
     ' MsgBox "Temp = " & Temp
     If Temp = 1000 Then Exit For
     
        S = 0
        For I = 1 To tmpColX.Count
            If tmpColX(I).Y = Temp Then
                S = S + 1
                YDim(S) = tmpColX(I).Ind
                ' MsgBox "Y- = " & YDim(S)
            End If
        Next I
  If S > 1 Then
    For a = 1 To S
        For I = 1 To S - 1
            If tmpColX(YDim(I)).X > tmpColX(YDim(I + 1)).X Then
                 YDim(I) = tmpColX(YDim(I + 1)).Ind
                 YDim(I + 1) = tmpColX(YDim(I)).Ind
            End If
        Next I
        ' MsgBox "Y+ = " & YDim(a)
    Next a
  End If

    For B = 1 To S
        ' MsgBox "B = " & B
        tmpColY.Add tmpColX(YDim(B))
        tempArr(K + B) = tmpColX(YDim(B)).Ind
        tmpColX(YDim(B)).Y = 1000
        ' MsgBox "ind = " & tempArr(K + B)
        ' & ", X = " & tmpColY(J).X & ", Y = " & tmpColY(J).Y
    Next B
    
    'For c = S To 1 Step -1
    '    tmpColX.Remove YDim(c)
    'Next c
        ' MsgBox "ind = " & tmpColY(J).Ind & ", X = " & tmpColY(J).X & ", Y = " & tmpColY(J).Y
        K = K + S
        ' MsgBox "indJ = " & tempArr(J)
    Next J
    

  
End Function

Public Function SortX(tempArr, GeoCol)
    Dim S, K As Integer
    Dim tmpColX, tmpColY As Collection
    Dim YDim() As Integer
    Dim XTemp As Integer
    
    ReDim YDim(GeoCol.Count + 1)
    'With CreateObject("System.Collections.ArrayList")
        'For Each it In GeoCol
        '    .Add it
        'Next
        ' SN = .toarray
            '.Sort
           ' MsgBox Join(.ToArray, vbLf)
        'For J = 0 To .Count - 1

         '   MsgBox .Item(J).X
        ' Next
        'End With
  
   'For Each Geo In GeoCol
    '    If Geo.Y <= tempX Then
   '         tempX = Geo.Y
   '         T = T + 1
    '    End If
  ' Next Geo
  
  
   Set tmpColX = GeoCol
   Set tmpColY = New Collection


    For J = 1 To tmpColX.Count
        Temp = tmpColX(1).X
        For I = 1 To tmpColX.Count
            If tmpColX(I).X < Temp Then
                Temp = tmpColX(I).X
            End If
        Next I
      ' MsgBox "Temp = " & Temp
     If Temp = 1000 Then Exit For
        S = 0
        For I = 1 To tmpColX.Count
         'MsgBox "X = " & tmpColX(I).X
            If Temp = tmpColX(I).X Then
            ' MsgBox "if = " & True
                S = S + 1
                YDim(S) = tmpColX(I).Ind
                 'MsgBox "Y- = " & YDim(S)
            End If
        Next I
        ' MsgBox "S = " & S
  If S > 1 Then
    For a = 1 To S
        For I = 1 To S - 1
            If tmpColX(YDim(I)).Y > tmpColX(YDim(I + 1)).Y Then
                 YDim(I) = tmpColX(YDim(I + 1)).Ind
                 YDim(I + 1) = tmpColX(YDim(I)).Ind
            End If
        Next I
         'MsgBox "Y+ = " & YDim(a)
    Next a
  End If

    For B = 1 To S
        ' MsgBox "B = " & B
        tmpColY.Add tmpColX(YDim(B))
        tempArr(K + B) = tmpColX(YDim(B)).Ind
        tmpColX(YDim(B)).X = 1000
        ' MsgBox "ind = " & tempArr(K + B)
        ' & ", X = " & tmpColY(J).X & ", Y = " & tmpColY(J).Y
    Next B
    
    'For c = S To 1 Step -1
    '    tmpColX.Remove YDim(c)
    'Next c
        ' MsgBox "ind = " & tmpColY(J).Ind & ", X = " & tmpColY(J).X & ", Y = " & tmpColY(J).Y
        K = K + S
        ' MsgBox "indJ = " & tempArr(J)
    Next J

        'MsgBox "T = " & T & ", K = " & K / T
    ' Set SortX = N
    
End Function

Public Function SetCollection(Geos) As Collection

    Dim MyRecord As New GeoClass
    Dim var As Collection
    Set var = New Collection

    For I = 1 To Geos.Count

        MyRecord.Ind = CInt(Right(Geos(I).Name, Len(Geos(I).Name) - 4))
        MyRecord.X = Geos(I).MinXL
        MyRecord.Y = Geos(I).MinYL
   
    ' MsgBox "MR Ind = " & MyRecord.Ind
        var.Add Item:=MyRecord, key:=CStr(I)
        Set MyRecord = Nothing
   ' MsgBox "GC Ind = " & GeoCol(I).Ind
    Next I
    
    Set SetCollection = var
    
End Function
