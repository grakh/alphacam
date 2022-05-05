VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "GeoClass"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
' GeoClass
Private dInd As Integer
Private dName As Integer
Private dX As Double
Private dY As Double

Property Let Ind(dValue As Integer)
    dInd = dValue
End Property

Property Let Name(dValue As Integer)
    dName = dValue
End Property

Property Let X(dValue As Double)
    dX = dValue
End Property

Property Let Y(dValue As Double)
    dY = dValue
End Property

Property Get Ind() As Integer
    Ind = dInd
End Property

Property Get Name() As Integer
    Name = dName
End Property

Property Get X() As Double
    X = dX
End Property

Property Get Y() As Double
    Y = dY
End Property
