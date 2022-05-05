VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmMain 
   Caption         =   "Cutting v-0.75"
   ClientHeight    =   6975
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   5985
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
    TextBox6.Enabled = True
    TextBox7.Enabled = False
End Sub

Private Sub OptionButton4_Click()
    TextBox6.Enabled = False
    TextBox7.Enabled = True
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
  
End Sub
