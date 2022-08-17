Attribute VB_Name = "Functions"

Public Function SortY(GeoCol, PathXYLen, delta)

    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var As Collection
    Set var = New Collection

    Dim oldGeo As Collection

    Set oldGeo = GeoCol
T = 1
    For J = 1 To oldGeo.Count
        TempY = 2000
        For Each Y In oldGeo
            If Y.Y < TempY Then
               TempY = CInt(Y.Y)
            End If
        Next Y
        ' MsgBox "temp = " & TempY
        M = 0
        
        For Each a In oldGeo
        M = M + 1
        
            If ((TempY - delta) < CInt(a.Y) And CInt(a.Y) < (TempY + delta)) Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1

                var.Add a
                var(S).Ind = S
                oldGeo.Remove M
                M = M - 1
            End If
        Next a
        PathXYLen(T) = S
        T = 2
     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
    
    Set SortY = var
  
End Function

Public Function SortX(GeoCol, PathXYLen, delta)

    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var As Collection
    Set var = New Collection

    Dim oldGeo As Collection

    Set oldGeo = GeoCol
T = 1
    For J = 1 To oldGeo.Count
        TempX = 2000
        For Each X In oldGeo
            If X.X < TempX Then
               TempX = CInt(X.X)
            End If
        Next X
        ' MsgBox "temp = " & TempY
        M = 0
        
        For Each a In oldGeo
        M = M + 1
        
            If ((TempX - delta) < CInt(a.X) And CInt(a.X) < (TempX + delta)) Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                
                var.Add a
                var(S).Ind = S
                oldGeo.Remove M
                M = M - 1
            End If
        Next a
        PathXYLen(T) = S
        T = 2
     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
    
    Set SortX = var
    
End Function

Public Function SetCollectionX(Geos, delta) As Collection

    Dim MyRecord As New GeoClass
    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var, oldGeos As Collection
    Set var = New Collection
    Set oldGeos = New Collection

    For I = 1 To Geos.Count

        MyRecord.Name = I
        ' CInt(Right(Geos(I).Name, Len(Geos(I).Name) - 4))
        MyRecord.Ind = I
        MyRecord.X = Geos(I).MinXL
        MyRecord.Y = Geos(I).MinYL
   
    ' MsgBox "MR Ind = " & MyRecord.Name
        'var.Add Item:=MyRecord, key:=CStr(I)
        oldGeos.Add Item:=MyRecord, key:=CStr(I)
        Set MyRecord = Nothing
   ' MsgBox "GC Ind = " & GeoCol(I).Ind
    Next I
    

    For J = 1 To Geos.Count
        TempX = 2000
        For Each X In oldGeos
            If X.X < TempX Then
               TempX = CInt(X.X)
            End If
        Next X
        'MsgBox "temp = " & TempX
        M = 0
        
        For Each a In oldGeos
        M = M + 1
            If ((TempX - delta) < CInt(a.X) And CInt(a.X) < (TempX + delta)) Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                var.Add a
                var(S).Ind = S
                oldGeos.Remove M
                M = M - 1
            End If

        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
  'MsgBox "Geos = " & Geos.Count & " var = " & var.Count
    Set SetCollectionX = var
    
End Function

Public Function SetCollectionY(Geos, delta) As Collection

    Dim MyRecord As New GeoClass
    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var, oldGeos As Collection
    Set var = New Collection
    Set oldGeos = New Collection

    For I = 1 To Geos.Count

        MyRecord.Name = I
        ' CInt(Right(Geos(I).Name, Len(Geos(I).Name) - 4))
        MyRecord.Ind = I
        MyRecord.X = Geos(I).MinXL
        MyRecord.Y = Geos(I).MinYL
   
    ' MsgBox "MR Ind = " & MyRecord.Name
        'var.Add Item:=MyRecord, key:=CStr(I)
        oldGeos.Add Item:=MyRecord, key:=CStr(I)
        Set MyRecord = Nothing
   ' MsgBox "GC Ind = " & GeoCol(I).Ind
    Next I
    

    For J = 1 To Geos.Count
        TempY = 2000
        For Each Y In oldGeos
            If Y.Y < TempY Then
               TempY = CInt(Y.Y)
            End If
        Next Y
        'MsgBox "temp = " & TempX
        M = 0

        For Each a In oldGeos
        M = M + 1
            If ((TempY - delta) < CInt(a.Y) And CInt(a.Y) < (TempY + delta)) Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1

                var.Add a
                var(S).Ind = S
                oldGeos.Remove M
                M = M - 1
            End If

        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
  'MsgBox "Geos = " & Geos.Count & " var = " & var.Count
    Set SetCollectionY = var
    
End Function

