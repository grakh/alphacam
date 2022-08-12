Attribute VB_Name = "MainM"
Public Function CreateonMoff()


    Dim Drw As Drawing
    Set Drw = App.ActiveDrawing
    Dim iHOC As Layer
    Dim P As Path
    Const ATTR As String = "LicomDECHMessZyklus"
    Dim V As Variant

On Error Resume Next
    Set iHOC = Drw.Layers("iHOC-System")
    If Err.Number <> 0 Then
        MsgBox "Layer iHOC not found", vbExclamation
        End
    End If
    
     


For Each P In Drw.ToolPaths
    
    V = P.Attribute(ATTR)
    
    If VarType(V) <> vbEmpty Then

        If iHOC.Visible Then P.Attribute(ATTR) = -1 Else P.Attribute(ATTR) = 1
        
    End If

Next P

    If iHOC.Visible Then
        iHOC.Visible = False
        fr.AddMenuItem2 "onM"
    Else:
        iHOC.Visible = True
        fr.AddMenuItem2 "Moff"
    End If
   ' Drw.Operations.Item(Drw.Operations.Count).Delete ' для черновой
 ' iHOC.Visible = True
    ' Drw.Options.ShowRapids = False
    ' Drw.ThreeDViews = True
    ' Drw.ZoomAll
    Drw.Redraw
    

    End
    
End Function
