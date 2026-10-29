Attribute VB_Name = "TwoSideMachining"
'================================================================
' Alphacam 2021 - Двусторонняя обточка (внутренний + внешний)
' + опциональный реверс-проход (перпендикулярный обратный)
'
' ВСЕ параметры вынесены в шапку как Public переменные модуля.
' Из формы (frmMain) перед вызовом TwoSideMachining надо установить
' значения всех переменных p_..., затем вызвать TwoSideMachining.
'
' Пример вызова из кнопки формы:
'   Private Sub btOk_Click()
'       p_ToolAngle = cbUgol.Value
'       p_ToolSize  = cbPyatka.Value
'       p_MatTop    = CDbl(tbTop.Value)
'       p_MatBottom = CDbl(tbBottom.Value)
'       p_OffsetIn  = CDbl(tbOffsetIn.Value)
'       p_OffsetOut = CDbl(tbOffsetOut.Value)
'       p_AngleIn   = CDbl(tbAngleIn.Value)
'       p_LenIn     = CDbl(tbLenIn.Value)
'       p_AngleOut  = CDbl(tbAngleOut.Value)
'       p_LenOut    = CDbl(tbLenOut.Value)
'       p_MaxLen    = CDbl(tbMaxLen.Value)
'       p_CorridorsPerOp = CInt(tbCorridorsPerOp.Value)
'       ' Направление коридора - устанавливаем ВСЕГДА (для LENGTH и GROUPS):
'       If optHoriz.Value Then
'           p_Corridor = CORRIDOR_HORIZ
'       Else
'           p_Corridor = CORRIDOR_VERT
'       End If
'       ' Режим:
'       If optPickOrder.Value Then
'           p_Mode = MODE_PICK_ORDER
'       ElseIf optByLength.Value Then     ' если в форме есть отдельный radio "По длине"
'           p_Mode = MODE_LENGTH
'       Else
'           p_Mode = MODE_GROUPS
'       End If
'       p_UseReverse = chkReverse.Value
'       frmMain.Hide
'       DoEvents
'       TwoSideMachining
'   End Sub
'================================================================

Option Explicit

' =================================================================
' ПАРАМЕТРЫ - устанавливаются из формы перед вызовом TwoSideMachining
' =================================================================

' --- Инструмент ---
' Путь тула: App.LicomdatPath & "LICOMDAT\MTools.Alp\GVM_TOOLS\STD_D" & p_ToolSize & "base" & p_ToolAngle & "°.AMT"
Public p_ToolAngle As String     ' "70", "80", "90" и т.д.
Public p_ToolSize As String      ' "1_2", "1_0", "0_8" и т.д.

' --- MillData ---
Public p_MatTop As Double        ' MaterialTop (Верх)
Public p_MatBottom As Double     ' FinalDepth  (Низ)

' --- Запоминание последних значений полей формы ---
' Public, чтобы переживать Load/Unload формы, пока открыт AlphaCam.
' "" (пусто) = ещё не задавалось, форма подставит дефолт.
Public g_LastTop As String      ' Верх   (TextBox15)
Public g_LastBottom As String   ' Низ    (TextBox14)
Public g_LastMaxLen As String   ' Длина  (TextBox7)

' --- Сдвиги входа/выхода ---
Public p_OffsetIn As Double      ' Смещение для внутреннего контура:
                                 '   0  = правый верхний угол
                                 '  >0 = сдвиг ВНИЗ по правой стороне на N мм
                                 '  <0 = сдвиг ВЛЕВО по верхней стороне на |N| мм
Public p_OffsetOut As Double     ' То же для внешнего контура

' --- Лиды (раздельно для внутр./внешн.) ---
Public p_AngleIn As Double       ' Угол внутреннего лида (градусы)
Public p_LenIn As Double         ' Длина/радиус внутреннего лида (мм)
Public p_AngleOut As Double      ' Угол внешнего лида
Public p_LenOut As Double        ' Длина/радиус внешнего лида
Public p_Overlap As Double       ' Overlap лида (по умолчанию 0.2)

' --- Стратегия разделения операций ---
Public p_Mode As Integer         ' MODE_LENGTH / MODE_GROUPS / MODE_PICK_ORDER
Public p_Corridor As Integer     ' CORRIDOR_HORIZ / CORRIDOR_VERT
                                 ' Используется в режимах MODE_LENGTH и MODE_GROUPS
Public p_CorridorsPerOp As Integer  ' Кол-во коридоров в одной операции
                                    '  1   = один коридор = одна операция
                                    ' >1   = объединить N коридоров
                                    ' <0   = разбить один коридор на |N| частей
Public p_MaxLen As Double        ' Лимит длины пути на одну операцию (мм)
Public p_Tolerance As Double     ' Допуск для упрощения геометрий (мм)

' --- Реверс ---
Public p_UseReverse As Boolean   ' True = создавать реверс-проход

' --- Быстрый режим ---
Public p_Fast As Boolean         ' True = один RoughFinish на всю коллекцию,
                                 '        затем назначение OpNo/атрибутов на тулпатах.
                                 '        Намного быстрее на больших выборках.

' =================================================================
' КОНСТАНТЫ (не настраиваются из формы)
' =================================================================
Public Const MODE_LENGTH        As Integer = 1
Public Const MODE_GROUPS        As Integer = 2
Public Const MODE_PICK_ORDER    As Integer = 3

Public Const CORRIDOR_HORIZ     As Integer = 1
Public Const CORRIDOR_VERT      As Integer = 2

Public p_ColumnTolerance As Double  ' Резерв: допуск коридоров (мм); сейчас
                                    ' кластеризация идёт по перекрытию bbox
                                    ' и этот параметр не используется
Private Const SAFE_RAPID        As Double = 10#
Private Const RAPID_DOWN_TO     As Double = 3#

Private Const ATTR_REVERS       As String = "revers"
Private Const ATTR_SV           As String = "SV"
Private Const ATTR_SIDE         As String = "_TSM_SIDE"  ' 0=внутр, 1=внешн

Private Const SV_LEFT_BOTTOM    As Integer = 1
Private Const SV_RIGHT_BOTTOM   As Integer = 2
Private Const SV_RIGHT_TOP      As Integer = 3
Private Const SV_LEFT_TOP       As Integer = 4

Private Const LAYER_IN          As String = "IN"
Private Const LAYER_OUT         As String = "OUT"

' =================================================================
' Внутренние (не трогать)
' =================================================================
Private g_CornerSV As Object
Private g_LDI As LeadData    ' лид внутреннего контура (заход=выход)
Private g_LDO As LeadData    ' лид внешнего контура (заход=выход)
Private g_LDFast As LeadData ' лид быстрого режима (заход=внутр, выход=внешн)

'================================================================
' ОСНОВНОЙ МАКРОС
'================================================================
Public Sub TwoSideMachining()
    Dim Drw As Drawing
    Set Drw = App.ActiveDrawing
    
    ' Применяем дефолты если что-то не задано
    If p_Overlap < 0 Then p_Overlap = 0.2
    If p_MaxLen <= 0 Then p_MaxLen = 3000#
    If p_Mode = 0 Then p_Mode = MODE_GROUPS
    If p_Corridor = 0 Then p_Corridor = CORRIDOR_VERT
    If p_CorridorsPerOp = 0 Then p_CorridorsPerOp = 1
    
    ' --- Подготовка инструмента ---
    GetMillTool p_ToolAngle, p_ToolSize
    If App.GetCurrentTool Is Nothing Then
        MsgBox "Инструмент не выбран.", vbExclamation
        Exit Sub
    End If
    
    ' --- Выбор геометрий ---
    Dim selPaths As Paths
    If p_Mode = MODE_PICK_ORDER Then
        Set selPaths = SelectGeosOneByOne(Drw)
    Else
        Set selPaths = Drw.UserSelectMultiGeosCollection( _
                           "Выбери геометрии для двусторонней обточки", 0)
    End If
    If selPaths Is Nothing Then Exit Sub
    If selPaths.Count = 0 Then
        MsgBox "Геометрии не выбраны.", vbExclamation
        Exit Sub
    End If
    
    ' --- Упрощение геометрий (опционально, по чекбоксу формы) ---
    If frmMain.CheckBox6.Value Then
        Call SimplifySelectedGeometries(selPaths, p_Tolerance, 0)
    End If
    
    ' Отключаем перерисовку для скорости обработки
    Drw.ScreenUpdating = False
    
    ' --- Слои IN/OUT ---
    Dim LyrIN As Layer, LyrOUT As Layer
    Set LyrIN = Drw.CreateLayer(LAYER_IN)
    LyrIN.Color = acamYELLOW
    LyrIN.Visible = True
    Set LyrOUT = Drw.CreateLayer(LAYER_OUT)
    LyrOUT.Color = acamYELLOW
    LyrOUT.Visible = True
    
    Drw.SetGeosSelected False
    Drw.SetToolPathsSelected False
    
    Dim pathArr() As Variant
    pathArr = ExtractPathData(selPaths)
    BuildCornerSVMap pathArr
    
    Dim processOrder() As Variant
    processOrder = OrderDetails(pathArr, p_Mode, p_Corridor, p_CorridorsPerOp)
    
    Dim geoInOut As Paths
    Set geoInOut = Drw.CreatePathCollection
    Dim detailOfCopy As Collection
    Set detailOfCopy = New Collection
    
    BuildGeoInOut Drw, pathArr, processOrder, LyrIN, LyrOUT, _
                  geoInOut, detailOfCopy
    
    LyrIN.Visible = False
    LyrOUT.Visible = False
    
    Dim MD As MillData
    Set MD = App.CreateMillData
    Call ConfigureMillData(MD)
    
    Dim opNoAfterMain As Integer
    opNoAfterMain = RunRoughFinishOps(Drw, geoInOut, detailOfCopy, MD, _
                                       pathArr, processOrder, p_Mode, _
                                       p_Corridor, p_CorridorsPerOp)
    
    ' --- Реверс ---
    If p_UseReverse Then
        RunReverseOp Drw, geoInOut, detailOfCopy, MD, _
                     pathArr, processOrder, p_Mode, p_Corridor, _
                     opNoAfterMain
    End If
    
    ' --- Финализация ---
    Drw.SetGeosSelected False
    Drw.SetToolPathsSelected False
    
    On Error Resume Next
    LyrIN.Visible = False
    LyrOUT.Visible = False
    On Error GoTo 0
    
    Set g_CornerSV = Nothing
    
    ' Сброс всех параметров к значениям по умолчанию,
    ' чтобы следующий запуск не наследовал старые значения.
    ResetParams
    
    ' Сворачиваем дерево операций (Collapse All)
    On Error Resume Next
    Drw.CollapseOperations
    On Error GoTo 0
    
    Drw.ScreenUpdating = True
    Drw.Redraw
    MsgBox "Готово.", vbInformation
End Sub

'================================================================
' Сброс всех параметров p_* к значениям по умолчанию.
'================================================================
Private Sub ResetParams()
    p_ToolAngle = ""
    p_ToolSize = ""
    p_MatTop = 0
    p_MatBottom = 0
    p_OffsetIn = 0
    p_OffsetOut = 0
    p_AngleIn = 0
    p_LenIn = 0
    p_AngleOut = 0
    p_LenOut = 0
    p_Overlap = 0
    p_Mode = 0
    p_Corridor = 0
    p_CorridorsPerOp = 0
    p_MaxLen = 0
    p_Tolerance = 0
    p_ColumnTolerance = 0
    p_UseReverse = False
    p_Fast = False
End Sub

'================================================================
' Выбор тула (как в твоём образце)
'================================================================
Private Sub GetMillTool(ByVal toolAngle As String, ByVal toolSize As String)
    On Error Resume Next
    App.SelectTool App.LicomdatPath & "LICOMDAT\MTools.Alp\GVM_TOOLS\STD_D" & _
                   toolSize & "base" & toolAngle & "°.AMT"
    If Err.Number <> 0 Then
        Err.Clear
        Dim F1 As String, F2 As String
        If Not App.GetAlphaCamFileName(toolAngle & " not found: Select Tool", _
                                         acamFileTypeTOOL, acamFileActionOPEN, _
                                         F1, F2) Then
            Exit Sub
        End If
        App.SelectTool F1
    End If
    On Error GoTo 0
End Sub

'================================================================
' Создание копий геометрий на слоях IN и OUT с ToolInOut/ToolSide.
'================================================================
Private Sub BuildGeoInOut(Drw As Drawing, pathArr As Variant, _
                           processOrder As Variant, _
                           LyrIN As Layer, LyrOUT As Layer, _
                           ByRef geoInOut As Paths, _
                           ByRef detailOfCopy As Collection)
    Dim i As Long
    
    For i = LBound(processOrder, 1) To UBound(processOrder, 1)
        Dim detIdx As Long
        detIdx = CLng(processOrder(i, 1))
        
        Dim p As Path
        Set p = pathArr(detIdx, 4)
        
        Dim minX As Double, maxX As Double, minY As Double, maxY As Double
        minX = CDbl(pathArr(detIdx, 6))
        maxX = CDbl(pathArr(detIdx, 7))
        minY = CDbl(pathArr(detIdx, 8))
        maxY = CDbl(pathArr(detIdx, 9))
        
        Dim isClosed As Boolean
        isClosed = True
        On Error Resume Next
        isClosed = p.Closed
        On Error GoTo 0
        
        Dim sx As Double, sy As Double
        
        ' Копия 1 (INSIDE / RIGHT)
        Dim c1 As Path
        On Error Resume Next
        Set c1 = p.Copy
        If Not c1 Is Nothing Then
            If isClosed Then
                c1.ToolInOut = acamINSIDE
                c1.CW = True
                ComputeStartPoint minX, maxX, minY, maxY, p_OffsetIn, sx, sy
                c1.SetStartPoint sx, sy
            Else
                c1.ToolSide = acamRIGHT
                EnsureStartFromTop c1
            End If
            c1.SetLayer LyrIN
            c1.Attribute(ATTR_SIDE) = 0     ' внутренний контур
            geoInOut.Add c1
            detailOfCopy.Add detIdx
        End If
        On Error GoTo 0
        
        ' Копия 2 (OUTSIDE / LEFT)
        Dim c2 As Path
        On Error Resume Next
        Set c2 = p.Copy
        If Not c2 Is Nothing Then
            If isClosed Then
                c2.ToolInOut = acamOUTSIDE
                c2.CW = False
                ComputeStartPoint minX, maxX, minY, maxY, p_OffsetOut, sx, sy
                c2.SetStartPoint sx, sy
            Else
                c2.ToolSide = acamLEFT
                EnsureStartFromTop c2
                c2.Reverse
            End If
            c2.SetLayer LyrOUT
            c2.Attribute(ATTR_SIDE) = 1     ' внешний контур
            geoInOut.Add c2
            detailOfCopy.Add detIdx
        End If
        On Error GoTo 0
    Next i
End Sub

'================================================================
Private Function RunRoughFinishOps(Drw As Drawing, geoInOut As Paths, _
                                    detailOfCopy As Collection, _
                                    MD As MillData, pathArr As Variant, _
                                    processOrder As Variant, _
                                    mode As Integer, _
                                    corridor As Integer, _
                                    corridorParam As Integer) As Integer
    If p_Fast Then
        RunRoughFinishOps = RunFastMode(Drw, geoInOut, MD, pathArr, _
                                         processOrder, mode, corridor, _
                                         corridorParam)
    Else
        RunRoughFinishOps = RunSlowMode(Drw, geoInOut, MD, pathArr, _
                                         processOrder, mode, corridor, _
                                         corridorParam)
    End If
End Function

'================================================================
' БЫСТРЫЙ РЕЖИМ:
' Один RoughFinish на ВСЮ коллекцию geoInOut, затем проход по
' созданным тулпатам для назначения OpNo и атрибутов.
'================================================================
Private Function RunFastMode(Drw As Drawing, geoInOut As Paths, _
                              MD As MillData, pathArr As Variant, _
                              processOrder As Variant, _
                              mode As Integer, _
                              corridor As Integer, _
                              corridorParam As Integer) As Integer
    Dim startOpNo As Integer
    startOpNo = NextOpNo(Drw)
    
    ' --- OpNo для каждой детали через универсальный планировщик ---
    Dim finalOp As Integer
    Dim detOpNo As Variant
    detOpNo = BuildDetailOpNos(pathArr, processOrder, mode, _
                                corridorParam, startOpNo, finalOp)
    
    Dim detCount As Long
    detCount = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    ' Быстрый режим: группируем детали по OpNo и делаем ОДИН RoughFinish
    ' на каждую операцию. Так операции создаются нативно (отдельными
    ' пунктами в Operations tree), но вызовов RoughFinish немного -
    ' по числу операций, а не по числу деталей.
    Dim i As Long
    Dim curOp As Integer
    Dim ip As Long
    ip = 1
    
    Do While ip <= detCount
        curOp = CInt(detOpNo(ip))
        
        ' Собираем ВСЕ копии этой операции в одну коллекцию, парами
        ' (внутр, внешн, внутр, внешн...). В быстром режиме лид берётся
        ' из g_LDFast (заход=внутр.блок, выход=внешн.блок), применяется
        ' через MillData ДО RoughFinish -> один вызов на операцию.
        Dim opGeos As Paths
        Set opGeos = Drw.CreatePathCollection
        Dim opRows As Collection
        Set opRows = New Collection
        
        Dim jp As Long
        jp = ip
        Do While jp <= detCount
            If CInt(detOpNo(jp)) <> curOp Then Exit Do
            
            Dim gi1 As Long, gi2 As Long
            gi1 = (jp - 1) * 2 + 1
            gi2 = (jp - 1) * 2 + 2
            
            If gi1 <= geoInOut.Count Then
                opGeos.Add geoInOut.Item(gi1)
                opRows.Add jp
            End If
            If gi2 <= geoInOut.Count Then
                opGeos.Add geoInOut.Item(gi2)
                opRows.Add jp
            End If
            
            jp = jp + 1
        Loop
        
        MD.OpNo = curOp
        MD.SetLeadData g_LDFast          ' заход/выход из внутр/внешн блоков
        On Error Resume Next
        MD.DeleteAttribute ATTR_SV
        On Error GoTo 0
        
        If opGeos.Count > 0 Then
            Drw.SetGeosSelected False
            opGeos.Selected = True
            DoEvents
            Dim Tps As Paths
            Set Tps = MD.RoughFinish
            DoEvents
            Drw.SetGeosSelected False
            Drw.SetToolPathsSelected False
            
            If Not Tps Is Nothing Then
                ' Лид уже применён через MillData. Ставим только SV.
                Dim m As Long
                For m = 1 To opRows.Count
                    If m > Tps.Count Then Exit For
                    Dim rowIdx As Long
                    rowIdx = CLng(opRows.Item(m))
                    Dim detIdx2 As Long
                    detIdx2 = CLng(processOrder(rowIdx, 1))
                    Dim origIdx As Long
                    origIdx = CLng(pathArr(detIdx2, 1))
                    If Not g_CornerSV Is Nothing Then
                        If g_CornerSV.Exists(origIdx) Then
                            On Error Resume Next
                            Tps.Item(m).Attribute(ATTR_SV) = CInt(g_CornerSV(origIdx))
                            On Error GoTo 0
                        End If
                    End If
                Next m
            End If
        End If
        
        Drw.SetGeosSelected False
        ip = jp
    Loop
    
    RunFastMode = finalOp
End Function

'================================================================
' Проставить атрибут SV на угловых деталях группы тулпатов.
' Tps идёт в порядке detRows (по одному тулпату на копию, но может
' быть и больше - тогда все тулпаты детали получают SV).
' Здесь считаем 1 тулпат = 1 копия (обычный случай).
'================================================================
Private Sub ApplyCornerSVForGroup(Tps As Paths, detRows As Collection, _
                                   processOrder As Variant, pathArr As Variant)
    If Tps Is Nothing Then Exit Sub
    If g_CornerSV Is Nothing Then Exit Sub
    
    Dim m As Long
    For m = 1 To detRows.Count
        If m > Tps.Count Then Exit For
        
        Dim rowIdx As Long
        rowIdx = CLng(detRows.Item(m))
        Dim detIdx2 As Long
        detIdx2 = CLng(processOrder(rowIdx, 1))
        Dim origIdx As Long
        origIdx = CLng(pathArr(detIdx2, 1))
        
        If g_CornerSV.Exists(origIdx) Then
            On Error Resume Next
            Tps.Item(m).Attribute(ATTR_SV) = CInt(g_CornerSV(origIdx))
            On Error GoTo 0
        End If
    Next m
End Sub

'================================================================
' МЕДЛЕННЫЙ РЕЖИМ
'================================================================
Private Function RunSlowMode(Drw As Drawing, geoInOut As Paths, _
                              MD As MillData, pathArr As Variant, _
                              processOrder As Variant, _
                              mode As Integer, _
                              corridor As Integer, _
                              corridorParam As Integer) As Integer
    Dim startOpNo As Integer
    startOpNo = NextOpNo(Drw)
    
    Dim finalOp As Integer
    Dim detOpNo As Variant
    detOpNo = BuildDetailOpNos(pathArr, processOrder, mode, _
                                corridorParam, startOpNo, finalOp)
    
    Dim detCount As Long
    detCount = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    Dim i As Long
    For i = 1 To detCount
        Dim detIdx As Long
        detIdx = CLng(processOrder(i, 1))
        EmitDetailPair Drw, geoInOut, MD, i, CInt(detOpNo(i)), pathArr, detIdx
    Next i
    
    RunSlowMode = finalOp
End Function

'================================================================
' Старые RunByLength/RunByGroups/RunPickOrder больше не нужны -
' их работу делает BuildDetailOpNos + общий цикл в RunSlowMode.
' Для совместимости оставлены как fallback.
'================================================================
Private Function RunByLength(Drw As Drawing, geoInOut As Paths, _
                              MD As MillData, pathArr As Variant, _
                              processOrder As Variant, _
                              startOpNo As Integer) As Integer
    Dim opNo As Integer
    opNo = startOpNo
    Dim accLen As Double
    accLen = 0
    
    Dim detCount As Long
    detCount = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    Dim i As Long
    For i = 1 To detCount
        Dim detIdx As Long
        detIdx = CLng(processOrder(i, 1))
        Dim detLen As Double
        detLen = CDbl(pathArr(detIdx, 5)) * 2
        
        If accLen >= p_MaxLen And accLen > 0 Then
            opNo = opNo + 1
            accLen = 0
        End If
        
        EmitDetailPair Drw, geoInOut, MD, i, opNo, pathArr, detIdx
        accLen = accLen + detLen
    Next i
    
    RunByLength = opNo
End Function

'================================================================
' Универсальный планировщик OpNo для каждой детали.
' Возвращает массив целых чисел длины detCount,
' где элемент i = номер операции для детали processOrder(i,...).
'
' Учитывает:
'   - mode (LENGTH / GROUPS / PICK_ORDER)
'   - corridorParam:
'       >=1 -> объединить N коридоров в одну операцию,
'              + лимит p_MaxLen внутри объединения
'       <0  -> разбить КАЖДЫЙ коридор на |N| примерно равных частей.
'              Если в коридоре больше |N| * p_MaxLen, число частей
'              увеличивается до достаточного, чтобы части были <= p_MaxLen.
'================================================================
Private Function BuildDetailOpNos(pathArr As Variant, _
                                    processOrder As Variant, _
                                    mode As Integer, _
                                    corridorParam As Integer, _
                                    startOpNo As Integer, _
                                    ByRef finalOpNo As Integer) As Variant
    Dim detCount As Long
    detCount = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    Dim detOpNo() As Integer
    ReDim detOpNo(1 To detCount)
    
    Dim opNo As Integer
    opNo = startOpNo
    
    Select Case mode
        Case MODE_PICK_ORDER
            ' Всё в одну операцию
            Dim i As Long
            For i = 1 To detCount
                detOpNo(i) = startOpNo
            Next i
            opNo = startOpNo
        
        Case MODE_LENGTH
            ' Прямой обход с лимитом длины
            Dim accLen As Double
            accLen = 0
            For i = 1 To detCount
                Dim detIdx As Long
                detIdx = CLng(processOrder(i, 1))
                Dim detLen As Double
                detLen = CDbl(pathArr(detIdx, 5)) * 2
                If accLen >= p_MaxLen And accLen > 0 Then
                    opNo = opNo + 1
                    accLen = 0
                End If
                detOpNo(i) = opNo
                accLen = accLen + detLen
            Next i
        
        Case MODE_GROUPS
            ' Сначала строим список коридоров: для каждого - старт, конец, длина
            Dim corrStarts As Collection
            Dim corrEnds As Collection
            Dim corrLens As Collection
            Set corrStarts = New Collection
            Set corrEnds = New Collection
            Set corrLens = New Collection
            
            Dim curCorr As Long
            curCorr = -1
            Dim corrStartIdx As Long
            Dim corrTotalLen As Double
            corrStartIdx = 1
            corrTotalLen = 0
            
            For i = 1 To detCount
                Dim ci As Long
                ci = CLng(processOrder(i, 2))
                Dim di As Long
                di = CLng(processOrder(i, 1))
                Dim dl As Double
                dl = CDbl(pathArr(di, 5)) * 2
                
                If curCorr = -1 Then
                    curCorr = ci
                    corrStartIdx = i
                    corrTotalLen = 0
                ElseIf ci <> curCorr Then
                    corrStarts.Add corrStartIdx
                    corrEnds.Add i - 1
                    corrLens.Add corrTotalLen
                    curCorr = ci
                    corrStartIdx = i
                    corrTotalLen = 0
                End If
                corrTotalLen = corrTotalLen + dl
            Next i
            If curCorr <> -1 Then
                corrStarts.Add corrStartIdx
                corrEnds.Add detCount
                corrLens.Add corrTotalLen
            End If
            
            Dim totalCorridors As Long
            totalCorridors = corrStarts.Count
            
            If corridorParam < 0 Then
                ' === РАЗБИТЬ каждый коридор на |N| частей ПО ЧИСЛУ ДЕТАЛЕЙ.
                ' ЛИМИТ ДЛИНЫ ИГНОРИРУЕМ. Например 10 деталей / 2 = 5+5,
                ' 11 деталей / 2 = 6+5 (первые части получают остаток). ===
                Dim splitN As Integer
                splitN = -corridorParam
                If splitN < 1 Then splitN = 1
                
                Dim c As Long
                For c = 1 To totalCorridors
                    Dim cStart As Long, cEnd As Long
                    cStart = corrStarts(c)
                    cEnd = corrEnds(c)
                    
                    Dim cCount As Long
                    cCount = cEnd - cStart + 1
                    
                    ' Базовый размер части и остаток
                    Dim baseSize As Long, remainder As Long
                    baseSize = cCount \ splitN
                    remainder = cCount Mod splitN
                    
                    ' Распределяем: первые remainder частей получают baseSize+1
                    Dim k As Long
                    Dim partIdx As Integer
                    Dim inPartCount As Long
                    Dim curPartSize As Long
                    partIdx = 0
                    inPartCount = 0
                    If partIdx < remainder Then
                        curPartSize = baseSize + 1
                    Else
                        curPartSize = baseSize
                    End If
                    
                    For k = cStart To cEnd
                        ' Переход к следующей части
                        If inPartCount >= curPartSize And partIdx < splitN - 1 Then
                            opNo = opNo + 1
                            partIdx = partIdx + 1
                            inPartCount = 0
                            If partIdx < remainder Then
                                curPartSize = baseSize + 1
                            Else
                                curPartSize = baseSize
                            End If
                        End If
                        
                        detOpNo(k) = opNo
                        inPartCount = inPartCount + 1
                    Next k
                    
                    If c < totalCorridors Then
                        opNo = opNo + 1
                    End If
                Next c
                
            ElseIf corridorParam > 1 Then
                ' === ОБЪЕДИНИТЬ N коридоров в одну операцию. ЛИМИТ ИГНОРИРУЕМ. ===
                Dim cc As Long
                For cc = 1 To totalCorridors
                    Dim ccStart As Long, ccEnd As Long
                    ccStart = corrStarts(cc)
                    ccEnd = corrEnds(cc)
                    
                    Dim kk As Long
                    For kk = ccStart To ccEnd
                        detOpNo(kk) = opNo
                    Next kk
                    
                    ' Переходим на новый OpNo каждые corridorParam коридоров
                    If cc Mod corridorParam = 0 And cc < totalCorridors Then
                        opNo = opNo + 1
                    End If
                Next cc
                
            Else
                ' === corridorParam = 1: один коридор = одна программа,
                ' но С УЧЁТОМ ЛИМИТА:
                '   - длина > лимит -> делим коридор на N равных частей,
                '                       где N = ceil(длина / лимит)
                '   - длина < 0.55 * лимит -> объединяем со следующим
                '                              пока сумма < лимит ===
                Const SHORT_THRESHOLD As Double = 0.55  ' половина + 10%
                
                Dim processed() As Boolean
                ReDim processed(1 To totalCorridors)
                
                Dim ck As Long
                For ck = 1 To totalCorridors
                    If processed(ck) Then GoTo NextCorr
                    
                    Dim sLen As Double
                    sLen = corrLens(ck)
                    Dim sStart As Long, sEnd As Long
                    sStart = corrStarts(ck)
                    sEnd = corrEnds(ck)
                    processed(ck) = True
                    
                    If sLen > p_MaxLen Then
                        ' --- Длинный коридор: делим на части ---
                        Dim nParts As Integer
                        nParts = CInt(Int(sLen / p_MaxLen + 0.999999))
                        If nParts < 1 Then nParts = 1
                        
                        Dim tLen As Double
                        tLen = sLen / nParts
                        
                        Dim pAcc As Double
                        Dim pDone As Integer
                        pAcc = 0
                        pDone = 0
                        
                        Dim kp As Long
                        For kp = sStart To sEnd
                            Dim dip As Long, dlp As Double
                            dip = CLng(processOrder(kp, 1))
                            dlp = CDbl(pathArr(dip, 5)) * 2
                            
                            If pAcc > 0 And pDone < nParts - 1 Then
                                If pAcc >= tLen Then
                                    opNo = opNo + 1
                                    pAcc = 0
                                    pDone = pDone + 1
                                End If
                            End If
                            
                            detOpNo(kp) = opNo
                            pAcc = pAcc + dlp
                        Next kp
                        
                        ' Закрываем операцию - следующий коридор уже отдельно
                        opNo = opNo + 1
                        
                    ElseIf sLen < p_MaxLen * SHORT_THRESHOLD Then
                        ' --- Короткий коридор: объединяем со следующими ---
                        ' Назначаем текущий OpNo всем деталям этого коридора
                        Dim ks As Long
                        For ks = sStart To sEnd
                            detOpNo(ks) = opNo
                        Next ks
                        
                        ' Пытаемся добавить следующие коридоры пока не дойдём до лимита
                        Dim totalSum As Double
                        totalSum = sLen
                        
                        Dim cn As Long
                        cn = ck + 1
                        Do While cn <= totalCorridors
                            If processed(cn) Then Exit Do
                            
                            Dim nextLen As Double
                            nextLen = corrLens(cn)
                            
                            If totalSum + nextLen <= p_MaxLen Then
                                ' Добавляем коридор cn к текущей операции
                                Dim nextStart As Long, nextEnd As Long
                                nextStart = corrStarts(cn)
                                nextEnd = corrEnds(cn)
                                
                                Dim kn As Long
                                For kn = nextStart To nextEnd
                                    detOpNo(kn) = opNo
                                Next kn
                                
                                processed(cn) = True
                                totalSum = totalSum + nextLen
                                cn = cn + 1
                            Else
                                Exit Do
                            End If
                        Loop
                        
                        ' Переходим на новый OpNo (если есть ещё коридоры)
                        If cn <= totalCorridors Then
                            opNo = opNo + 1
                        End If
                        
                    Else
                        ' --- Нормальный коридор: одна программа ---
                        Dim kr As Long
                        For kr = sStart To sEnd
                            detOpNo(kr) = opNo
                        Next kr
                        opNo = opNo + 1
                    End If
NextCorr:
                Next ck
            End If
    End Select
    
    finalOpNo = opNo + 1
    BuildDetailOpNos = detOpNo
End Function

Private Function RunPickOrder(Drw As Drawing, geoInOut As Paths, _
                               MD As MillData, pathArr As Variant, _
                               processOrder As Variant, _
                               startOpNo As Integer) As Integer
    Dim detCount As Long
    detCount = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    Dim i As Long
    For i = 1 To detCount
        Dim detIdx As Long
        detIdx = CLng(processOrder(i, 1))
        EmitDetailPair Drw, geoInOut, MD, i, startOpNo, pathArr, detIdx
    Next i
    
    RunPickOrder = startOpNo
End Function

'================================================================
Private Sub EmitDetailPair(Drw As Drawing, geoInOut As Paths, _
                            MD As MillData, i As Long, opNo As Integer, _
                            pathArr As Variant, detIdx As Long)
    Dim origIdx As Long
    origIdx = CLng(pathArr(detIdx, 1))
    
    Dim svCode As Integer
    Dim isCorner As Boolean
    isCorner = False
    svCode = 0
    
    If Not g_CornerSV Is Nothing Then
        If g_CornerSV.Exists(origIdx) Then
            isCorner = True
            svCode = CInt(g_CornerSV(origIdx))
        End If
    End If
    
    Dim idx1 As Long, idx2 As Long
    idx1 = (i - 1) * 2 + 1
    idx2 = (i - 1) * 2 + 2
    
    MD.OpNo = opNo
    
    On Error Resume Next
    If isCorner Then
        MD.Attribute(ATTR_SV) = svCode
    Else
        MD.DeleteAttribute ATTR_SV
    End If
    On Error GoTo 0
    
    If idx1 <= geoInOut.Count Then
        Drw.SetGeosSelected False
        geoInOut.Item(idx1).Selected = True
        DoEvents
        Dim tps1 As Paths
        Set tps1 = MD.RoughFinish
        DoEvents
        ' idx1 - внутренняя копия (слой IN)
        If Not tps1 Is Nothing Then
            Dim q1 As Long
            For q1 = 1 To tps1.Count
                ApplyLead tps1.Item(q1), True     ' idx1 = копия IN
            Next q1
        End If
    End If
    
    If idx2 <= geoInOut.Count Then
        Drw.SetGeosSelected False
        geoInOut.Item(idx2).Selected = True
        DoEvents
        Dim tps2 As Paths
        Set tps2 = MD.RoughFinish
        DoEvents
        ' idx2 - внешняя копия (слой OUT)
        If Not tps2 Is Nothing Then
            Dim q2 As Long
            For q2 = 1 To tps2.Count
                ApplyLead tps2.Item(q2), False    ' idx2 = копия OUT
            Next q2
        End If
    End If
    
    Drw.SetGeosSelected False
End Sub

'================================================================
Private Sub RunReverseOp(Drw As Drawing, geoInOut As Paths, _
                          detailOfCopy As Collection, _
                          MD As MillData, pathArr As Variant, _
                          processOrder As Variant, _
                          mode As Integer, corridor As Integer, _
                          ByRef opNo As Integer)
    Dim revOrder() As Variant
    
    If mode = MODE_PICK_ORDER Then
        revOrder = OrderDetailsForReversePick(processOrder)
    Else
        Dim lastStrat As Integer
        If (mode = MODE_GROUPS Or mode = MODE_LENGTH) And corridor = CORRIDOR_HORIZ Then
            lastStrat = 2
        Else
            lastStrat = 1
        End If
        revOrder = OrderDetailsForReverse(pathArr, lastStrat)
    End If
    
    opNo = opNo + 1
    
    If p_Fast Then
        RunReverseFast Drw, geoInOut, detailOfCopy, MD, _
                        revOrder, opNo
    Else
        RunReverseSlow Drw, geoInOut, detailOfCopy, MD, _
                        revOrder, opNo
    End If
End Sub

'================================================================
' БЫСТРЫЙ реверс: создаём НОВЫЕ копии геометрий в порядке реверса
' и делаем один RoughFinish на этой новой коллекции. Новые копии
' нужны, чтобы AlphaCam уважал порядок выделения и не переупорядочивал
' тулпаты в одной операции.
'================================================================
Private Sub RunReverseFast(Drw As Drawing, geoInOut As Paths, _
                            detailOfCopy As Collection, _
                            MD As MillData, _
                            revOrder As Variant, _
                            opNo As Integer)
    ' Временный слой для копий реверса
    Dim revLayer As Layer
    On Error Resume Next
    Set revLayer = Drw.CreateLayer("REV_TMP")
    If Not revLayer Is Nothing Then
        revLayer.Color = acamRED
        revLayer.Visible = True
    End If
    On Error GoTo 0
    
    Dim detCount As Long
    detCount = UBound(revOrder, 1) - LBound(revOrder, 1) + 1
    
    MD.OpNo = opNo
    MD.SetLeadData g_LDFast           ' заход/выход из внутр/внешн блоков
    On Error Resume Next
    MD.DeleteAttribute ATTR_SV
    On Error GoTo 0
    MD.Attribute(ATTR_REVERS) = 1
    
    ' Собираем НОВЫЕ копии в порядке реверса парами (внутр, внешн...)
    ' в одну коллекцию. Один RoughFinish на всё - скорость. Лид для
    ' всех путей из ВНУТРЕННЕГО блока (быстрый режим).
    Dim revPaths As Paths
    Set revPaths = Drw.CreatePathCollection
    
    Dim i As Long
    For i = 1 To detCount
        Dim detIdx As Long
        detIdx = CLng(revOrder(i, 1))
        
        Dim idx1 As Long, idx2 As Long
        idx1 = FindCopyIndexByDetail(detailOfCopy, detIdx, 1)
        idx2 = FindCopyIndexByDetail(detailOfCopy, detIdx, 2)
        
        If idx1 > 0 Then
            On Error Resume Next
            Dim newC1 As Path
            Set newC1 = geoInOut.Item(idx1).Copy
            If Not newC1 Is Nothing Then
                If Not revLayer Is Nothing Then newC1.SetLayer revLayer
                revPaths.Add newC1
            End If
            On Error GoTo 0
        End If
        
        If idx2 > 0 Then
            On Error Resume Next
            Dim newC2 As Path
            Set newC2 = geoInOut.Item(idx2).Copy
            If Not newC2 Is Nothing Then
                If Not revLayer Is Nothing Then newC2.SetLayer revLayer
                revPaths.Add newC2
            End If
            On Error GoTo 0
        End If
    Next i
    
    If revPaths.Count > 0 Then
        Drw.SetGeosSelected False
        revPaths.Selected = True
        DoEvents
        Dim Tps As Paths
        Set Tps = MD.RoughFinish
        DoEvents
        Drw.SetGeosSelected False
        Drw.SetToolPathsSelected False
        If Not Tps Is Nothing Then
            Dim k As Long
            For k = 1 To Tps.Count
                On Error Resume Next
                Tps.Item(k).OpNo = opNo
                Tps.Item(k).Attribute(ATTR_REVERS) = 1
                On Error GoTo 0
            Next k
        End If
    End If
    
    MD.DeleteAttribute ATTR_REVERS
    Drw.SetGeosSelected False
    
    ' Скрываем временный слой с копиями
    On Error Resume Next
    If Not revLayer Is Nothing Then revLayer.Visible = False
    On Error GoTo 0
End Sub

'================================================================
' МЕДЛЕННЫЙ реверс (по старому)
'================================================================
Private Sub RunReverseSlow(Drw As Drawing, geoInOut As Paths, _
                            detailOfCopy As Collection, _
                            MD As MillData, _
                            revOrder As Variant, _
                            opNo As Integer)
    MD.OpNo = opNo
    
    On Error Resume Next
    MD.DeleteAttribute ATTR_SV
    On Error GoTo 0
    
    MD.Attribute(ATTR_REVERS) = 1
    
    Dim detCount As Long
    detCount = UBound(revOrder, 1) - LBound(revOrder, 1) + 1
    
    Dim i As Long
    For i = 1 To detCount
        Dim detIdx As Long
        detIdx = CLng(revOrder(i, 1))
        
        Dim idx1 As Long, idx2 As Long
        idx1 = FindCopyIndexByDetail(detailOfCopy, detIdx, 1)
        idx2 = FindCopyIndexByDetail(detailOfCopy, detIdx, 2)
        
        If idx1 > 0 Then
            Drw.SetGeosSelected False
            geoInOut.Item(idx1).Selected = True
            DoEvents
            Dim rtps1 As Paths
            Set rtps1 = MD.RoughFinish
            DoEvents
            If Not rtps1 Is Nothing Then
                Dim rq1 As Long
                For rq1 = 1 To rtps1.Count
                    ApplyLead rtps1.Item(rq1), True    ' idx1 = копия IN
                Next rq1
            End If
        End If
        
        If idx2 > 0 Then
            Drw.SetGeosSelected False
            geoInOut.Item(idx2).Selected = True
            DoEvents
            Dim rtps2 As Paths
            Set rtps2 = MD.RoughFinish
            DoEvents
            If Not rtps2 Is Nothing Then
                Dim rq2 As Long
                For rq2 = 1 To rtps2.Count
                    ApplyLead rtps2.Item(rq2), False   ' idx2 = копия OUT
                Next rq2
            End If
        End If
    Next i
    
    MD.DeleteAttribute ATTR_REVERS
    Drw.SetGeosSelected False
End Sub

'================================================================
' Реверс для PICK_ORDER: просто обратный порядок выбора деталей.
'================================================================
Private Function OrderDetailsForReversePick(processOrder As Variant) As Variant
    Dim n As Long
    n = UBound(processOrder, 1) - LBound(processOrder, 1) + 1
    
    Dim res() As Variant
    ReDim res(1 To n, 1 To 2)
    
    Dim i As Long
    For i = 1 To n
        ' Идём в обратном порядке: i-я деталь реверса = (n - i + 1)-я из основного
        res(i, 1) = CLng(processOrder(n - i + 1, 1))
        res(i, 2) = 1
    Next i
    
    OrderDetailsForReversePick = res
End Function

Private Function FindCopyIndexByDetail(detailOfCopy As Collection, _
                                        detIdx As Long, _
                                        whichCopy As Integer) As Long
    Dim i As Long
    Dim count As Long
    count = 0
    
    For i = 1 To detailOfCopy.Count
        If CLng(detailOfCopy.Item(i)) = detIdx Then
            count = count + 1
            If count = whichCopy Then
                FindCopyIndexByDetail = i
                Exit Function
            End If
        End If
    Next i
    
    FindCopyIndexByDetail = 0
End Function

'================================================================
Private Function OrderDetails(pathArr As Variant, mode As Integer, _
                               corridor As Integer, _
                               corridorParam As Integer) As Variant
    Dim n As Long
    n = UBound(pathArr, 1) - LBound(pathArr, 1) + 1
    
    Dim result() As Variant
    ReDim result(1 To n, 1 To 2)
    
    Select Case mode
        Case MODE_PICK_ORDER
            Dim i As Long
            For i = 1 To n
                result(i, 1) = i
                result(i, 2) = 1
            Next i
        
        Case MODE_LENGTH
            ' Используем ту же коридорную сортировку, что и MODE_GROUPS
            ' (направление коридора задаётся параметром p_Corridor).
            ' Деление на операции - только по лимиту длины (RunByLength).
            result = OrderByCorridors(pathArr, corridor, 1)
        
        Case MODE_GROUPS
            result = OrderByCorridors(pathArr, corridor, corridorParam)
    End Select
    
    OrderDetails = result
End Function

'================================================================
Private Function OrderByCorridors(pathArr As Variant, corridor As Integer, _
                                   corridorParam As Integer) As Variant
    Dim outerCol As Integer, innerCol As Integer
    Dim bboxMinCol As Integer, bboxMaxCol As Integer
    
    If corridor = CORRIDOR_HORIZ Then
        outerCol = 3: innerCol = 2
        bboxMinCol = 8: bboxMaxCol = 9   ' MinYL, MaxYL
    Else
        outerCol = 2: innerCol = 3
        bboxMinCol = 6: bboxMaxCol = 7   ' MinXL, MaxXL
    End If
    
    Dim n As Long
    n = UBound(pathArr, 1) - LBound(pathArr, 1) + 1
    
    ' Кластеризация по центрам внешней оси с адаптивным шагом сетки.
    ' clusterId(i) = номер кластера (коридора) для детали i.
    Dim clusterId() As Long
    clusterId = ClusterByGrid(pathArr, outerCol, n)
    
    Dim i As Long
    
    ' clusterId уже содержит номера коридоров 1..K, упорядоченные по
    ' координате внешней оси. Находим число кластеров.
    Dim numClusters As Long
    numClusters = 0
    For i = 1 To n
        If clusterId(i) > numClusters Then numClusters = clusterId(i)
    Next i
    
    ' Собираем результат: для каждого коридора по порядку собираем
    ' детали, сортируем по inner-координате.
    Dim res() As Variant
    ReDim res(1 To n, 1 To 2)
    Dim outRow As Long
    outRow = 0
    
    Dim c As Long
    For c = 1 To numClusters
        Dim ids() As Long
        Dim cnt As Long
        ReDim ids(1 To n)
        cnt = 0
        For i = 1 To n
            If clusterId(i) = c Then
                cnt = cnt + 1
                ids(cnt) = i
            End If
        Next i
        
        If cnt > 0 Then
            ' Сортируем ids по inner-координате (возр.)
            Dim aa As Long, bb As Long, tt As Long
            For aa = 1 To cnt - 1
                For bb = 1 To cnt - 1
                    If CDbl(pathArr(ids(bb), innerCol)) > CDbl(pathArr(ids(bb + 1), innerCol)) Then
                        tt = ids(bb)
                        ids(bb) = ids(bb + 1)
                        ids(bb + 1) = tt
                    End If
                Next bb
            Next aa
            
            Dim k As Long
            For k = 1 To cnt
                outRow = outRow + 1
                res(outRow, 1) = ids(k)
                res(outRow, 2) = c
            Next k
        End If
    Next c
    
    OrderByCorridors = res
End Function

'================================================================
' Кластеризация деталей по координате внешней оси в "коридоры".
' Использует адаптивный порог = половина медианного шага между
' соседними уникальными позициями центров. Устойчиво и к плотной
' решётке, и к рваным фигурным деталям разного размера.
' Возвращает массив clusterId(1..n) с номерами коридоров 1..K,
' упорядоченными по возрастанию координаты.
'================================================================
Private Function ClusterByGrid(pathArr As Variant, outerCol As Integer, _
                                n As Long) As Long()
    Dim clusterId() As Long
    ReDim clusterId(1 To n)
    
    If n = 0 Then
        ClusterByGrid = clusterId
        Exit Function
    End If
    If n = 1 Then
        clusterId(1) = 1
        ClusterByGrid = clusterId
        Exit Function
    End If
    
    ' Определяем колонки bbox по внешней оси
    Dim bboxMinCol As Integer, bboxMaxCol As Integer
    If outerCol = 3 Then
        bboxMinCol = 8: bboxMaxCol = 9   ' Y
    Else
        bboxMinCol = 6: bboxMaxCol = 7   ' X
    End If
    
    ' --- Кластеризация по ЦЕНТРАМ внешней оси ---
    ' Ряды разделяются по разрывам между отсортированными центрами.
    ' Порог разрыва = доля от средней высоты детали (примерный шаг ряда).
    ' Работает даже когда bbox соседних рядов перекрываются, т.к.
    ' центры рядов всё равно разнесены на шаг сетки.
    
    ' Сортируем детали по центру внешней оси
    Dim ord() As Long
    ReDim ord(1 To n)
    Dim i As Long
    For i = 1 To n
        ord(i) = i
    Next i
    
    Dim a As Long, b As Long, t As Long
    For a = 1 To n - 1
        For b = 1 To n - 1
            If CDbl(pathArr(ord(b), outerCol)) > CDbl(pathArr(ord(b + 1), outerCol)) Then
                t = ord(b)
                ord(b) = ord(b + 1)
                ord(b + 1) = t
            End If
        Next b
    Next a
    
    ' Средняя высота детали по внешней оси (для ширины полосы)
    Dim sumSize As Double
    sumSize = 0
    For i = 1 To n
        sumSize = sumSize + (CDbl(pathArr(i, bboxMaxCol)) - CDbl(pathArr(i, bboxMinCol)))
    Next i
    Dim avgSize As Double
    avgSize = sumSize / n
    If avgSize < 1 Then avgSize = 1
    
    ' --- Жадное построение рядов ---
    ' Идём по деталям, отсортированным по центру внешней оси (снизу вверх).
    ' Первая необработанная деталь задаёт НАЧАЛО ряда. Все следующие
    ' детали, чей центр в пределах полосы [start .. start + bandWidth],
    ' попадают в тот же ряд. Как только центр выходит за полосу -
    ' начинается новый ряд.
    '
    ' bandWidth = 0.7 * (высота ПЕРВОЙ детали ряда). Привязка к реальной
    ' детали, а не к среднему - устойчиво к смеси крупных и мелких.
    Dim assigned() As Boolean
    ReDim assigned(1 To n)
    
    Dim curCluster As Long
    curCluster = 0
    
    Dim idxPos As Long
    idxPos = 1
    Do While idxPos <= n
        ' Находим первую необработанную деталь в порядке ord
        Do While idxPos <= n
            If Not assigned(ord(idxPos)) Then Exit Do
            idxPos = idxPos + 1
        Loop
        If idxPos > n Then Exit Do
        
        ' Эта деталь начинает новый ряд
        curCluster = curCluster + 1
        Dim rowStart As Double
        rowStart = CDbl(pathArr(ord(idxPos), outerCol))
        
        ' Ширина полосы = 0.7 высоты первой детали ряда
        Dim firstH As Double
        firstH = CDbl(pathArr(ord(idxPos), bboxMaxCol)) - CDbl(pathArr(ord(idxPos), bboxMinCol))
        If firstH < 1 Then firstH = avgSize
        Dim bandWidth As Double
        bandWidth = firstH * 0.7
        
        ' Все детали с центром в [rowStart .. rowStart + bandWidth] - в этот ряд
        Dim jrow As Long
        For jrow = idxPos To n
            If Not assigned(ord(jrow)) Then
                Dim cVal As Double
                cVal = CDbl(pathArr(ord(jrow), outerCol))
                If cVal <= rowStart + bandWidth Then
                    clusterId(ord(jrow)) = curCluster
                    assigned(ord(jrow)) = True
                Else
                    Exit For   ' дальше центры только больше - выходим
                End If
            End If
        Next jrow
        
        idxPos = idxPos + 1
    Loop
    
    ClusterByGrid = clusterId
End Function

Private Function OrderDetailsForReverse(pathArr As Variant, _
                                          lastStrat As Integer) As Variant
    ' Перпендикулярные коридоры со стартом из правого верхнего угла:
    '   lastStrat = 1 (основная: вертикальные коридоры снизу вверх) ->
    '       реверс: ГОРИЗОНТАЛЬНЫЕ коридоры сверху вниз,
    '       внутри строки справа налево
    '   lastStrat = 2 (основная: горизонтальные коридоры слева направо) ->
    '       реверс: ВЕРТИКАЛЬНЫЕ коридоры справа налево,
    '       внутри столбца сверху вниз
    
    Dim outerCol As Integer, innerCol As Integer
    Dim outerAsc As Boolean, innerAsc As Boolean
    Dim bboxMinCol As Integer, bboxMaxCol As Integer
    
    Select Case lastStrat
        Case 1
            outerCol = 3: outerAsc = False
            innerCol = 2: innerAsc = False
            bboxMinCol = 8: bboxMaxCol = 9
        Case 2
            outerCol = 2: outerAsc = False
            innerCol = 3: innerAsc = False
            bboxMinCol = 6: bboxMaxCol = 7
    End Select
    
    Dim n As Long
    n = UBound(pathArr, 1) - LBound(pathArr, 1) + 1
    
    ' Кластеризация по сетке (адаптивный шаг).
    Dim clusterId() As Long
    clusterId = ClusterByGrid(pathArr, outerCol, n)
    
    Dim i As Long
    Dim numClusters As Long
    numClusters = 0
    For i = 1 To n
        If clusterId(i) > numClusters Then numClusters = clusterId(i)
    Next i
    
    ' clusterId нумерует коридоры по ВОЗРАСТАНИЮ координаты.
    ' Для реверса outerAsc = False -> идём в обратном порядке кластеров.
    Dim res() As Variant
    ReDim res(1 To n, 1 To 2)
    Dim outRow As Long
    outRow = 0
    
    Dim cStart As Long, cEnd As Long, cStep As Long
    If outerAsc Then
        cStart = 1: cEnd = numClusters: cStep = 1
    Else
        cStart = numClusters: cEnd = 1: cStep = -1
    End If
    
    Dim outCorrIdx As Long
    outCorrIdx = 0
    
    Dim c As Long
    For c = cStart To cEnd Step cStep
        Dim ids() As Long
        Dim cnt As Long
        ReDim ids(1 To n)
        cnt = 0
        For i = 1 To n
            If clusterId(i) = c Then
                cnt = cnt + 1
                ids(cnt) = i
            End If
        Next i
        
        If cnt > 0 Then
            outCorrIdx = outCorrIdx + 1
            
            ' Сортируем ids по inner-координате с учётом innerAsc
            Dim aa As Long, bb As Long, tt As Long
            For aa = 1 To cnt - 1
                For bb = 1 To cnt - 1
                    Dim swap2 As Boolean
                    If innerAsc Then
                        swap2 = (CDbl(pathArr(ids(bb), innerCol)) > CDbl(pathArr(ids(bb + 1), innerCol)))
                    Else
                        swap2 = (CDbl(pathArr(ids(bb), innerCol)) < CDbl(pathArr(ids(bb + 1), innerCol)))
                    End If
                    If swap2 Then
                        tt = ids(bb)
                        ids(bb) = ids(bb + 1)
                        ids(bb + 1) = tt
                    End If
                Next bb
            Next aa
            
            Dim k As Long
            For k = 1 To cnt
                outRow = outRow + 1
                res(outRow, 1) = ids(k)
                res(outRow, 2) = outCorrIdx
            Next k
        End If
    Next c
    
    OrderDetailsForReverse = res
End Function

'================================================================
'================================================================
' Применить лид на готовый тулпат.
'   isInner = True  -> параметры внутреннего контура (p_AngleIn/p_LenIn)
'   isInner = False -> параметры внешнего контура (p_AngleOut/p_LenOut)
' Заход и выход одинаковые (как задумано).
'================================================================
Private Sub ApplyLead(tp As Path, isInner As Boolean)
    On Error Resume Next
    Dim ang As Double, ln As Double
    If isInner Then
        ang = p_AngleIn
        ln = p_LenIn
    Else
        ang = p_AngleOut
        ln = p_LenOut
    End If
    tp.SetLeadInOutAuto acamLeadBOTH, acamLeadBOTH, ln, ln, ang, False, False, p_Overlap
    On Error GoTo 0
End Sub

'================================================================
' Применить лид на тулпат, определив сторону по атрибуту ATTR_SIDE,
' который был поставлен на геометрию-копию (0=внутр, 1=внешн) и
' унаследован тулпатом. Надёжнее чем определять по чётности позиции.
'================================================================
Private Sub ApplyLeadByAttr(tp As Path)
    Dim sideVal As Integer
    sideVal = 0    ' по умолчанию внутренний
    On Error Resume Next
    sideVal = CInt(tp.Attribute(ATTR_SIDE))
    On Error GoTo 0
    
    ApplyLead tp, (sideVal = 0)
End Sub

Private Sub ConfigureMillData(MD As MillData)
    MD.SafeRapidLevel = SAFE_RAPID
    MD.RapidDownTo = RAPID_DOWN_TO
    MD.MaterialTop = p_MatTop
    MD.FinalDepth = p_MatBottom
    MD.XYCorners = acamCornersSTRAIGHT
    MD.McComp = acamCompMC
    MD.NumberOfCuts = 1
    
    ' Два набора лидов:
    '   LDI - для ВНУТРЕННЕГО контура (заход = выход = p_AngleIn/p_LenIn)
    '   LDO - для ВНЕШНЕГО контура   (заход = выход = p_AngleOut/p_LenOut)
    Set g_LDI = App.CreateLeadData
    g_LDI.LeadIn = acamLeadBOTH
    g_LDI.LeadOut = acamLeadBOTH
    g_LDI.LineArcInTangential = True
    g_LDI.LineArcOutTangential = True
    g_LDI.LengthIn = p_LenIn
    g_LDI.LengthOut = p_LenIn
    g_LDI.RadiusIn = p_LenIn
    g_LDI.RadiusOut = p_LenIn
    g_LDI.AngleIn = p_AngleIn
    g_LDI.AngleOut = p_AngleIn
    g_LDI.SlopeIn = False
    g_LDI.SlopeOut = False
    g_LDI.Overlap = p_Overlap
    
    Set g_LDO = App.CreateLeadData
    g_LDO.LeadIn = acamLeadBOTH
    g_LDO.LeadOut = acamLeadBOTH
    g_LDO.LineArcInTangential = True
    g_LDO.LineArcOutTangential = True
    g_LDO.LengthIn = p_LenOut
    g_LDO.LengthOut = p_LenOut
    g_LDO.RadiusIn = p_LenOut
    g_LDO.RadiusOut = p_LenOut
    g_LDO.AngleIn = p_AngleOut
    g_LDO.AngleOut = p_AngleOut
    g_LDO.SlopeIn = False
    g_LDO.SlopeOut = False
    g_LDO.Overlap = p_Overlap
    
    ' Лид для БЫСТРОГО режима: заход из "внутреннего" блока,
    ' выход из "внешнего". Применяется через MillData ДО RoughFinish,
    ' поэтому один RoughFinish на всю операцию даёт нужные лиды.
    Set g_LDFast = App.CreateLeadData
    g_LDFast.LeadIn = acamLeadBOTH
    g_LDFast.LeadOut = acamLeadBOTH
    g_LDFast.LineArcInTangential = True
    g_LDFast.LineArcOutTangential = True
    g_LDFast.LengthIn = p_LenIn        ' заход = "внутренний" блок
    g_LDFast.LengthOut = p_LenOut      ' выход = "внешний" блок
    g_LDFast.RadiusIn = p_LenIn
    g_LDFast.RadiusOut = p_LenOut
    g_LDFast.AngleIn = p_AngleIn
    g_LDFast.AngleOut = p_AngleOut
    g_LDFast.SlopeIn = False
    g_LDFast.SlopeOut = False
    g_LDFast.Overlap = p_Overlap
    
    ' По умолчанию ставим внутренний (перед каждым проходом переопределяем)
    MD.SetLeadData g_LDI
End Sub

'================================================================
Private Function ExtractPathData(selPaths As Paths) As Variant
    Dim arr() As Variant
    Dim i As Long, n As Long
    Dim p As Path
    
    n = selPaths.Count
    ReDim arr(1 To n, 1 To 9)
    
    For i = 1 To n
        Set p = selPaths.Item(i)
        arr(i, 1) = i
        arr(i, 2) = (p.MinXL + p.MaxXL) / 2
        arr(i, 3) = (p.MinYL + p.MaxYL) / 2
        Set arr(i, 4) = p
        arr(i, 5) = p.Length
        arr(i, 6) = p.MinXL
        arr(i, 7) = p.MaxXL
        arr(i, 8) = p.MinYL
        arr(i, 9) = p.MaxYL
    Next i
    
    ExtractPathData = arr
End Function

'================================================================
Private Sub BuildCornerSVMap(pathArr As Variant)
    Set g_CornerSV = CreateObject("Scripting.Dictionary")
    
    Dim n As Long
    n = UBound(pathArr, 1) - LBound(pathArr, 1) + 1
    If n = 0 Then Exit Sub
    
    Dim usedIdx As Object
    Set usedIdx = CreateObject("Scripting.Dictionary")
    
    Dim svOrder(1 To 4) As Integer
    svOrder(1) = SV_LEFT_BOTTOM
    svOrder(2) = SV_RIGHT_BOTTOM
    svOrder(3) = SV_RIGHT_TOP
    svOrder(4) = SV_LEFT_TOP
    
    Dim s As Integer
    For s = 1 To 4
        Dim sv As Integer
        sv = svOrder(s)
        
        Dim bestIdx As Long, bestKey As Long
        Dim bestScore As Double
        bestIdx = -1
        bestKey = -1
        bestScore = 0
        
        Dim i As Long
        For i = LBound(pathArr, 1) To UBound(pathArr, 1)
            Dim origIdx As Long
            origIdx = CLng(pathArr(i, 1))
            
            If Not usedIdx.Exists(origIdx) Then
                Dim cx As Double, cy As Double
                cx = CDbl(pathArr(i, 2))
                cy = CDbl(pathArr(i, 3))
                
                Dim score As Double
                score = CornerScore(cx, cy, sv)
                
                If bestIdx = -1 Or score > bestScore Then
                    bestIdx = i
                    bestScore = score
                    bestKey = origIdx
                End If
            End If
        Next i
        
        If bestIdx <> -1 Then
            g_CornerSV.Add bestKey, sv
            usedIdx.Add bestKey, True
        End If
    Next s
End Sub

Private Function CornerScore(cx As Double, cy As Double, sv As Integer) As Double
    Select Case sv
        Case SV_LEFT_BOTTOM:  CornerScore = -(cx + cy)
        Case SV_RIGHT_BOTTOM: CornerScore = cx - cy
        Case SV_RIGHT_TOP:    CornerScore = cx + cy
        Case SV_LEFT_TOP:     CornerScore = -cx + cy
    End Select
End Function

'================================================================
Private Sub ComputeStartPoint(minX As Double, maxX As Double, _
                               minY As Double, maxY As Double, _
                               offset As Double, _
                               ByRef sx As Double, ByRef sy As Double)
    If offset = 0 Then
        sx = maxX: sy = maxY
    ElseIf offset > 0 Then
        sx = maxX
        sy = maxY - offset
        If sy < minY Then sy = minY
    Else
        sx = maxX + offset
        sy = maxY
        If sx < minX Then sx = minX
    End If
End Sub

Private Sub EnsureStartFromTop(p As Path)
    On Error Resume Next
    Dim firstE As Element, lastE As Element
    Set firstE = p.GetFirstElem
    Set lastE = p.GetLastElem
    If firstE Is Nothing Or lastE Is Nothing Then
        On Error GoTo 0
        Exit Sub
    End If
    Dim sY As Double, eY As Double
    sY = firstE.StartYL
    eY = lastE.EndYL
    If eY > sY Then p.Reverse
    On Error GoTo 0
End Sub

'================================================================
' Поштучный выбор (для PICK_ORDER)
'================================================================
Private Function SelectGeosOneByOne(Drw As Drawing) As Paths
    Dim result As Paths
    Set result = Drw.CreatePathCollection
    
    Const MARKER_LAYER_NAME As String = "_PICK_MARKERS"
    Dim markerLayer As Layer
    Dim origLayer As Layer
    
    On Error Resume Next
    Set origLayer = Drw.GetLayer()
    If origLayer Is Nothing Then Set origLayer = Drw.GetFirstLayer
    Set markerLayer = Drw.CreateLayer(MARKER_LAYER_NAME)
    If Not markerLayer Is Nothing Then
        markerLayer.Visible = True
        markerLayer.Lock = False
    End If
    On Error GoTo 0
    
    Dim markers As Paths
    Set markers = Drw.CreatePathCollection
    
    Dim p As Path
    Dim count As Long
    count = 0
    
    Do
        On Error Resume Next
        If Not markerLayer Is Nothing Then markerLayer.Lock = True
        On Error GoTo 0
        
        Set p = Nothing
        On Error Resume Next
        Set p = Drw.UserSelectOneGeo( _
            "Выбери деталь #" & (count + 1) & " (Esc/ПКМ - закончить)")
        On Error GoTo 0
        
        If p Is Nothing Then Exit Do
        
        Dim alreadyIn As Boolean
        alreadyIn = False
        Dim k As Long
        For k = 1 To result.Count
            If result.Item(k) Is p Then alreadyIn = True: Exit For
        Next k
        
        If Not alreadyIn Then
            result.Add p
            count = count + 1
            
            On Error Resume Next
            If Not markerLayer Is Nothing Then
                markerLayer.Lock = False
                Drw.SetLayer markerLayer
            End If
            
            Dim bboxW As Double, bboxH As Double
            bboxW = p.MaxXL - p.MinXL
            bboxH = p.MaxYL - p.MinYL
            Dim dia As Double
            dia = (bboxW + bboxH) * 0.015
            If dia < 3 Then dia = 3
            If dia > 20 Then dia = 20
            
            Dim off As Double
            off = dia * 0.7
            Dim mx As Double, my As Double
            mx = p.MaxXL + off
            my = p.MaxYL + off
            
            Dim marker As Path
            Set marker = Drw.CreateCircle(dia, mx, my)
            If Not marker Is Nothing Then
                marker.SetLayer markerLayer
                markers.Add marker
            End If
            
            If Not origLayer Is Nothing Then Drw.SetLayer origLayer
            Drw.Redraw
            DoEvents
            On Error GoTo 0
        End If
    Loop
    
    On Error Resume Next
    If Not markerLayer Is Nothing Then markerLayer.Lock = False
    Drw.SetGeosSelected False
    Dim mi As Long
    For mi = 1 To markers.Count
        markers.Item(mi).Selected = True
    Next mi
    Drw.DeleteSelected
    Drw.SetGeosSelected False
    If Not markerLayer Is Nothing Then markerLayer.Delete
    If Not origLayer Is Nothing Then Drw.SetLayer origLayer
    Drw.Redraw
    On Error GoTo 0
    
    Set SelectGeosOneByOne = result
End Function

'================================================================
Private Function NextOpNo(Drw As Drawing) As Integer
    Dim n As Integer: n = 1
    On Error Resume Next
    n = Drw.Operations.Count + 1
    On Error GoTo 0
    NextOpNo = n
End Function

'================================================================
Private Function SortArray2D(arr As Variant, primaryCol As Integer, _
                             secondaryCol As Integer, _
                             primaryAsc As Boolean, _
                             secondaryAsc As Boolean) As Variant
    Dim res As Variant
    res = arr
    
    Dim lo As Long, hi As Long
    lo = LBound(res, 1)
    hi = UBound(res, 1)
    
    Dim i As Long, j As Long, k As Long, cols As Long
    Dim p1 As Double, p2 As Double, s1 As Double, s2 As Double
    Dim swap As Boolean, tmp As Variant
    cols = UBound(res, 2)
    
    For i = lo To hi - 1
        For j = lo To hi - 1
            p1 = CDbl(res(j, primaryCol))
            p2 = CDbl(res(j + 1, primaryCol))
            s1 = CDbl(res(j, secondaryCol))
            s2 = CDbl(res(j + 1, secondaryCol))
            
            swap = False
            If p1 <> p2 Then
                If primaryAsc Then swap = (p1 > p2) Else swap = (p1 < p2)
            Else
                If secondaryAsc Then swap = (s1 > s2) Else swap = (s1 < s2)
            End If
            
            If swap Then
                For k = 1 To cols
                    If IsObject(res(j, k)) Then
                        Dim ot As Object
                        Set ot = res(j, k)
                        Set res(j, k) = res(j + 1, k)
                        Set res(j + 1, k) = ot
                    Else
                        tmp = res(j, k)
                        res(j, k) = res(j + 1, k)
                        res(j + 1, k) = tmp
                    End If
                Next k
            End If
        Next j
    Next i
    
    SortArray2D = res
End Function

Private Function ExtractSubArray(arr As Variant, fromRow As Long, _
                                  toRow As Long) As Variant
    Dim cols As Long
    cols = UBound(arr, 2)
    
    Dim res() As Variant
    ReDim res(1 To (toRow - fromRow + 1), 1 To cols)
    
    Dim i As Long, k As Long, idx As Long
    idx = 1
    For i = fromRow To toRow
        For k = 1 To cols
            If IsObject(arr(i, k)) Then
                Set res(idx, k) = arr(i, k)
            Else
                res(idx, k) = arr(i, k)
            End If
        Next k
        idx = idx + 1
    Next i
    
    ExtractSubArray = res
End Function
