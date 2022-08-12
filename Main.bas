Attribute VB_Name = "Main"

Public Function CreatePrimitive( _
    Order As String _
    )

    Dim Drw As Drawing
    Set Drw = App.ActiveDrawing
    Dim LyrIN, LyrOUT, Lyr, iHOC As Layer
    Dim NG(100), CountG(100) As Integer
    Dim GeoInOut, GeoRev As Paths
    Dim ret As String
    Dim Geos As Paths
    Dim PathXYLen(2) As Integer
    Dim Text6count, GeoMax, GeoMin As Integer
    Dim Measurement As New Dictionary
    
    PathXYLen(1) = 1
    
    Collection Drw, Geos, LyrIN, LyrOUT, NG, GeoInOut, CountG, PathXYLen, GeoMax, iHOC, Measurement, GeoMin

    Mill Drw, Geos.Count, LyrIN, LyrOUT, NG, GeoInOut, CountG, PathXYLen, GeoMax, Measurement
    
  'MsgBox ("N = " & Drw.Operations.Item(1).Number)
   ' Drw.Operations.Item(Drw.Operations.Count).Delete ' ��� ��������
 iHOC.Visible = True
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
    
      Dim geo As Path
    For Each geo In Geos
        geo.ToolInOut = acamINSIDE
        'Geo.SetStartPoint 800, 600
        geo.Copy.SetLayer (LyrIN)
        geo.ToolInOut = acamOUTSIDE
        'Geo.SetStartPoint 800, 600
        geo.Copy.SetLayer (LyrOUT)
    Next geo
    
      Geos.Selected = False
        
   
End Sub

' Try to select given Mill tool.
' If not successful, ask the user to select a tool.
' Illustrates error handling.

Private Sub GetMillTool(Name As String, Comb As String) ' Name of tool, eg "Flat - 10mm", no folder or extension
    ' Enable error handling
    On Error Resume Next
    ' Try to select given tool
    App.SelectTool App.LicomdatPath & "LICOMDAT\MTools.Alp\GVM_TOOLS\STD_D" & Comb & "base" & Name & "�.AMT"
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


Public Sub Collection(Drw, Geos, LyrIN, LyrOUT, NG, GeoInOut, CountG, PathXYLen, GeoMax, iHOC, Measurement, GeoMin)

    Dim geo As Path
    Dim GeoIn, GeoOut As Path
    Dim rev, res As Boolean
    Dim J, J1 As Integer
    Dim ArrGeo() As Integer
    Dim Chet As Double

    
    
    
    Set GeoInOut = Drw.CreatePathCollection
    
    rev = False
    res = False

    Set LyrIN = Drw.CreateLayer("IN")
    LyrIN.Color = acamYELLOW
    
    Set LyrOUT = Drw.CreateLayer("OUT")
    LyrOUT.Color = acamYELLOW

    Set iHOC = Drw.CreateLayer("iHOC-System")
    iHOC.Color = acamWHITE
    iHOC.Visible = False
   
    Set Geos = Drw.UserSelectMultiGeosCollection("Multi Finish: Select Geometries", 0)
    If Geos.Count = 0 Then End
NG(0) = 0
CountG(0) = 0
NamberGeo = 1

ArrGeo = OrderGeo(Geos, PathXYLen)
For Each R In ArrGeo

  ' MsgBox ("ArrGeo = " & R)
Next R


For Each it In Geos
    If frmMain.OptionButton1.Value Then
        If it.MinXL > GeoMax Then GeoMax = it.MinXL Else GeoMin = it.MinXL
    Else:
        If it.MinYL > GeoMax Then GeoMax = it.MinYL Else GeoMin = it.MinYL
    End If
Next
' MsgBox "GeoMaxX = " & GeoMaxX & "GeoMaxY = " & GeoMaxY

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
    CountGeo Drw, Geos, ArrGeo, CountG, GeoMax, iHOC, Measurement, GeoMin
    InOutAutoClose Drw, Geos, LyrIN, LyrOUT, GeoIn, GeoInOut, ArrGeo
    
    LyrIN.Visible = False
    LyrOUT.Visible = False

    
End Sub

Public Sub Mill(Drw, GeosCount, LyrIN, LyrOUT, NG, GeoInOut, CountG, PathXYLen, GeoMax, Measurement)
Dim J, a, DOc, D, K As Integer
Dim PathLen As Double
Const ATTR2 As String = "LicomDECHMessPunkt_X"
Const ATTR3 As String = "LicomDECHMessPunkt_Y"
Const ATTR1 As String = "LicomDECHMessZyklus"


  GetMillTool frmMain.ComboBox2.Text, frmMain.ComboBox1.Text
  

 Dim TpsIn, TpsOut As Paths
 Dim PIn As Path
 Dim LD As LeadData
 Dim MD As MillData
 Dim check, flag As Boolean
 
 flag = False

 ' get a suboperation



 Set MD = App.CreateMillData

Set LD = App.CreateLeadData
With LD
 ' change the leaddata
    .LeadIn = acamLeadBOTH
    .LengthIn = CDbl(frmMain.TextBox9.Value)
    .RadiusIn = CDbl(frmMain.TextBox9.Value)
    .AngleIn = CInt(frmMain.TextBox8.Value)
    .LineArcInTangential = True
    .LeadOut = acamLeadBOTH
    .LengthOut = CDbl(frmMain.TextBox11.Value)
    .RadiusOut = CDbl(frmMain.TextBox11.Value)
    .AngleOut = CInt(frmMain.TextBox10.Value)
    .LineArcOutTangential = True
End With
' (re)set the new leaddata for the milldata
MD.SetLeadData LD

    DOc = Drw.Operations.Count
    ' MsgBox ("OpNo = " & DOc)
        MD.OpNo = DOc + 1
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
' MsgBox ("PathXYLen = " & PathXYLen(1))

Set TpsIn = MD.RoughFinish

Drw.Operations.Item(Drw.Operations.Count).Delete ' ��� ��������
' LyrIN.Geometries.Selected = False
' LyrOUT.Geometries.Selected = True

' GeoInOut.Selected = True
' Set TpsOut = MD.RoughFinish

 Drw.SetLayer Nothing
 Drw.DeleteSelected
 
J = 1

' If frmMain.OptionButton3.Value Then J = 0
Chet = PathXYLen(1) / frmMain.TextBox6.Value

If PathXYLen(1) Mod Chet = 0 Then
    Text6count = 0
Else: Text6count = Fix(Chet) * frmMain.TextBox6.Value
End If

check = frmMain.CheckBox1.Value

        ' Apply lead-in/out on the new tool paths
    For I = 1 To GeoInOut.Count

        If check = False Then

            If (CountG(J)) < I Then
                ' MsgBox ("CountG = " & CountG(J))
                ' If Measurement.Exists(CountG(J)) Then
                ' End If
                J = J + 1
            End If
        Else:
             If (I Mod 2 <> 0) Then
                If Text6count <> 0 Then
                    If T = PathXYLen(1) Then
                        J = J + 1
                        T = 1
                        D = 0
                        Else: T = T + 1
                    End If
                 
                    If D = CInt(frmMain.TextBox6.Value) Then
                        If T < Text6count Then J = J + 1
                        D = 0
                        ' If flag Then J = 0
                    End If
                Else:
                        If D = CInt(frmMain.TextBox6.Value) Then
                            J = J + 1
                            D = 0
                        End If
                End If
                D = D + 1
              
            End If
            
        End If
        
        If I = CountG(J) Then
            ' MsgBox ("I = " & CountG(J))
            MD.Attribute(ATTR1) = 1
            MD.Attribute(ATTR2) = Measurement.Item(CountG(J))(0)
            MD.Attribute(ATTR3) = Measurement.Item(CountG(J))(1)
        Else:
            MD.DeleteAttribute (ATTR1)
            MD.DeleteAttribute (ATTR2)
            MD.DeleteAttribute (ATTR3)
        End If
        'TpsIn(I).OpNo = J + DOc

        MD.OpNo = J + DOc
        
        Drw.DeleteSelected
        GeoInOut(I).Selected = True ' select the path in the collection
        MD.RoughFinish
        Drw.DeleteSelected
                  
     Next I
     

        'LyrIN.Geometries.Selected = True
        'LyrOUT.Geometries.Selected = True
        'GeoInOut.Selected = True
        'MD.OpNo = J + DOc + 1
'AfterRoughFinish TpsIn, 0
     'MDin.RoughFinishUsePreviousMachining = True
       ' MD.RoughFinish
    'Drw.Operations.Collapse
    Drw.DeleteSelected
    Drw.Redraw
    
End Sub

 Sub AfterRoughFinish(PS As Paths, Redo As Integer)

  Dim P As Path

  For Each P In PS

   P.Attribute("LicomUKDMBTest1") = "Test1"

  Next P

 End Sub


