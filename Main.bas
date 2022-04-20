Attribute VB_Name = "Main"

Public Function CreatePrimitive( _
    Order As String _
    )

    Dim Drw As Drawing
    Set Drw = App.ActiveDrawing
    Dim LyrIN, LyrOUT, Lyr As Layer
    Dim NG(60), CountG(60) As Integer
    Dim GeoInOut, GeoRev As Paths
    Dim ret As String
    Dim Geos As Paths
    
    
    Collection Drw, Geos, LyrIN, LyrOUT, NG, GeoInOut, CountG

    Mill Drw, Geos.Count, LyrIN, LyrOUT, NG, GeoInOut, CountG
    
  'MsgBox ("N = " & Drw.Operations.Item(1).Number)
   Drw.Operations.Item(Drw.Operations.Count).Delete
 
    ' Drw.Options.ShowRapids = False
    ' Drw.ThreeDViews = True
    Drw.ZoomAll
    Drw.Redraw
    
    'App.Run (MacroName, [Parm1], [Parm2], [Parm3], [Parm4], [Parm5], [Parm6], [Parm7], [Parm8])
    ' ret = App.Run(Anderson_Gravur, Main.GetGeoPoint(Format(0, 0)), Main.MessZyklusEntfernen(Format(0, 0)), Main.SetMessZyklusEinfuegen(Format(0, 0)))
    End
    
End Function
' Do multiple rough/finish paths on selected geometries.
' The geometries are selected using a Paths Collection so
' they can be reselected with a single command.

Public Sub Collection2(Drw, Geos, LyrIN, LyrOUT)

        
    
    Set LyrIN = Drw.CreateLayer("IN")
    LyrIN.Color = acamRED
    ' Set GeosIN = lyrIN.CreateCollections
    
    Set LyrOUT = Drw.CreateLayer("OUT")
    LyrOUT.Color = acamRED
    ' Set GeosOUT = lyrOUT.CreateCollections


   
    Set Geos = Drw.UserSelectMultiGeosCollection("Multi Finish: Select Geometries", 0)
    If Geos.Count = 0 Then End

    ' Set tool sides for rough/finish
    Geos.Selected = True
    
    ' Drw.SetToolSideAuto acamToolSidePOCKET
    
      Dim Geo As Path
    For Each Geo In Geos
        Geo.ToolInOut = acamINSIDE
        'Geo.SetStartPoint 800, 600
        Geo.Copy.SetLayer (LyrIN)
        Geo.ToolInOut = acamOUTSIDE
        'Geo.SetStartPoint 800, 600
        Geo.Copy.SetLayer (LyrOUT)
    Next Geo
    
      Geos.Selected = False
        
   
End Sub

' Try to select given Mill tool.
' If not successful, ask the user to select a tool.
' Illustrates error handling.

Private Sub GetMillTool(Name As String, Comb As String) ' Name of tool, eg "Flat - 10mm", no folder or extension
    ' Enable error handling
    On Error Resume Next
    ' Try to select given tool
    App.SelectTool App.LicomdatPath & "LICOMDAT\MTOOLS.ALP\GVM_TOOLS\STD_D" & Comb & "base" & Name & "°.AMT"
    If Err.Number <> 0 Then
        ' Failed so ask user
        Err.Clear
        Dim F1 As String, F2 As String
        If Not App.GetAlphaCamFileName(Name & " not found: Select Tool", acamFileTypeTOOL, acamFileActionOPEN, F1, F2) Then
            End
        End If
        ' Select chosen tool
        App.SelectTool F1
    End If
End Sub


Public Sub Collection(Drw, Geos, LyrIN, LyrOUT, NG, GeoInOut, CountG)

    Dim Geo As Path
    Dim GeoIn, GeoOut As Path
    Dim rev, res As Boolean
    Dim J, J1 As Integer
    Dim ArrGeo() As Integer
    
    
    Set GeoInOut = Drw.CreatePathCollection
    
    rev = False
    res = False

    Set LyrIN = Drw.CreateLayer("IN")
    LyrIN.Color = acamYELLOW
    
    Set LyrOUT = Drw.CreateLayer("OUT")
    LyrOUT.Color = acamYELLOW



   
    Set Geos = Drw.UserSelectMultiGeosCollection("Multi Finish: Select Geometries", 0)
    If Geos.Count = 0 Then End
NG(0) = 0
CountG(0) = 0
NamberGeo = 1

ArrGeo = OrderGeo(Geos)
For Each R In ArrGeo

  ' MsgBox ("ArrGeo = " & R)
Next R

  'If Geos.Count > 2 Then
  '      If Geos(1).MinYL > Geos(2).MinYL Then rev = True
        
  '  For J = 2 To Geos.Count
        ' MsgBox ("J = " & Geos(J).MinYL & ", J1 = " & Geos(J1).MinYL)
  '      If Geos(1).MinXL > Geos(J).MinXL Then
   '         res = True
   '         Exit For
   '     End If
   ' Next J
  'End If
    
    ' MsgBox ("rev = " & rev & ", res = " & res & ", J = " & J)

    'If rev Then InOutReversY Geos, NG
    'If res Then InOutReversX Geos, NG
    
    'If rev And res Then
    '    InOutReversX Geos, NG
    '    InOutReversY Geos, NG
    'ElseIf Not rev And Not res Then
    '    InOutXY Geos, NG
    'End If
    
    ' MsgBox ("Count = " & NG(1))
    'CountGeo Geos, ArrGeo, CountG
    InOutAutoClose Drw, Geos, LyrIN, LyrOUT, GeoIn, GeoInOut, ArrGeo
    
    LyrIN.Visible = False
    LyrOUT.Visible = False

    
End Sub

Public Sub Mill(Drw, GeosCount, LyrIN, LyrOUT, NG, GeoInOut, CountG)
Dim J, a, DOc As Integer
Dim PathLen As Double

  GetMillTool frmMain.ComboBox2.Text, frmMain.ComboBox1.Text
  

 Dim TpsIn, TpsOut As Paths
 Dim LD As LeadData
 Dim MD As MillData

 ' get a suboperation



 Set MD = App.CreateMillData

Set LD = App.CreateLeadData
With LD
 ' change the leaddata
    .LeadIn = acamLeadBOTH
    .LengthIn = 1
    .RadiusIn = 1
    .AngleIn = 45
    .LineArcInTangential = True
    .LeadOut = acamLeadBOTH
    .LengthOut = 1
    .RadiusOut = 1
    .AngleOut = 45
    .LineArcOutTangential = True
End With
' (re)set the new leaddata for the milldata
MD.SetLeadData LD
    DOc = Drw.Operations.Count
    ' MsgBox ("OpNo = " & DOc)
        MD.OpNo = 1
        MD.SafeRapidLevel = 10
        MD.RapidDownTo = 3
        MD.MaterialTop = 0.25
        MD.FinalDepth = 0
        MD.XYCorners = acamCornersSTRAIGHT
        MD.McComp = acamCompMC
        MD.NumberOfCuts = 1
        
        
Drw.SetLayer Nothing
        ' MD.Attribute("LicomUKDMBOperationName") = "MANUAL WITH TOOL COMP"
 'LyrIN.Geometries.Selected = True
 'LyrOUT.Geometries.Selected = True
    GeoInOut.Selected = True
'MsgBox ("GeoInOut = " & GeoInOut.Count)

Set TpsIn = MD.RoughFinish

' LyrIN.Geometries.Selected = False
' LyrOUT.Geometries.Selected = True

' GeoInOut.Selected = True
' Set TpsOut = MD.RoughFinish

 Drw.SetLayer Nothing

J = 1

        ' Apply lead-in/out on the new tool paths
    For I = 1 To TpsIn.Count
    
        If (I Mod 2 <> 0) Then
     '  If (CountG(j)) < i Then
            J = J + 1
        End If
            TpsIn(I).OpNo = J + DOc


            ' TpsIn(a).CW = True
            
          ' If (N Mod 2 = 0) Then
            'TpsIn(i).SetStartPoint 800, 600
            'TpsIn(i).SetLeadInOutAuto acamLeadBOTH, acamLeadBOTH, 1, 1, 45, False, False, 0

            ' TpsOut(i).OpNo = j + DOc
            ' TpsOut(a).CW = False
          
     Next I
     

        'LyrIN.Geometries.Selected = True
        'LyrOUT.Geometries.Selected = True
        GeoInOut.Selected = True
        MD.OpNo = J + DOc + 1

     'MDin.RoughFinishUsePreviousMachining = True
        MD.RoughFinish
        
    'LyrIN.Visible = False
    'LyrOUT.Visible = False
    
End Sub
