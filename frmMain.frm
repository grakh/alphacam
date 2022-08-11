VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmMain 
   Caption         =   "Cutting v-2.1"
   ClientHeight    =   7410
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   5955
   OleObjectBlob   =   "frmMain.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub btCancel_Click()
    End
End Sub

Private Sub btOk_Click()
    frmMain.Hide
    DoEvents
    
    CreatePrimitive Val(TextBox1.Text)
End Sub

Private Sub OptionButton3_Click()
   ' TextBox6.Enabled = True
   ' TextBox7.Enabled = False
End Sub

Private Sub OptionButton4_Click()
   ' TextBox6.Enabled = False
   ' TextBox7.Enabled = True
End Sub

Private Sub CheckBox1_Click()
    If CheckBox1.Value = True Then
        Frame5.Caption = "Элементов в одной программе"
        TextBox7.Enabled = False
    Else:
        Frame5.Caption = "Программ в одной линии"
        TextBox7.Enabled = True
    End If
End Sub

Private Sub SpinButton1_Change()
TextBox12.Value = SpinButton1.Value
End Sub

Private Sub TextBox10_Change()
If IsNumeric(TextBox10.Value) = False Then TextBox10.Value = ""
End Sub

Private Sub TextBox11_Change()
If IsNumeric(TextBox11.Value) = False Then TextBox11.Value = ""
End Sub

Private Sub TextBox12_Change()
If IsNumeric(TextBox12.Value) = False Then TextBox12.Value = ""
End Sub

Private Sub TextBox13_Change()
If IsNumeric(TextBox13.Value) = False Then TextBox13.Value = ""
End Sub

Private Sub TextBox2_Change()
If IsNumeric(TextBox2.Value) = False Then TextBox2.Value = ""
End Sub

Private Sub TextBox3_Change()
If IsNumeric(TextBox3.Value) = False Then TextBox3.Value = ""
End Sub

Private Sub TextBox4_Change()
If IsNumeric(TextBox4.Value) = False Then TextBox4.Value = ""
End Sub

Private Sub TextBox5_Change()
If IsNumeric(TextBox5.Value) = False Then TextBox5.Value = ""
End Sub

Private Sub TextBox6_Change()
If IsNumeric(TextBox6.Value) = False Then TextBox6.Value = ""
End Sub

Private Sub TextBox7_Change()
If IsNumeric(TextBox7.Value) = False Then TextBox7.Value = ""
End Sub

Private Sub TextBox8_Change()
If IsNumeric(TextBox8.Value) = False Then TextBox8.Value = ""


End Sub

Private Sub TextBox9_Change()
If IsNumeric(TextBox9.Value) = False Then TextBox9.Value = ""
End Sub

Private Sub UserForm_Initialize()
  ComboBox1.AddItem "1_2"
  ComboBox1.AddItem "0_8"
  ComboBox1.AddItem "0_6"
  ComboBox1.AddItem "1_0"
  
  ComboBox2.AddItem "90"
  ComboBox2.AddItem "80"
  ComboBox2.AddItem "70"
  ComboBox2.AddItem "60"
  ComboBox2.AddItem "50"
  ComboBox2.AddItem "75"
  ComboBox2.AddItem "100"
  
  ' TextBox6.Enabled = False
  TextBox7.Enabled = True
  TextBox8.MaxLength = 2
  TextBox10.MaxLength = 2
  
End Sub
