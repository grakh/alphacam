Attribute VB_Name = "Events"
Public Type Geor
      Ind As Integer    ' Geo name.
        X As Double     ' X coordinate.
        Y As Double     ' Y coordinate.
End Type


Public Function InitAlphacamAddIn(acamversion As Long) As Integer
    Dim fr As Frame
    Set fr = App.Frame
    
        With fr
            Dim ItemName As String, MenuName As String
            ItemName = "Primitive": MenuName = "Cutting"
            .AddMenuItem2 ItemName, "ShowfrmMain", acamMenuNEW, MenuName
        End With
    InitAlphacamAddIn = 0
End Function

Function ShowfrmMain()
    Load frmMain
    frmMain.Show
End Function
