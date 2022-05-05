Attribute VB_Name = "Functions"

Public Function SortY(tempArr, GeoCol)

    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var As Collection
    Set var = New Collection

    Dim oldGeo As Collection

    Set oldGeo = GeoCol

    For J = 1 To oldGeo.Count
        TempY = 1000
        For Each Y In oldGeo
            If Y.Y < TempY Then
               TempY = CInt(Y.Y)
            End If
        Next Y
        ' MsgBox "temp = " & TempY
        m = 0
        For Each a In oldGeo
        m = m + 1
            If CInt(a.Y) = TempY Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                var.Add a
                var(S).Ind = S
                oldGeo.Remove m
                m = m - 1
            End If
        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
    
    For B = 1 To var.Count

        tempArr(B) = var(B).Name
        
    Next B
  
End Function

Public Function SortX(tempArr, GeoCol)

    Dim TempX, TempY As Double
    Dim S As Integer
    Dim var As Collection
    Set var = New Collection

    Dim oldGeo As Collection

    Set oldGeo = GeoCol

    For J = 1 To oldGeo.Count
        TempX = 1000
        For Each X In oldGeo
            If X.X < TempX Then
               TempX = CInt(X.X)
            End If
        Next X
        ' MsgBox "temp = " & TempY
        m = 0
        For Each a In oldGeo
        m = m + 1
            If CInt(a.X) = TempX Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                var.Add a
                var(S).Ind = S
                oldGeo.Remove m
                m = m - 1
            End If
        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
    
    For B = 1 To var.Count

        tempArr(B) = var(B).Name
        
    Next B
    
End Function

Public Function SetCollectionX(Geos) As Collection

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
        TempX = 1000
        For Each X In oldGeos
            If X.X < TempX Then
               TempX = CInt(X.X)
            End If
        Next X
        'MsgBox "temp = " & TempX
        m = 0
        For Each a In oldGeos
        m = m + 1
            If CInt(a.X) = TempX Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                var.Add a
                var(S).Ind = S
                oldGeos.Remove m
                m = m - 1
            End If
        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
  'MsgBox "Geos = " & Geos.Count & " var = " & var.Count
    Set SetCollectionX = var
    
End Function

Public Function SetCollectionY(Geos) As Collection

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
        TempY = 1000
        For Each Y In oldGeos
            If Y.Y < TempY Then
               TempY = CInt(Y.Y)
            End If
        Next Y
        'MsgBox "temp = " & TempX
        m = 0
        For Each a In oldGeos
        m = m + 1
            If CInt(a.Y) = TempY Then
            ' MsgBox "temp = " & TempX & " m = " & m
                S = S + 1
                var.Add a
                var(S).Ind = S
                oldGeos.Remove m
                m = m - 1
            End If
        Next a

     ' MsgBox "Ind = " & var(J).Ind & ", Name = " & var(J).Name
    Next J
  'MsgBox "Geos = " & Geos.Count & " var = " & var.Count
    Set SetCollectionY = var
    
End Function

