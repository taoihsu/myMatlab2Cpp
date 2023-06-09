Imports VB = Microsoft.VisualBasic
Imports Scripting
'Imports System.IO

Public Class frmMain
#Region "Form Level Declarations"

   'Cognex
   Public WithEvents clsVPRO As clsVPROSupport

   'RSLinx OPC
   ' Create OPC instances
   Public FlexiblePLC As myOPC.myOPC = New myOPC.myOPC
   Public IndustrialAutomationPLC As myOPC.myOPC = New myOPC.myOPC

#End Region

#Region "Main Form Event Routines"
   Private Sub me_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        DeskDebug = False



      '2014-9-19 *START potter added the frmCompareDB dialog
      frmCompareDB.Show()
      System.Windows.Forms.Application.DoEvents()
      Threading.Thread.Sleep(500)
      Call CompareDatabase()
      frmCompareDB.Close()
      frmCompareDB.Dispose()
      '2014-9-19 *END 


      'This line of code loads data into the 'ProductInfoDataSet.Info' table. You can move, or remove it, as needed.
      Me.InfoTableAdapter.Fill(Me.ProductInfoDataSet.Info)

      'Set Default View To The Main Tabs And Remove The ManualControl Tab From View
      tbcMain.SelectTab(tabMainTest)
      tbcMain.TabPages.Remove(tabManualControl)
      IOTabVisable = False

      'Update Labels On I/O Form And Channel Maps
      GetTesterSpec("Tester")
      GetTesterSpec("TesterSpecificPaths") '1-11-14 jgk added

      GetTesterSpec("DAQ_USB_6525_Port_0_Channel_Map")
      GetTesterSpec("DAQ_USB_6525_Port_1_Channel_Map")
      GetTesterSpec("DAQ_USB_6525_Port_0_1_Channel_Map")
      GetTesterSpec("DAQ_USB_6525_Port_1_1_Channel_Map")

      GetTesterSpec("DAQ_USB_6009_AI_Channel_Map")

      If MCC_USB_3112_DeviceName IsNot Nothing Then
         If MCC_USB_3112_DeviceName.ToUpper <> "NA" Then
            'TODO: add code to show tab3112 of tbcGeneralIO ...after setting up to default to not be visible
            GetTesterSpec("DAQ_USB_31XX_AO_Channel_Map")
         End If
      End If

      InitializeHardware()

      Call SetLightingDefaultLevels()

      Me.Show()

      'Login An Operato
      frmPassword.ShowDialog()

      'Load A Part Number
      frmLoadPartNumber.ShowDialog()


      ' Set AutoMatic Mode To True As Default
      FullAuto = True
      tmrAutomaticMode.Enabled = True
      '2017-6-27 potter added
      tmrTestingDUT.Enabled = True
      TestingDUTTesting = False

   End Sub
   Private Sub me_FormClosing(ByVal sender As Object, ByVal e As System.Windows.Forms.FormClosingEventArgs) Handles Me.FormClosing

      MasterReset()

      clsVPRO.Dispose()

      End
   End Sub

#End Region 'End Main Form Event Routines

#Region "Menu Functions"
   Public Sub mnuAddOpp_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuAddOpp.Click
      Dim AddOpDBConString As String = My.Settings.TesterSpecConnectionString
      Dim AddOpDBConnection As OleDb.OleDbConnection = Nothing
      Dim AddOpDBCmdString As String = ""
      Dim AddOpDBCmd As OleDb.OleDbCommand = Nothing

      Dim AuthorizeOp As String = ""
      Dim CurrentOp As String = ""
      Dim CurrentType As String = ""
      Dim NewOp As String = ""
      Dim NewType As String = ""
      Dim resp As Int16
      Dim Status As Int16 = 1

      CurrentOp = OperatorScan
      CurrentType = TypeScan

      If CurrentType = "O" Then
         MessageBox.Show("A Supervisor or Admin must Login First", "AUTHORIZING LOGIN", MessageBoxButtons.OK, MessageBoxIcon.Exclamation)
         frmPassword.ShowDialog()
         Do Until TypeScan = "S" Or TypeScan = "A"
            System.Windows.Forms.Application.DoEvents()
            If LoginCancel = True Then
               LoginCancel = False
               OperatorScan = CurrentOp
               TypeScan = CurrentType
               Exit Sub
            End If
         Loop
         AuthorizeOp = OperatorScan
      End If

      AuthorizeOp = OperatorScan

      NewOp = Microsoft.VisualBasic.InputBox("Enter Name of the new Operator", "Name?", "", Me.Width / 2, Me.Height / 2)

      If NewOp = "" Then Exit Sub

      NewType = Microsoft.VisualBasic.InputBox("Enter their login type" & Microsoft.VisualBasic.ControlChars.CrLf & Microsoft.VisualBasic.ControlChars.CrLf & "O = Operator" & Microsoft.VisualBasic.ControlChars.CrLf & "S = Supervisor" & Microsoft.VisualBasic.ControlChars.CrLf & "L = Limited Tech (Cannot clear stack/errors)" & Microsoft.VisualBasic.ControlChars.CrLf & "T = Tech" & Microsoft.VisualBasic.ControlChars.CrLf & "A = Admin", "Login Type?", "O", Me.Width / 2, Me.Height / 2).ToUpper
      If NewType = "" Then Exit Sub

      If OperatorScan = "S" And NewType <> "O" Then
         MessageBox.Show("You are only authorized to add operators!" & Microsoft.VisualBasic.ControlChars.CrLf & Microsoft.VisualBasic.ControlChars.CrLf & "Contact the Test Engineer", "ATTENTION!", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         OperatorScan = CurrentOp
         TypeScan = CurrentType
         Exit Sub
      End If

      resp = MessageBox.Show("By adding this operator, you are stating that they have been trained to run this FFT." & Microsoft.VisualBasic.ControlChars.CrLf & Microsoft.VisualBasic.ControlChars.CrLf & "  Do you want to continue?", "VERIFY", MessageBoxButtons.YesNo, MessageBoxIcon.Question)
      If resp = DialogResult.No Then
         OperatorScan = CurrentOp
         TypeScan = CurrentType
         Exit Sub
      End If

      MessageBox.Show("Have the New Operator Enter thier Password", "NEW LOGIN", MessageBoxButtons.OK, MessageBoxIcon.Information)
      NewLogin = ""
      NewOpFlag = True
      frmPassword.ShowDialog()
      Do Until NewLogin <> ""
         System.Windows.Forms.Application.DoEvents()
         If LoginCancel = True Then
            LoginCancel = False
            OperatorScan = CurrentOp
            TypeScan = CurrentType
            NewOpFlag = False
            Exit Sub
         End If
      Loop
      NewOpFlag = False

      Try
         AddOpDBConnection = New OleDb.OleDbConnection(AddOpDBConString)
         AddOpDBConnection.Open()
         AddOpDBCmdString = "INSERT INTO Operator Values('" & NewLogin & "','" & NewOp & "','" & NewType & "','" & AuthorizeOp & "')" 'Insert Command
         AddOpDBCmd = New OleDb.OleDbCommand(AddOpDBCmdString, AddOpDBConnection)
         Status = AddOpDBCmd.ExecuteNonQuery
         OperatorScan = NewOp
         TypeScan = NewType
         AddOpDBCmd.Dispose() 'Done in Test sequence table
         AddOpDBConnection.Close()
      Catch ex As Exception
         WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, True, "ERROR CREATING NEW OPERATOR")
         If AddOpDBCmd IsNot Nothing Then
            AddOpDBCmd.Dispose() 'Done in Test sequence table
         End If
         If AddOpDBConnection IsNot Nothing Then
            AddOpDBConnection.Close()
         End If

      End Try

   End Sub

   Public Sub mnuBypass_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuBypass.Click

      If mnuBypass.Checked = True Then
         mnuBypass.Checked = False
         GNGBypass = False
         Call DetermineIFGoNoGoModeRequired()
      Else
         mnuBypass.Checked = True
         GNGBypass = True
         If TestMode = "G" Then
            Dim Result As Boolean = ChangeProduct(SelectedPartNumberBeforeRunningGNGs) 'change part number after completing gonogos '5-13-13 jgk added here too
            Call UpdateMode("Normal")
            Call UpdateGrid("Clear")
            '2018-5-6 potter added traceabilityenable judgement
            '2017-6-27 Potter write FFTReady=0 
            If ProductInfo.TraceabilityEnable = True Then
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
            Else
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
            End If
         End If
      End If
      GNGBypass = mnuBypass.Checked

   End Sub

   Public Sub mnuClearError_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuClearError.Click
      Dim abc As Integer
      abc = MessageBox.Show("Has Error Condition has been Corrected?", "ATTENTION", MessageBoxButtons.YesNo, MessageBoxIcon.Question)
      If abc = DialogResult.Yes Then
         ErrorFlag = False
      End If
   End Sub

   Public Sub mnuClearFailures_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuClearFailures.Click
      Dim DownTimeOperator As String
      Dim DownTimeReason As String
      Dim DownTimeTimer As TimeSpan
      Dim CurrentOp As String
      Dim CurrentType As String

      CurrentOp = OperatorScan
      CurrentType = TypeScan

      DownTimeTimer = DateTime.Now.TimeOfDay

      Do Until TypeScan = "T" Or TypeScan = "A"
         frmPassword.ShowDialog()
         System.Windows.Forms.Application.DoEvents()
         If LoginCancel = True Then
            LoginCancel = False
            OperatorScan = CurrentOp
            TypeScan = CurrentType
            Exit Sub
         End If
      Loop

      If (UnauthorizedRetest = False And (TypeScan = "T" Or TypeScan = "A")) Or (UnauthorizedRetest = True And (TypeScan = "S" Or TypeScan = "A")) Then
         FailClearLogin = OperatorScan
         Call ButtonsOn()
         OperatorScan = CurrentOp
         TypeScan = CurrentType
         FailCount = 0
         UpdateModeUnits("Failure")
         FailureHistory(0) = ""
         FailureHistory(1) = ""
         FailureHistory(2) = ""
         FailureHistory(3) = ""
         UnauthorizedRetest = False
         'TotalPassed = 0
         'TotalFailed = 0
         'TotalTested = 0
         'Me.lblNumberOfPartsPassed.Text = ""
         'Me.lblNumberOfPartsFailed.Text = ""
         'Me.lblNumberOfPartsTested.Text = ""
         ''Write Variables To Database So They Can Be Re-Loaded At Powerup)
         'WriteTesterSpecField("Tester", "TotalPassed", TotalPassed.ToString)
         'WriteTesterSpecField("Tester", "TotalFailed", TotalFailed.ToString)
         'WriteTesterSpecField("Tester", "TotalTested", TotalTested.ToString)
      Else
         MessageBox.Show("YOU ARE NOT AUTHORIZED TO CLEAR THE FAILURES!", "ACCESS DENIED!", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         Exit Sub
      End If
      DownTimeReason = "Clear Failures"
      DownTimeOperator = FailClearLogin
      Call Log_DownTimeData()
      If MessageBox.Show("Do you want to enter Retest Mode?", "Enter Retest Mode?", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
         '2014-1-16 Potter Added
         Me.rbRetest.Checked = True
         RetestCount = 1 'set retestcount to 1, make sure just can retest once
         'Call UpdateMode("Retest")
      End If

      TypeScan = CurrentType
      OperatorScan = CurrentOp
      Me.lblCurrentOperator.Text = OperatorScan
      Me.lblOperator.Text = OperatorScan

   End Sub

   Public Sub mnuExit_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuExit.Click
      Call ResetLightingLevels()
      Me.Close()
   End Sub

   Public Sub mnuHaltonTest_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuHaltonTest.Click
      If mnuHaltonTest.Checked = False Then
         StopSeq = Convert.ToSingle(Microsoft.VisualBasic.InputBox("Enter the sequence number to stop on", "Halt On Test"))
         If StopSeq > 0 Then
            mnuHaltonTest.Checked = True
         End If
      Else
         mnuHaltonTest.Checked = False
      End If
      HaltonTest = mnuHaltonTest.Checked
   End Sub

   Public Sub mnuIODebug_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs)

   End Sub

   Public Sub mnuLoop_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuLoop.Click
      If mnuTechMode.Checked = False Then
         mnuLoop.Checked = False
         NumLoopsWanted = 0
         LoopDelay = 0
      Else
         If mnuLoop.Checked = True Then
            mnuLoop.Checked = False
            NumLoopsWanted = 0
            LoopDelay = 0
         Else
            mnuLoop.Checked = True
            NumLoopsWanted = Convert.ToInt16(Microsoft.VisualBasic.InputBox("Enter the number of loops to run, enter 0 to run infinite", "Number of Loops?"))
            LoopDelay = Convert.ToSingle(Microsoft.VisualBasic.InputBox("Enter the delay time between loops", "Delay?"))
         End If
      End If
      LoopTest = mnuLoop.Checked
   End Sub

   Public Sub mnuMultipleFailures_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuMultipleFailures.Click
      If mnuTechMode.Checked = False Then
         mnuMultipleFailures.Checked = False
      Else
         If mnuMultipleFailures.Checked = True Then
            mnuMultipleFailures.Checked = False
         Else
            mnuMultipleFailures.Checked = True
         End If
      End If
      MultipleFailures = mnuMultipleFailures.Checked
   End Sub

   Private Sub mnuStepTest_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles mnuStepTest.Click
      If mnuTechMode.Checked = False Then
         mnuStepTest.Checked = False
      Else
         If mnuStepTest.Checked = True Then
            mnuStepTest.Checked = False
         Else
            mnuStepTest.Checked = True
         End If
      End If
      StepTest = mnuStepTest.Checked
   End Sub

   Public Sub mnuPrintBox_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs)
   End Sub

   Public Sub mnuPrintLabels_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuPrintLabels.Click
      If mnuTechMode.Checked = False Then
         mnuPrintLabels.Checked = False
      Else
         If mnuPrintLabels.Checked = True Then
            mnuPrintLabels.Checked = False
         Else
            mnuPrintLabels.Checked = True
         End If
      End If
      PrintLabels = mnuPrintLabels.Checked
   End Sub

   Public Sub mnuTech_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuTech.Click
      If TypeScan = "T" Or TypeScan = "A" Then
         mnuTechMode.Enabled = True
         mnuLoop.Enabled = True
         mnuPrintLabels.Enabled = True
         mnuStepTest.Enabled = True
         mnuMultipleFailures.Enabled = True
         mnuBypass.Enabled = True
         mnuOptionHalt.Enabled = True
         mnuHaltonTest.Enabled = True
         mnuClearFailures.Enabled = True
         mnuClearError.Enabled = True

      Else
         mnuLoop.Enabled = False
         mnuTechMode.Enabled = False
         mnuPrintLabels.Enabled = False
         mnuStepTest.Enabled = False
         mnuMultipleFailures.Enabled = False
         If GNGBypass = True Then
            mnuBypass.Enabled = True
         Else
            mnuBypass.Enabled = False
         End If
         mnuOptionHalt.Enabled = False
         mnuHaltonTest.Enabled = False
         mnuClearFailures.Enabled = False
         mnuClearError.Enabled = False
      End If

   End Sub

   Public Sub mnuOptionHalt_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuOptionHalt.Click
      If (Me.mnuOptionHalt.Checked = True) Then
         Me.mnuOptionHalt.Checked = False
      Else
         Me.mnuOptionHalt.Checked = True
      End If
      OptionHalt = Me.mnuOptionHalt.Checked
   End Sub

   Public Sub mnuTechMode_Click(ByVal eventSender As System.Object, ByVal eventArgs As System.EventArgs) Handles mnuTechMode.Click
      If Me.mnuTechMode.Checked = False Then
         Call UpdateMode("Tech")
         Call UpdateMode("FullAutoFalse")
         '2017-6-27 Potter write FFTReady=1 
         Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
      Else
         Call UpdateMode("FullAutoTrue") '5-13-13 jgk move this call before Call UpdateMode("Normal") to get Start mode to not be visible
         Call UpdateMode("Normal")
         Call DetermineIFGoNoGoModeRequired()

         '2018-5-6 potter added traceabilityenable judgement
         '2017-6-27 Potter write FFTReady=0 
         If ProductInfo.TraceabilityEnable = True Then
            Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
         Else
            Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
         End If
      End If

   End Sub

   Sub UpdateMode(ByRef Choice As String)
      'Updates Menu Items, Variables and Screen Colors
      Dim Title As String
      Dim Message As String

      Select Case Choice
         Case "Normal"
            Application.DoEvents()
            If Me.tsAutomaticMode.Checked = True Then
               Me.cmdStart.Visible = False
            Else
               Me.cmdStart.Visible = True
            End If
            Me.mnuStepTest.Checked = False
            StepTest = False
            Me.mnuMultipleFailures.Checked = False
            MultipleFailures = False
            Me.mnuOptionHalt.Checked = False
            OptionHalt = False
            Me.mnuHaltonTest.Checked = False
            HaltonTest = False
            Me.mnuLoop.Checked = False
            LoopTest = False
            Me.mnuPrintLabels.Checked = False
            PrintLabels = False
            Me.mnuTechMode.Checked = False
            Me.rbNormal.Checked = True
            Me.lblCurrentMode.Text = "NORMAL"
            Me.tabMainTest.BackColor = System.Drawing.Color.WhiteSmoke
            UpdateModeUnits("Failures")
            TestMode = " "
            ''2013-12-3 Potter Added txtCarrier
            'txtCarrier.Text = ""
            'txtCarrier.Focus()

         Case "GoNoGo"
            If numGoNoGos > 0 Then 'Only enter GONOGOMODE if units are setup
               Me.UpdateDUTStatus("Clear")

               NumGoNoGosToGo = numGoNoGos
               For j = 0 To 10
                  GNGLoaded(j) = False
                  GNGDone(j) = False
               Next j

               If Me.tsAutomaticMode.Checked = True Then Me.cmdStart.Visible = False

               UpdateModeUnits("None")

               Me.mnuStepTest.Checked = False
               StepTest = False
               Me.mnuMultipleFailures.Checked = False
               MultipleFailures = False
               Me.mnuOptionHalt.Checked = False
               OptionHalt = False
               Me.mnuHaltonTest.Checked = False
               HaltonTest = False
               Me.mnuPrintLabels.Checked = False
               PrintLabels = False
               Me.mnuTechMode.Checked = False
               Me.mnuLoop.Checked = False
               LoopTest = False
               Me.mnuBypass.Checked = False

               GNGBypass = False

               Me.lblCurrentMode.Text = "GO/NOGO"
               Me.tabMainTest.BackColor = System.Drawing.Color.LimeGreen

               TestMode = "G"

               MessageBox.Show("NOW ENTERING GO/NO GO MODE", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Information)

               UpdateDataTextBox("Clear")
               'UpdateGrid("Clear", 0)

               UpdateGrid("GNG", 0)
            Else
               MessageBox.Show("Fault: No Go Nogo's found in database, Call Test Tech", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Information)
            End If

         Case "Tech"
            Me.cmdStart.Visible = True
            Me.mnuLoop.Checked = False
            LoopTest = False
            Me.lblModeUnitCaption.Visible = False
            Me.mnuStepTest.Checked = False
            StepTest = False
            Me.mnuMultipleFailures.Checked = False
            MultipleFailures = False
            Me.mnuOptionHalt.Checked = False
            OptionHalt = False
            Me.mnuHaltonTest.Checked = False
            HaltonTest = False
            Me.mnuPrintLabels.Checked = False
            PrintLabels = False
            Me.mnuBypass.Checked = False
            GNGBypass = False
            Me.mnuTechMode.Checked = True
            Me.lblCurrentMode.Text = "TECH"
            Me.tabMainTest.BackColor = System.Drawing.Color.DarkKhaki
            TestMode = "T"
            Call UpdateModeUnits("Failures")
            FullAuto = False

         Case "Retest"
            Call UpdateDUTStatus("Clear")
            If Me.tsAutomaticMode.Checked = True Then Me.cmdStart.Visible = False
            LoopTest = False
            '2014-5-4 Potter added authority control
            If TypeScan = "O" Then
               RetestCount = 1
            Else
               Message = "Enter the Number of Parts to be Retested:" ' Set prompt.
               Title = "Number of Parts?" ' Set title.
               RetestCount = 0
               RetestCount = Convert.ToInt16(Val(Microsoft.VisualBasic.InputBox(Message, Title, "")))
               If RetestCount <= 0 Then RetestCount = 1
            End If

            UpdateModeUnits("Retest")
            Me.mnuStepTest.Checked = False
            StepTest = False
            Me.mnuMultipleFailures.Checked = False
            MultipleFailures = False
            Me.mnuOptionHalt.Checked = False
            OptionHalt = False
            Me.mnuHaltonTest.Checked = False
            HaltonTest = False
            Me.mnuPrintLabels.Checked = False
            PrintLabels = False
            Me.mnuTechMode.Checked = False
            Me.lblCurrentMode.Text = "RETEST"
            Me.tabMainTest.BackColor = System.Drawing.Color.Yellow
            TestMode = "R"

         Case "Clear"
            If Me.tsAutomaticMode.Checked = True Then Me.cmdStart.Visible = False
            Me.lblModeUnitCaption.Visible = False
            Me.mnuStepTest.Checked = False
            StepTest = False
            Me.mnuMultipleFailures.Checked = False
            MultipleFailures = False
            Me.mnuOptionHalt.Checked = False
            OptionHalt = False
            Me.mnuHaltonTest.Checked = False
            HaltonTest = False
            Me.mnuPrintLabels.Checked = False
            PrintLabels = False
            Me.mnuTechMode.Checked = False
            Me.lblCurrentMode.Text = ""
            Me.tabMainTest.BackColor = System.Drawing.Color.RoyalBlue
            TestMode = " "
            UpdateModeUnits("Failures")

         Case "FullAutoFalse"
            tsAutomaticMode.Checked = False
            lblAutoMode.Text = "Manual Mode"
            FullAuto = False
            tmrAutomaticMode.Enabled = False

         Case "FullAutoTrue"
            tsAutomaticMode.Checked = True
            lblAutoMode.Text = "Automatic Mode"
            tmrAutomaticMode.Enabled = True
            FullAuto = True
      End Select

      Me.lblCurrentMode.Text = Me.lblCurrentMode.Text
      Me.lblCurrentMode.BackColor = Me.BackColor
      Me.Refresh()
      'System.Windows.Forms.Application.DoEvents()
   End Sub

#End Region 'End Menu Functions Region

#Region "IO Tab Communication Routines"
   Private Sub cmdEraseCalibrationBlock_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdEraseCalibrationBlock.Click
      'This Command Will Erase The Calibration Block (of Memory) In Miami-Lite Cameras
      Camera.EraseCalibrationBlock()
   End Sub

   Private Sub cmdReadSupportedPlatformID_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadSupportedPlatformID.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtSupportedPlatformID.Text = ""
      Me.txtSupportedPlatformID.Text = Camera.SupportedPlatformIDs
      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadPlatformID_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadPlatformID.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtPlatformId.Text = ""
      Me.txtPlatformId.Text = Camera.PlatformID

      'Display Errors if any
      lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWritePlatformIDToPart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWritePlatformIDToPart.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.PlatformID = Me.txtPlatformId.Text
      Me.txtPlatformId.Text = ""

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadSerialNumber_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadSerialNumber.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtSerialNumber.Text = ""
      Me.txtSerialNumber.Text = Camera.SerialNumber

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWriteSerialNumberToPart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteSerialNumberToPart.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.SerialNumber = Me.txtSerialNumber.Text
      Me.txtSerialNumber.Text = ""

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadMagnaSerialNumber_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadMagnaSerialNumber.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtMagnaSerialNumber.Text = ""
      Me.txtMagnaSerialNumber.Text = Camera.MagnaSerialNumber

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWriteMagnaSerialNumberToPart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteMagnaSerialNumberToPart.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.MagnaSerialNumber = Me.txtMagnaSerialNumber.Text
      Me.txtMagnaSerialNumber.Text = ""

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadXOffset_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadXOffset.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtXoffset.Text = ""
      Application.DoEvents()
      Me.txtXoffset.Text = Camera.Xoffset

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWriteXOffsetToPart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteXOffsetToPart.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.Xoffset = Me.txtXoffset.Text

      Me.txtXoffset.Text = ""

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadYOffset_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadYOffset.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtYOffset.Text = ""
      Application.DoEvents()
      Me.txtYOffset.Text = Camera.YOffset

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWriteYOffsetToPart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteYOffsetToPart.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.YOffset = Me.txtYOffset.Text
      Me.txtYOffset.Text = ""

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadSoftwareRevision_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadSoftwareRevision.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""
      Me.txtSoftwareRevision.Text = ""

      Me.txtSoftwareRevision.Text = Camera.SoftwareVersion

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdImagerSoftwareRevision_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdImagerSoftwareRevision.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtImagerSoftwareRevision.Text = ""
      Me.txtImagerSoftwareRevision.Text = Camera.ImagerSoftwareRevision

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdBootloaderSoftwareRevision_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdBootloaderSoftwareRevision.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtBootloaderSoftwareRevision.Text = ""
      Me.txtBootloaderSoftwareRevision.Text = Camera.BootLoaderSoftwareRevision

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdPlatformSpecificSoftwareRevision_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPlatformSpecificSoftwareRevision.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtPlatformSpecificSoftwareRevision.Text = ""
      Me.txtPlatformSpecificSoftwareRevision.Text = Camera.PlatformSpecificSoftwareRevision

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadImagerRevisionNumber_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadImagerRevisionNumber.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtImagerRevision.Text = ""
      Me.txtImagerRevision.Text = Camera.ImagerRevision

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdCalibrationSoftwareRevision_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdCalibrationSoftwareRevision.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtCalibrationSoftwareRevision.Text = ""
      Me.txtCalibrationSoftwareRevision.Text = Camera.CalibrationSoftwareVersion

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadStatusByte_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadStatusByte.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtStatusByte.Text = ""
      Me.txtStatusByte.Text = Camera.LinStatusByte

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadCheckSum_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadCheckSum.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtChecksum.Text = ""
      Me.txtChecksum.Text = Camera.Checksum
      Me.ToolTip1.SetToolTip(Me.txtChecksum, Me.txtChecksum.Text)

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdTurnOnOverlays_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdTurnOnOverlays.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.TurnOnOrOffStaticOverlays = "ON"

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdTurnOffOverlays_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdTurnOffOverlays.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.TurnOnOrOffStaticOverlays = "OFF"

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdShowDebugger_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdShowDebugger.Click
      Camera.ViewDebugger = True
   End Sub

   Private Sub cmdTestReadBlock_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdTestReadBlock.Click
      Dim TempXoffset As Short
      Dim TempYoffset As Short
      Dim TempOrientation As Short
      Dim TempOrientation_PGA As Short
      Dim TempOverlay As Short

      lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Select Case ProductInfo.CommunicationType
         Case Is = "MiamiLite_I2C"
            Camera.ReadCalibrationBlock(TempXoffset, TempYoffset, TempOrientation, TempOverlay, TempOrientation_PGA)

            Select Case TempOrientation_PGA
               Case Is = MiamiLiteOrientations.NormalNonMirrored
                  optOrientation_Normal_Non_Mirrored.Checked = True
               Case Is = MiamiLiteOrientations.NormalMirrored
                  optOrientation_Normal_Mirrored.Checked = True
               Case Is = MiamiLiteOrientations.VflippedMirrored
                  optOrientation_Vertical_Flipped_Mirrored.Checked = True
               Case Is = MiamiLiteOrientations.VFlippedNonMirrored
                  optOrientation_Vertical_Flipped_Non_Mirrored.Checked = True
               Case Else
                  optOrientation_Normal_Non_Mirrored.Checked = False
                  optOrientation_Normal_Mirrored.Checked = False
                  optOrientation_Vertical_Flipped_Mirrored.Checked = False
                  optOrientation_Vertical_Flipped_Non_Mirrored.Checked = False
            End Select

         Case Else
            Camera.ReadCalibrationBlock(TempXoffset, TempYoffset, TempOrientation, TempOverlay)

            Select Case TempOrientation
               Case Is = 0
                  optOrientation_Normal_Non_Mirrored.Checked = True
               Case Is = 1
                  optOrientation_Normal_Mirrored.Checked = True
               Case Is = 2
                  optOrientation_Vertical_Flipped_Mirrored.Checked = True
               Case Is = 3
                  optOrientation_Vertical_Flipped_Non_Mirrored.Checked = True
               Case Else
                  optOrientation_Normal_Non_Mirrored.Checked = False
                  optOrientation_Normal_Mirrored.Checked = False
                  optOrientation_Vertical_Flipped_Mirrored.Checked = False
                  optOrientation_Vertical_Flipped_Non_Mirrored.Checked = False
            End Select

      End Select

      Me.txtOff.Text = CStr(TempXoffset)
      Me.txtYOff.Text = CStr(TempYoffset)
      Me.txtOverlay.Text = CStr(TempOverlay)

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdWriteCalibrationBlock_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteCalibrationBlock.Click
      Dim OrientationVal As Short

      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Select Case ProductInfo.CommunicationType
         Case Is = "MiamiLite_I2C"
            'Use These Values FoR MiamiLite Cameras
            If optOrientation_Normal_Non_Mirrored.Checked = True Then OrientationVal = MiamiLiteOrientations.NormalNonMirrored
            If optOrientation_Normal_Mirrored.Checked = True Then OrientationVal = MiamiLiteOrientations.NormalMirrored
            If optOrientation_Vertical_Flipped_Mirrored.Checked = True Then OrientationVal = MiamiLiteOrientations.VflippedMirrored
            If optOrientation_Vertical_Flipped_Non_Mirrored.Checked = True Then OrientationVal = MiamiLiteOrientations.VFlippedNonMirrored
            If optOrientation_Normal_Non_Mirrored.Checked = False And optOrientation_Normal_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Non_Mirrored.Checked = False Then
               OrientationVal = 0
            End If

         Case Else
            'Exit Sub   2018-11-22 tony wang add
            If optOrientation_Normal_Non_Mirrored.Checked = True Then OrientationVal = 0 '0=Normal, Non-Mirrored
            If optOrientation_Normal_Mirrored.Checked = True Then OrientationVal = 1 '1=Normal,Mirrored
            If optOrientation_Vertical_Flipped_Mirrored.Checked = True Then OrientationVal = 2 '2=VflippedMirrored
            If optOrientation_Vertical_Flipped_Non_Mirrored.Checked = True Then OrientationVal = 3 '3=VFlippedNonMirrored
            If optOrientation_Normal_Non_Mirrored.Checked = False And optOrientation_Normal_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Non_Mirrored.Checked = False Then
               OrientationVal = 0
            End If

      End Select

      BinFileNameToFlash = Mid(ProductInfo.PN, 1, 6) & "_Extended.bin"
      Camera.WriteCalibrationBlock(Val(Me.txtOff.Text), Val(Me.txtYOff.Text), OrientationVal, Val(Me.txtOverlay.Text), My.Settings.BinFilePath & BinFileNameToFlash, Me.chkXY_Only.Checked)

      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString

   End Sub

   Private Sub cmdSetOrinetation_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSetOrinetation.Click
      Dim OrientationVal As Short
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      'Set Orientation To Normal (send a 1)

      If optOrientation_Normal_Non_Mirrored.Checked = True Then OrientationVal = 0
      If optOrientation_Normal_Mirrored.Checked = True Then OrientationVal = 2
      If optOrientation_Vertical_Flipped_Mirrored.Checked = True Then OrientationVal = 4
      If optOrientation_Vertical_Flipped_Non_Mirrored.Checked = True Then OrientationVal = 6
      If optOrientation_Normal_Non_Mirrored.Checked = False And optOrientation_Normal_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Mirrored.Checked = False And optOrientation_Vertical_Flipped_Non_Mirrored.Checked = False Then
         OrientationVal = 0
      End If

      Camera.Orientation = CStr(OrientationVal)

      'Display Errors if any
      lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub cmdReadECUSerialNumber_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadECUSerialNumber.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Me.txtECUSerialNumber.Text = ""
      Me.txtECUSerialNumber.Text = Camera.ECUSerialNumber

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString

   End Sub

   Private Sub cmdWriteECUSerialNumber_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteECUSerialNumber.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.ECUSerialNumber = Me.txtECUSerialNumber.Text
      Me.txtECUSerialNumber.Text = ""

      'Display Errors if any
      lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString

   End Sub

   Private Sub cmdSetOverlayDelay_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSetOverlayDelay.Click
      Me.lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.SetOverLayDelay = Me.txtOverlayDelay.Text

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.ErrorCode)
      Me.lblErrorString.Text = Camera.ErrorString

   End Sub

   Private Sub cmdTestForPartConnected_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdTestForPartConnected.Click
      Select Case Camera.TestForPartConnected
         Case Is = True
            Me.cmdTestForPartConnected.BackColor = Color.LawnGreen

         Case Else
            Me.cmdTestForPartConnected.BackColor = Color.Crimson

      End Select
   End Sub

   Private Sub cmdWriteDigPort0_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWriteDigPort0.Click, Button1.Click
      Dim ButtonClicked As Control
      Dim Data2Write As String

      ButtonClicked = DirectCast(sender, Control)
      ButtonClicked.Enabled = False

      Data2Write = ""
      If chkDigPort0_0.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_2.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_3.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_4.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_5.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_6.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_7.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"

      lblDAQDeviceID.Text = DAQ_USB_6525_DeviceName

      Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 0, Data2Write)

      Try
         If TypeOf sender Is Control Then ButtonClicked.Enabled = True
      Catch ex As Exception
         'Dont care
      End Try

   End Sub

   Private Sub cmdResetEnterProgramMode_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdResetEnterProgramMode.Click

      Camera.IsInProgramMode = False

   End Sub
#End Region 'End The TAB Communication Routines



#Region "Main Form Routines"
   Private Sub updateTimeAndDate_Tick(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles updateTimeAndDate.Tick
      'Updates The Time And Date On The Main Screen
      Me.ToolStripStatusLabelTime.Text = Format$(Now, "Medium Time")
      Me.ToolStripStatusLabelDate.Text = Format$(Now, "Short Date")
      Me.Text = Tester & "    Julian Day ___ YYDDD ___ " & FiveDigitJulianNumber.ToString

      '2013-12-3 Potter Added txtCarrier
      If txtCarrier.Focused = False Then
         Application.DoEvents()
         txtCarrier.Focus()
      End If

   End Sub

   Private Sub cmdStart_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdStart.Click
      'Call The Main Start Routine When Clicked Upon
      Start()

   End Sub
   Sub Start()
      'This Sub Is Used When The Start Button Is Clicked Upon Or When The Start Signal Is Received From The Automation

      Dim DownTimeOperator As String = ""
      Dim DownTimeReason As String = ""
      Dim FailClearLogin As String = ""
      Dim DownTimeTimer As Single = 0
      Dim i As Short
      Dim KeepLoaded As Boolean = False
      Dim LoopAtStart As Boolean = False

      ''2014-1-15 Potter added, if the TraceabilityEnable = True, check the carrier textbox
      'If TestMode = " " Then
      '   If ProductInfo.TraceabilityEnable = True Then
      '      If txtCarrier.Text.Length <> 10 Or txtCarrier.Text.ToUpper.StartsWith("CARRIER") = False Then
      '         MessageBox.Show("MUST SCAN CORRECT CARRIER BOX FIRST!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
      '         txtCarrier.SelectAll()
      '         txtCarrier.Focus()

      '         'Restart The Automatic Mode Timer
      '         If tsAutomaticMode.Checked = True Then
      '            tmrAutomaticMode.Enabled = True
      '         End If

      '         Exit Sub
      '      End If
      '   End If
      'End If

      ''2017-3-3 Potter Added
      'If TestMode = " " Then
      '   If ProductInfo.TraceabilityEnable = True Then
      '      If txtCarrier.Text.Length <> 10 Or txtCarrier.Text.ToUpper.StartsWith("CARRIER") = False Or txtCarrier.Enabled = True Then
      '         'MessageBox.Show("MUST SCAN CORRECT CARRIER BOX FIRST!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
      '         lblCarrierPrompt.Text = "Incorrect Carrier"
      '         txtCarrier.Enabled = True
      '         txtCarrier.SelectAll()
      '         txtCarrier.Focus()
      '         tmrAutomaticMode.Enabled = True
      '         Exit Sub
      '      Else
      '         lblCarrierPrompt.Text = ""
      '         CarrierName = txtCarrier.Text
      '         txtCarrier.Text = ""
      '         txtCarrier.Enabled = True
      '         txtCarrier.Focus()
      '      End If
      '   End If
      'Else
      '   lblCarrierPrompt.Text = ""
      'End If
      ''2017-3-3

      tmrAutomaticMode.Enabled = False

      '2017-6-27 Potter Added set FFTPassed=0,FFTFailed=0,FFTTesting=1
      Call WriteDigPort(DAQ_6514_DeviceName, 4, 5, "0") 'FFTPassed=0
      Call WriteDigPort(DAQ_6514_DeviceName, 4, 6, "0") 'FFTFailed=0
      Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "1") 'FFTTesting=1

      TestingDUTTesting = False

      InitializeVariables()

      UpdateNestData()

        '2018-5-4 potter added
        '5-7-15 jgk added to insure than old image is not used during Intrinsic Calibration
        If IntrinsicCalibrationRequired = True Then
            If My.Computer.FileSystem.FileExists(IntrinsicCalibrationSupportFolderPath & "ImageForIntrinsicCalibration.BMP") Then
                Kill(IntrinsicCalibrationSupportFolderPath & "ImageForIntrinsicCalibration.BMP")
            End If
        End If

      If Microsoft.VisualBasic.IsNothing(StopWatch) Then
         StopWatch = New Stopwatch
      End If

      ChangeImageOrientationBeforePlatformIDSet()
      SetLightingDefaultLevels()
      StopWatch.Reset()
      StopWatch.Start()
      TotalLoadTime = 0
      TotalTestTime = 0
      TotalUnloadTime = 0
      DutFail = 0
      CycleCount = 0
      For j = 1 To 100
         FailureList(j) = ""
      Next j


STARTAGAIN:
      DownTimeTimer = 0
      FailClearLogin = ""
      DownTimeReason = ""
      DownTimeOperator = ""

      Call Me.UpdateDataTextBox("Clear")
      'Call Me.UpdateGrid("Clear")

      For i = 0 To NumDUTs - 1
         Call Me.UpdateDUTStatus("Clear")
      Next i
      If LoopTest = True Then
         If (CycleCount >= NumLoopsWanted) And NumLoopsWanted <> 0 Then
            Me.mnuLoop.Checked = False
            LoopTest = False
         End If
      End If
      LoopAtStart = LoopTest

      Call ButtonsOff()

      Me.lstOpNotice.Items.Clear()

      If ErrorFlag = True Then
         MessageBox.Show("MUST CLEAR ERROR BEFORE TESTING!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         Me.mnuLoop.Checked = False
         LoopTest = False
         GoTo SkipTesting
      End If

      'TODO: Remove This For Normal Production
      'REMOVED FOR DEBUG
      'If (FailCount >= 3 Or UnauthorizedRetest = True) Then
      '   Call ButtonsOff()
      '   If FailureStartTime = 0 Then
      '      FailureStartTime = DateTime.Now.TimeOfDay.TotalSeconds
      '      FailureFlag = "Stack"
      '   End If
      '   MessageBox.Show("Maximum failure count has been reached" & Microsoft.VisualBasic.ControlChars.CrLf & "Call technician to evaluate tester failures", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Warning)
      '   Call Me.AppendMsg("Enter Password To Unlock Tester")
      '   Call Me.mnuClearFailures_Click(Me.mnuClearFailures, New System.EventArgs())
      '   GoTo SkipTesting
      'End If

      If OperatorScan = "" Then
         MessageBox.Show("No operator logged in!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         Me.mnuLoop.Checked = False
         LoopTest = False
         GoTo SkipTesting
      End If

      If Me.txtSelectedPartNumber.Text = "" Or Me.txtSelectedPartNumber.Text = "Part Number Not Found" Then
         MessageBox.Show("Please Enter A Part Number Before Trying To Start A Test!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         Me.mnuLoop.Checked = False
         ProductIndex = -1
         LoopTest = False
         GoTo SkipTesting
      End If

      'load dut
      Testing = True

      Me.UpdateStatus("Testing")

      TotalLoadTime = StopWatch.ElapsedMilliseconds / 1000

      Call MainTestLoop()

      TotalUnloadTime = StopWatch.ElapsedMilliseconds / 1000
      Me.UpdateGrid("EndOfTest")

      Call Me.UpdateStatus("Complete")

      Dim xMsg As String
      Dim xTitle As String
      Dim xResponse As Short
      If (HaltonTest = True And TestMode = "T") Or ((ProductStatus = FAIL And DUTDisabled = False)) And (TestMode <> "G" And OptionHalt = True) Then
         'show a message box giving opportunity for input
         'if desired, show the I/O access screen, set flag, do not unload, do not enable palm timer
         If OptionHalt = True Then
            xMsg = "Part has failed test.  Do you want to keep the part loaded?."
            xTitle = "NOTICE: Part has failed test"
         Else
            xMsg = "Part has reached stopping sequence.  Do you want to keep the part loaded?."
            xTitle = "NOTICE: Testing was stopped"
         End If
         xResponse = MessageBox.Show(xMsg, xTitle, MessageBoxButtons.YesNo, MessageBoxIcon.Question)
         KeepLoaded = False
         If xResponse = DialogResult.Yes Then ' User chose Yes.
            KeepLoaded = True
         End If
      End If


      TotalLoadTime = System.Math.Round(TotalLoadTime, 3)
      TotalTestTime = System.Math.Round(TotalUnloadTime - TotalLoadTime, 3)
      TotalUnloadTime = System.Math.Round(StopWatch.ElapsedMilliseconds / 1000 - TotalUnloadTime, 3)
      LastCycleTime = DateTime.Now.TimeOfDay.Subtract(LastTestEndTime)
      LastTestEndTime = DateTime.Now.TimeOfDay
      Call Me.AppendMsg("Time required to load DUT: " & TotalLoadTime)
      Call Me.AppendMsg("Total test time: " & TotalTestTime)
      Call Me.AppendMsg("Time required to unload DUT: " & TotalUnloadTime)
      Call Me.AppendMsg("Last cycle time:" & LastCycleTime.TotalSeconds.ToString)

      'Master Reset (Turns Off All I/O And Power Supply To DUT
      MasterReset()

      Dim IsGNG_Mode_Required As Boolean = False
      If TestMode <> "G" Then
         If TestMode = " " Or TestMode = "R" Then
            IsGNG_Mode_Required = IsGoNoGoModeRequired()
         End If
      End If

      Call EndOfTest(IsGNG_Mode_Required) 'call function for determining if gonogo mode is required and passes result to EndOfTest


      Call Me.UpdateStatus("Clear")

      'If FailCount >= 3 Then
      '   MessageBox.Show("Maximum failure WARNING" & Microsoft.VisualBasic.ControlChars.CrLf & "Call technician to evaluate tester failures", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Warning)
      '   FailureStartTime = DateTime.Now.TimeOfDay.TotalSeconds
      '   FailureFlag = "Stack"
      'End If

      If UnauthorizedRetest = True Then
         Call ButtonsOff()
         Me.lblModeUnits.BackColor = System.Drawing.Color.Purple
         If FailureStartTime = 0 Then
            FailureStartTime = DateTime.Now.TimeOfDay.TotalSeconds
            FailureFlag = "Stack"
         End If
         MessageBox.Show("UNAUTHORIZED RETESTING OF PARTS" & Microsoft.VisualBasic.ControlChars.CrLf & "Call a supervisor to evaluate tester failures", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Warning)
         Call Me.AppendMsg("Enter Password To Unlock Tester")
         Call Me.mnuClearFailures_Click(Me.mnuClearFailures, New System.EventArgs())
      End If

      If TestMode = "G" Then
         If (NumDUTs = 1 And NumGoNoGosToGo <= 0) Then
            Call WriteTesterSpecField("Product", "LastGoDate", DateTime.Now.DayOfYear.ToString)
            Call WriteTesterSpecField("Product", "LastGoTime", DateTime.Now.TimeOfDay.TotalSeconds.ToString)
            Last_Go_Date = DateTime.Now.DayOfYear.ToString
            Last_Go_Time = DateTime.Now.TimeOfDay.TotalSeconds
            Dim Result As Boolean = ChangeProduct(SelectedPartNumberBeforeRunningGNGs) 'change part number after completing gonogos
            GoNogoMsgAtEndOfTestNeeded = False
            Call UpdateMode("Normal")
            '2018-5-6 potter added traceabilityenable judgement
            '2017-6-27 Potter write FFTReady=0 
            If ProductInfo.TraceabilityEnable = True Then
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
            Else
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
            End If
         Else
            '
         End If
         Call UpdateGrid("GNG", 0)
      Else
         If TestMode = "R" Then
            If RetestCount <= 0 Then
               Call UpdateMode("Normal")
               '2018-5-6 potter added traceabilityenable judgement
               '2017-6-27 Potter write FFTReady=0 
               If ProductInfo.TraceabilityEnable = True Then
                  Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
               Else
                  Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
               End If
            ElseIf RetestCount < NumDUTs Then
               For i = RetestCount To NumDUTs - 1
                  Call Me.UpdateDUTStatus("Disable")
               Next
            End If
         End If
         If TestMode = " " Or TestMode = "R" Then
            'Call DetermineIFGoNoGoModeRequired()
            Call EnterGoNoGoModeIfRequired(IsGNG_Mode_Required)

         End If
      End If

SkipTesting:
      Me.Cursor = System.Windows.Forms.Cursors.Default
      Call ButtonsOn()
      Testing = False

      If (LoopTest = True Or LoopAtStart) And KeepLoaded = False Then
         Call Me.UpdateGrid("Loop", 0)
         System.Windows.Forms.Application.DoEvents()
         If LoopDelay = 0 Then
            System.Threading.Thread.Sleep(5000)
         Else
            System.Threading.Thread.Sleep(LoopDelay * 1000)
         End If
         If (CycleCount >= NumLoopsWanted) And NumLoopsWanted <> 0 Then
            Me.mnuLoop.Checked = False
            LoopTest = False
         End If
         If LoopTest = True Then GoTo STARTAGAIN
      End If

      'Restart The Automatic Mode Timer
      If tsAutomaticMode.Checked = True Then
         tmrAutomaticMode.Enabled = True
      End If

   End Sub
   Sub UpdateNestData()
       'This Sub Will Also Read Which Nest Number Is At The Test Station
      'Select Case ProductInfo.OEM.ToUpper
      '   Case Is = "HONDA"
      '      Me.lblNestInUse.Text = "3: Honda"
      '   Case Is = "FORD_LONDON"
      '      Me.lblNestInUse.Text = "5: Ford London"
      '   Case Is = "FORD_MEGAPIXEL"
      '      Me.lblNestInUse.Text = "6: Ford Megapixel"
      '   Case Is = "FORD"
      '      Me.lblNestInUse.Text = "7: Ford"
      '   Case Else
      '      Me.lblNestInUse.Text = "8: Unknown"
      'End Select

      Select Case ProductInfo.FixtureID.ToUpper
         Case Is = "1"
            Me.lblNestInUse.Text = "1: Qoros"
         Case Is = "2"
            Me.lblNestInUse.Text = "2: Ford 45Degree Rear Cover"
         Case Is = "3"
            Me.lblNestInUse.Text = "3: Ford Other Rear Cover"
         Case Is = "4"
            Me.lblNestInUse.Text = "4: GM RVC"
         Case Else
            Me.lblNestInUse.Text = "5-7: Unknown"
      End Select

   End Sub
   Sub InitializeHardware()
      'Initializes All Required Hardware

      UpdateStatus("Init")

      'Create Instance For Access To The Camera Communication dll
      Camera = New Global_Camera.Communication
      'Create Instance For Access To The Cognex Class
      'Try

      '   ' load the Cognex vision support class and the Default Quickbild Application (will change based on part numbers when selected)
      '   clsVPRO = New clsVPROSupport(Me, tlsStatus, disRecord, stsVPROStatus, My.Settings.QuickBuildApplicationPath & "Default.vpp", picDisplay)
      '   ' set all of the properties
      '   With clsVPRO
      '      .FailCode = 999
      '      .RegionSizeCenter = New Size(48, 10)
      '      .RegionSizeRGB = New Size(5, 5)
      '      .RegionSizeSides = New Size(48, 32)
      '      .PixelSize = 0.0056
      '      .ImageOrientationRequired = clsVPROSupport.ImageOrientationRequiredEnum.None
      '   End With

      'Catch ex As Exception
      '   MessageBox.Show("frmMain_Load: " & ex.Message)
      'End Try

   
      Try
         'Init The Power Supply
         PowerSupplyGPIB = New NI_GPIB
         PowerSupplyGPIB.OpenGPIB(0, PSGPIBAdd)
         IO_Support.PowerSupplyControl(PSIndex.PS1, 0.0, 0.0, False)
         IO_Support.PowerSupplyControl(PSIndex.PS2, 0.0, 0.0, False)

      Catch ex As Exception
         MessageBox.Show("frmMain_Load: Initilize Power Supply Faliure " & ex.Message)
      End Try

      Try
         'Init The Meter
         MeterGPIB = New NI_GPIB
         MeterGPIB.OpenGPIB(0, MeterGPIBAdd)
         'Set The Meter For Current Mode (That is all we can do with the way the meter is wired)
         MeterGPIB.WriteGPIB("")

      Catch ex As Exception
         MessageBox.Show("frmMain_Load: Initilize Multi-Meter Faliure " & ex.Message)
      End Try

      'Set Voltage Divider Ratios
      For i = 0 To 7
         VoltDividerRatio(i) = 1 'No Dividers Right Now
      Next i

      If MCC_USB_3112_DeviceName.ToUpper <> "NA" Then
         'Initialize the USB-3112 Boards
         Try
            MCC3112DUT1 = New MCC31xx(Dut1USB3112CardNumber)
            'Configure Digital Port For Input   (Input 0, Output is 1)
            MCC3112DUT1.ConfigPortDirection(0)

         Catch ex As Exception
            WritetoErrorLog(ex, True, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, True, "Exception Was Thrown See Error Log For Details")
         End Try
      End If

      Me.rbDut1.Checked = True

   End Sub


#End Region 'End Main Form Routines


#Region "Main Operator Form"
   Sub AppendMsg(ByVal Message As String)
      Me.lstOpNotice.Items.Add(Message)
      Me.lstOpNotice.SelectedIndex = Me.lstOpNotice.Items.Count - 1
      Me.lstOpNotice.Refresh()
   End Sub
   Private Sub TestGrid_RowsAdded(ByVal sender As Object, ByVal e As System.Windows.Forms.DataGridViewRowsAddedEventArgs) Handles TestGrid.RowsAdded
      'Scroll to the last row.
      Me.TestGrid.FirstDisplayedScrollingRowIndex = Me.TestGrid.RowCount - 1
   End Sub

   Private Sub cmdChangeProduct_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdChangeProduct.Click
      frmLoadPartNumber.ShowDialog()
   End Sub

   Sub UpdateStatus(ByVal Choice As String)
      Try
         ' this sub updates the status display only
         ' the specific dut result after each TestIndex is updated within UpdateDUTStatus()
         If ErrorFlag = True Then Choice = "Error"
         Select Case Choice
            Case "Select Product Type"
               Me.lblTesterStatus.Text = "SELECT PRODUCT"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Yellow
               UpdateDUTStatus("Clear")

            Case "Login Operator"
               Me.lblTesterStatus.Text = "LOGIN OPERATOR"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Aquamarine
               UpdateDUTStatus("Clear")

            Case "Init"
               Me.lblTesterStatus.Text = "INITIALIZING"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Orange

            Case "Ready"
               Me.lblTesterStatus.Text = "READY TO START"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Cyan

            Case "Error"
               ErrorFlag = True
               Me.lblTesterStatus.Text = "ERROR"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Red
               UpdateDUTStatus("Clear")
               ButtonsOn()

            Case "Clear"
               Me.lblTesterStatus.Text = ""
               Me.lblTesterStatus.BackColor = System.Drawing.Color.White

            Case "Testing"
               Me.lblTesterStatus.Text = "TESTING"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Yellow
               UpdateDUTStatus("Testing")

            Case "Complete"
               Me.lblTesterStatus.Text = "COMPLETE"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Yellow
               If ProductStatus = PASS Then
                  UpdateDUTStatus("Pass")
               ElseIf ProductStatus = FAIL Then
                  Call Me.UpdateDUTStatus("Fail")
               Else
                  Call Me.UpdateDUTStatus("Incomplete")
               End If

            Case Else
               Me.lblTesterStatus.Text = "Incorrect Message"
               Me.lblTesterStatus.BackColor = System.Drawing.Color.Red
         End Select
         Me.lblTesterStatus.Text = Me.lblTesterStatus.Text
         Me.lblTesterStatus.BackColor = Me.lblTesterStatus.BackColor
         Me.lblTesterStatus.Refresh()

      Catch ex As Exception
         WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, False, "")
      End Try
   End Sub

   Sub UpdateDUTStatus(ByVal Choice As String)
      Select Case Choice
         Case "Clear"
            lbldutStatus.BackColor = System.Drawing.Color.White
            lbldutStatus.ForeColor = System.Drawing.Color.Gray

         Case "Empty" 'do not clear indicator, just reset flags
            lbldutStatus.Text = ""

         Case "Incomplete"
            lbldutStatus.BackColor = System.Drawing.Color.Orange
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "INCOMPLETE"

         Case "Pass"
            lbldutStatus.BackColor = System.Drawing.Color.Lime
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "PASS"

         Case "Fail"
            lbldutStatus.BackColor = System.Drawing.Color.Red
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "FAIL"

         Case "Load"
            lbldutStatus.BackColor = System.Drawing.Color.White
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "LOAD UNIT"

         Case "Loaded"
            lbldutStatus.BackColor = System.Drawing.Color.LightGray
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "UNIT LOADED"
         Case "Un-Loaded"
            lbldutStatus.BackColor = System.Drawing.Color.White
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = ""
         Case "Scan"
            'Not Used At This Time
         Case "Disable"
            lbldutStatus.BackColor = System.Drawing.Color.Black
            lbldutStatus.ForeColor = System.Drawing.Color.White
            lbldutStatus.Text = "DISABLED"

         Case "Un-Disable"
            lbldutStatus.BackColor = System.Drawing.Color.White
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = ""

         Case "Testing"
            lbldutStatus.BackColor = System.Drawing.Color.White
            lbldutStatus.ForeColor = System.Drawing.Color.Gray
            lbldutStatus.Text = "Testing..."

         Case "Operated As Expected"
            lbldutStatus.BackColor = System.Drawing.Color.Blue 'blue
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "Operated As Expected"

         Case "Failed To Operate As Expected"
            lbldutStatus.BackColor = System.Drawing.Color.MediumPurple  'Red 'purple
            lbldutStatus.ForeColor = System.Drawing.Color.Black
            lbldutStatus.Text = "Failed To Operate As Expected"

      End Select
      lbldutStatus.Refresh()

   End Sub

   Sub UpdateModeUnits(ByVal UnitType As String)
      'Pass in "Failure", "Retest", or anything else"
      Select Case UnitType
         Case Is = "Failure"
            If FailCount > 0 Then
               Me.lblModeUnitCaption.Text = "# FAILURES"
               Me.lblModeUnitCaption.ForeColor = Color.Red
               Me.lblModeUnitCaption.Visible = True
               Me.lblModeUnits.Text = FailCount
               If FailCount = 1 Then
                  Me.lblModeUnits.BackColor = System.Drawing.Color.Yellow
               ElseIf FailCount = 2 Then
                  Me.lblModeUnits.BackColor = System.Drawing.Color.Orange
               Else
                  Me.lblModeUnits.BackColor = System.Drawing.Color.Red
               End If
               Me.lblModeUnits.Visible = True
            Else
               Me.lblModeUnits.Visible = False
               Me.lblModeUnitCaption.Visible = False
            End If

         Case Is = "Retest"
            If RetestCount > 0 Then
               Me.lblModeUnitCaption.Text = "# RETESTS"
               Me.lblModeUnits.BackColor = Color.Black
               Me.lblModeUnits.ForeColor = Color.Yellow
               Me.lblModeUnitCaption.ForeColor = Color.Black
               Me.lblModeUnitCaption.Visible = True
               Me.lblModeUnits.Text = RetestCount
               Me.lblModeUnits.Visible = True
            Else
               Me.lblModeUnits.Visible = False
               Me.lblModeUnitCaption.Visible = False
            End If
         Case Else
            Me.lblModeUnits.Visible = False
            Me.lblModeUnitCaption.Visible = False

      End Select
      Me.lblModeUnitCaption.Refresh()
      Me.lblModeUnits.Refresh()

   End Sub

   Sub UpdateDataTextBox(ByVal Operation As String, Optional ByVal TestSeq As Short = 0)
      'Dim MeHandle As IntPtr
      'MeHandle = me.Handle


      Try
         Dim j As Short
         Dim i As Short
         Dim ColShift As Short
         Dim FailListRow As Short
         Dim RowAdded As Boolean
         Me.TestGrid.SuspendLayout()
         Select Case Operation
            Case "NewTest"
               Dim Row2Write(3) As String

               Select Case NumDUTs
                  Case 1
                     AppendDataTextBox("")
                     AppendDataTextBox("Seq #" & TestSeqInfo(TestSeq).Sequence.ToString & " - " & TestSeqInfo(TestSeq).Description)

                            '2018-5-4 potter added
                            '11/9/16 MRC/jgk added
                            Select Case TestSeqInfo(TestIndex).InputName.ToUpper
                                Case Is = "EVALUATE INTRINSIC CALIBRATION"
                                    If TestMode = "G" And GNGSkipIntrinsicCalChecked(DutSerialNumbers.DutAEISerialNumber) = True Then
                                        AppendDataTextBox("Nogo Mode, DISABLED AND WAS NOT RUN")
                                    End If
                                Case Is = "RUN INTRINSIC CALIBRATION"
                                    If TestMode = "G" And GNGSkipIntrinsicCalChecked(DutSerialNumbers.DutAEISerialNumber) = True Then
                                        AppendDataTextBox("Nogo Mode, DISABLED AND WAS NOT RUN")
                                    End If
                            End Select

                  Case Else
                     'Only One Dut Supported In This Program
               End Select

            Case "TestData"

               If (TestSeqData(TestSeq).ResultValue = -999 And TestSeqData(TestSeq).ResultString = "-999") Or TestSeqInfo(TestSeq).TestType.ToUpper = "SETUP ONLY / NO MEASUREMENTS".ToUpper Then 'no TestSeq ran
                  AppendDataTextBox("Setup Step Only, No Measurements Taken")
               Else
                  If TestSeqData(TestSeq).SeqFailed = True Then
                     AppendDataTextBox(" !!! F A I L E D !!!")
                     Me.txtDataBox.BackColor = Color.Pink
                  End If
                  If TestSeqInfo(TestSeq).StringComp = False Then
                     AppendDataTextBox("Limts: " & TestSeqInfo(TestSeq).LCL.ToString & " - " & TestSeqInfo(TestSeq).UCL.ToString)
                     AppendDataTextBox("Data Measured: " & TestSeqData(TestSeq).ResultValue)
                  Else
                     AppendDataTextBox("Should be: " & TestSeqData(TestSeq).StringShouldBe)
                     AppendDataTextBox("Data Read: " & TestSeqData(TestSeq).ResultString)
                  End If
               End If

            Case "Clear"
               Me.TestGrid.Rows.Clear()
               Me.TestGrid.RowCount = 0

               txtDataBox.Clear()
               Me.txtDataBox.BackColor = Color.White

            Case "Loop"

               Me.TestGrid.RowCount = Me.TestGrid.RowCount + 2
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "LOOP DATA"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               For DUTIndex = 0 To Me.TestGrid.ColumnCount - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(DUTIndex).Style.BackColor = Color.Yellow
               Next
               Me.TestGrid.RowCount = Me.TestGrid.RowCount + 3
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 3).Cells(1).Value = "Number of Cycles"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 3).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 2).Cells(1).Value = "Number of Failures"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 2).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               FailListRow = Me.TestGrid.RowCount - 1
               Me.TestGrid.Rows(FailListRow).Cells(1).Value = "Failure Lists"
               Me.TestGrid.Rows(FailListRow).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               ColShift = 0
               If DUTDisabled = False Then
                  CycleCount = CycleCount + 1
               End If
               If ((ProductStatus = FAIL) And DUTDisabled = False) Then
                  DutFail = DutFail + 1
                  If DutFail < 100 Then FailureList(DutFail) = FailureDesc
               End If


               Me.TestGrid.Rows(FailListRow - 2).Cells(3 - ColShift).Value = CycleCount
               Me.TestGrid.Rows(FailListRow - 1).Cells(3 - ColShift).Value = DutFail
               For j = 1 To DutFail
                  If FailureList(j) <> "" Then
                     If FailListRow + j > Me.TestGrid.RowCount - 1 Then
                        Me.TestGrid.RowCount = Me.TestGrid.RowCount + 1
                     End If
                     Me.TestGrid.Rows(FailListRow).Cells(3 - ColShift).Value = FailureList(j)
                     FailListRow = FailListRow + 1
                  End If
               Next j

               Me.TestGrid.ResumeLayout()
               Application.DoEvents()
               Me.TestGrid.Refresh()

            Case "GNG"
               Me.TestGrid.RowCount = Me.TestGrid.RowCount + numGoNoGos + 2
               Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(1).Value = "GO/NOGO STATUS"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               For i = 0 To Me.TestGrid.ColumnCount - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(i).Style.BackColor = Color.Yellow
               Next i

               ColShift = 0
               For j = 0 To numGoNoGos - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(1).Value = GNGSerialNumber(j, 0).SN
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  If GNGDone(j) = True Then
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(3 - ColShift).Value = "Complete"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(3 - ColShift).Style.BackColor = Color.LightGray
                  End If
               Next j

               Me.TestGrid.ResumeLayout()
               Application.DoEvents()
               Me.TestGrid.Refresh()

            Case "EndOfTest"
               If TestMode <> "G" Then
                  Me.TestGrid.RowCount = Me.TestGrid.RowCount + 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "SERIAL NUMBER"
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  ColShift = 0

                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = DutSerialNumbers.LabelSerialNumber
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  If ProductStatus = PASS Then
                     Me.TestGrid.Text = "PASS"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.BackColor = Color.Lime

                  Else
                     Me.TestGrid.Text = "FAIL"
                     If DUTDisabled = True Then
                        Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = "-"
                     Else
                        Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.BackColor = Color.Red
                     End If
                  End If
               End If

               RowAdded = False
               ColShift = 0
               If FailureDesc.Trim.Length > 0 And DUTDisabled = False Then
                  If RowAdded = False Then
                     Me.TestGrid.RowCount = Me.TestGrid.RowCount + 2
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "FAILURES"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                     RowAdded = True
                  End If
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = FailureDesc
                  AppendDataTextBox("")
                  AppendDataTextBox("FAILURES: " & FailureDesc)
               End If

               Me.TestGrid.ResumeLayout()
               Application.DoEvents()
               Me.TestGrid.Refresh()

         End Select


      Catch ex As Exception
         WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, False, "")
      End Try
   End Sub
   Sub UpdateGrid(ByVal Operation As String, Optional ByVal TestSeq As Short = 0)
      'Dim MeHandle As IntPtr
      'MeHandle = me.Handle

      Try
         Dim j As Short
         Dim i As Short
         Dim ColShift As Short
         Dim FailListRow As Short
         Dim RowAdded As Boolean
         Me.TestGrid.SuspendLayout()
         Select Case Operation
            Case "NewTest"
               Dim Row2Write(3) As String
               Dim DUTDefault As String
               Row2Write(DUT1) = ""
               DUTDefault = ""

               Row2Write(0) = TestSeqInfo(TestSeq).Sequence.ToString
               If TestSeqInfo(TestSeq).Disable = True Then
                  Row2Write(1) = "<DISABLED> " & TestSeqInfo(TestSeq).Description
               Else
                  Row2Write(1) = TestSeqInfo(TestSeq).Description
               End If
               If TestSeqInfo(TestSeq).TestType.ToUpper = "SETUP ONLY / NO MEASUREMENTS".ToUpper Then
                  Row2Write(2) = "N/A"
                  Row2Write(3) = "N/A"
                  DUTDefault = "-"
               Else
                  If TestSeqInfo(TestSeq).StringComp = False Then
                     Row2Write(2) = TestSeqInfo(TestSeq).LCL.ToString
                     Row2Write(3) = TestSeqInfo(TestSeq).UCL.ToString
                  End If
               End If
               Select Case NumDUTs
                  Case 1
                     '                         Seq    , Desc        , LCL         ,              , UCL
                     Me.TestGrid.Rows.Add(Row2Write(0), Row2Write(1), Row2Write(2), DUTDefault, Row2Write(3))
                  Case Else
                     'Only One Dut Supported In This Program
               End Select
               'If IsNothing(StopWatch) = False Then Console.WriteLine("UpdateGrid-" & Operation & "-Add Line | seq:" & TestSeqInfo(TestSeq).Sequence & " ts:" & StopWatch.ElapsedMilliseconds.ToString)
               If TestSeqInfo(TestSeq).Disable = True Then
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).DefaultCellStyle.BackColor = Color.DarkGray
               Else
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(0).Style.BackColor = Color.LightGray
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.BackColor = Color.LightGray
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(2).Style.BackColor = Color.LightCyan
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 + NumDUTs).Style.BackColor = Color.LightCyan
               End If
               'If IsNothing(StopWatch) = False Then Console.WriteLine("UpdateGrid-" & Operation & "-SetColor | seq:" & TestSeqInfo(TestSeq).Sequence & " ts:" & StopWatch.ElapsedMilliseconds.ToString)

               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(0).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleLeft
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(2).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               For DUTIndex = 0 To NumDUTs - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 + DUTIndex).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               Next
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 + NumDUTs).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               Me.lblTestSeq.Text = TestSeqInfo(TestSeq).Sequence.ToString & ":"
               Me.lblTestDescription.Text = TestSeqInfo(TestSeq).Description
            Case "TestData"

               If (TestSeqData(TestSeq).ResultValue = -999 And TestSeqData(TestSeq).ResultString = "-999") Or TestSeqInfo(TestSeq).TestType.ToUpper = "SETUP ONLY / NO MEASUREMENTS".ToUpper Then 'no TestSeq ran
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3).Value = "-"
               Else
                  If TestSeqInfo(TestSeq).StringComp = False Then
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3).Value = TestSeqData(TestSeq).ResultValue
                  Else
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3).Value = TestSeqData(TestSeq).ResultString
                  End If
               End If
               If TestSeqData(TestSeq).SeqFailed = True Then
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3).Style.BackColor = Color.Salmon
               End If

            Case "Clear"

               If TestMode <> "G" Then
                  Me.TestGrid.Rows.Clear()
                  Me.TestGrid.RowCount = 0
               End If

            Case "Loop"

               Me.TestGrid.RowCount = Me.TestGrid.RowCount + 2
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "LOOP DATA"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               For DUTIndex = 0 To Me.TestGrid.ColumnCount - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(DUTIndex).Style.BackColor = Color.Yellow
               Next
               Me.TestGrid.RowCount = Me.TestGrid.RowCount + 3
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 3).Cells(1).Value = "Number of Cycles"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 3).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 2).Cells(1).Value = "Number of Failures"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - 2).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               FailListRow = Me.TestGrid.RowCount - 1
               Me.TestGrid.Rows(FailListRow).Cells(1).Value = "Failure Lists"
               Me.TestGrid.Rows(FailListRow).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               ColShift = 0
               If DUTDisabled = False Then
                  CycleCount = CycleCount + 1
               End If
               If ((ProductStatus = FAIL) And DUTDisabled = False) Then
                  DutFail = DutFail + 1
                  If DutFail < 100 Then FailureList(DutFail) = FailureDesc
               End If


               Me.TestGrid.Rows(FailListRow - 2).Cells(3 - ColShift).Value = CycleCount
               Me.TestGrid.Rows(FailListRow - 1).Cells(3 - ColShift).Value = DutFail
               For j = 1 To DutFail
                  If FailureList(j) <> "" Then
                     If FailListRow + j > Me.TestGrid.RowCount - 1 Then
                        Me.TestGrid.RowCount = Me.TestGrid.RowCount + 1
                     End If
                     Me.TestGrid.Rows(FailListRow).Cells(3 - ColShift).Value = FailureList(j)
                     FailListRow = FailListRow + 1
                  End If
               Next j

            Case "GNG"
               Me.TestGrid.RowCount = Me.TestGrid.RowCount + numGoNoGos + 2
               Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(1).Value = "GO/NOGO STATUS"
               Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
               For i = 0 To Me.TestGrid.ColumnCount - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - numGoNoGos - 1).Cells(i).Style.BackColor = Color.Yellow
               Next i

               ColShift = 0
               For j = 0 To numGoNoGos - 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(1).Value = GNGSerialNumber(j, 0).SN
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  If GNGDone(j) = True Then
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(3 - ColShift).Value = "Complete"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - j - 1).Cells(3 - ColShift).Style.BackColor = Color.LightGray
                  End If
               Next j

            Case "EndOfTest"
               If TestMode <> "G" Then
                  Me.TestGrid.RowCount = Me.TestGrid.RowCount + 1
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "SERIAL NUMBER"
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  ColShift = 0

                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = DutSerialNumbers.LabelSerialNumber
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                  If ProductStatus = PASS Then
                     Me.TestGrid.Text = "PASS"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.BackColor = Color.Lime

                  Else
                     Me.TestGrid.Text = "FAIL"
                     If DUTDisabled = True Then
                        Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = "-"
                     Else
                        Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Style.BackColor = Color.Red
                     End If
                  End If
               End If

               RowAdded = False
               ColShift = 0
               If FailureDesc.Trim.Length > 0 And DUTDisabled = False Then
                  If RowAdded = False Then
                     Me.TestGrid.RowCount = Me.TestGrid.RowCount + 2
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Value = "FAILURES"
                     Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(1).Style.Alignment = DataGridViewContentAlignment.MiddleCenter
                     RowAdded = True
                  End If
                  Me.TestGrid.Rows(Me.TestGrid.RowCount - 1).Cells(3 - ColShift).Value = FailureDesc
               End If

         End Select
         'If Me.TestGrid.RowCount > 25 Then Me.TestGrid.FirstDisplayedScrollingRowIndex = Me.TestGrid.RowCount - 25
         Me.TestGrid.ResumeLayout()
         Application.DoEvents()
         Me.TestGrid.Refresh()

      Catch ex As Exception
         WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, False, "")
      End Try
   End Sub
   Sub AppendDataTextBox(ByVal msg As String)

      txtDataBox.Text = txtDataBox.Text & msg
      txtDataBox.Text = txtDataBox.Text & vbCrLf
      txtDataBox.SelectionStart = Len(txtDataBox.Text)
      txtDataBox.ScrollToCaret()

   End Sub
   Sub ButtonsOff()

      'This sub will be used to prevent the START button or the TECH MODE button from being accessed

      'This sub will perform the following:
      'Disable the START button on the Main form
      'Disable the TECH button on the Main form
      If TestMode <> "T" Then
         Me.mnuTech.Enabled = False
      End If
      Me.cmdChangeProduct.Enabled = False
      Me.cmdChangeOperator.Enabled = False
      Me.mnuProduction.Enabled = False

      Me.cmdStart.Enabled = False

   End Sub
   Sub ButtonsOn()
      Me.mnuExit.Enabled = True
      Me.mnuTech.Enabled = True
      Me.mnuProduction.Enabled = True
      Me.cmdChangeProduct.Enabled = True
      Me.cmdChangeOperator.Enabled = True
      Me.cmdStart.Enabled = True
   End Sub


#Region "Operator Login Routines"

   Private Sub cmdChangeOperator_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdChangeOperator.Click
      'Show The Form That Will Allow an Operator To Be Logged In
      frmPassword.ShowDialog()
      If TypeScan <> "T" And TypeScan <> "A" Then
         If IOTabVisable = True Then
            Me.tbcMain.TabPages.Remove(Me.tabManualControl)
            IOTabVisable = False
            UpdateMode("Normal")
            '2018-5-6 potter added traceabilityenable judgement
            '2017-6-27 Potter write FFTReady=0 
            If ProductInfo.TraceabilityEnable = True Then
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
            Else
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
            End If
         End If
      Else
         If IOTabVisable = False Then
            Me.tbcMain.TabPages.Add(Me.tabManualControl)
            IOTabVisable = True
            UpdateMode("Tech")
            '2017-6-27 Potter write FFTReady=1 
            Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1

      End If
      End If

   End Sub

#End Region ' End Operator Login Routines


   Private Sub cmdPS1_ON_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPS1_ON.Click

      IO_Support.PowerSupplyControl(PSIndex.PS1, Me.txtPS1volts.Value, Me.txtPS1amps.Value, True)

   End Sub

   Private Sub cmdUpdatePS1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdUpdatePS1.Click

      IO_Support.PowerSupplyControl(PSIndex.PS1, Me.txtPS1volts.Value, Me.txtPS1amps.Value, True)

   End Sub

   Private Sub cmdPS1OutOff_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPS1OutOff.Click

      IO_Support.PowerSupplyControl(PSIndex.PS1, Me.txtPS1volts.Value, Me.txtPS1amps.Value, False)

   End Sub

   Private Sub cmdReadPS1Current_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadPS1Current.Click
      Dim VSET As String = ""
      Dim ISET As String = ""

      Me.txtGPIBRx.Clear()

      IO_Support.ReadPowerSupplyOutput(PSIndex.PS1, VSET, ISET)

      Me.txtGPIBRx.Text = "VSET = " & VSET
      Me.txtGPIBRx.Text = Me.txtGPIBRx.Text & Microsoft.VisualBasic.ControlChars.CrLf & "Current = " & ISET

   End Sub

   Private Sub cmdReadPS2Current_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReadPS2Current.Click
      Dim VSET As String = ""
      Dim ISET As String = ""

      Me.txtGPIBRx.Clear()

      IO_Support.ReadPowerSupplyOutput(PSIndex.PS2, VSET, ISET)

      Me.txtGPIBRx.Text = "VSET = " & VSET
      Me.txtGPIBRx.Text = Me.txtGPIBRx.Text & Microsoft.VisualBasic.ControlChars.CrLf & "Current = " & ISET

   End Sub

   Private Sub cmdUpdatePS2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdUpdatePS2.Click

      IO_Support.PowerSupplyControl(PSIndex.PS2, Me.txtPS2volts.Value, Me.txtPS2amps.Value, True)

   End Sub
   Private Sub cmdPS2OutOff_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPS2OutOff.Click

      IO_Support.PowerSupplyControl(PSIndex.PS2, Me.txtPS2volts.Value, Me.txtPS2amps.Value, False)

   End Sub

   Private Sub cmdSingleScan_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSingleScan.Click
      cmdSingleScan.Enabled = False
      Dim Result As AnalogMeasure
      Dim ChanToRead As Short
      Dim Dither As Boolean
      Dim DitherFactor As Int32
      Dim NumSamples As Long
      Dim SampleRate As Double
      Dim TermConfig As NationalInstruments.DAQmx.AITerminalConfiguration
      Dither = Me.chkDither.Checked
      DitherFactor = Convert.ToInt32(Me.txtDitherFactor.Text)
      NumSamples = Convert.ToInt64(Me.txtNoOfScans.Text)
      SampleRate = 1 / Convert.ToDouble(Me.txtScanRate.Text)
      If Me.optScanType_0.Checked = True Then
         TermConfig = DAQmx.AITerminalConfiguration.Rse
      Else
         TermConfig = DAQmx.AITerminalConfiguration.Differential
      End If
      If Me.chkScanAnalogIn.Checked = False Then
         txtMinValue.Text = "-"
         txtMaxValue.Text = "-"
         txtMeanValue.Text = "-"
         txtRMSValue.Text = "-"
         txtDCValue.Text = "-"
         txtFreqValue.Text = "-"
      End If

      ChanToRead = Convert.ToInt16(txtChannel.Text)
      Result = ReadNIAI(DAQ_USB_6009_DeviceName, ChanToRead, NumSamples, SampleRate, TermConfig, Dither, DitherFactor)

      Me.txtMinValue.Text = Result.Min.ToString
      Me.txtMaxValue.Text = Result.Max.ToString
      Me.txtMeanValue.Text = Result.Mean.ToString
      Me.txtRMSValue.Text = Result.RMS.ToString
      Me.txtDCValue.Text = Result.DC.ToString
      Me.txtFreqValue.Text = Result.Freq.ToString
      If Microsoft.VisualBasic.IsNothing(Result.DataToGraph) = False Then
         Me.CWGraph1.PlotWaveformAppend(Result.DataToGraph)
         Me.CWGraph1.Refresh()
      Else
         Me.CWGraph1.ClearData()
      End If

      'Me.txtChannel.Text = ChanToRead
      'Me.txtNoOfScans.Text = NumSamples
      'Me.txtScanRate.Text = SampleRate
      'If TermConfig = DAQmx.AITerminalConfiguration.Rse Then Me.optScanType_0.Checked = True
      'If TermConfig = DAQmx.AITerminalConfiguration.Differential Then Me.optScanType_1.Checked = True
      'Me.txtDitherFactor.Text = DitherFactor.ToString


      cmdSingleScan.Enabled = True

   End Sub

   Private Sub optAIchannel_0_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles optAIchannel_0.CheckedChanged, optAIchannel_1.CheckedChanged, optAIchannel_2.CheckedChanged, optAIchannel_3.CheckedChanged, optAIchannel_4.CheckedChanged, _
                                                                                                     optAIchannel_5.CheckedChanged, optAIchannel_6.CheckedChanged, optAIchannel_7.CheckedChanged
      Dim ButtonClicked As Control
      ButtonClicked = DirectCast(sender, Control)
      Me.txtChannel.Text = ButtonClicked.Name.Substring(ButtonClicked.Name.IndexOf("_") + 1)

   End Sub

#End Region 'End Main Operator Form Routines Region


#Region "Cognex IO Form Controls"
   Private Sub btnZoom_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)

   End Sub

   Private Sub rdoAlign_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoAlign.CheckedChanged
      If rdoAlign.Checked = False Then Exit Sub

      grpJob.Enabled = False
      Try
         clsVPRO.VisionTask(clsVPROSupport.VisionTasks.Align)
         bolAlignReady = True
         bolFocusReady = False
         bolColorReady = False

      Catch ex As Exception
         MessageBox.Show("Failed to select the Align vision operations.  " & ex.Message)
         bolAlignReady = False
         rdoAlign.Checked = False
      End Try

      grpJob.Enabled = True

   End Sub

   Private Sub rdoFocus_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoFocus.CheckedChanged

      If rdoFocus.Checked = False Then Exit Sub

      grpJob.Enabled = False
      Try
         clsVPRO.VisionTask(clsVPROSupport.VisionTasks.Focus)
         bolFocusReady = True
         bolAlignReady = False
         bolColorReady = False

      Catch ex As Exception
         MessageBox.Show("Failed to select the Focus vision operations.  " & ex.Message)
         bolFocusReady = False
         rdoFocus.Checked = False
      End Try

      grpJob.Enabled = True

   End Sub

   Private Sub rdoColor_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoColor.CheckedChanged

      If rdoColor.Checked = False Then Exit Sub

      grpJob.Enabled = False
      Try
         clsVPRO.VisionTask(clsVPROSupport.VisionTasks.Color)
         bolFocusReady = False
         bolAlignReady = False
         bolColorReady = True

      Catch ex As Exception
         MessageBox.Show("Failed to select the Focus vision operations.  " & ex.Message)
         bolFocusReady = False
         rdoFocus.Checked = False
      End Try

      grpJob.Enabled = True

   End Sub
   Private Sub btnFit_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnFit.Click

      btnFit.Enabled = False
      Try
         clsVPRO.ZoomFit() 'fit to the entire contents of the screen
      Catch ex As Exception
         MessageBox.Show("Failed zoom fit.  " & ex.Message)
      End Try
      btnFit.Enabled = True

   End Sub


   Private Sub btnRunOnce_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRunOnce.Click

      btnRunOnce.Enabled = False
      Try
         clsVPRO.RunOnce()
      Catch ex As Exception
         MessageBox.Show("Failed run once: " & ex.Message)
      End Try
      btnRunOnce.Enabled = True

   End Sub

   Private Sub btnSavePic_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnSavePic.Click
      btnSavePic.Enabled = False
      Try
         clsVPRO.SavePictureJPG("c:\PicturesJPG", "SavedImage", chkGraphics.Checked)
         clsVPRO.SavePictureBMP("c:\PicturesBMP", "SavedImage", chkGraphics.Checked)
      Catch ex As Exception
         MessageBox.Show("Could not save the picture.  " & ex.Message)
      End Try
      btnSavePic.Enabled = True

   End Sub
   Private Sub gclsMTF_ResultsReady() Handles clsVPRO.ResultsReady

      If bolAlignReady = True Then AlignData() 'IF Checking Aligment Data Then Get Results
      If bolFocusReady = True Then FocusData() 'IF Checking Focus Data Then Get Results
      If bolColorReady = True Then ColorData() 'IF Checking Color Data Then Get Results

   End Sub

   Private Sub gclsMTF_RunningState(ByVal state As clsVPROSupport.RunningStates) Handles clsVPRO.RunningState

      If state = clsVPROSupport.RunningStates.RunningContinuous Then
         lblJobState.Text = "Running Continuous"
         lblJobState.BackColor = Color.Yellow
      ElseIf state = clsVPROSupport.RunningStates.RunningSingle Then
         lblJobState.Text = "Running Single"
         lblJobState.BackColor = Color.Yellow
      ElseIf state = clsVPROSupport.RunningStates.Stopped Then
         lblJobState.Text = "Stopped"
         lblJobState.BackColor = Color.LimeGreen
         bolResultsReady = True
      End If

   End Sub

   Private Sub AlignData()
      Dim x, y, angle As Double

      'Clear Out Any Previous Results
      AlignmentVariables.MeasuredX = 999
      AlignmentVariables.MeasuredY = 999
      AlignmentVariables.MeasuredAngle = 999
      AlignmentVariables.MeasuredOrientation = ""


      Try
         clsVPRO.GetAlignData(x, y, angle)
         AlignmentVariables.MeasuredOrientation = clsVPRO.ImageOrientation.ToString
         AlignmentVariables.MeasuredAngle = Format((angle + Nest_Pallet_Offset(NestOrPalletNumberInUse).RotationAngle_Offset), "#0.0")
         AlignmentVariables.MeasuredX = Format((x + Nest_Pallet_Offset(NestOrPalletNumberInUse).X_Offset), "#0.0")
         AlignmentVariables.MeasuredY = Format((y + Nest_Pallet_Offset(NestOrPalletNumberInUse).Y_Offset), "#0.0")

      Catch ex As Exception
         MessageBox.Show("AlignData: " & ex.Message)
      End Try

      'Calculate The Alignment Degrees From Measured Values
      AlignmentVariables.degrees = Format(CalculateAlignmentDegrees(AlignmentVariables.MeasuredX, AlignmentVariables.MeasuredY), "#0.00")
      txtAlignX.Text = AlignmentVariables.MeasuredX
      txtAlignY.Text = AlignmentVariables.MeasuredY
      txtImageOrientation.Text = AlignmentVariables.MeasuredOrientation
      txtMeasuredDegrees.Text = AlignmentVariables.degrees.ToString
      txtAlignAngle.Text = AlignmentVariables.MeasuredAngle
      txtAlignCenterX.Text = (AlignmentVariables.CenterX).ToString
      txtAlignCenterY.Text = (AlignmentVariables.CenterY).ToString
      txtAlignAngleError.Text = (AlignmentVariables.MeasuredAngle - 0).ToString
      txtAlignErrorX.Text = Format(AlignmentVariables.PixelErrorX, "#0.0")
      txtAlignErrorY.Text = Format(AlignmentVariables.PixelErrorY, "#0.0")
      txtDegreesError.Text = Format(AlignmentVariables.degrees - 0, "#0.0")
      x = Nothing
      y = Nothing
      angle = Nothing

   End Sub
   Private Sub FocusData()

      Dim Lpmm As Double
      '3/5/14 jgk added 
      Dim Target_X As Double
      Dim Target_Y As Double
      Dim Center_X As Double
      Dim Center_Y As Double

      Try

         With clsVPRO

            .GetFocusData(clsVPROSupport.RegionEnum.Center, Lpmm, Target_X, Target_Y) '3/5/14 jgk added Target_X, Target_Y
            txtFocusCL.Text = Format(Lpmm, "#0.0")
            '3/5/14 jgk added Target_X, Target_Y
            Center_X = Format(Target_X, "#0.0")
            Center_Y = Format(Target_Y, "#0.0")
            'txtFocusCX.Text = Center_X
            'txtFocusCY.Text = Center_Y

            .GetFocusData(clsVPROSupport.RegionEnum.LeftTop, Lpmm, Target_X, Target_Y) '3/5/14 jgk added Target_X, Target_Y
            txtFocusLTL.Text = Format(Lpmm, "#0.0")
            '3/5/14 jgk added Target_X, Target_Y
            Target_X = Target_X - Center_X 'calc delta from center
            Target_Y = Target_Y - Center_Y 'calc delta from center
            'txtFocusLTX.Text = Format(Target_X, "#0.0")
            'txtFocusLTY.Text = Format(Target_Y, "#0.0")
            'txtFocusLTHyp.Text = Format(Math.Sqrt(Target_X ^ 2 + Target_Y ^ 2), "#0.0") 'calc distance for center (hyp)

            .GetFocusData(clsVPROSupport.RegionEnum.RightTop, Lpmm, Target_X, Target_Y) '3/5/14 jgk added Target_X, Target_Y
            txtFocusRTL.Text = Format(Lpmm, "#0.0")
            '3/5/14 jgk added Target_X, Target_Y
            Target_X = Target_X - Center_X 'calc delta from center
            Target_Y = Target_Y - Center_Y 'calc delta from center
            'txtFocusRTX.Text = Format(Target_X, "#0.0")
            'txtFocusRTY.Text = Format(Target_Y, "#0.0")
            'txtFocusRTHyp.Text = Format(Math.Sqrt(Target_X ^ 2 + Target_Y ^ 2), "#0.0") 'calc distance for center (hyp)

            .GetFocusData(clsVPROSupport.RegionEnum.LeftBot, Lpmm, Target_X, Target_Y) '3/5/14 jgk added Target_X, Target_Y  '8-14-13 jgk corrected, was .RightBot, Lpmm)
            txtFocusLBL.Text = Format(Lpmm, "#0.0")
            '3/5/14 jgk added Target_X, Target_Y
            Target_X = Target_X - Center_X 'calc delta from center
            Target_Y = Target_Y - Center_Y 'calc delta from center
            'txtFocusLBX.Text = Format(Target_X, "#0.0")
            'txtFocusLBY.Text = Format(Target_Y, "#0.0")
            'txtFocusLBHyp.Text = Format(Math.Sqrt(Target_X ^ 2 + Target_Y ^ 2), "#0.0") 'calc distance for center (hyp)

            .GetFocusData(clsVPROSupport.RegionEnum.RightBot, Lpmm, Target_X, Target_Y) '3/5/14 jgk added Target_X, Target_Y '8-14-13 jgk corrected, was .LeftBot, Lpmm)
            txtFocusRBL.Text = Format(Lpmm, "#0.0")
            '3/5/14 jgk added Target_X, Target_Y
            Target_X = Target_X - Center_X 'calc delta from center
            Target_Y = Target_Y - Center_Y 'calc delta from center
            'txtFocusRBX.Text = Format(Target_X, "#0.0")
            'txtFocusRBY.Text = Format(Target_Y, "#0.0")
            'txtFocusRBHyp.Text = Format(Math.Sqrt(Target_X ^ 2 + Target_Y ^ 2), "#0.0") 'calc distance for center (hyp)


         End With
         'Try

         '   With clsVPRO

         '      .GetFocusData(clsVPROSupport.RegionEnum.Center, Lpmm)
         '      txtFocusCL.Text = Format(Lpmm, "#0.0")

         '      .GetFocusData(clsVPROSupport.RegionEnum.LeftTop, Lpmm)
         '      txtFocusLTL.Text = Format(Lpmm, "#0.0")

         '      .GetFocusData(clsVPROSupport.RegionEnum.RightTop, Lpmm)
         '      txtFocusRTL.Text = Format(Lpmm, "#0.0")

         '      .GetFocusData(clsVPROSupport.RegionEnum.RightBot, Lpmm)
         '      txtFocusLBL.Text = Format(Lpmm, "#0.0")

         '      .GetFocusData(clsVPROSupport.RegionEnum.LeftBot, Lpmm)
         '      txtFocusRBL.Text = Format(Lpmm, "#0.0")

         '   End With

      Catch ex As Exception
         MessageBox.Show("FocusData: " & ex.Message)
      End Try

      Lpmm = Nothing


   End Sub

   Private Sub ColorData()

      Dim r, b, g As Integer

      Try
         With clsVPRO

            .GetColorData(clsVPROSupport.ColorEnum.Red, r, g, b)
            txtRedR.Text = r.ToString
            txtRedB.Text = b.ToString
            txtRedG.Text = g.ToString
            txtRedCPA.Text = CalcChromPhaseAngle(CPA_Color.Red, r, g, b).ToString

            .GetColorData(clsVPROSupport.ColorEnum.Blue, r, g, b)
            txtBlueR.Text = r.ToString
            txtBlueB.Text = b.ToString
            txtBlueG.Text = g.ToString
            txtBlueCPA.Text = CalcChromPhaseAngle(CPA_Color.Blue, r, g, b).ToString

            .GetColorData(clsVPROSupport.ColorEnum.Green, r, g, b)
            txtGreenR.Text = r.ToString
            txtGreenB.Text = b.ToString
            txtGreenG.Text = g.ToString
            txtGreenCPA.Text = CalcChromPhaseAngle(CPA_Color.Green, r, g, b).ToString


         End With

      Catch ex As Exception
         MessageBox.Show("ColorData: " & ex.Message)
      End Try

      r = Nothing
      b = Nothing
      g = Nothing

   End Sub

   Private Sub rbRetest_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rbRetest.CheckedChanged
      If Me.rbRetest.Checked = True Then
         '2014-5-4 Potter added authority control
         If TypeScan = "O" Then
            frmRetestPassword.ShowDialog()
            If My.Settings.RetestPassword = frmRetestPassword.tbRetestPassword.Text Then ' InputBox("Please enter the password", "Restet Password") Then
               Call UpdateMode("Retest")
            Else
               MsgBox("Password incorrect, turn to Normal mode!")
               Me.rbRetest.Checked = False
               Me.rbNormal.Checked = True
            End If
         Else
            Call UpdateMode("Retest")
         End If
         '2017-6-27 Potter write FFTReady=1 
         Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
      End If
   End Sub

   Private Sub rbNormal_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rbNormal.CheckedChanged
      If Me.rbNormal.Checked = True Then
      End If
   End Sub

   Private Sub rbGonogo_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rbGonogo.CheckedChanged
      'If Me.rbGonogo.Checked = True Then
      '   Call UpdateMode("GoNoGo")
      'End If
   End Sub

   Private Sub rdoNone_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoNone.CheckedChanged
      If clsVPRO IsNot Nothing Then
         clsVPRO.ImageOrientationRequired = clsVPROSupport.ImageOrientationRequiredEnum.None
      End If
   End Sub

   Private Sub rdoVFlip_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoVFlip.CheckedChanged
      If clsVPRO IsNot Nothing Then
         clsVPRO.ImageOrientationRequired = clsVPROSupport.ImageOrientationRequiredEnum.VerticalFlip
      End If
   End Sub

   Private Sub rdoHFlip_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoHFlip.CheckedChanged
      If clsVPRO IsNot Nothing Then
         clsVPRO.ImageOrientationRequired = clsVPROSupport.ImageOrientationRequiredEnum.HorizontalFlip
      End If
   End Sub

   Private Sub rdoRotate_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdoRotate.CheckedChanged
      If clsVPRO IsNot Nothing Then
         clsVPRO.ImageOrientationRequired = clsVPROSupport.ImageOrientationRequiredEnum.Rotate
      End If
   End Sub
   Private Sub nudZoomFactor_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles nudZoomFactor.ValueChanged
      If clsVPRO IsNot Nothing Then
         Try
            clsVPRO.ZoomCustom(nudZoomFactor.Value) 'Zoom By A Factor Of X * 100
         Catch ex As Exception
            MessageBox.Show("Failed zoom.   " & ex.Message)
         End Try
      End If

   End Sub

#End Region 'End Cognex IO Controls Region

   Private Sub tmrAutomaticMode_Tick(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles tmrAutomaticMode.Tick
       'This Timer Will Check The State OF The Start Signal From The Automation (When not in Manual Mode)

      'If In Manual Mode Then Exit Sub
      If FullAuto = False Then Exit Sub

      'If A Part Number Has Not Been Selected Then Exit The Sub
      If Camera.Partnumber = "" Then
         tmrAutomaticMode.Enabled = False
         'Load A Part Number

         ' frmLoadPartNumber.ShowDialog()

         tmrAutomaticMode.Enabled = True
      End If

      'If An Operator Is Not Logged In Then Exit Sub
      If OperatorScan = "" Then
         'Login An Operator
         tmrAutomaticMode.Enabled = False

         frmPassword.ShowDialog()

         tmrAutomaticMode.Enabled = True
      End If

      'If The Productinfo has not been loaded yet Then Exit Sub
      If ProductInfo.OEM = "" Then Exit Sub

      ''2013-12-3 Potter Added txtCarrier
      'If txtCarrier.Focused = False Then
      '   Application.DoEvents()
      '   txtCarrier.Focus()
      'End If


      'UpdateStatus("Ready")

      ''Start Test When Operator Activates Start Switch
      'Select Case ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Start_Switch")
      '   Case True
      '      'Disable Timer So That It Is Not Called On The Next Tick
      '      tmrAutomaticMode.Enabled = False

      '      'Call The Start Test Routine
      '      Start()

      '   Case False
      '      'Do Nothing
      'End Select
      Try
         Dim ReturnedStates() As Boolean
         Dim TableReady As Boolean
         Dim TableTestReady As Boolean
         Dim TableRotate As Boolean
         Dim DUTn As Integer
         ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 0, 0, 4) '0 TableReady, 1 TableTestReady, 2 DUT1, 3 DUT2, 4 TableRotate
         TableReady = ReturnedStates(0)
         TableTestReady = ReturnedStates(1)
         TableRotate = ReturnedStates(4)

         Dim tempMsgString As String
         tempMsgString = ""
         If TableReady = True Then tempMsgString = "Table Ready,"
         If TableTestReady = True Then tempMsgString = tempMsgString & "Table TestReady,"
         If TableRotate = True Then tempMsgString = tempMsgString & "Table Rotate,"
         If lblPLCStatusMessages.Text <> tempMsgString Then lblPLCStatusMessages.Text = tempMsgString


         If ReturnedStates(2) = True Then
            If ReturnedStates(3) = True Then
               DUTn = 3
               lblNestNumberAtThisStation.Text = " "
            Else
               DUTn = 1
               lblNestNumberAtThisStation.Text = "1"
            End If
         Else
            If ReturnedStates(3) = True Then
               DUTn = 2
               lblNestNumberAtThisStation.Text = "2"
            Else
               DUTn = 0
               lblNestNumberAtThisStation.Text = " "
            End If
         End If


         If TableRotate = True And TestMode = " " Then
            '2018-5-6 potter added traceabilityenable judgement
            '2017-6-27 Potter write FFTReady=0 
            If ProductInfo.TraceabilityEnable = True Then
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "0") 'FFTReady=0
            Else
               Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1
            End If
         End If

         If TableTestReady = True Then
            UpdateStatus("Ready")
            CarrierNameTesting = CarrierName
            lblCarrierPrompt.Text = ""
            txtCarrier.Text = ""
            txtCarrier.Enabled = True
            txtCarrier.Focus()
            TestingDUTTesting = True
         End If


         'If WaitingRotateTable = False And WaitingTakePart = False And ReturnedStates(0) = True And ReturnedStates(1) = True Then 'OperationDUT start
         '   tmrAutomaticMode.Enabled = False
         '   If TestMode = " " Then
         '      If ProductInfo.TraceabilityEnable = True Then
         '         If txtCarrier.Text.Length <> 10 Or txtCarrier.Text.ToUpper.StartsWith("CARRIER") = False Or txtCarrier.Enabled = True Then
         '            'MessageBox.Show("MUST SCAN CORRECT CARRIER BOX FIRST!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
         '            lblCarrierPrompt.Text = "Incorrect Carrier"
         '            txtCarrier.Enabled = True
         '            txtCarrier.SelectAll()
         '            txtCarrier.Focus()
         '            tmrAutomaticMode.Enabled = True
         '            Exit Sub
         '         Else
         '            lblCarrierPrompt.Text = ""
         '            WaitingRotateTable = True
         '            CarrierName = txtCarrier.Text
         '            txtCarrier.Text = ""
         '            txtCarrier.Enabled = True
         '            txtCarrier.Focus()

         '            '2017-6-27 Potter write FFTReady 
         '            Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1")

         '         End If
         '      End If
         '   Else
         '      lblCarrierPrompt.Text = ""
         '      WaitingRotateTable = True

         '   End If

         '   'waiting for testing finished
         '   'Waiting prompt
         '   lblMsg.Visible = True
         '   lblMsg.BackColor = Color.Yellow
         '   lblMsg.ForeColor = Color.Black
         '   lblMsg.Text = "Waiting For Testing Finished"
         '   Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "11") 'Indicater Yellow lignt Open
         '   If TestingDUTTesting = True Then
         '      tmrAutomaticMode.Enabled = True
         '      Exit Sub
         '   End If
         '   tmrAutomaticMode.Enabled = True
         'End If

         ''Rotate table
         'If TestingDUTTesting = False And WaitingRotateTable = True Then
         '   tmrAutomaticMode.Enabled = False
         '   'Rotate DUT turntable
         '   Dim lastStates As Boolean
         '   Dim notdf As Boolean
         '   Call WriteDigPort(DAQ_6514_DeviceName, 6, 0, "0") 'Clinder Down

         '   Dim count As Integer = 0
         '   ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 1, 5, 5)
         '   While ReturnedStates(0) = False
         '      Delay(100)
         '      ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 1, 5, 5)
         '      count = count + 1
         '      If count > 20 Then
         '         MessageBox.Show("Can not Detect the Clinder SensorDown Signal,Please Check", "Digit Input Check")
         '         count = 0
         '      End If
         '   End While

         '   Call WriteDigPort(DAQ_6514_DeviceName, 5, 5, "1") 'start rotation
         '   ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 1, 3, 4)
         '   lastStates = ReturnedStates(0)
         '   While Not notdf
         '      Application.DoEvents()
         '      ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 1, 3, 4)
         '      If lastStates = True And ReturnedStates(0) = False Then
         '         notdf = True
         '      Else
         '         lastStates = ReturnedStates(0)
         '      End If
         '      If ReturnedStates(1) = True Then
         '         MessageBox.Show("Detected the Inverter Alarm", "Digit Input Check")
         '         Exit While
         '      End If
         '   End While
         '   Call WriteDigPort(DAQ_6514_DeviceName, 5, 5, "0") 'stop rotation
         '   Call WriteDigPort(DAQ_6514_DeviceName, 6, 0, "1") 'clinder up

         '   'Result Prompt
         '   OperationDUTStatus = TestingDUTStatus
         '   If OperationDUTStatus = 1 Then
         '      WaitingTakePart = True
         '      lblMsg.Visible = True
         '      lblMsg.BackColor = Color.LimeGreen
         '      lblMsg.ForeColor = Color.Black
         '      lblMsg.Text = "Place Part On Table"
         '      tmrAutomaticMode.Enabled = True
         '      Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "01") 'Indicater G lignt Open
         '   ElseIf OperationDUTStatus = 2 Then
         '      WaitingTakePart = True
         '      lblMsg.Visible = True
         '      lblMsg.BackColor = Color.Red
         '      lblMsg.ForeColor = Color.Black
         '      lblMsg.Text = "Place Part In Scrap Bin"
         '      tmrAutomaticMode.Enabled = True
         '      Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "10") 'Indicater R lignt Open
         '   Else
         '      'txtCarrier.Text = ""
         '      'txtCarrier.Enabled = True
         '      'txtCarrier.Focus()
         '      WaitingTakePart = False
         '      lblMsg.Visible = True
         '      lblMsg.BackColor = Color.WhiteSmoke
         '      lblMsg.ForeColor = Color.Black
         '      lblMsg.Text = "Add A New Part"
         '      tmrAutomaticMode.Enabled = True
         '      Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "00") 'Indicater R,G lignt Close
         '   End If

         '   UpdateStatus("Ready")
         '   '2015-5-8 potter added
         '   CarrierNameTesting = CarrierName
         '   '2015-5-8
         '   TestingDUTTesting = True
         '   WaitingRotateTable = False

         '   tmrAutomaticMode.Enabled = True
         'End If

         ''
         'If WaitingTakePart = True And (OperationDUTStatus = 1 Or OperationDUTStatus = 2) Then
         '   tmrAutomaticMode.Enabled = False
         '   If OperationDUTStatus = 2 Then
         '      ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 0, 6, 6) ' Scrap bin check
         '      If ReturnedStates(0) = False Then
         '         tmrAutomaticMode.Enabled = True
         '         Exit Sub
         '      End If
         '   End If
         '   ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 0, 4, 5) 'Light Grating check
         '   If ReturnedStates(0) = False Or ReturnedStates(1) = False Then
         '      OperationDUTStatus = 0
         '      'txtCarrier.Text = ""
         '      'txtCarrier.Enabled = True
         '      'txtCarrier.Focus()
         '      WaitingTakePart = False
         '      lblMsg.Visible = True
         '      lblMsg.BackColor = Color.WhiteSmoke
         '      lblMsg.ForeColor = Color.Black
         '      lblMsg.Text = "Add A New Part"
         '      tmrAutomaticMode.Enabled = True
         '      Call WriteDigPort(DAQ_6514_DeviceName, 4, 4, "00") 'Indicater R,G lignt Close
         '   End If
         '   tmrAutomaticMode.Enabled = True
         'End If


      Catch ex As Exception

      Finally
         tmrAutomaticMode.Enabled = True
      End Try


   End Sub

   Private Sub cmdPrintFailLabel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPrintFailLabel.Click

      Print_Labels("Fail")

   End Sub

   Private Sub cmdInitMeter_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)

   End Sub

   Private Sub cmdSetCurrentMode_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)

   End Sub

   Private Sub cmbMeterSetFunction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles cmbMeterSetFunction.Click

   End Sub


   Private Sub cmdMeterRead_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdMeterRead.Click
      cmdMeterRead.Enabled = False
      txtMeterCommand.Text = "MEAS:"
      Select Case cmbMeterSetFunction.Text
         Case "Voltage (DC)"
            txtMeterCommand.Text = txtMeterCommand.Text & "VOLT:DC? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Voltage (AC)"
            txtMeterCommand.Text = txtMeterCommand.Text & "VOLT:AC? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Resistance"
            txtMeterCommand.Text = txtMeterCommand.Text & "RES? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Four Wire Resistance"
            txtMeterCommand.Text = txtMeterCommand.Text & "FRES? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Capacitance"
            txtMeterCommand.Text = txtMeterCommand.Text & "CAP? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Current (DC)"
            txtMeterCommand.Text = txtMeterCommand.Text & "CURR:DC? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Current (AC)"
            txtMeterCommand.Text = txtMeterCommand.Text & "CURR:AC? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Frequency"
            txtMeterCommand.Text = txtMeterCommand.Text & "FREQ? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Period"
            txtMeterCommand.Text = txtMeterCommand.Text & "PER? "
            If cmbMeterSetRange.Text <> "Auto" Then txtMeterCommand.Text = txtMeterCommand.Text & ActualValue(cmbMeterSetRange.Text)
         Case "Diode"
            txtMeterCommand.Text = txtMeterCommand.Text & "DIOD? "
         Case "Continuity"
            txtMeterCommand.Text = txtMeterCommand.Text & "CONT? "
      End Select

      IO_Support.SendMeterCommand(txtMeterCommand.Text)

      cmdMeterRead.Enabled = True
   End Sub

   Private Sub cmdSendMeterCommand_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSendMeterCommand.Click
      cmdSendMeterCommand.Enabled = False

      IO_Support.SendMeterCommand(txtMeterCommand.Text)

      cmdSendMeterCommand.Enabled = True

   End Sub

   Private Sub cmbMeterSetFunction_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmbMeterSetFunction.SelectedIndexChanged
      cmbMeterSetRange.Enabled = False
      cmbMeterSetRange.Items.Clear()
      Select Case cmbMeterSetFunction.Text
         Case "Voltage (DC)"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "Vdc"
            cmbMeterSetRange.Items.Add("")
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("100mV")
            cmbMeterSetRange.Items.Add("1V")
            cmbMeterSetRange.Items.Add("10V")
            cmbMeterSetRange.Items.Add("100V")
            cmbMeterSetRange.Items.Add("1000V")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Voltage (AC)"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "V"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("0.1")
            cmbMeterSetRange.Items.Add("1V")
            cmbMeterSetRange.Items.Add("10V")
            cmbMeterSetRange.Items.Add("100V")
            cmbMeterSetRange.Items.Add("1000V")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Resistance"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "Ohms"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("100")
            cmbMeterSetRange.Items.Add("1K")
            cmbMeterSetRange.Items.Add("100K")
            cmbMeterSetRange.Items.Add("1000K")
            cmbMeterSetRange.Items.Add("1M")
            cmbMeterSetRange.Items.Add("10M")
            cmbMeterSetRange.Items.Add("100M")
            cmbMeterSetRange.Items.Add("1G")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Four Wire Resistance"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "Ohms"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("100")
            cmbMeterSetRange.Items.Add("1K")
            cmbMeterSetRange.Items.Add("100K")
            cmbMeterSetRange.Items.Add("1000K")
            cmbMeterSetRange.Items.Add("1M")
            cmbMeterSetRange.Items.Add("10M")
            cmbMeterSetRange.Items.Add("100M")
            cmbMeterSetRange.Items.Add("1G")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Capacitance"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "F"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("1n")
            cmbMeterSetRange.Items.Add("10n")
            cmbMeterSetRange.Items.Add("100n")
            cmbMeterSetRange.Items.Add("1u")
            cmbMeterSetRange.Items.Add("10u")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Current (DC)"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "A"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("100u")
            cmbMeterSetRange.Items.Add("1m")
            cmbMeterSetRange.Items.Add("10m")
            cmbMeterSetRange.Items.Add("100m")
            cmbMeterSetRange.Items.Add("1")
            cmbMeterSetRange.Items.Add("3")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Current (AC)"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "A"
            cmbMeterSetRange.Items.Add("Auto")
            cmbMeterSetRange.Items.Add("100u")
            cmbMeterSetRange.Items.Add("1m")
            cmbMeterSetRange.Items.Add("10m")
            cmbMeterSetRange.Items.Add("100m")
            cmbMeterSetRange.Items.Add("1")
            cmbMeterSetRange.Items.Add("3")
            cmbMeterSetRange.SelectedIndex = 0
         Case "Frequency"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "Hz"
            cmbMeterSetRange.Items.Add("3")
            cmbMeterSetRange.Items.Add("20")
            cmbMeterSetRange.Items.Add("300k")
            cmbMeterSetRange.SelectedIndex = 1
         Case "Period"
            cmbMeterSetRange.Enabled = True
            lblRange.Text = "S"
            cmbMeterSetRange.Items.Add("3.33u")
            cmbMeterSetRange.Items.Add("50m")
            cmbMeterSetRange.Items.Add("333.33m")
            cmbMeterSetRange.SelectedIndex = 1
         Case "Diode"
         Case "Continuity"
         Case Else

      End Select

   End Sub

   Private Sub btnSetAODefaults_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnSetAODefaults.Click

      Call GetTesterSpec("DAQ_USB_31XX_AO_Channel_Map")
      Call SetLightingDefaultLevels()

   End Sub

   Public Sub SetLightingDefaultLevels()
      Dim AOchan As Integer

      If MCC_USB_3112_DeviceName.ToUpper <> "NA" Then
         For AOchan = 0 To 7
            MCC3112DUT1.WriteVOut(AOchan, AODefaultValves(AOchan))
         Next AOchan
      End If

   End Sub
   Public Sub ResetLightingLevels()
      Dim AOchan As Integer

      If MCC_USB_3112_DeviceName.ToUpper <> "NA" Then
         For AOchan = 0 To 7
            MCC3112DUT1.WriteVOut(AOchan, 0)
         Next AOchan
      End If

   End Sub

   Public Sub btnAnalogOutputApply_0_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnAnalogOutputApply_0.Click, btnAnalogOutputApply_1.Click, btnAnalogOutputApply_2.Click, btnAnalogOutputApply_3.Click, btnAnalogOutputApply_4.Click, btnAnalogOutputApply_5.Click, btnAnalogOutputApply_6.Click,
       btnAnalogOutputApply_7.Click

      'Applys the voltage to the selected Analog Output based on the value in the numeric edit control on the manual screen

      Dim ButtonClicked As Control
      Dim Index As Short

      ButtonClicked = DirectCast(sender, Control)
      Index = Convert.ToInt16(ButtonClicked.Name.Substring(ButtonClicked.Name.Length - 1, 1))

      'If DUT 1 Is Selected then
      If rbDut1.Checked = True Then
         Select Case ButtonClicked.Name
            Case "btnAnalogOutputApply_0"
               MCC3112DUT1.WriteVOut(0, Convert.ToSingle(Me.neAnalogOutput_0.Value))
            Case "btnAnalogOutputApply_1"
               MCC3112DUT1.WriteVOut(1, Convert.ToSingle(Me.neAnalogOutput_1.Value))
            Case "btnAnalogOutputApply_2"
               MCC3112DUT1.WriteVOut(2, Convert.ToSingle(Me.neAnalogOutput_2.Value))
            Case "btnAnalogOutputApply_3"
               MCC3112DUT1.WriteVOut(3, Convert.ToSingle(Me.neAnalogOutput_3.Value))
            Case "btnAnalogOutputApply_4"
               MCC3112DUT1.WriteVOut(4, Convert.ToSingle(Me.neAnalogOutput_4.Value))
            Case "btnAnalogOutputApply_5"
               MCC3112DUT1.WriteVOut(5, Convert.ToSingle(Me.neAnalogOutput_5.Value))
            Case "btnAnalogOutputApply_6"
               MCC3112DUT1.WriteVOut(6, Convert.ToSingle(Me.neAnalogOutput_6.Value))
            Case "btnAnalogOutputApply_7"
               MCC3112DUT1.WriteVOut(7, Convert.ToSingle(Me.neAnalogOutput_7.Value))
         End Select
      End If


   End Sub

   Public Sub btnAnalogOutputRemove_0_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnAnalogOutputRemove_0.Click, btnAnalogOutputRemove_1.Click, btnAnalogOutputRemove_2.Click, btnAnalogOutputRemove_3.Click, btnAnalogOutputRemove_4.Click, btnAnalogOutputRemove_5.Click, btnAnalogOutputRemove_6.Click, btnAnalogOutputRemove_7.Click
      'Removes the voltage applied to the selected Analog Output (sets to zero volts)
      Dim ButtonClicked As Control
      Dim Index As Short

      ButtonClicked = DirectCast(sender, Control)
      Index = Convert.ToInt16(ButtonClicked.Name.Substring(ButtonClicked.Name.Length - 1, 1))

      'If DUT 1 Is Selected then
      If rbDut1.Checked = True Then
         Select Case ButtonClicked.Name
            Case "btnAnalogOutputRemove_0"
               MCC3112DUT1.WriteVOut(0, 0)
               Me.neAnalogOutput_0.Value = "0"
            Case "btnAnalogOutputRemove_1"
               MCC3112DUT1.WriteVOut(1, 0)
               Me.neAnalogOutput_1.Value = "0"
            Case "btnAnalogOutputRemove_2"
               MCC3112DUT1.WriteVOut(2, 0)
               Me.neAnalogOutput_2.Value = "0"
            Case "btnAnalogOutputRemove_3"
               MCC3112DUT1.WriteVOut(3, 0)
               Me.neAnalogOutput_3.Value = "0"
            Case "btnAnalogOutputRemove_4"
               MCC3112DUT1.WriteVOut(4, 0)
               Me.neAnalogOutput_4.Value = "0"
            Case "btnAnalogOutputRemove_5"
               MCC3112DUT1.WriteVOut(5, 0)
               Me.neAnalogOutput_5.Value = "0"
            Case "btnAnalogOutputRemove_6"
               MCC3112DUT1.WriteVOut(6, 0)
               Me.neAnalogOutput_6.Value = "0"
            Case "btnAnalogOutputRemove_7"
               MCC3112DUT1.WriteVOut(7, 0)
               Me.neAnalogOutput_7.Value = "0"
         End Select
      End If

   End Sub

   Private Sub btnResetAOvalues_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnResetAOvalues.Click

      Me.neAnalogOutput_0.Value = "0" : Me.neAnalogOutput_1.Value = "0" : Me.neAnalogOutput_2.Value = "0" : Me.neAnalogOutput_3.Value = "0"
      Me.neAnalogOutput_4.Value = "0" : Me.neAnalogOutput_5.Value = "0" : Me.neAnalogOutput_6.Value = "0" : Me.neAnalogOutput_7.Value = "0"
      Call ResetLightingLevels()

   End Sub

   Private Sub btnLoadNestOffsets_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnLoadNestOffsets.Click
      'Find Out What Nest Is At The Test Fixture

      UpdateNestData()

      'Tell Vision Class What Fixture Offsets To Use
      'TODO UPDATE VISION PRO CLASS TO NEW VERSION FROM BRUCE
      ' Me.clsVPRO.SetFixtureValues(Nest_Pallet_Offset(NestOrPalletNumberInUse).X_Offset, Nest_Pallet_Offset(NestOrPalletNumberInUse).Y_Offset, Nest_Pallet_Offset(NestOrPalletNumberInUse).RotationAngle_Offset)
      txtFixX.Text = Nest_Pallet_Offset(NestOrPalletNumberInUse).X_Offset.ToString
      txtFixY.Text = Nest_Pallet_Offset(NestOrPalletNumberInUse).Y_Offset.ToString
      txtFixAngle.Text = Nest_Pallet_Offset(NestOrPalletNumberInUse).RotationAngle_Offset
   End Sub



   Private Sub btnSetupLINCommunication_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnSetupLINCommunication.Click
      Try
         Camera.DisableInitCommandsWithEachMessage()
      Catch ex As Exception
         WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, True, "ERROR SETTING LIN COMMUNICATION")
      End Try


   End Sub

   Private Sub cmdPrintPassLabel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPrintPassLabel.Click
      Print_Labels("PASS")
   End Sub


   Public Sub mnuIncludeGraphs_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles mnuIncludeGraphs.Click

      If mnuTechMode.Checked = False Then
         mnuIncludeGraphs.Checked = False
      Else
         If mnuIncludeGraphs.Checked = True Then
            mnuIncludeGraphs.Checked = False
         Else
            mnuIncludeGraphs.Checked = True
         End If
      End If
      IncludeGraphsWithSavedImage = mnuIncludeGraphs.Checked

   End Sub

   Private Sub ResetTotalsToolStripMenuItem_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ResetTotalsToolStripMenuItem.Click
      TotalPassed = 0
      TotalFailed = 0
      TotalTested = 0
      Me.lblNumberOfPartsPassed.Text = TotalPassed.ToString
      Me.lblNumberOfPartsFailed.Text = TotalFailed.ToString
      Me.lblNumberOfPartsTested.Text = TotalTested.ToString
      'Write Variables To Database So They Can Be Re-Loaded At Powerup)
      WriteTesterSpecField("Tester", "TotalPassed", TotalPassed.ToString)
      WriteTesterSpecField("Tester", "TotalFailed", TotalFailed.ToString)
      WriteTesterSpecField("Tester", "TotalTested", TotalTested.ToString)
   End Sub

   Private Sub rbMode0_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rbMode0.CheckedChanged, rbMode1.CheckedChanged, rbMode2.CheckedChanged, rbMode3.CheckedChanged
      'This Sub Will Change The Viewing Mode Of Honda Cameras
      'Based On Which Radio Button Is Clicked On
      'This Will Not Work IF GPIO is Disabled (happens when Communication Is Sent To The Honda Camera)

      'This Was The Channel Map At The Time This Sub Was Created
      'Port ID	Port Channel Name
      '0	Relay 1 VBAT
      '1	Relay 2 ON=I2C Disconnect From NI
      '2	Relay 3 BIT0 Control (Used On Honda)
      '3	Relay 4 BIT1 Control (Used On Honda)
      '4	Relay 5 On = Level Shifted I2C (Used On Honda)
      '5:    Relay(6(Not Connected))
      '6:    Relay(7(Not Connected))
      '7:    Relay(8(Not Connected))

      'Disconnet NI I2C from Relays
      Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 1, "1")

      Dim ButtonClicked As Control
      ButtonClicked = DirectCast(sender, Control)

      Select Case ButtonClicked.Name
         Case Is = "rbMode0"
            'BIT 0 = 0
            'BIT 1 = 0
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 2, "0")
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 3, "0")

         Case Is = "rbMode1"
            'BIT 0 = 0
            'BIT 1 = 1
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 2, "0")
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 3, "1")

         Case Is = "rbMode2"
            'BIT 0 = 1
            'BIT 1 = 0
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 2, "1")
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 3, "0")

         Case Is = "rbMode3"
            'BIT 0 = 1
            'BIT 1 = 1
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 2, "1")
            Call WriteDigPort(DAQ_USB_6525_DeviceName, 0, 3, "1")
         Case Else

      End Select


   End Sub

   Private Sub btnDigitalSharpeningOFF_Click(sender As Object, e As EventArgs) Handles btnDigitalSharpeningOFF.Click
      Camera.DigitalSharpnessControl = False
   End Sub

   Private Sub btnDigitalSharpeningON_Click(sender As Object, e As EventArgs) Handles btnDigitalSharpeningON.Click
      Camera.DigitalSharpnessControl = True
   End Sub

   Private Sub btnReadDigitalSharpeningState_Click(sender As Object, e As EventArgs) Handles btnReadDigitalSharpeningState.Click

      Select Case Camera.DigitalSharpnessControl
         Case True
            cbDigitalSharpeningState.CheckState = CheckState.Checked
         Case False
            cbDigitalSharpeningState.CheckState = CheckState.Unchecked
      End Select

   End Sub

   Private Sub btnReadVoltageMonitorCircuitValue_Click(sender As Object, e As EventArgs) Handles btnReadVoltageMonitorCircuitValue.Click

      lblErrorCode.Text = ""
      lblErrorString.Text = ""

      txtVoltageMonitorCircuitValue.Text = Camera.VoltageMonitorCircuit

      lblErrorCode.Text = Camera.errorCode
      lblErrorString.Text = Camera.ErrorString

   End Sub


   Private Sub cmdWriteDigPort0_1_Click(sender As Object, e As EventArgs) Handles cmdWriteDigPort0_1.Click, Button3.Click
      Dim ButtonClicked As Control
      Dim Data2Write As String

      ButtonClicked = DirectCast(sender, Control)
      ButtonClicked.Enabled = False

      Data2Write = ""
      If chkDigPort0_0_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_1_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_2_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_3_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_4_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_5_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_6_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chkDigPort0_7_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"

      lblDAQDeviceID_1.Text = DAQ_USB_6525_1_DeviceName

      Call WriteDigPort(DAQ_USB_6525_1_DeviceName, 0, 0, Data2Write)

      Try
         If TypeOf sender Is Control Then ButtonClicked.Enabled = True
      Catch ex As Exception
         'Dont care
      End Try


   End Sub

   Private Sub cmdReadDigPort_Click_1(sender As Object, e As EventArgs) Handles cmdReadDigPort1.Click, Button2.Click
      Dim ReturnedStates() As Boolean
      cmdReadDigPort1.Enabled = False
      ReturnedStates = ReadDigPort(lblDAQDeviceID.Text, 1, 0, 7)

      laPort1(0).Value = ReturnedStates(0)
      laPort1(1).Value = ReturnedStates(1)
      laPort1(2).Value = ReturnedStates(2)
      laPort1(3).Value = ReturnedStates(3)
      laPort1(4).Value = ReturnedStates(4)
      laPort1(5).Value = ReturnedStates(5)
      laPort1(6).Value = ReturnedStates(6)
      laPort1(7).Value = ReturnedStates(7)

      cmdReadDigPort1.Enabled = True

   End Sub

   Private Sub cmdReadDigPort1_1_Click(sender As Object, e As EventArgs) Handles cmdReadDigPort1_1.Click
      Dim ReturnedStates() As Boolean
      cmdReadDigPort1_1.Enabled = False
      ReturnedStates = ReadDigPort(DAQ_USB_6525_1_DeviceName, 1, 0, 7)

      laPort1_1(0).Value = ReturnedStates(0)
      laPort1_1(1).Value = ReturnedStates(1)
      laPort1_1(2).Value = ReturnedStates(2)
      laPort1_1(3).Value = ReturnedStates(3)
      laPort1_1(4).Value = ReturnedStates(4)
      laPort1_1(5).Value = ReturnedStates(5)
      laPort1_1(6).Value = ReturnedStates(6)
      laPort1_1(7).Value = ReturnedStates(7)

      cmdReadDigPort1_1.Enabled = True

   End Sub
   '2014-9-19 Potter Wang added Database check Z:\=\\mdefile1.magna.global\Tester
   Sub CompareDatabase()
      Dim oFSO As New FileSystemObject
      Dim oFileNet As File
      Dim oFileLocal As File
      Dim netPathHolly As String
      'Dim netPathZJG As String
      Dim localPathHolly As String
      'Dim localpathZJG As String
      Dim localPathCopy As String
      Dim timeStr As String
      Dim bUpadted As Boolean = False

      timeStr = DateTime.Now
      timeStr = Replace(Replace(timeStr.ToString, "/", "-"), ":", ",")
      netPathHolly = "Z:\FFT\Global Camera Product Info Database\"
      localPathHolly = "T:\FFT\Global Camera Product Info Database\Holly DB\"
      localPathCopy = "T:\FFT\Global Camera Product Info Database\Holly DB\Backup\"
      'netPathZJG = "T:\FFT\FCM\Database\OP90 Tester\"
      'localpathZJG = "C:\FFT\FCM FFT\Source\"
      Try
         'update Holly Database
         oFileNet = oFSO.GetFile(netPathHolly & "ProductInfo.mdb")
         oFileLocal = oFSO.GetFile(localPathHolly & "ProductInfo.mdb")
         If oFileNet.DateLastModified <> oFileLocal.DateLastModified Or oFileNet.Size <> oFileLocal.Size Then
            oFileNet.Copy(localPathHolly & "ProductInfo.mdb")
            oFileLocal.Copy(localPathCopy & "ProductInfo_Holly_" & timeStr & ".mdb")
            frmCompareDB.lblPrompt.Text = "Holly ProductInfo Database updated, Please call the engineer to check it."
            'Microsoft.VisualBasic.Interaction.MsgBox("Holly ProductInfo Database updated, Please call the engineer to check it.")
            bUpadted = True
         End If
         '2014-9-23 *START Potter
         'update Holly Database
         netPathHolly = "Z:\FFT\Universal Camera 3\"
         oFileNet = oFSO.GetFile(netPathHolly & "Universal_FFT_3_Master_Test_Sequence.mdb")
         oFileLocal = oFSO.GetFile(localPathHolly & "Universal_FFT_3_Master_Test_Sequence.mdb")
         If oFileNet.DateLastModified <> oFileLocal.DateLastModified Or oFileNet.Size <> oFileLocal.Size Then
            oFileNet.Copy(localPathHolly & "Universal_FFT_3_Master_Test_Sequence.mdb")
            oFileLocal.Copy(localPathCopy & "Universal_FFT_3_Master_Test_Sequence_Holly_" & timeStr & ".mdb")
            frmCompareDB.lblPrompt.Text = "Holly Universal_FFT_3_Master_Test_Sequence Database updated, Please call the engineer to check it."
            'Microsoft.VisualBasic.Interaction.MsgBox("Holly Universal_FFT_3_Master_Test_Sequence Database updated, Please call the engineer to check it.")
            bUpadted = True
         End If
         '2014-9-23 *END
         If bUpadted = True Then
            frmDBPassword.ShowDialog()
            While My.Settings.DBPassword <> frmDBPassword.tbDBPassword.Text
               System.Windows.Forms.Application.DoEvents()
               Threading.Thread.Sleep(50)
               frmDBPassword.ShowDialog()
            End While
         End If

      Catch ex As Exception
         Call WritetoErrorLog(ex, True, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, True, "ERROR COMPARE DATABASE")
         End
      End Try

      If bUpadted = True Then
         End
      End If

   End Sub
   '2017-3-3 Potter added
   Private Sub txtCarrier_KeyDown(sender As Object, e As KeyEventArgs) Handles txtCarrier.KeyDown
      Static lastKeyValue As Integer = 0
      If lastKeyValue = 13 And e.KeyValue = 40 Then
         If TestMode = " " Then
            If ProductInfo.TraceabilityEnable = True Then
               If txtCarrier.Text.Length <> 10 Or txtCarrier.Text.ToUpper.StartsWith("CARRIER") = False Then
                  'MessageBox.Show("MUST SCAN CORRECT CARRIER BOX FIRST!", "ATTENTION", MessageBoxButtons.OK, MessageBoxIcon.Stop)
                  lblCarrierPrompt.Text = "Incorrect Carrier"
                  txtCarrier.Enabled = True
                  txtCarrier.SelectAll()
                  txtCarrier.Focus()
               Else
                  lblCarrierPrompt.Text = ""
                  CarrierName = txtCarrier.Text

                  '2017-6-27 Potter write FFTReady=1 
                  Call WriteDigPort(DAQ_6514_DeviceName, 4, 3, "1") 'FFTReady=1

                  txtCarrier.Enabled = False
               End If
            End If
         Else
            lblCarrierPrompt.Text = ""
         End If
      End If
      lastKeyValue = e.KeyValue

   End Sub


   ''2017-4-23 potter added
   'Private Sub tmrTransfer_Tick(sender As Object, e As EventArgs) Handles tmrTransfer.Tick
   '   Try
   '      Dim strPrompt As String = ""
   '      Dim strPassword As String = "123456"
   '      strPrompt = "Part SN:" + TransferBox.FFTSN
   '      Select Case TransferBox.Status
   '         Case 1 'Light Pass Bin
   '            tmrTransfer.Enabled = True
   '            lblMsg.Visible = True
   '            lblMsg.BackColor = Color.LimeGreen
   '            lblMsg.ForeColor = Color.Black
   '            lblMsg.Text = "Pick the Part from Transfer Box"

   '            'Turn On The Pass Bin Light On The Packout Cart
   '            WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Pass_Bin_Light", "1")
   '            TransferBox.Status = 2
   '         Case 2 'Waiting for pick up the part from Transfer Box
   '            tmrTransfer.Enabled = True
   '            'Wait For Operator To Break The Beam On The Light Curtain
   '            If ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Fail_Bin_Beam_Broken") Or ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Reject_Bin_Beam_Broken") Or ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Pass_Bin_Beam_Broken") Then
   '               'If Operator Put The Part On The Fail Side Then Sound the alarm
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Alarm", "1")
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Red_Light", "1")
   '               lblMsg.Visible = True
   '               lblMsg.BackColor = Color.Yellow
   '               lblMsg.ForeColor = Color.Black
   '               lblMsg.Text = "PART IS IN THE WRONG BIN"
   '            End If
   '            If ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Transfer_Box_Switch") Then
   '               TransferBox.Status = 3
   '            End If

   '         Case 3
   '            tmrTransfer.Enabled = True
   '            lblMsg.Visible = True
   '            lblMsg.BackColor = Color.LimeGreen
   '            lblMsg.ForeColor = Color.Black
   '            lblMsg.Text = "Place the Transfer Part In PASS Bin"
   '            TransferBox.Status = 4
   '         Case 4 ''Waiting for put the part in Pass Bin

   '            If ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Fail_Bin_Beam_Broken") Or ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Reject_Bin_Beam_Broken") Then
   '               'If Operator Put The Part On The Fail Side Then Sound the alarm
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Alarm", "1")
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Red_Light", "1")
   '               lblMsg.Visible = True
   '               lblMsg.BackColor = Color.Yellow
   '               lblMsg.ForeColor = Color.Black
   '               lblMsg.Text = "PART IS IN THE WRONG BIN"
   '            End If
   '            If ReadDigitalInput(DAQ_USB_6525_1_DeviceName, "Pass_Bin_Beam_Broken") Then

   '               lblMsg.Visible = False
   '               lblMsg.BackColor = Color.WhiteSmoke
   '               lblMsg.ForeColor = Color.Black
   '               lblMsg.Text = ""

   '               'When Reaching Here Correct Bin Was Activated
   '               'Turn Off All Outputs
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Pass_Bin_Light", "0")
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Fail_Bin_Light", "0")
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Alarm", "0")
   '               WriteDigitalOutput(DAQ_USB_6525_1_DeviceName, "Red_Light", "0")

   '               TransferBox.Status = 0
   '               TransferBox.FFTSN = ""
   '               tmrTransfer.Enabled = False
   '            End If
   '         Case Else
   '            tmrTransfer.Enabled = True
   '      End Select
   '   Catch ex As Exception
   '   Finally
   '      tmrTransfer.Enabled = True
   '   End Try
   'End Sub

   Private Sub cmd6514WritePort_Click(sender As Object, e As EventArgs) Handles cmd6514WritePort.Click
      Dim ButtonClicked As Control
      Dim Data2Write As String

      ButtonClicked = DirectCast(sender, Control)
      ButtonClicked.Enabled = False

      Data2Write = ""
      If chk6514Port4_0.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_1.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_2.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_3.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_4.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_5.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_6.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"
      If chk6514Port4_7.Checked = True Then Data2Write = Data2Write & "1" Else Data2Write = Data2Write & "0"

      lbl6514ID.Text = DAQ_USB_6525_DeviceName

      Call WriteDigPort(DAQ_6514_DeviceName, 4, 0, Data2Write)

      Try
         If TypeOf sender Is Control Then ButtonClicked.Enabled = True
      Catch ex As Exception
         'Dont care
      End Try
   End Sub

   Private Sub cmd6514ReadPort0_Click(sender As Object, e As EventArgs) Handles cmd6514ReadPort0.Click
      Dim ReturnedStates() As Boolean
      cmd6514ReadPort0.Enabled = False
      ReturnedStates = ReadDigPort(DAQ_6514_DeviceName, 0, 0, 7)

      la6514Port0(0).Value = ReturnedStates(0)
      la6514Port0(1).Value = ReturnedStates(1)
      la6514Port0(2).Value = ReturnedStates(2)
      la6514Port0(3).Value = ReturnedStates(3)
      la6514Port0(4).Value = ReturnedStates(4)
      la6514Port0(5).Value = ReturnedStates(5)
      la6514Port0(6).Value = ReturnedStates(6)
      la6514Port0(7).Value = ReturnedStates(7)

      cmd6514ReadPort0.Enabled = True
   End Sub

   '2017-6-27 potter added
   Private Sub tmrTestingDUT_Tick(sender As Object, e As EventArgs) Handles tmrTestingDUT.Tick
      tmrTestingDUT.Enabled = False

      If TestMode <> "T" Then
         If TestingDUTTesting = True Then
            Start()
         End If
      End If

      tmrTestingDUT.Enabled = True
   End Sub

   Private Sub btnDUTPowerOverCameralinkBackChannel_ON_Click(sender As Object, e As EventArgs) Handles btnDUTPowerOverCameralinkBackChannel_ON.Click
      lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.DutPowerOverCameraLink(("ON"))

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.errorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

   Private Sub btnDUTPowerOverCameralinkBackChannel_OFF_Click(sender As Object, e As EventArgs) Handles btnDUTPowerOverCameralinkBackChannel_OFF.Click
      lblErrorCode.Text = ""
      Me.lblErrorString.Text = ""

      Camera.DutPowerOverCameraLink(("OFF"))

      'Display Errors if any
      Me.lblErrorCode.Text = CStr(Camera.errorCode)
      Me.lblErrorString.Text = Camera.ErrorString
   End Sub

    Public Sub New()

        ' This call is required by the designer.
        InitializeComponent()

        ' Add any initialization after the InitializeComponent() call.

        '2018-5-4 potter added
        ' Add any initialization after the InitializeComponent() call.
        '8/15/16 jgk added.  Added so that the Matlab code in the Intrinsic Cal dlls run BEFORE the Labview MTF code runs,
        'which allows Matlab code to function properly
        'Added the config and bmp files to the resources, so that they will by retained in the MagnaCameraTest project and
        'useable no matter what the Solution and Project folder are named.  Note this is a config file for a given test system
        'and an image from it.  In this case it is a Ford Zurich Lite which is way the Len Type is 185H_LVDS
      '2018-5-4 potter omited
      Dim ICal As New IntrinsicCal.clsICal '9/7/16 jgk

      ICal.RunCalibration(System.IO.Path.GetFullPath(Application.StartupPath & "\..\..\Resources\") & "SetupImageForIntrinsicCalibration.BMP", _
      System.IO.Path.GetFullPath(Application.StartupPath & "\..\..\Resources\") & "Setup_OCamCalib3D_config.txt", _
      "185H_LVDS", 0, 0) '8/12/16 8/16/16 jgk added

      If ICal IsNot Nothing Then ICal = Nothing '9/7/16 jgk

    End Sub
   ''2018-5-4 potter added
   'Private Sub btnRunInstrinsicTest_Click(sender As Object, e As EventArgs) Handles btnRunInstrinsicTest.Click

   '    RunInstrinsicCalibration()

   'End Sub
   '2018-5-4 potter added
    Function RunInstrinsicCalibration() As Boolean


        '8/3/15 jgk changed to throw exception ...was Return False.  Note, the Catch code will return false
        If Me.clsVPRO.LiveCameraCheckBeforeRunningIntrinsicCalibration = False Then
            Throw New Exception("Failed the Live Camera Image Check in the RunIntrinsicCalibration Routine in frmMain")
        End If

        Dim DosWindowText As String = ""
        Try

            'Determine Which Config File To Load
            If ProductInfo.IntrinsicConfigFileName <> "na" Then '7/14/16 7/29/16 jgk added using new ProductInfo.IntrinsicConfigFileName
                IntrinsicConfigFileName = ProductInfo.IntrinsicConfigFileName
            Else
                Select Case ProductInfo.OEM.ToUpper
                    Case "FORD"
                        IntrinsicConfigFileName = "Ford_OCamCalib3D_config.txt"

                    Case "CHRYSLER"
                        IntrinsicConfigFileName = "Chrysler_OCamCalib3D_config.txt"

                    Case Else
                        Throw New Exception("Neither FORD or CHRYSLER OEM was selected to define the IntrinsicConfigFileName in the RunIntrinsicCalibration Routine in frmMain") '8/3/15 jgk was Return False
                End Select
            End If


            '8/3/15 added file check
         If System.IO.File.Exists(IntrinsicCalibrationSupportFolderPath & "ImageForIntrinsicCalibration.BMP") = False Then
            Throw New Exception(IntrinsicCalibrationSupportFolderPath & "ImageForIntrinsicCalibration.BMP" & " was not found previous to use in the RunIntrinsicCalibration Routine in frmMain")
         End If

            'Pass it any arguments needed
            'BS 6-12-15 updated arguments string for new exe v2p1
            'jgk 6/15/15 - defined arguments
            '1st - Image to Process, 
            '2nd - Product type specific Config File (initially: Ford and Chrysler); based on Lens differences (FOV, etc), possibly nest differnces, or other differences effect image,
            '3rd - Lens Type (from Product Info)
            '4th and 5th - X and Y Nest offset (referred to as Round Table Offsets by Sailauf  (NOTE THESE A NEW TO v2p1 revsion), should be in pixels but not sure as of 6-16-15, SO MUST LEAVE AS 0's FOR NOW
            '6th Z Nest offset in millimeters 6-18-15 added getting it from db table
            '7th, 8th, 9th and 10th - X and Y MacBeth Chart Locating Dots (Big Black Dots to left and right of center focus target), Left-X, Left-Y, Right-X, Right-Y, respectively
            'Note if populated with 9999, the Intrinsic Cal routine will use it old method for determining center location
            '11th is a switch, 0 not to sure all image screens the the Intrinsic Cal can display and 1 to display them


            '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            '7/24/16 7/26/16 jgk had to change to handle adding _Univ7 Tester specific suffix due to image difference in Univ7
            'Jagmal sent the following:
            '  The root cause is that the light settings are different for Univ-5 and Univ-7. In the source code I am doing template matching for finding the center dots and it seems to not working for Uni-7 which worked for Univ-5 and GL-1.
            '1.	Please copy the attached file in the directory where the intrinsic executable is.
            '2.	And when you call the routine please pass the as lens_identifier = 185H_LVDS_Univ7 instead of 185H_LVDS.
            Dim LensTypeToPass As String = ProductInfo.LensType
            Select Case Tester
                Case "Universal 7 FFT"
                    LensTypeToPass = LensTypeToPass & "_Univ7"
                Case Else
            End Select

            Dim ICal As New IntrinsicCal.clsICal '9/7/16 jgk
         '2018-5-5 potter omited for pass this calibration '2018-5-10 potter added again
         '8/12/16 jgk change to this.  BUT THIS FUNCTION (RunInstrinsicCalibration) IS NOT NEEDED, BECAUSE THIS IS BEING SPLIT UP
         'INTO A INITIATE INTRINSIC CALIBRATION AND EVALUATE INTRINSIC CALIBRATION TO SAVE TIME!
         ICal.RunCalibration(IntrinsicCalibrationSupportFolderPath & "ImageForIntrinsicCalibration.BMP", _
           IntrinsicCalibrationSupportFolderPath & IntrinsicConfigFileName, _
           LensTypeToPass, _
           Trim(CDbl(Nest_Pallet_Offset(NestOrPalletNumberInUse).Z_Offset)), _
           0)

            If ICal IsNot Nothing Then ICal = Nothing '9/7/16 jgk


            Dim Result As Boolean = ExtractIntrinsicParameterDataFromTextFile()

            '10/7/15 jgk moved here and in the case else to save the data even if we pass or fail
            'Store Value For Logging Purposes
            IntrinsicParametersToWrite.ConstanStartSequence = Camera.Constant_Start_Sequence_Default_Value
            IntrinsicParametersToWrite.MagnaSerialNumber = DutSerialNumbers.DutMagnaSerialNumber
            IntrinsicParametersToWrite.AEISerialNumber = DutSerialNumbers.DutAEISerialNumber
            IntrinsicParametersToWrite.FinalAssemblyPartNumber = ProductInfo.Customer_PN

            Select Case Result
                Case True
                    Select Case IntrinsicParametersToWrite.success
                        Case True
                            'Show Dos Window Text NOTE Only For Debug Comment Out for normal operation
                            'MessageBox.Show("Intrinsic Calibration Results = " & DosWindowText)

                            '10/7/15 jgk moved here and in the case else to save the data even if we pass or fail
                            'note removed from end of WriteIntrinsicParameterDataToEEprom
                            IntrinsicParameterDataWriter.Add_G_IntrinsicParamsValuesWritten()

                            Return True
                        Case Else
                            ' MessageBox.Show("Intrinsic Calibration Results = " & DosWindowText)

                            '10/7/15 jgk moved here and in the case True to save the data even if we pass or fail
                            'note removed from end of WriteIntrinsicParameterDataToEEprom
                            IntrinsicParameterDataWriter.Add_G_IntrinsicParamsValuesWritten()

                            Throw New Exception("IntrinsicParametersToWrite.success returned False, in the RunIntrinsicCalibration Routine in frmMain") '8/3/15 jgk was Return False
                    End Select
                Case False
                    Throw New Exception("ExtractIntrinsicParameterDataFromTextFile returned False, in the RunIntrinsicCalibration Routine in frmMain") '8/3/15 jgk was Return False
            End Select

        Catch ex As Exception
            WritetoErrorLog(ex, False, True, "Error Occured In: " & New StackTrace().GetFrame(0).GetMethod.ToString, False, "")
            Return False
        End Try

        Return False


    End Function

   
End Class
