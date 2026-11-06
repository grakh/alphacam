Attribute VB_Name = "OrderComments"
'================================================================
' Alphacam VBA - Комментарии к заказу из XML спецификации
'
' По номеру заказа читает файл спецификации и показывает
' комментарии к заказу:
'   - КомментарийКонтрагента  (атрибут корня)   -> "контрагент"
'   - Комментарий             (атрибут корня)   -> "обычный"
'   - ПользовательскийКомментарий + time (узел)  -> "пользователь"
'
' Путь к XML строится так же, как в пост-процессоре OutNC:
'   \\storage\Zakaz\<PPP>000-<PPP>999\<NNN>\XML\specification_<NNN>.xml
'   где <PPP> = номер заказа без последних 3 цифр, <NNN> = номер заказа.
'
' Запуск: ShowOrderComments
'================================================================

Option Explicit

' Базовая папка заказов (как в посте). При необходимости поменять.
Private Const ZAKAZ_ROOT As String = "\\storage\Zakaz\"

'================================================================
' ОСНОВНОЙ МАКРОС
'================================================================
Public Sub ShowOrderComments()
    Dim orderNum As String

    ' Номер по умолчанию - из имени чертежа (первый числовой токен > 1000),
    ' как в UserForm_Activate поста (split по "_").
    orderNum = GuessOrderFromDrawing()

    ' Спросить/подтвердить номер
    orderNum = InputBox("Введите номер заказа:", "Комментарии к заказу", orderNum)
    If Len(Trim(orderNum)) = 0 Then Exit Sub
    orderNum = Trim(orderNum)

    If Not IsNumeric(orderNum) Then
        MsgBox "Номер заказа должен быть числом.", vbExclamation, "Комментарии к заказу"
        Exit Sub
    End If
    If CDbl(orderNum) <= 1000 Then
        MsgBox "Номер заказа должен быть больше 1000.", vbExclamation, "Комментарии к заказу"
        Exit Sub
    End If

    ' Путь к файлу спецификации
    Dim xmlPath As String
    xmlPath = BuildSpecPath(orderNum)

    ' Проверка наличия файла
    On Error Resume Next
    Dim exists As Boolean
    exists = (Dir(xmlPath, vbNormal) <> "")
    If Not exists Then exists = (Dir(xmlPath, vbSystem) <> "")
    On Error GoTo 0

    If Not exists Then
        MsgBox "Файл спецификации не найден:" & vbCrLf & xmlPath, _
               vbExclamation, "Комментарии к заказу"
        Exit Sub
    End If

    ' Загрузка XML
    Dim XDoc As Object
    Set XDoc = CreateObject("MSXML2.DOMDocument")
    XDoc.async = False
    XDoc.validateOnParse = False

    If Not XDoc.Load(xmlPath) Then
        MsgBox "Не удалось прочитать XML:" & vbCrLf & xmlPath, _
               vbExclamation, "Комментарии к заказу"
        Set XDoc = Nothing
        Exit Sub
    End If

    Dim root As Object
    Set root = XDoc.documentElement        ' <Спецификация>
    If root Is Nothing Then
        MsgBox "Пустой или некорректный XML.", vbExclamation, "Комментарии к заказу"
        Set XDoc = Nothing
        Exit Sub
    End If

    ' --- Чтение данных ---
    Dim orderName As String, buyer As String, dateMake As String, approved As String
    orderName = GetAttr(root, "НаименованиеЗаказа")
    buyer = GetAttr(root, "Покупатель")
    dateMake = GetAttr(root, "ДатаИзготовления")
    approved = GetAttr(root, "УтвердилСпецификацию")

    Dim cContragent As String, cComment As String
    cContragent = GetAttr(root, "КомментарийКонтрагента")
    cComment = GetAttr(root, "Комментарий")

    Dim cUser As String, cUserTime As String
    Dim userNode As Object
    Set userNode = root.selectSingleNode("ПользовательскийКомментарий")
    If Not userNode Is Nothing Then
        cUser = Trim(userNode.Text)
        cUserTime = GetAttr(userNode, "time")
    End If

    Set XDoc = Nothing

    ' --- Формирование сообщения ---
    Dim msg As String
    msg = "Заказ № " & orderNum
    If Len(orderName) > 0 Then msg = msg & "   " & orderName
    msg = msg & vbCrLf
    If Len(buyer) > 0 Then msg = msg & buyer & vbCrLf
    If Len(dateMake) > 0 Then msg = msg & "Дата изготовления: " & dateMake & vbCrLf
    msg = msg & String(40, "-") & vbCrLf

    msg = msg & "Комментарий контрагента:" & vbCrLf
    msg = msg & "   " & IIf(Len(cContragent) > 0, cContragent, "(нет)") & vbCrLf & vbCrLf

    msg = msg & "Комментарий:" & vbCrLf
    msg = msg & "   " & IIf(Len(cComment) > 0, cComment, "(нет)") & vbCrLf & vbCrLf

    msg = msg & "Пользовательский комментарий"
    If Len(cUserTime) > 0 Then msg = msg & " (" & cUserTime & ")"
    msg = msg & ":" & vbCrLf
    msg = msg & "   " & IIf(Len(cUser) > 0, cUser, "(нет)")

    If Len(approved) > 0 Then
        msg = msg & vbCrLf & String(40, "-") & vbCrLf
        msg = msg & "Утвердил спецификацию: " & approved
    End If

    MsgBox msg, vbInformation, "Комментарии к заказу № " & orderNum
End Sub

'================================================================
' Построение пути к файлу спецификации (как в посте OutNC).
'================================================================
Private Function BuildSpecPath(ByVal orderNum As String) As String
    Dim prefix As String
    prefix = Left(orderNum, Len(orderNum) - 3)    ' номер без последних 3 цифр

    BuildSpecPath = ZAKAZ_ROOT & _
                    prefix & "000-" & prefix & "999\" & _
                    orderNum & "\XML\specification_" & orderNum & ".xml"
End Function

'================================================================
' Номер заказа из имени чертежа: первый числовой токен > 1000
' среди частей, разделённых "_".
'================================================================
Private Function GuessOrderFromDrawing() As String
    GuessOrderFromDrawing = ""
    On Error Resume Next

    Dim nm As String
    nm = App.ActiveDrawing.Name
    If Len(nm) = 0 Then Exit Function

    ' Отрезаем расширение, если есть
    Dim dotPos As Long
    dotPos = InStrRev(nm, ".")
    If dotPos > 0 Then nm = Left(nm, dotPos - 1)

    Dim parts() As String, i As Long
    parts = Split(nm, "_")
    For i = LBound(parts) To UBound(parts)
        Dim tok As String
        tok = Trim(parts(i))
        If IsNumeric(tok) Then
            If CDbl(tok) > 1000 Then
                GuessOrderFromDrawing = tok
                Exit Function
            End If
        End If
    Next i

    On Error GoTo 0
End Function

'================================================================
' Чтение атрибута узла. Возвращает "" если атрибута нет.
'================================================================
Private Function GetAttr(node As Object, ByVal attrName As String) As String
    GetAttr = ""
    On Error Resume Next
    Dim a As Object
    Set a = node.Attributes.getNamedItem(attrName)
    If Not a Is Nothing Then GetAttr = Trim(a.Text)
    On Error GoTo 0
End Function
