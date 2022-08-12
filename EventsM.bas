Attribute VB_Name = "Events"
Public Function InitAlphacamAddIn(acamversion As Long) As Integer
    Dim fr As Frame
    Set fr = App.Frame
    
        With fr
            Dim ItemName As String, MenuName As String
            ItemName = "onMoff": MenuName = "Cutting"
            .AddMenuItem2 ItemName, "ShowfrmMain", acamMenuNEW, MenuName
        End With
    InitAlphacamAddIn = 0
End Function

Function ShowfrmMain()
    MainM.CreateonMoff
End Function

