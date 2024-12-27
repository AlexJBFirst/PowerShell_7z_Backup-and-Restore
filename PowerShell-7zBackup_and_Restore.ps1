#PARAMS########################################################################################
Param(
	[Parameter(ValueFromPipeline, HelpMessage = "For a simple backup job, enter 'SimpleBackup'`nFor a backup job with time filtering, enter 'TimeFilteredBackup'")]
	[ValidateSet('SimpleBackup', 'TimeFilteredBackup', 'Copy', 'Sync')]
	[String]$AutomationType,

	[Parameter(ValueFromPipeline, HelpMessage = "If you have already opened this script in the GUI, you can use the selected saved profile as the main profile for AutomationType tasks")]
	[ValidateNotNull()]
	[string[]]$ProfileName
)

Process {
	$Profiles_from_Pipeline += $ProfileName
}

End {
	if ($AutomationType -and -not $ProfileName) {
		Write-Output "Parameter 'ProfileName' is not specified."
	
		exit
	}

	if ($ProfileName -and -not $AutomationType) {
		Write-Output "Parameter 'AutomationType' is not specified."
	
		exit
	}

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	#PARAMS########################################################################################END
	#IMPORTANT_VARIABLES###########################################################################
	$ScriptVersion = [System.Version]::Parse("2.0.2")
	$Path_to_Script = $MyInvocation.MyCommand.Path
	$Running_Folder = Split-Path -Parent $Path_to_Script
	$ScriptPath = $MyInvocation.MyCommand.Path
	#IMPORTANT_VARIABLES###########################################################################END
	#FUNCTION_SCRIPT_BODY##########################################################################
	function settings {
		param (
			[String]$ProfileName,
			[String]$BackupDirectory,
			[String]$Executable_7z,
			[String]$SecondBackupDirectory,
			[String]$BackupName,
			[String]$Source,
			[String]$RestoreDirectory,
			[decimal]$RestorePoints,
			[decimal]$BackupDayFilter,
			[boolean]$BackupCheckboxStatus,
			[boolean]$RestoreCheckboxStatus,
			[boolean]$CopyCheckboxStatus
		)

		$Settings = [PSCustomObject]@{
			ProfileName           = ([String]"$ProfileName");
			BackupDirectory       = ([string]"$BackupDirectory");
			Executable_7z         = ([string]"$Executable_7z");
			SecondBackupDirectory = ([string]"$SecondBackupDirectory");
			BackupName            = ([string]"$BackupName");
			Source                = ([string]"$Source");
			RestoreDirectory      = ([string]"$RestoreDirectory");
			RestorePoints         = ([decimal]$RestorePoints);
			BackupDayFilter       = ([decimal]$BackupDayFilter);
			BackupCheckboxStatus  = ([boolean]$BackupCheckboxStatus);
			RestoreCheckboxStatus = ([boolean]$RestoreCheckboxStatus);
			CopyCheckboxStatus    = ([boolean]$CopyCheckboxStatus);
		}
	
		return $Settings
	}

	function ProfileImporter {
		if (Test-Path "${Running_Folder}\ProfileList.xml") {
			$ImportedProfileXML = Import-Clixml -Path "${Running_Folder}\ProfileList.xml"
			$ProfileXML = [System.Collections.ArrayList]::new()
		
			foreach ($profile in $ImportedProfileXML) {
				$SettingParameters = @{
					ProfileName           = "$($profile.ProfileName)"
					BackupDirectory       = "$($profile.BackupDirectory)"
					Executable_7z         = "$($profile.Executable_7z)"
					SecondBackupDirectory = "$($profile.SecondBackupDirectory)"
					BackupName            = "$($profile.BackupName)"
					Source                = "$($profile.Source)"
					RestoreDirectory      = "$($profile.RestoreDirectory)"
					RestorePoints         = $($profile.RestorePoints)
					BackupDayFilter       = $($profile.BackupDayFilter)
					BackupCheckboxStatus  = $($profile.BackupCheckboxStatus)
					RestoreCheckboxStatus = $($profile.RestoreCheckboxStatus)
					CopyCheckboxStatus    = $($profile.CopyCheckboxStatus)
				}
				[void]$ProfileXML.Add($(settings @SettingParameters))
			}
		}

		return ,$ProfileXML
	}

	function Profile7zExecCheck {
		param (
			$ProfileXmlObject
		)

		$Profiles7z = $ProfileXmlObject | Where-Object { -not ([string]::IsNullOrWhiteSpace($_.Executable_7z)) }
	
		foreach ($profile in $Profiles7z) {
			if (-not (Test-Path $profile.Executable_7z) -or -not $profile.Executable_7z.Contains('7z.exe')) {
				$FailedExecutablePath += , $profile.ProfileName
			}
		}
	
		return $FailedExecutablePath
	}

	function FormsVariables {
		$FormsVariables = @{
			FormsText          = "PowerShell 7z Backup and Restore v${ScriptVersion}"
			FormsFont          = New-Object System.Drawing.Font("Times New Roman", 18, [System.Drawing.FontStyle]::Bold)
			FormsBackColor     = 'Black'
			FormsForeColor     = 'White'
			FormsBorderStyle   = 'FixedDialog'
			FormsStartPosition = 'CenterScreen'
			FormsTextAlign     = 'MiddleCenter'
		}
	
		return $FormsVariables
	}

	function ListFiller {
		param (
			$ProfileXmlObject,
			$Menu,
			$RestoreMenuListObjects
		)

		switch ($Menu) {
			'ProfileMenu' {
				if ($ProfileXmlObject.count -eq 0) {
					return
				}
				if ($ProfileXmlObject.Count -eq 1) {
					[void]$ProfileMenu_ProfileList_LISTBOX.Items.Clear()
					[void]$ProfileMenu_ProfileList_LISTBOX.Items.Add("$($ProfileXmlObject.ProfileName)")
				}
				else {
					[void]$ProfileMenu_ProfileList_LISTBOX.Items.Clear()
					[void]$ProfileMenu_ProfileList_LISTBOX.Items.AddRange(@(
							$ProfileXmlObject.ProfileName
						))
				}
			}
			'BackupMenu' {
				if ($ProfileXmlObject.count -eq 0) {
					return
				}
				if ($ProfileXmlObject.Count -eq 1) {
					[void]$BackupMenu_ProfileList_LISTBOX.Items.Clear()
					[void]$BackupMenu_ProfileList_LISTBOX.Items.Add("$($ProfileXmlObject.ProfileName)")
				}
				else {
					[void]$BackupMenu_ProfileList_LISTBOX.Items.Clear()
					[void]$BackupMenu_ProfileList_LISTBOX.Items.AddRange(@(
							$ProfileXmlObject.ProfileName
						))
				}
			}
			'RestoreMenu' {
				if ($ProfileXmlObject.count -eq 0) {
					return
				}
				if ($ProfileXmlObject.Count -eq 1) {
					[void]$RestoreMenu_ProfileList_LISTBOX.Items.Add("$($ProfileXmlObject.ProfileName)")
				}
				else {
					[void]$RestoreMenu_ProfileList_LISTBOX.Items.AddRange(@(
							$ProfileXmlObject.ProfileName
						))
				}
			}
			'RestoreMenuList' {
				if ($RestoreMenuListObjects.count -eq 0) {
					return
				}
				if ($RestoreMenuListObjects.Count -eq 1) {
					[void]$RestoreMenuList_List_LISTBOX.Items.Add("$RestoreMenuListObjects")
				}
				else {
					[void]$RestoreMenuList_List_LISTBOX.Items.AddRange($RestoreMenuListObjects)
				}
			}
		}
	}

	function CMDAutomationTypeChecker {
		param (
			[string]$AutomationType,
			[string]$Automation_ProfileName,
			$ProfileObject,
			$ProfileXmlObject
		)

		if (-not $ProfileObject) {
			Write-Output "There is no profile named $Automation_ProfileName in the profile list, please enter the correct profile name."
			Write-Output "Here are the names of the profiles that exist in your profile list"
			Write-Output "#####"
			$ProfileXmlObject.ProfileName
			Write-Output "#####"
			Throw "$Automation_ProfileName - exited"
		}
		switch ($AutomationType) {
			'SimpleBackup' {
				if ($ProfileObject.BackupCheckboxStatus -eq $false) {
					Write-Output "Profile - $Automation_ProfileName, does not support `'AutomationType`' - $AutomationType`nTo enable this type of task, switch to graphical mode and enable this feature in the script profile menu"
					Throw "$Automation_ProfileName - exited"
				}
			}
			'TimeFilteredBackup' {
				if ($ProfileObject.BackupCheckboxStatus -eq $false) {
					Write-Output "Profile - $Automation_ProfileName, does not support `'AutomationType`' - $AutomationType`nTo enable this type of task, switch to graphical mode and enable this feature in the script profile menu"
					Throw "$Automation_ProfileName - exited"
				}
			}
			'Copy' {
				if ($ProfileObject.CopyCheckboxStatus -eq $false) {
					Write-Output "Profile - $Automation_ProfileName, does not support `'AutomationType`' - $AutomationType`nTo enable this type of task, switch to graphical mode and enable this feature in the script profile menu"
					Throw "$Automation_ProfileName - exited"
				}
			}
			'Sync' {
				if ($ProfileObject.CopyCheckboxStatus -eq $false) {
					Write-Output "Profile - $Automation_ProfileName, does not support `'AutomationType`' - $AutomationType`nTo enable this type of task, switch to graphical mode and enable this feature in the script profile menu"
					Throw "$Automation_ProfileName - exited"
				}
				elseif (($ProfileObject.CopyCheckboxStatus -eq $true) -and ($ProfileObject.Source[-1] -ne '\')) {
					Write-Output "Profile - $Automation_ProfileName, does not support `'AutomationType`' - $AutomationType`nThe synchronization task is available only for directories."
					Throw "$Automation_ProfileName - exited"
				}
			}
		}
	}

	function CMDAutomationTypeExecutor {
		param (
			[string]$AutomationType,
			$ProfileObject
		)
	
		switch ($AutomationType) {
			'SimpleBackup' {
				$JobParameters = @{
					Executable_7z         = $ProfileObject.Executable_7z
					BackupDirectory       = $ProfileObject.BackupDirectory
					SecondBackupDirectory = $ProfileObject.SecondBackupDirectory
					BackupName            = $ProfileObject.BackupName
					Source                = $ProfileObject.Source
					RestorePoints         = $ProfileObject.RestorePoints
					MessageSingleDir      = $(TextFiller -JobStartingMessage ' Archiving JOB Started ' -JobEndingMessage ' Archiving JOB Finished ')
					MessageFirstDir       = $(TextFiller -JobStartingMessage ' Archiving JOB to the First Directory Started ' -JobEndingMessage ' First Archiving JOB Finished ')
					MessageSecondDir      = $(TextFiller -JobStartingMessage ' Archiving JOB to the Second Directory Started ' -JobEndingMessage ' Second Archiving JOB Finished ')
				}
				SimpleBackup_Job @JobParameters
			}
			'TimeFilteredBackup' {
				$JobParameters = @{
					Executable_7z         = $ProfileObject.Executable_7z
					BackupDirectory       = $ProfileObject.BackupDirectory
					SecondBackupDirectory = $ProfileObject.SecondBackupDirectory
					BackupName            = $ProfileObject.BackupName
					Source                = $ProfileObject.Source
					RestorePoints         = $ProfileObject.RestorePoints
					BackupDayFilter       = $ProfileObject.BackupDayFilter
					MessageSingleDir      = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB Started ' -JobEndingMessage ' Time Filtered Archiving JOB Finished ')
					MessageFirstDir       = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB to the First Directory Started ' -JobEndingMessage ' First Time Filtered Archiving JOB Finished ')
					MessageSecondDir      = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB to the Second Directory Started ' -JobEndingMessage ' Second Time Filtered Archiving JOB Finished ')
				}
				TimeFilteredBackup_Job @JobParameters
			}
			'Copy' {
				$JobParameters = @{
					BackupDirectory       = $ProfileObject.BackupDirectory
					SecondBackupDirectory = $ProfileObject.SecondBackupDirectory
					Source                = $ProfileObject.Source
					MessageSingleDir      = $(TextFiller -JobStartingMessage ' Copy JOB Started ' -JobEndingMessage ' Copy JOB Finished ')
					MessageFirstDir       = $(TextFiller -JobStartingMessage ' Copy JOB to the First Folder Started ' -JobEndingMessage ' First Copy JOB Finished ')
					MessageSecondDir      = $(TextFiller -JobStartingMessage ' Copy JOB to the Second Folder Started ' -JobEndingMessage ' Second Copy JOB Finished ')
				}
				CopyFile_Job @JobParameters
			}
			'Sync' {
				$JobParameters = @{
					BackupDirectory       = $ProfileObject.BackupDirectory
					SecondBackupDirectory = $ProfileObject.SecondBackupDirectory
					Source                = $ProfileObject.Source
					MessageSingleDir      = $(TextFiller -JobStartingMessage ' Sync Copy JOB Started ' -JobEndingMessage ' Sync JOB Finished ')
					MessageFirstDir       = $(TextFiller -JobStartingMessage ' Sync JOB to the First Folder Started ' -JobEndingMessage ' First Sync JOB Finished ')
					MessageSecondDir      = $(TextFiller -JobStartingMessage ' Sync JOB to the Second Folder Started ' -JobEndingMessage ' Second Sync JOB Finished ')
				}
				Sync_Job @JobParameters
			}
		}
	}

	function TextFiller {
		param (
			[string]$JobStartingMessage,
			[string]$JobEndingMessage,
			[string]$SingleMessage
		)

		if ($SingleMessage) {
			$SingleMessageText = '#' * 5 + $SingleMessage + '#' * 5 
		}
		if ($JobStartingMessage) {
			$body_start = '#' * [math]::Floor((79 - $JobStartingMessage.Length) / 2) + $JobStartingMessage + '#' * [math]::Ceiling((79 - $JobStartingMessage.Length) / 2)
			$StartMessage = "$('#'*79)`n$body_start`n$('#'*79)`n"
		}
		if ($JobEndingMessage) {
			$body_end = '#' * [math]::Floor((79 - $JobEndingMessage.Length) / 2) + $JobEndingMessage + '#' * [math]::Ceiling((79 - $JobEndingMessage.Length) / 2)
			$EndMessage = "`n$('#'*79)`n$body_end`n$('#'*79)"
		}
		$Message = [PSCustomObject]@{
			StartMessage  = $StartMessage
			EndMessage    = $EndMessage
			SingleMessage = $SingleMessageText
		}
	
		return $Message
	}
	#FUNCTION_SCRIPT_BODY##########################################################################END
	#FUNCTIONS_ADVANCED_MENU#######################################################################
	function ClearProfile {
		$AdvancedMenu_ProfileName_TEXTBOX.Text = $null
		$AdvancedMenu_BackupName_TEXTBOX.Text = $null
		$AdvancedMenu_BackupDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_RestorePoints_TEXTBOX.Text = $null
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = $null
		$AdvancedMenu_Source_TEXTBOX.Text = $null
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_7zipExecutable_TEXTBOX.Text = $null
		$AdvancedMenu_Backup_CHECKBOX.Checked = $false
		$AdvancedMenu_Restore_CHECKBOX.Checked = $false
		$AdvancedMenu_Copy_CHECKBOX.Checked = $false
	}

	function EditProfile {
		param (
			[string]$ChosenProfile,
			$ProfileXmlObject
		)

		$ProfileMenu_LABEL.Tag += 1
		$ProfileIndex = $ProfileXmlObject.IndexOf($($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$ChosenProfile" }))
		$ProfileXmlObject[$ProfileIndex].ProfileName = "$($AdvancedMenu_ProfileName_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].BackupDirectory = "$($AdvancedMenu_BackupDirectory_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].Executable_7z = "$($AdvancedMenu_7zipExecutable_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].SecondBackupDirectory = "$($AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].BackupName = "$($AdvancedMenu_BackupName_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].Source = "$($AdvancedMenu_Source_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].RestoreDirectory = "$($AdvancedMenu_RestoreDirectory_TEXTBOX.Text)"
		$ProfileXmlObject[$ProfileIndex].RestorePoints = [decimal]$($AdvancedMenu_RestorePoints_TEXTBOX.Text)
		$ProfileXmlObject[$ProfileIndex].BackupDayFilter = [decimal]$($AdvancedMenu_BackupDayFilter_TEXTBOX.Text)
		$ProfileXmlObject[$ProfileIndex].BackupCheckboxStatus = $($AdvancedMenu_Backup_CHECKBOX.Checked)
		$ProfileXmlObject[$ProfileIndex].RestoreCheckboxStatus = $($AdvancedMenu_Restore_CHECKBOX.Checked)
		$ProfileXmlObject[$ProfileIndex].CopyCheckboxStatus = $($AdvancedMenu_Copy_CHECKBOX.Checked)
		ListFiller -ProfileXmlObject $ProfileXmlObject -Menu 'ProfileMenu'
		ProfileMenuButtonsActive
		ErrorForm -ErrorLabelText "Profile: `"$($AdvancedMenu_ProfileName_TEXTBOX.Text)`" - changed."

		return ,$ProfileXmlObject
	}

	function AddProfile {
		param (
			$ProfileXmlObject
		)

		$ProfileMenu_LABEL.Tag += 1
		$SettingParameters = @{
			ProfileName           = "$($AdvancedMenu_ProfileName_TEXTBOX.Text)"
			BackupDirectory       = "$($AdvancedMenu_BackupDirectory_TEXTBOX.Text)"
			Executable_7z         = "$($AdvancedMenu_7zipExecutable_TEXTBOX.Text)"
			SecondBackupDirectory = "$($AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text)"
			BackupName            = "$($AdvancedMenu_BackupName_TEXTBOX.Text)"
			Source                = "$($AdvancedMenu_Source_TEXTBOX.Text)"
			RestoreDirectory      = "$($AdvancedMenu_RestoreDirectory_TEXTBOX.Text)"
			RestorePoints         = $($AdvancedMenu_RestorePoints_TEXTBOX.Text)
			BackupDayFilter       = $($AdvancedMenu_BackupDayFilter_TEXTBOX.Text)
			BackupCheckboxStatus  = $($AdvancedMenu_Backup_CHECKBOX.Checked)
			RestoreCheckboxStatus = $($AdvancedMenu_Restore_CHECKBOX.Checked)
			CopyCheckboxStatus    = $($AdvancedMenu_Copy_CHECKBOX.Checked)
		}
		[void]$ProfileXML.Add($(settings @SettingParameters))
		ListFiller -ProfileXmlObject $ProfileXML -Menu 'ProfileMenu'
		ProfileMenuButtonsActive
		ErrorForm -ErrorLabelText "Profile: `"$($AdvancedMenu_ProfileName_TEXTBOX.Text)`" - created."

		return ,$ProfileXML
	}

	function FieldValidation {
		switch ($true) {
		([string]::IsNullOrWhiteSpace($AdvancedMenu_ProfileName_TEXTBOX.Text)) {
				ErrorForm -ErrorLabelText "An error occurred, the 'ProfileName' text field is empty.`nPlease enter a profile name in the appropriate text box" -Height 140 -Width 580
				return "error"
			}
		(-not ($AdvancedMenu_Backup_CHECKBOX.Checked) -and -not ($AdvancedMenu_Restore_CHECKBOX.Checked) -and -not ($AdvancedMenu_Copy_CHECKBOX.Checked)) {
				ErrorForm -ErrorLabelText "Click on the appropriate checkbox to select the functionality you will use."
				return "error"
			}
		($AdvancedMenu_Backup_CHECKBOX.Checked)	{
				if ([string]::IsNullOrWhiteSpace($AdvancedMenu_BackupName_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'BackupName' text field is empty.`nPlease enter a backup name in the appropriate text box" -Height 140 -Width 580
					return "error"
				}
				elseif ([string]::IsNullOrWhiteSpace($AdvancedMenu_BackupDirectory_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'BackupDirectory' text field is empty.`nPlease select a directory to back up to" -Height 140 -Width 620
					return "error"
				}
				elseif ([string]::IsNullOrWhiteSpace($AdvancedMenu_Source_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'SourceDirectory' text field is empty.`nPlease select a source directory" -Height 140 -Width 620
					return "error"
				}
				elseif (-not (Test-Path -Path "$($AdvancedMenu_7zipExecutable_TEXTBOX.Text)")) {
					ErrorForm -ErrorLabelText "An error has occurred.`nThe path to the 7zip executable file is not valid.`nIf you do not have the 7zip program installed, please install it from the official website:`nhttps://www.7-zip.org/`nOr enter the path to the 7z.exe executable file in the appropriate text box." -Height 200 -Width 580
					return "error"
				}
			}
		($AdvancedMenu_Restore_CHECKBOX.Checked) {
				if ([string]::IsNullOrWhiteSpace($AdvancedMenu_BackupDirectory_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'BackupDirectory' text field is empty.`nPlease select a directory to back up to" -Height 140 -Width 580
					return "error"
				}
				elseif ([string]::IsNullOrWhiteSpace($AdvancedMenu_RestoreDirectory_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'RestoreDirectory' text field is empty.`nPlease select a directory to restore" -Height 140 -Width 580
					return "error"
				}
				elseif (-not (Test-Path -Path "$($AdvancedMenu_7zipExecutable_TEXTBOX.Text)")) {
					ErrorForm -ErrorLabelText "An error has occurred.`nThe path to the 7zip executable file is not valid.`nIf you do not have the 7zip program installed, please install it from the official website:`nhttps://www.7-zip.org/`nOr enter the path to the 7z.exe executable file in the appropriate text box." -Height 200 -Width 580
					return "error"
				}
			}
		($AdvancedMenu_Copy_CHECKBOX.Checked) {
				if ([string]::IsNullOrWhiteSpace($AdvancedMenu_BackupDirectory_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'BackupDirectory' text field is empty.`nPlease select a directory to back up to" -Height 140 -Width 580
					return "error"
				}
				elseif ([string]::IsNullOrWhiteSpace($AdvancedMenu_Source_TEXTBOX.Text)) {
					ErrorForm -ErrorLabelText "An error occurred, the 'SourceDirectory' text field is empty.`nPlease select a source directory" -Height 140 -Width 580
					return "error"
				}
			}
		}
	}

	function CreateProfileListFile {
		$ProfileXML = [System.Collections.ArrayList]::new()
		$SettingParameters = @{
			ProfileName           = "$($AdvancedMenu_ProfileName_TEXTBOX.Text)"
			BackupDirectory       = "$($AdvancedMenu_BackupDirectory_TEXTBOX.Text)"
			Executable_7z         = "$($AdvancedMenu_7zipExecutable_TEXTBOX.Text)"
			SecondBackupDirectory = "$($AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text)"
			BackupName            = "$($AdvancedMenu_BackupName_TEXTBOX.Text)"
			Source                = "$($AdvancedMenu_Source_TEXTBOX.Text)"
			RestoreDirectory      = "$($AdvancedMenu_RestoreDirectory_TEXTBOX.Text)"
			RestorePoints         = $($AdvancedMenu_RestorePoints_TEXTBOX.Text)
			BackupDayFilter       = $($AdvancedMenu_BackupDayFilter_TEXTBOX.Text)
			BackupCheckboxStatus  = $($AdvancedMenu_Backup_CHECKBOX.Checked)
			RestoreCheckboxStatus = $($AdvancedMenu_Restore_CHECKBOX.Checked)
			CopyCheckboxStatus    = $($AdvancedMenu_Copy_CHECKBOX.Checked)
		}
		[void]$ProfileXML.Add($(settings @SettingParameters))
		$ProfileXML | Export-Clixml -Path "${Running_Folder}\ProfileList.xml"
		ErrorForm -ErrorLabelText "A new profile with name: `"$($AdvancedMenu_ProfileName_TEXTBOX.Text)`" - created."
		$AdvancedMenu_FORM.Tag = $ProfileXML
		$AdvancedMenu_FORM.Close()
	}

	function AdvancedMenuSwitch {
		function States {
			param (
				$FormItems,
				[bool]$IsEnabled
			)

			[string]$Color = if ($IsEnabled -eq $true) { 'Window' } else { 'DarkGray' }
			foreach ($Box in $FormItems) {
				$Box.Enabled = $IsEnabled
				if ($box -is [System.Windows.Forms.TextBox]) {
					$Box.BackColor = $Color
					switch ($true) {
						{ $IsEnabled -eq $false } { $Box.Text = '' }
						{ $IsEnabled -eq $true -and ($Box.Name -eq 'AdvancedMenu_RestorePoints_TEXTBOX' -or $Box.Name -eq 'AdvancedMenu_BackupDayFilter_TEXTBOX') } {
							$Box.Text = if ([string]::IsNullOrWhiteSpace($Box.Text)) { 1 } else { $Box.Text }
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'AdvancedMenu_7zipExecutable_TEXTBOX' } {
							$Box.Text = if ([string]::IsNullOrWhiteSpace($Box.Text)) { (Get-Command 7z).Source 2>$null } else { $Box.Text }
						}
					}
				}
			}
		}

		States -IsEnabled ($AdvancedMenu_Backup_CHECKBOX.Checked) -FormItems @(
			$AdvancedMenu_BackupName_TEXTBOX,
			$AdvancedMenu_RestorePoints_TEXTBOX,
			$AdvancedMenu_BackupDayFilter_TEXTBOX
		)
		States -IsEnabled ($AdvancedMenu_Backup_CHECKBOX.Checked -or $AdvancedMenu_Restore_CHECKBOX.Checked -or $AdvancedMenu_Copy_CHECKBOX.Checked) -FormItems @(
			$AdvancedMenu_BackupDirectory_TEXTBOX,
			$AdvancedMenu_BackupDirectory_BUTTON
		)
		States -IsEnabled ($AdvancedMenu_Backup_CHECKBOX.Checked -or $AdvancedMenu_Copy_CHECKBOX.Checked) -FormItems @(
			$AdvancedMenu_SecondBackupDirectory_TEXTBOX,
			$AdvancedMenu_SecondBackupDirectory_BUTTON,
			$AdvancedMenu_SecondBackupDirectoryClear_BUTTON,
			$AdvancedMenu_Source_TEXTBOX,
			$AdvancedMenu_SourceDirectory_BUTTON,
			$AdvancedMenu_SourceFile_BUTTON
		)
		States -IsEnabled ($AdvancedMenu_Restore_CHECKBOX.Checked) -FormItems @(
			$AdvancedMenu_RestoreDirectory_TEXTBOX,
			$AdvancedMenu_RestoreDirectory_BUTTON,
			$AdvancedMenu_RestoreCopySource_BUTTON
		)
		States -IsEnabled ($AdvancedMenu_Backup_CHECKBOX.Checked -or $AdvancedMenu_Restore_CHECKBOX.Checked) -FormItems @(
			$AdvancedMenu_7zipExecutable_TEXTBOX,
			$AdvancedMenu_7ZipExecutable_BUTTON
		)
	}
	#FUNCTIONS_ADVANCED_MENU#######################################################################END
	#FUNCTIONS_PROFILE_MENU########################################################################
	function ProfileMenuButtonsActive {
		if ($ProfileMenu_ProfileList_LISTBOX.SelectedItem) {
			$ProfileMenu_Edit_BUTTON.Enabled = $true
			$ProfileMenu_Delete_BUTTON.Enabled = $true
		}
		else {
			$ProfileMenu_Edit_BUTTON.Enabled = $false
			$ProfileMenu_Delete_BUTTON.Enabled = $false
		}
	}

	function ProfileMenuProfileParametersList {
		$ProfileMenu_ProfileParameterBackup_CHECKBOX.Checked = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)" }).BackupCheckboxStatus)
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.Checked = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)" }).RestoreCheckboxStatus)
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Checked = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)" }).CopyCheckboxStatus)
		$ProfileMenu_ProfileParameterList_LISTBOX.Items.Clear()
		$ProfileMenu_ProfileParameterList_LISTBOX.Items.AddRange(@(
			"Source: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).Source)"	
			"BackupDirectory: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).BackupDirectory)"
			"SecondBackupDirectory: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).SecondBackupDirectory)"
			"RestoreDirectory: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).RestoreDirectory)"
			"NumberOfBackups: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).RestorePoints)"
			"BackupDayFilter: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).BackupDayFilter)"
			"BackupName: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).BackupName)"
			"7z.exe_PATH: $(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)"}).Executable_7z)"
		))
	}

	function DeleteProfileGT1 {
		param (
			$ProfileXmlObject,
			[string]$ChosenProfile
		)

		$ProfileXmlObject.Remove($($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$ChosenProfile" }))
		ListFiller -ProfileXmlObject $ProfileXmlObject -Menu 'ProfileMenu'
		ProfileMenuButtonsActive
		ErrorForm -ErrorLabelText "Profile: `"$ChosenProfile`" - deleted."

		return ,$ProfileXmlObject
	}

	function DeleteLastProfile {
		Remove-Item ${Running_Folder}\ProfileList.xml
		ErrorForm -ErrorLabelText "The last profile has been removed from the list of profiles.`nTo create a new profile, run this script again to create a new list of profiles."
		$ProfileMenu_FORM.Close()
		$MainMenu_FORM.Close()
	}
	#FUNCTIONS_PROFILE_MENU########################################################################END
	#FUNCTIONS_LOG_FORM############################################################################
	function SimpleBackup_Job {
		param (
			[string]$Executable_7z,
			[string]$BackupDirectory,
			[string]$SecondBackupDirectory,
			[string]$BackupName,
			[string]$Source,
			[decimal]$RestorePoints,
			$MessageSingleDir = $null,
			$MessageFirstDir = $null,
			$MessageSecondDir = $null
		)

		$Time = (Get-Date -format "dd/MM/yyyy/HH/mm/ss")
		$7zBackupName = -join ("$BackupDirectory", "$BackupName", '_', "$Time", '.7z')
		$RobocopyBackupName = -join ("$BackupName", '_', "$Time", '.7z')
		$SecondBackupDirectoryName = -join ("$SecondBackupDirectory", "$BackupName", '_', "$Time", '.7z')

		if ("$BackupDirectory" -and -not "$SecondBackupDirectory") {
			$MessageSingleDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}"
			& "$Executable_7z" a "$7zBackupName" "$Source`*" -bsp1
			if (-not $?) {
				Write-Output "ERROR. BACKUP JOB FAILED on item:"
				Write-Output "$7zBackupName"
				return
			}
			$MessageSingleDir.EndMessage
		}
		elseif ("$BackupDirectory" -and "$SecondBackupDirectory") {
			$MessageFirstDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}" -SecondBackupDirectory "${SecondBackupDirectory}"
			& "$Executable_7z" a "$7zBackupName" "$Source`*" -bsp1
			if (-not $?) {
				Write-Output "ERROR. BACKUP JOB FAILED on item:"
				Write-Output "$7zBackupName"
				return
			}
			$hash = Get-FileHash "$7zBackupName"
			$MessageFirstDir.EndMessage
			$MessageSecondDir.StartMessage
			Robocopy "$BackupDirectory" "$SecondBackupDirectory" "$RobocopyBackupName" /mt /z /NC /NS /NP
			$hash2 = Get-FileHash "$SecondBackupDirectoryName"
			$MessageSecondDir.EndMessage
			if (-not ($hash.Hash -eq $hash2.hash)) {
				Write-Output "Something went wrong:`nThe File `'$SecondBackupDirectoryName`' crashed while being copied."
				Write-Output "Files in the directories: `'${SecondBackupDirectory}`' and `'${BackupDirectory}`' were not deleted after the job was completed. Rotation in the archive directories was not performed."
				return
			}
			Get-ChildItem "$SecondBackupDirectory" -Filter *.7z | Where-Object -FilterScript { $_.Name -match "^${BackupName}_*" } | Sort-Object -Property CreationTime | Select-Object -SkipLast $RestorePoints | Remove-Item
		}
		Get-ChildItem -Path "$BackupDirectory" -Filter *.7z | Where-Object { $_.Name -match "^${BackupName}_*" } | Sort-Object -Property CreationTime | Select-Object -SkipLast $RestorePoints | Remove-Item
	}

	function TimeFilteredBackup_Job {
		param (
			[string]$Executable_7z,
			[string]$BackupDirectory,
			[string]$SecondBackupDirectory,
			[string]$BackupName,
			[string]$Source,
			[decimal]$RestorePoints,
			[decimal]$BackupDayFilter,
			$MessageSingleDir = $null,
			$MessageFirstDir = $null,
			$MessageSecondDir = $null
		)

		$Files = Get-ChildItem $Source | Where-Object { $_.LastWriteTime -gt ((Get-Date).adddays(-$BackupDayFilter)) }
		$Time = (Get-Date -format "dd/MM/yyyy/HH/mm/ss")
		$7zBackupName = -join ("$BackupDirectory", "$BackupName", '_', "$Time", '.7z')
		$RobocopyBackupName = -join ("$BackupName", '_', "$Time", '.7z')
		$SecondBackupDirectoryName = -join ("$SecondBackupDirectory", "$BackupName", '_', "$Time", '.7z')

		if ($Files.count -eq 0) {
			Write-Output "There are nothing to backup"
			return
		}
		if ("$BackupDirectory" -and -not "$SecondBackupDirectory") {
			$MessageSingleDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}"
			foreach ($file in $Files) {
				$file_fullname = $file.FullName
				& "$Executable_7z" a "$7zBackupName" "$file_fullname" -bsp1
			}
			$MessageSingleDir.EndMessage
		}
		elseif ("$BackupDirectory" -and "$SecondBackupDirectory") {
			$MessageFirstDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}" -SecondBackupDirectory "${SecondBackupDirectory}"
			foreach ($file in $Files) {
				$file_fullname = $file.FullName
				& "$Executable_7z" a "$7zBackupName" "$file_fullname" -bsp1
			}
			$hash = Get-FileHash "$7zBackupName"
			$MessageFirstDir.EndMessage
			$MessageSecondDir.StartMessage
			Robocopy "$BackupDirectory" "$SecondBackupDirectory" "$RobocopyBackupName" /mt /z /NC /NS /NP
			$hash2 = Get-FileHash "$SecondBackupDirectoryName"
			$MessageSecondDir.EndMessage
			if (-not ($hash.Hash -eq $hash2.hash)) {
				Write-Output "Something went wrong:`nThe File `'$SecondBackupDirectoryName`' crashed while being copied."
				Write-Output "Files in the directories: `'${SecondBackupDirectory}`' and `'${BackupDirectory}`' were not deleted after the job was completed. Rotation in the archive directories was not performed."
				return
			}
			Get-ChildItem "$SecondBackupDirectory" -Filter *.7z | Where-Object -FilterScript { $_.Name -match "^${BackupName}_*" } | Sort-Object -Property CreationTime | Select-Object -SkipLast $RestorePoints | Remove-Item
		}
		Get-ChildItem -Path "$BackupDirectory" -Filter *.7z | Where-Object { $_.Name -match "^${BackupName}_*" } | Sort-Object -Property CreationTime | Select-Object -SkipLast $RestorePoints | Remove-Item
	}

	function CopyFile_Job {
		param (
			[string]$BackupDirectory,
			[string]$SecondBackupDirectory,
			[string]$Source,
			$MessageSingleDir = $null,
			$MessageFirstDir = $null,
			$MessageSecondDir = $null
		)

		$SourceLeaf = Split-Path $Source -Leaf
		$DestinationFirstDir = -join ("$BackupDirectory", "$SourceLeaf")
		$DestinationSecondDir = -join ("$SecondBackupDirectory", "$SourceLeaf")

		if ("$BackupDirectory" -and -not "$SecondBackupDirectory") {
			$MessageSingleDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}"
			if ($Source[-1] -eq '\') {
				Robocopy "$($Source.TrimEnd('\'))" "$DestinationFirstDir" /E /mt /z /NC /NS /NP
			}
			else {
				Robocopy "$(Split-Path $Source -Parent)" "$BackupDirectory" "$SourceLeaf" /mt /z /NC /NS /NP
			}
			$MessageSingleDir.EndMessage
		}
		elseif ($BackupDirectory -and $SecondBackupDirectory) {
			$MessageFirstDir.StartMessage
			check_directories -BackupDirectory ${BackupDirectory} -SecondBackupDirectory ${SecondBackupDirectory}
			if ($Source[-1] -eq '\') {
				Robocopy "$($Source.TrimEnd('\'))" "$DestinationFirstDir" /E /mt /z /NC /NS /NP
			}
			else {
				Robocopy "$(Split-Path $Source -Parent)" "$BackupDirectory" "$SourceLeaf" /mt /z /NC /NS /NP
			}
			$MessageFirstDir.EndMessage
			$MessageSecondDir.StartMessage
			if ($Source[-1] -eq '\') {
				Robocopy "$($Source.TrimEnd('\'))" "$DestinationSecondDir" /E /mt /z /NC /NS /NP
			}
			else {
				Robocopy "$(Split-Path $Source -Parent)" "$SecondBackupDirectory" "$SourceLeaf" /mt /z /NC /NS /NP
			}
			$MessageSecondDir.EndMessage
		}
	}

	function Sync_Job {
		param (
			[string]$BackupDirectory,
			[string]$SecondBackupDirectory,
			[string]$Source,
			$MessageSingleDir = $null,
			$MessageFirstDir = $null,
			$MessageSecondDir = $null
		)

		$SourceLeaf = Split-Path $Source -Leaf
		$DestinationFirstDir = -join ("$BackupDirectory", "$SourceLeaf")
		$DestinationSecondDir = -join ("$SecondBackupDirectory", "$SourceLeaf")
		if ("$BackupDirectory" -and -not "$SecondBackupDirectory") {
			$MessageSingleDir.StartMessage
			check_directories -BackupDirectory "${BackupDirectory}"
			Robocopy "$($Source.TrimEnd('\'))" "$DestinationFirstDir" /MIR /mt /z /NC /NS /NP
			$MessageSingleDir.EndMessage
		}
		elseif ($BackupDirectory -and $SecondBackupDirectory) {
			$MessageFirstDir.StartMessage
			check_directories -BackupDirectory ${BackupDirectory} -SecondBackupDirectory ${SecondBackupDirectory}
			Robocopy "$($Source.TrimEnd('\'))" "$DestinationFirstDir" /MIR /mt /z /NC /NS /NP
			$MessageFirstDir.EndMessage
			$MessageSecondDir.StartMessage
			Robocopy "$($Source.TrimEnd('\'))" "$DestinationSecondDir" /MIR /mt /z /NC /NS /NP
			$MessageSecondDir.EndMessage
		}
	}

	function Restore_Job {
		param (
			[string]$SelectedProfile,
			[string]$Executable_7z,
			[string]$BackupDirectory,
			[string]$RestoreDirectory,
			[string]$SelectedBackup,
			[bool]$RestoreMenu_CheckBox,
			$MessageSingleDir = $null,
			$MessageFirstDir = $null,
			$MessageSecondDir = $null
		)

		if ($RestoreDirectory.Length -eq 3 -and $RestoreDirectory -match '^[a-zA-Z]:\\+$') {
			Write-Output "ERROR. RESTORE JOB FAILED on item:"
			Write-Output "$RestoreDirectory"
			Write-Output "The recovery directory cannot be the root of the disk.`n`nBecause during recovery, the program will try to delete all files from the disk root.`n`nPlease create a separate recovery directory at the root of the disk, even if it is the only one on the disk."
			return
		}
		if ($RestoreMenu_CheckBox) {
			$MessageFirstDir.StartMessage
			$BackupDirectory_Before_restore = -join ("$BackupDirectory", "Backups_before_restore\")
			if (Test-Path -Path "$RestoreDirectory") {
				SimpleBackup_Job -Executable_7z $Executable_7z -BackupDirectory $BackupDirectory_Before_restore -BackupName $SelectedProfile -Source $RestoreDirectory -RestorePoints 3
			}
			else {
				Write-Output "Directory: $RestoreDirectory dose not exist"
			}
			if ($LASTEXITCODE -gt 0) {
				return
			}
			$MessageFirstDir.EndMessage
			$MessageSecondDir.StartMessage
			if (Test-Path -Path "$RestoreDirectory") {
				Remove-Item "$RestoreDirectory`*" -Recurse
			}
			& "$Executable_7z" x "$SelectedBackup" -o"$RestoreDirectory" -bsp1
			if (-not $?) {
				Write-Output "ERROR. RESTORE JOB FAILED on item:"
				Write-Output "$SelectedBackup"
				Write-Output "To dir: $RestoreDirectory"
				return
			}
			$MessageSecondDir.EndMessage
		}
		else {
			$MessageSecondDir.StartMessage
			if (Test-Path -Path "$RestoreDirectory") {
				Remove-Item "$RestoreDirectory`*" -Recurse
			}
			& "$Executable_7z" x "$SelectedBackup" -o"$RestoreDirectory" -bsp1
			if (-not $?) {
				Write-Output "ERROR. RESTORE JOB FAILED on item:"
				Write-Output "$SelectedBackup"
				Write-Output "To dir: $RestoreDirectory"
				return
			}
			$MessageSecondDir.EndMessage
		}
	}
	#FUNCTIONS_LOG_FORM############################################################################END
	#FUNCTIONS_BACKUP_MENU#########################################################################
	function DiskVariablesBackup {
		param (
			$ProfileXmlObject,
			[string]$SelectedProfile
		)

		$DriveLetter_backups = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupDirectory).split(':')[0]
		$DriveBackupLeftSpace = ([math]::round((Get-PSDrive $DriveLetter_backups).Free[0] / 1Mb, 3)).ToString("N3")
		$BackupMenu_SpaceLeftOnDisk_LABEL.Text = "There is $DriveBackupLeftSpace MB of free space left on drive $DriveLetter_backups.`nIf you want to use this script to automate your tasks, below are the commands on how to use this script in the command line or in the task scheduler."
		$BackupDrives = @{
			$DriveLetter_backups = $DriveBackupLeftSpace
		}

		return $BackupDrives
	}

	function check_directories {
		param (
			$BackupDirectory,
			$SecondBackupDirectory
		)

		switch ($true) {
		(-not [string]::IsNullOrWhiteSpace($BackupDirectory)) {
				if (-not (Test-Path -Path "$BackupDirectory")) {
					New-Item -ItemType Directory "$BackupDirectory"
				}
			}
		(-not [string]::IsNullOrWhiteSpace($SecondBackupDirectory)) {
				if ( -not (Test-Path -Path "$SecondBackupDirectory")) {
					New-Item -ItemType Directory "$SecondBackupDirectory"
				}
			}
		}
	}

	function BackupMenuButtons {
		param (
			$ProfileXmlObject,
			[String]$SelectedProfile
		)

		function States {
			param (
				$FormItems,
				[bool]$IsEnabled
			)

			foreach ($Box in $FormItems) {
				$Box.Enabled = $IsEnabled
				if ($box -is [System.Windows.Forms.TextBox]) {
					switch ($true) {
						{ $IsEnabled -eq $false -and ($Box.Name -eq 'BackupMenu_SimpleBackupCMDString_TEXTBOX' -or $Box.Name -eq 'BackupMenu_TimeFiltredBackupCMDString_TEXTBOX') } {
							$Box.Text = 'The Backup checkbox for this profile is disabled'
						}
						{ $IsEnabled -eq $false -and ($Box.Name -eq 'BackupMenu_SimpleCopyCMDString_TEXTBOX' -or $Box.Name -eq 'BackupMenu_SyncCMDString_TEXTBOX') } {
							$Box.Text = 'The Copy checkbox for this profile is disabled'
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_SimpleBackupCMDString_TEXTBOX' } {
							$Box.Text = "powershell -file `"$Path_to_Script`" -AutomationType SimpleBackup -ProfileName `"$($SelectedProfile)`""
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_TimeFiltredBackupCMDString_TEXTBOX' } {
							$Box.Text = "powershell -file `"$Path_to_Script`" -AutomationType TimeFilteredBackup -ProfileName `"$($SelectedProfile)`""
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_SimpleCopyCMDString_TEXTBOX' } {
							$Box.Text = "powershell -file `"$Path_to_Script`" -AutomationType Copy -ProfileName `"$($SelectedProfile)`""
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_SyncCMDString_TEXTBOX' } {
							$Box.Text = "powershell -file `"$Path_to_Script`" -AutomationType Sync -ProfileName `"$($SelectedProfile)`""
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_Source_TEXTBOX' } {
							$Box.Text = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Source)"
							if ($Box.Text[-1] -ne '\') {
								$BackupMenu_Sync_BUTTON.Enabled = $false
								$BackupMenu_SyncCMDString_TEXTBOX.Text = 'The synchronization task is available only for directories.'
								$BackupMenu_SyncCMDString_TEXTBOX.Enabled = $false
								$BackupMenu_SyncCMDStringClipboard_BUTTON.Enabled = $false
							}
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_FirstDestination_TEXTBOX' } {
							$Box.Text = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						}
						{ $IsEnabled -eq $true -and $Box.Name -eq 'BackupMenu_SecondDestination_TEXTBOX' } {
							if ( [string]::IsNullOrWhiteSpace("$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)")) {
								$Box.Text = "Second Backup folder is not set"
								$Box.Enabled = $false
								$BackupMenu_SecondDestination_BUTTON.Enabled = $false
							}
							else {
								$Box.Text = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)"
								$Box.Enabled = $True
								$BackupMenu_SecondDestination_BUTTON.Enabled = $True
							}
						}
					}
				}
			}
		}
	
		$BackupCheckbox = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupCheckboxStatus
		$CopyCheckBox = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).CopyCheckboxStatus
		States -IsEnabled ($BackupCheckbox) -FormItems @(
			$BackupMenu_SimpleBackup_BUTTON,
			$BackupMenu_TimeFiltredBackup_BUTTON,
			$BackupMenu_SimpleBackupCMDString_TEXTBOX,
			$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX,
			$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON,
			$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON
		)
		States -IsEnabled ($CopyCheckBox) -FormItems @(
			$BackupMenu_SimpleCopy_BUTTON,
			$BackupMenu_Sync_BUTTON,
			$BackupMenu_SimpleCopyCMDString_TEXTBOX,
			$BackupMenu_SyncCMDString_TEXTBOX,
			$BackupMenu_SyncCMDStringClipboard_BUTTON,
			$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON
		)
		States -IsEnabled ($CopyCheckBox -or $BackupCheckbox) -FormItems @(
			$BackupMenu_Source_BUTTON,
			$BackupMenu_Source_TEXTBOX,
			$BackupMenu_FirstDestination_BUTTON,
			$BackupMenu_FirstDestination_TEXTBOX,
			$BackupMenu_SecondDestination_TEXTBOX
		)
	}
	#FUNCTIONS_BACKUP_MENU##########################################################################END
	#FUNCTIONS_RESTORE_MENU#########################################################################
	function DiskVariablesRestore {
		param (
			$ProfileXmlObject,
			[string]$SelectedProfile
		)

		$DriveLetter_restore = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).RestoreDirectory).split(':')[0]
		$DriveRestoreLeftSpace = ([math]::round((Get-PSDrive $DriveLetter_restore).Free[0] / 1Mb, 3)).ToString("N3")
		$RestoreMenu_SpaceLeftOnDisk_LABEL.Text = "There is $DriveRestoreLeftSpace MB of free space left on drive $DriveLetter_restore."
		$RestoreDrives = @{
			$DriveLetter_restore = $DriveRestoreLeftSpace
		}
	
		return $RestoreDrives
	}
	function RestoreMenuButtons {
		param (
			$ProfileXmlObject,
			[String]$SelectedProfile
		)

		function States {
			param (
				$FormItems,
				[bool]$IsEnabled
			)

			foreach ($box in $FormItems) {
				$Box.Enabled = $IsEnabled
				if ($box -is [System.Windows.Forms.TextBox]) {
					switch ($true) {
						{ $box.name -eq 'RestoreMenu_DestinationRestoreDirectory_TEXTBOX' } {
							$box.text = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).RestoreDirectory
						}
						{ $box.name -eq 'RestoreMenu_SourceBackupDirectory_TEXTBOX' } {
							$box.text = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupDirectory
						}
					}
				}
			}
		}
	
		$BackupCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupCheckboxStatus
		$RestoreCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).RestoreCheckboxStatus
		$CopyCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).CopyCheckboxStatus
		$BackupDirectory = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupDirectory
		$BackupName = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupName
	
		if (-not $BackupCheckboxStatus -and -not $CopyCheckboxStatus -and $RestoreCheckboxStatus) {
			$BackupAfterDisasterDirectory = -join ($BackupDirectory, "Backups_before_restore\")
			$BackupDirectoryArchives = $BackupDirectory
		}
		else {
			$BackupAfterDisasterDirectory = -join ($BackupDirectory, "Backups_before_restore\", $SelectedProfile)
			$BackupDirectoryArchives = -join ($BackupDirectory, $BackupName)
		}
		States -IsEnabled (-not ([string]::IsNullOrWhiteSpace($SelectedProfile)) -and (Test-Path $BackupDirectoryArchives*) ) -FormItems @(
			$RestoreMenu_ClassicRestore_BUTTON,
			$RestoreMenu_SourceBackupDirectory_BUTTON,
			$RestoreMenu_DestinationRestoreDirectory_BUTTON,
			$RestoreMenu_DestinationRestoreDirectory_TEXTBOX,
			$RestoreMenu_SourceBackupDirectory_TEXTBOX
		)
		States -IsEnabled (Test-Path $BackupAfterDisasterDirectory*) -FormItems @(
			$RestoreMenu_RestoreAfterDisaster_BUTTON
		)
	}
	#FUNCTIONS_RESTORE_MENU#########################################################################END
	#FUNCTIONS_MAIN_MENU############################################################################
	function CheckUpdate {
		ping github.com -n 1 > $null
		if ($LASTEXITCODE -ne 0){
			$MainMenu_Update_BUTTON.Text = 'Cannot connect to GITHUB'
			return
		}
		$GitScriptBody = (Invoke-WebRequest https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/raw/main/PowerShell-7zBackup_and_Restore.ps1).content -split "`r`n"
		$ScriptVersionScript = $ScriptVersion
		$MatchedVersion = ($GitScriptBody -split "`n" | Where-Object {$_ -match '\[System.Version\]::Parse'})
		if ([string]::IsNullOrWhiteSpace($MatchedVersion)){
			$MainMenu_Update_BUTTON.Text = 'Nothing to update'
			$MainMenu_Update_BUTTON.Enabled = $false
			return
		} 
		Invoke-Expression $MatchedVersion
		if ($ScriptVersionScript -ge $ScriptVersion) {
			$MainMenu_Update_BUTTON.Text = 'Nothing to update'
			$MainMenu_Update_BUTTON.Enabled = $false
		} 
		else {
			$MainMenu_Update_BUTTON.Text = 'Do you want to update the script?'
			[bool]$ScriptUpdate = $true
		}
		$CheckUpdateResult = @{
			ScriptUpdate = $ScriptUpdate
			GitScriptBody = $GitScriptBody
		}
		return $CheckUpdateResult
	}

	function UpdateScript {
		param (
			$ScriptPath,
			$GitScriptBody
		)
		ping github.com -n 1 > $null
		if ($LASTEXITCODE -ne 0){
			$MainMenu_Update_BUTTON.Text = 'Cannot connect to GITHUB'
			return
		}
		Write-Output $GitScriptBody > "$ScriptPath"
		ErrorForm -ErrorLabelText "Script Updated, exiting... Please restart the Script"
		$MainMenu_FORM.Close()
	}
	#FUNCTIONS_MAIN_MENU#############################################################################END
	#FUNCTIONS_FORMS#################################################################################
	function LogForm {
		param (
			$ProfileXmlObject,
			[string]$LogFormJob,
			$SelectedProfile,
			$SelectedBackup
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$Log_FORM = New-Object System.Windows.Forms.Form
		$Log_FORM.Text = $FormsVariables.FormsText
		$Log_FORM.Font = $FormsVariables.FormsFont
		$Log_FORM.BackColor = $FormsVariables.FormsBackColor
		$Log_FORM.ForeColor = $FormsVariables.FormsForeColor
		$Log_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$Log_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$Log_FORM.ClientSize = New-Object System.Drawing.Size(700, 600)
		#######################################################################################################
		$Log_LABEL = New-Object System.Windows.Forms.Label
		$Log_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$Log_LABEL.Size = New-Object System.Drawing.Size(680, 30)
		$Log_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 20, [System.Drawing.FontStyle]::Regular)
		$Log_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$Log_LABEL.Text = "Operational Log"
		$Log_FORM.Controls.Add($Log_LABEL)
		#######################################################################################################
		$Log_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$Log_TEXTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$Log_TEXTBOX.Location = New-Object System.Drawing.Point(10, 45)
		$Log_TEXTBOX.Size = New-Object System.Drawing.Size(680, 500)
		$Log_TEXTBOX.Multiline = $true
		$Log_TEXTBOX.ReadOnly = $true
		$Log_TEXTBOX.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
		$Log_TEXTBOX.Text = ''
		$Log_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$Log_FORM.Controls.Add($Log_TEXTBOX)
		#######################################################################################################
		$Log_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$Log_Exit_BUTTON.Location = New-Object System.Drawing.Point(300, 550)
		$Log_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 40)
		$Log_Exit_BUTTON.Text = "Ok"
		$Log_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$Log_Exit_BUTTON.UseVisualStyleBackColor = $true
		$Log_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$Log_FORM.AcceptButton = $Log_Exit_BUTTON
		$Log_FORM.Controls.Add($Log_Exit_BUTTON)
		#######################################################################################################
		$Log_FORM.add_Shown({
			Switch ($LogFormJob) {
				"SimpleBackup_Job" {
					$Log_Exit_BUTTON.Enabled = $false
					$Job_Parameters = @{
						Executable_7z              = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Executable_7z)"
						BackupDirectory            = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						SecondBackupDirectory      = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)"
						BackupName                 = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupName)"
						Source                     = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Source)"
						RestorePoints              = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).RestorePoints)
						MessageSingleDir           = $(TextFiller -JobStartingMessage ' Archiving JOB Started ' -JobEndingMessage ' Archiving JOB Finished ')
						MessageFirstDir            = $(TextFiller -JobStartingMessage ' Archiving JOB to the First Directory Started ' -JobEndingMessage ' First Archiving JOB Finished ')
						MessageSecondDir           = $(TextFiller -JobStartingMessage ' Archiving JOB to the Second Directory Started ' -JobEndingMessage ' Second Archiving JOB Finished ')
						Function_SimpleBackup_Job  = "function SimpleBackup_Job {`n$($Function:SimpleBackup_Job.ToString())`n}"
						Function_check_directories = "function check_directories {`n$($Function:check_directories.ToString())`n}"
					}
					$StartTime = Get-Date
					$job = Start-Job -ArgumentList @(
						$Job_Parameters.Executable_7z,
						$Job_Parameters.BackupDirectory,
						$Job_Parameters.SecondBackupDirectory,
						$Job_Parameters.BackupName,
						$Job_Parameters.Source,
						$Job_Parameters.RestorePoints,
						$Job_Parameters.MessageSingleDir,
						$Job_Parameters.MessageFirstDir,
						$Job_Parameters.MessageSecondDir,
						$Job_Parameters.Function_SimpleBackup_Job,
						$Job_Parameters.Function_check_directories
					) -ScriptBlock {
						param (
							$Executable_7z,
							$BackupDirectory,
							$SecondBackupDirectory,
							$BackupName,
							$Source,
							$RestorePoints,
							$MessageSingleDir,
							$MessageFirstDir,
							$MessageSecondDir,
							$Function_SimpleBackup_Job,
							$Function_check_directories
						)
						Invoke-Expression $Function_SimpleBackup_Job
						Invoke-Expression $Function_check_directories
						SimpleBackup_Job -Executable_7z $Executable_7z -BackupDirectory $BackupDirectory -SecondBackupDirectory $SecondBackupDirectory -BackupName $BackupName -Source $Source -RestorePoints $RestorePoints -MessageSingleDir $MessageSingleDir -MessageFirstDir $MessageFirstDir -MessageSecondDir $MessageSecondDir | Out-String -Stream | ForEach-Object {
							$RCOUT = $_.Trim() + "`r`n"
							switch ($true) {
								($RCOUT -cmatch "^ROBOCOPY") { $RCOUT -Replace ('(\s+)', ' ') }
								($RCOUT -cmatch "^Started|^Source|^Dest|^Files|^Options") { $RCOUT -Replace ('( : )', "`t: ") }
								($RCOUT -cmatch '^Total') { $RCOUT -replace '^Total', "`t      Total" }
								($RCOUT -cmatch "^Dirs|^Bytes|^Times") { $RCOUT -replace ' : ', "`t: " }
								($RCOUT -cmatch "^Ended") { $RCOUT -replace ' :\s+', "`t:   " } 
								($RCOUT -cmatch "^Speed") { $RCOUT -replace ' :\s+', "`t:   " } 
								Default { $RCOUT }
							}
						}
					}
					while (-not ($Job.State -match "Completed|Failed|Stopped")) {
						Start-Sleep -Milliseconds 200
						Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
						[System.Windows.Forms.Application]::DoEvents()
					}
					Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
					Remove-Job -Job $job
					$EndTime = Get-Date
					$Log_TEXTBOX.AppendText("Elapsed Time: $(($EndTime - $StartTime).TotalSeconds) seconds")
					$Log_Exit_BUTTON.Enabled = $true
				}
				"TimeFilteredBackup_Job" {
					$Log_Exit_BUTTON.Enabled = $false
					$Job_Parameters = @{
						Executable_7z                   = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Executable_7z)"
						BackupDirectory                 = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						SecondBackupDirectory           = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)"
						BackupName                      = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupName)"
						Source                          = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Source)"
						RestorePoints                   = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).RestorePoints)
						BackupDayFilter                 = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$SelectedProfile" }).BackupDayFilter)
						MessageSingleDir                = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB Started ' -JobEndingMessage ' Time Filtered Archiving JOB Finished ')
						MessageFirstDir                 = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB to the First Directory Started ' -JobEndingMessage ' First Time Filtered Archiving JOB Finished ')
						MessageSecondDir                = $(TextFiller -JobStartingMessage ' Time Filtered Archiving JOB to the Second Directory Started ' -JobEndingMessage ' Second Time Filtered Archiving JOB Finished ')
						Function_TimeFilteredBackup_Job = "function TimeFilteredBackup_Job {`n$($Function:TimeFilteredBackup_Job.ToString())`n}"
						Function_check_directories      = "function check_directories {`n$($Function:check_directories.ToString())`n}"
					}
					$StartTime = Get-Date
					$job = Start-Job -ArgumentList @(
						$Job_Parameters.Executable_7z,
						$Job_Parameters.BackupDirectory,
						$Job_Parameters.SecondBackupDirectory,
						$Job_Parameters.BackupName,
						$Job_Parameters.Source,
						$Job_Parameters.RestorePoints,
						$Job_Parameters.BackupDayFilter,
						$Job_Parameters.MessageSingleDir,
						$Job_Parameters.MessageFirstDir,
						$Job_Parameters.MessageSecondDir,
						$Job_Parameters.Function_TimeFilteredBackup_Job,
						$Job_Parameters.Function_check_directories
					) -ScriptBlock {
						param (
							$Executable_7z,
							$BackupDirectory,
							$SecondBackupDirectory,
							$BackupName,
							$Source,
							$RestorePoints,
							$BackupDayFilter,
							$MessageSingleDir,
							$MessageFirstDir,
							$MessageSecondDir,
							$Function_TimeFilteredBackup_Job,
							$Function_check_directories
						)
						Invoke-Expression $Function_TimeFilteredBackup_Job
						Invoke-Expression $Function_check_directories
						TimeFilteredBackup_Job -Executable_7z $Executable_7z -BackupDirectory $BackupDirectory -SecondBackupDirectory $SecondBackupDirectory -BackupName $BackupName -Source $Source -RestorePoints $RestorePoints -BackupDayFilter $BackupDayFilter -MessageSingleDir $MessageSingleDir -MessageFirstDir $MessageFirstDir -MessageSecondDir $MessageSecondDir | Out-String -Stream | ForEach-Object {
							$RCOUT = $_.Trim() + "`r`n"
							switch ($true) {
								($RCOUT -cmatch "^ROBOCOPY") { $RCOUT -Replace ('(\s+)', ' ') }
								($RCOUT -cmatch "^Started|^Source|^Dest|^Files|^Options") { $RCOUT -Replace ('( : )', "`t: ") }
								($RCOUT -cmatch '^Total') { $RCOUT -replace '^Total', "`t      Total" }
								($RCOUT -cmatch "^Dirs|^Bytes|^Times") { $RCOUT -replace ' : ', "`t: " }
								($RCOUT -cmatch "^Ended") { $RCOUT -replace ' :\s+', "`t:   " } 
								($RCOUT -cmatch "^Speed") { $RCOUT -replace ' :\s+', "`t:   " } 
								Default { $RCOUT }
							}
						}
					}

					while (-not ($Job.State -match "Completed|Failed|Stopped")) {
						Start-Sleep -Milliseconds 200
						Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
						[System.Windows.Forms.Application]::DoEvents()
					}
			
					Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
					Remove-Job -Job $job
					$EndTime = Get-Date
					$Log_TEXTBOX.AppendText("Elapsed Time: $(($EndTime - $StartTime).TotalSeconds) seconds")
					$Log_Exit_BUTTON.Enabled = $true
				}
				"CopyFile_Job" {
					$Log_Exit_BUTTON.Enabled = $false
					$Job_Parameters = @{
						BackupDirectory            = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						SecondBackupDirectory      = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)"
						Source                     = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Source)"
						MessageSingleDir           = $(TextFiller -JobStartingMessage ' Copy JOB Started ' -JobEndingMessage ' Copy JOB Finished ')
						MessageFirstDir            = $(TextFiller -JobStartingMessage ' Copy JOB to the First Folder Started ' -JobEndingMessage ' First Copy JOB Finished ')
						MessageSecondDir           = $(TextFiller -JobStartingMessage ' Copy JOB to the Second Folder Started ' -JobEndingMessage ' Second Copy JOB Finished ')
						Function_CopyFile_Job      = "function CopyFile_Job {`n$($Function:CopyFile_Job.ToString())`n}"
						Function_check_directories = "function check_directories {`n$($Function:check_directories.ToString())`n}"
					}
					$StartTime = Get-Date
					$job = Start-Job -ArgumentList @(
						$Job_Parameters.BackupDirectory,
						$Job_Parameters.SecondBackupDirectory,
						$Job_Parameters.Source,
						$Job_Parameters.MessageSingleDir,
						$Job_Parameters.MessageFirstDir,
						$Job_Parameters.MessageSecondDir,
						$Job_Parameters.Function_CopyFile_Job,
						$Job_Parameters.Function_check_directories
					) -ScriptBlock {
						param (
							$BackupDirectory,
							$SecondBackupDirectory,
							$Source,
							$MessageSingleDir,
							$MessageFirstDir,
							$MessageSecondDir,
							$Function_CopyFile_Job,
							$Function_check_directories
						)
						Invoke-Expression $Function_CopyFile_Job
						Invoke-Expression $Function_check_directories
						CopyFile_Job -BackupDirectory $BackupDirectory -SecondBackupDirectory $SecondBackupDirectory -Source $Source -MessageSingleDir $MessageSingleDir -MessageFirstDir $MessageFirstDir -MessageSecondDir $MessageSecondDir | Out-String -Stream | ForEach-Object {
							$RCOUT = $_.Trim() + "`r`n"
							switch ($true) {
								($RCOUT -cmatch "^ROBOCOPY") { $RCOUT -Replace ('(\s+)', ' ') }
								($RCOUT -cmatch "^Started|^Source|^Dest|^Files|^Options") { $RCOUT -Replace ('( : )', "`t: ") }
								($RCOUT -cmatch '^Total') { $RCOUT -replace '^Total', "`t      Total" }
								($RCOUT -cmatch "^Dirs|^Bytes|^Times") { $RCOUT -replace ' : ', "`t: " }
								($RCOUT -cmatch "^Ended") { $RCOUT -replace ' :\s+', "`t:   " } 
								($RCOUT -cmatch "^Speed") { $RCOUT -replace ' :\s+', "`t:   " } 
								Default { $RCOUT }
							}
						}
					}

					while (-not ($Job.State -match "Completed|Failed|Stopped")) {
						Start-Sleep -Milliseconds 200
						Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
						[System.Windows.Forms.Application]::DoEvents()
					}
			
					Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
					Remove-Job -Job $job
					$EndTime = Get-Date
					$Log_TEXTBOX.AppendText("Elapsed Time: $(($EndTime - $StartTime).TotalSeconds) seconds")
					$Log_Exit_BUTTON.Enabled = $true
				}
				"Sync_Job" {
					$Log_Exit_BUTTON.Enabled = $false
					$Job_Parameters = @{
						BackupDirectory            = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						SecondBackupDirectory      = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).SecondBackupDirectory)"
						Source                     = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Source)"
						MessageSingleDir           = $(TextFiller -JobStartingMessage ' Sync Copy JOB Started ' -JobEndingMessage ' Sync JOB Finished ')
						MessageFirstDir            = $(TextFiller -JobStartingMessage ' Sync JOB to the First Folder Started ' -JobEndingMessage ' First Sync JOB Finished ')
						MessageSecondDir           = $(TextFiller -JobStartingMessage ' Sync JOB to the Second Folder Started ' -JobEndingMessage ' Second Sync JOB Finished ')
						Function_Sync_Job          = "function Sync_Job {`n$($Function:Sync_Job.ToString())`n}"
						Function_check_directories = "function check_directories {`n$($Function:check_directories.ToString())`n}"
					}
					$StartTime = Get-Date
					$job = Start-Job -ArgumentList @(
						$Job_Parameters.BackupDirectory,
						$Job_Parameters.SecondBackupDirectory,
						$Job_Parameters.Source,
						$Job_Parameters.MessageSingleDir,
						$Job_Parameters.MessageFirstDir,
						$Job_Parameters.MessageSecondDir,
						$Job_Parameters.Function_Sync_Job,
						$Job_Parameters.Function_check_directories
					) -ScriptBlock {
						param (
							$BackupDirectory,
							$SecondBackupDirectory,
							$Source,
							$MessageSingleDir,
							$MessageFirstDir,
							$MessageSecondDir,
							$Function_Sync_Job,
							$Function_check_directories
						)
						Invoke-Expression $Function_Sync_Job
						Invoke-Expression $Function_check_directories
						Sync_Job -BackupDirectory $BackupDirectory -SecondBackupDirectory $SecondBackupDirectory -Source $Source -MessageSingleDir $MessageSingleDir -MessageFirstDir $MessageFirstDir -MessageSecondDir $MessageSecondDir | Out-String -Stream | ForEach-Object {
							$RCOUT = $_.Trim() + "`r`n"
							switch ($true) {
								($RCOUT -cmatch "^ROBOCOPY") { $RCOUT -Replace ('(\s+)', ' ') }
								($RCOUT -cmatch "^Started|^Source|^Dest|^Files|^Options") { $RCOUT -Replace ('( : )', "`t: ") }
								($RCOUT -cmatch '^Total') { $RCOUT -replace '^Total', "`t      Total" }
								($RCOUT -cmatch "^Dirs|^Bytes|^Times") { $RCOUT -replace ' : ', "`t: " }
								($RCOUT -cmatch "^Ended") { $RCOUT -replace ' :\s+', "`t:   " } 
								($RCOUT -cmatch "^Speed") { $RCOUT -replace ' :\s+', "`t:   " } 
								Default { $RCOUT }
							}
						}
					}
					while (-not ($Job.State -match "Completed|Failed|Stopped")) {
						Start-Sleep -Milliseconds 200
						Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
						[System.Windows.Forms.Application]::DoEvents()
					}
					Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
					Remove-Job -Job $job
					$EndTime = Get-Date
					$Log_TEXTBOX.AppendText("Elapsed Time: $(($EndTime - $StartTime).TotalSeconds) seconds")
					$Log_Exit_BUTTON.Enabled = $true
				}
				"Restore_Job" {
					$Log_Exit_BUTTON.Enabled = $false
					$Job_Parameters = @{
						SelectedProfile            = $SelectedProfile
						Executable_7z              = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).Executable_7z)"
						BackupDirectory            = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).BackupDirectory)"
						RestoreDirectory           = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$SelectedProfile"}).RestoreDirectory)"
						RestoreMenu_CheckBox       = $RestoreMenu_CheckBox_CHECKBOX.Checked
						SelectedBackup             = $SelectedBackup
						MessageFirstDir            = $(TextFiller -JobStartingMessage ' Backup Before Restoring JOB Started ' -JobEndingMessage ' Backup Before Restoring JOB Finished ')
						MessageSecondDir           = $(TextFiller -JobStartingMessage ' Restoring JOB Started ' -JobEndingMessage ' Restoring JOB Finished ')
						Function_Restore_Job       = "function Restore_Job {`n$($Function:Restore_Job.ToString())`n}"
						Function_check_directories = "function check_directories {`n$($Function:check_directories.ToString())`n}"
						Function_SimpleBackup_Job  = "function SimpleBackup_Job {`n$($Function:SimpleBackup_Job.ToString())`n}"
					}
					$StartTime = Get-Date
					$job = Start-Job -ArgumentList @(
						$Job_Parameters.SelectedProfile,
						$Job_Parameters.Executable_7z,
						$Job_Parameters.BackupDirectory,
						$Job_Parameters.RestoreDirectory,
						$Job_Parameters.RestoreMenu_CheckBox,
						$Job_Parameters.SelectedBackup,
						$Job_Parameters.MessageFirstDir,
						$Job_Parameters.MessageSecondDir,
						$Job_Parameters.Function_Restore_Job,
						$Job_Parameters.Function_check_directories,
						$Job_Parameters.Function_SimpleBackup_Job
					) -ScriptBlock {
						param (
							$SelectedProfile,
							$Executable_7z,
							$BackupDirectory,
							$RestoreDirectory,
							$RestoreMenu_CheckBox,
							$SelectedBackup,
							$MessageFirstDir,
							$MessageSecondDir,
							$Function_Restore_Job,
							$Function_check_directories,
							$Function_SimpleBackup_Job
						)
						Invoke-Expression $Function_Restore_Job
						Invoke-Expression $Function_check_directories
						Invoke-Expression $Function_SimpleBackup_Job
						Restore_Job -SelectedProfile $SelectedProfile -Executable_7z $Executable_7z -BackupDirectory $BackupDirectory -RestoreDirectory $RestoreDirectory -RestoreMenu_CheckBox $RestoreMenu_CheckBox -SelectedBackup $SelectedBackup -MessageFirstDir $MessageFirstDir -MessageSecondDir $MessageSecondDir | Out-String -Stream | ForEach-Object {
							$RCOUT = $_.Trim() + "`r`n"
							switch ($true) {
								($RCOUT -cmatch "^ROBOCOPY") { $RCOUT -Replace ('(\s+)', ' ') }
								($RCOUT -cmatch "^Started|^Source|^Dest|^Files|^Options") { $RCOUT -Replace ('( : )', "`t: ") }
								($RCOUT -cmatch '^Total') { $RCOUT -replace '^Total', "`t      Total" }
								($RCOUT -cmatch "^Dirs|^Bytes|^Times") { $RCOUT -replace ' : ', "`t: " }
								($RCOUT -cmatch "^Ended") { $RCOUT -replace ' :\s+', "`t:   " } 
								($RCOUT -cmatch "^Speed") { $RCOUT -replace ' :\s+', "`t:   " } 
								Default { $RCOUT }
							}
						}
					}
					while (-not ($job.State -match "Completed|Failed|Stopped")) {
						Start-Sleep -Milliseconds 200
						Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
						[System.Windows.Forms.Application]::DoEvents()
					}
					Receive-Job -Job $job | ForEach-Object { $Log_TEXTBOX.AppendText("$_") }
					Remove-Job -Job $job
					$EndTime = Get-Date
					$Log_TEXTBOX.AppendText("Elapsed Time: $(($EndTime - $StartTime).TotalSeconds) seconds")
					$Log_Exit_BUTTON.Enabled = $true
				}
			}
		})
		$Log_FORM.ShowDialog() > $null
	}

	function ErrorForm {
		param (
			[string]$ErrorLabelText,
			[Parameter(HelpMessage = 'Default Value is: 140')][decimal]$Height = 140,
			[Parameter(HelpMessage = 'Default Value is: 500')][decimal]$Width = 500
		)

		[decimal]$FormHeight = $Height
		[decimal]$FormWidth = $Width
		[decimal]$LabelHeight = $Height - 60
		[decimal]$LabelWidth = $Width - 20
		[decimal]$MainMenu_Exit_BUTTONDrPointX = ($Width - 120) * 0.5
		[decimal]$MainMenu_Exit_BUTTONDrPointY = 15 + $LabelHeight
		$FormsVariables = FormsVariables
		#######################################################################################################
		$Error_FORM = New-Object System.Windows.Forms.Form
		$Error_FORM.Text = $FormsVariables.FormsText
		$Error_FORM.Font = $FormsVariables.FormsFont
		$Error_FORM.BackColor = $FormsVariables.FormsBackColor
		$Error_FORM.ForeColor = $FormsVariables.FormsForeColor
		$Error_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$Error_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$Error_FORM.ClientSize = New-Object System.Drawing.Size($FormWidth, $FormHeight)
		#######################################################################################################
		$Error_LABEL = New-Object System.Windows.Forms.Label
		$Error_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$Error_LABEL.Size = New-Object System.Drawing.Size($LabelWidth, $LabelHeight)
		$Error_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$Error_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$Error_LABEL.Text = "$ErrorLabelText"
		$Error_FORM.Controls.Add($Error_LABEL)
		#######################################################################################################
		$Error_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$Error_Exit_BUTTON.Location = New-Object System.Drawing.Point($MainMenu_Exit_BUTTONDrPointX, $MainMenu_Exit_BUTTONDrPointY)
		$Error_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$Error_Exit_BUTTON.Text = 'Exit'
		$Error_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$Error_Exit_BUTTON.Add_Click({
				$Error_FORM.Close()
			})
		$Error_FORM.Controls.Add($Error_Exit_BUTTON)
		$Error_FORM.AcceptButton = $Error_Exit_BUTTON
		#######################################################################################################
		[void]$Error_FORM.ShowDialog()
	}

	function No7zip {
		param (
			$ProfileXmlObject,
			$Profile7zExecCheck
		)

		$FormsVariables = FormsVariables
		$Exec7z = (Get-Command 7z).Source 2>$null
		#######################################################################################################
		$No7zip_FORM = New-Object System.Windows.Forms.Form
		$No7zip_FORM.Text = $FormsVariables.FormsText
		$No7zip_FORM.Font = $FormsVariables.FormsFont
		$No7zip_FORM.BackColor = $FormsVariables.FormsBackColor
		$No7zip_FORM.ForeColor = $FormsVariables.FormsForeColor
		$No7zip_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$No7zip_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$No7zip_FORM.ClientSize = New-Object System.Drawing.Size(620, 215)
		#######################################################################################################
		$No7zip_LABEL = New-Object System.Windows.Forms.Label
		$No7zip_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$No7zip_LABEL.Size = New-Object System.Drawing.Size(600, 120)
		$No7zip_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$No7zip_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$No7zip_LABEL.Text = "When reading profiles, the directory with the executable file 7z.exe is no longer valid.`nEither the 7zip program has been removed from the PC or the directory where the executable file is located has changed.`nSpecify a new directory with the executable file, or reinstall the 7zip program."
		$No7zip_FORM.Controls.Add($No7zip_LABEL)
		#######################################################################################################
		$No7zip_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$No7zip_TEXTBOX.Location = New-Object System.Drawing.Point(10, 135)
		$No7zip_TEXTBOX.Size = New-Object System.Drawing.Size(560, 30)
		$No7zip_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$No7zip_TEXTBOX.TextAlign = 'Center'
		$No7zip_TEXTBOX.Text = if ([string]::IsNullOrWhiteSpace($Exec7z)) { 'C:\Program Files\' } else { $Exec7z }
		$No7zip_TEXTBOX.ReadOnly = $True
		$No7zip_FORM.Controls.Add($No7zip_TEXTBOX)
		#######################################################################################################
		$No7zip_Directory_BUTTON = New-Object System.Windows.Forms.Button
		$No7zip_Directory_BUTTON.Location = New-Object System.Drawing.Point(575, 135)
		$No7zip_Directory_BUTTON.Size = New-Object System.Drawing.Size(35, 26)
		$No7zip_Directory_BUTTON.Text = '...'
		$No7zip_Directory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$No7zip_Directory_BUTTON.Add_Click({
			$No7zip_Directory_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$No7zip_Directory_BUTTON_directoryname.RootFolder = "MyComputer"
			$No7zip_Directory_BUTTON_directoryname.SelectedPath = "C:\Program Files\"
			if ($No7zip_Directory_BUTTON_directoryname.ShowDialog() -eq "OK") {
				$No7zip_TEXTBOX.Text = "$($No7zip_Directory_BUTTON_directoryname.SelectedPath)\7z.exe"
			}
		})
		$No7zip_FORM.AcceptButton = $No7zip_Directory_BUTTON
		$No7zip_FORM.Controls.Add($No7zip_Directory_BUTTON)
		#######################################################################################################
		$No7zip_OK_BUTTON = New-Object System.Windows.Forms.Button
		$No7zip_OK_BUTTON.Location = New-Object System.Drawing.Point(10, 170)
		$No7zip_OK_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$No7zip_OK_BUTTON.Text = 'OK'
		$No7zip_OK_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$No7zip_OK_BUTTON.Add_Click({
			if (-not (Test-Path -Path $No7zip_TEXTBOX.Text)) {
				ErrorForm -ErrorLabelText "Wrong directory.`nThere are no 7z.exe in directory`n$($No7zip_TEXTBOX.Text|Split-Path -Parent)"
				return
			}
			$ProfileXML = [System.Collections.ArrayList]::new()
			foreach ($profile in $ProfileXmlObject) {
				if ($profile.ProfileName -notin $Profile7zExecCheck) {
					[void]$ProfileXML.Add($profile)
				}
				else {
					$SettingParameters = @{
						ProfileName           = "$($profile.ProfileName)"
						BackupDirectory       = "$($profile.BackupDirectory)"
						Executable_7z         = "$($No7zip_TEXTBOX.Text)"
						SecondBackupDirectory = "$($profile.SecondBackupDirectory)"
						BackupName            = "$($profile.BackupName)"
						Source                = "$($profile.Source)"
						RestoreDirectory      = "$($profile.RestoreDirectory)"
						RestorePoints         = $($profile.RestorePoints)
						BackupDayFilter       = $($profile.BackupDayFilter)
						BackupCheckboxStatus  = $($profile.BackupCheckboxStatus)
						RestoreCheckboxStatus = $($profile.RestoreCheckboxStatus)
						CopyCheckboxStatus    = $($profile.CopyCheckboxStatus)
					}
					[void]$ProfileXML.Add($(settings @SettingParameters))
				}
			}
			$ProfileXML | Export-Clixml -Path ${Running_Folder}\ProfileList.xml
			ErrorForm -ErrorLabelText "The changes are saved. All profiles now have the correct path to the 7zip executable file"
			$No7zip_FORM.Tag = $ProfileXML
			$No7zip_FORM.Close()
		})
		$No7zip_FORM.AcceptButton = $No7zip_OK_BUTTON
		$No7zip_FORM.Controls.Add($No7zip_OK_BUTTON)
		#######################################################################################################
		$No7zip_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$No7zip_Exit_BUTTON.Location = New-Object System.Drawing.Point(510, 170)
		$No7zip_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$No7zip_Exit_BUTTON.Text = 'Exit'
		$No7zip_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$No7zip_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$No7zip_FORM.AcceptButton = $No7zip_Exit_BUTTON
		$No7zip_FORM.Controls.Add($No7zip_Exit_BUTTON)
		######################################################################################################
		$No7zip_FORM.ShowDialog() > $null
		Return ,$No7zip_FORM.Tag
	}

	function BackupMenu {
		param (
			$ProfileXmlObject
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$BackupMenu_FORM = New-Object System.Windows.Forms.Form
		$BackupMenu_FORM.Text = $FormsVariables.FormsText
		$BackupMenu_FORM.Font = $FormsVariables.FormsFont
		$BackupMenu_FORM.BackColor = $FormsVariables.FormsBackColor
		$BackupMenu_FORM.ForeColor = $FormsVariables.FormsForeColor
		$BackupMenu_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$BackupMenu_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$BackupMenu_FORM.ClientSize = New-Object System.Drawing.Size(820, 635)
		#######################################################################################################		
		$BackupMenu_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$BackupMenu_LABEL.Size = New-Object System.Drawing.Size(800, 20)
		$BackupMenu_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 16, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_LABEL.Text = "Please select one of the options below."
		$BackupMenu_FORM.Controls.Add($BackupMenu_LABEL)
		#######################################################################################################
		$BackupMenu_ProfileParameters_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_ProfileParameters_LABEL.Location = New-Object System.Drawing.Point(10, 35)
		$BackupMenu_ProfileParameters_LABEL.Size = New-Object System.Drawing.Size(290, 25)
		$BackupMenu_ProfileParameters_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$BackupMenu_ProfileParameters_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$BackupMenu_ProfileParameters_LABEL.Text = "Profile parameters list"
		$BackupMenu_ProfileParameters_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$BackupMenu_FORM.Controls.Add($BackupMenu_ProfileParameters_LABEL)
		#######################################################################################################
		$BackupMenu_ProfileList_LISTBOX = New-Object System.Windows.Forms.ListBox
		$BackupMenu_ProfileList_LISTBOX.Location = New-Object System.Drawing.Point(10, 67)
		$BackupMenu_ProfileList_LISTBOX.Size = New-Object System.Drawing.Size(290, 236)
		$BackupMenu_ProfileList_LISTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$BackupMenu_ProfileList_LISTBOX.ScrollAlwaysVisible = $true
		$BackupMenu_ProfileList_LISTBOX.HorizontalScrollbar = $true
		$BackupMenu_ProfileList_LISTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_ProfileList_LISTBOX.Add_SelectedIndexChanged({
			BackupMenuButtons -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			[string]$DriveLetter = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)" }).BackupDirectory).split(':')[0]
			if ($BackupMenu_ProfileList_LISTBOX.Tag.Keys -contains "$DriveLetter") {
				$BackupMenu_SpaceLeftOnDisk_LABEL.Text = "There is $($BackupMenu_ProfileList_LISTBOX.Tag[$DriveLetter]) MB of free space left on drive $DriveLetter.`nIf you want to use this script to automate your tasks, below are the commands on how to use this script in the command line or in the task scheduler."
			}
			else {
				$BackupMenu_ProfileList_LISTBOX.Tag += $(DiskVariablesBackup -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)")
			}
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_ProfileList_LISTBOX)
		#######################################################################################################
		$BackupMenu_SimpleBackup_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SimpleBackup_BUTTON.Location = New-Object System.Drawing.Point(305, 35)
		$BackupMenu_SimpleBackup_BUTTON.Size = New-Object System.Drawing.Size(150, 60)
		$BackupMenu_SimpleBackup_BUTTON.Text = 'Simple Backup Job'
		$BackupMenu_SimpleBackup_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleBackup_BUTTON.Enabled = $false
		$BackupMenu_SimpleBackup_BUTTON.Add_Click({
			LogForm -LogFormJob "SimpleBackup_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			DiskVariablesBackup -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			$BackupMenu_ProfileList_LISTBOX.Tag = $null
		})
		$BackupMenu_FORM.AcceptButton = $BackupMenu_SimpleBackup_BUTTON
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleBackup_BUTTON)
		######################################################################################################
		$BackupMenu_SimpleBackup_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_SimpleBackup_LABEL.Location = New-Object System.Drawing.Point(460, 35)
		$BackupMenu_SimpleBackup_LABEL.Size = New-Object System.Drawing.Size(350, 60)
		$BackupMenu_SimpleBackup_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleBackup_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleBackup_LABEL.Text = "This job archives files from the source directory into a compressed format and stores them in the destination directory"
		$BackupMenu_SimpleBackup_LABEL.BorderStyle = "FixedSingle"
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleBackup_LABEL)
		#######################################################################################################
		$BackupMenu_TimeFiltredBackup_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_TimeFiltredBackup_BUTTON.Location = New-Object System.Drawing.Point(305, 100)
		$BackupMenu_TimeFiltredBackup_BUTTON.Size = New-Object System.Drawing.Size(150, 60)
		$BackupMenu_TimeFiltredBackup_BUTTON.Text = 'Time Filtred Backup Job'
		$BackupMenu_TimeFiltredBackup_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_TimeFiltredBackup_BUTTON.Enabled = $false
		$BackupMenu_TimeFiltredBackup_BUTTON.Add_Click({
			LogForm -LogFormJob "TimeFilteredBackup_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			DiskVariablesBackup -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			$BackupMenu_ProfileList_LISTBOX.Tag = $null
		})
		$BackupMenu_FORM.AcceptButton = $BackupMenu_TimeFiltredBackup_BUTTON
		$BackupMenu_FORM.Controls.Add($BackupMenu_TimeFiltredBackup_BUTTON)
		######################################################################################################
		$BackupMenu_TimeFiltredBackup_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_TimeFiltredBackup_LABEL.Location = New-Object System.Drawing.Point(460, 100)
		$BackupMenu_TimeFiltredBackup_LABEL.Size = New-Object System.Drawing.Size(350, 60)
		$BackupMenu_TimeFiltredBackup_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_TimeFiltredBackup_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_TimeFiltredBackup_LABEL.Text = "This backup job includes only files modified in the last $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)" }).BackupDayFilter) days. (According to your settings)"
		$BackupMenu_TimeFiltredBackup_LABEL.BorderStyle = "FixedSingle"
		$BackupMenu_FORM.Controls.Add($BackupMenu_TimeFiltredBackup_LABEL)
		#######################################################################################################
		$BackupMenu_SimpleCopy_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SimpleCopy_BUTTON.Location = New-Object System.Drawing.Point(305, 165)
		$BackupMenu_SimpleCopy_BUTTON.Size = New-Object System.Drawing.Size(150, 60)
		$BackupMenu_SimpleCopy_BUTTON.Text = 'Copy File Job'
		$BackupMenu_SimpleCopy_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleCopy_BUTTON.Enabled = $false
		$BackupMenu_SimpleCopy_BUTTON.Add_Click({
			LogForm -LogFormJob "CopyFile_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			DiskVariablesBackup -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			$BackupMenu_ProfileList_LISTBOX.Tag = $null
		})
		$BackupMenu_FORM.AcceptButton = $BackupMenu_SimpleCopy_BUTTON
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleCopy_BUTTON)
		######################################################################################################
		$BackupMenu_SimpleCopy_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_SimpleCopy_LABEL.Location = New-Object System.Drawing.Point(460, 165)
		$BackupMenu_SimpleCopy_LABEL.Size = New-Object System.Drawing.Size(350, 60)
		$BackupMenu_SimpleCopy_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleCopy_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleCopy_LABEL.Text = "This job copies files from the source directory to the destination directory incrementally."
		$BackupMenu_SimpleCopy_LABEL.BorderStyle = "FixedSingle"
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleCopy_LABEL)
		#######################################################################################################
		$BackupMenu_Sync_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_Sync_BUTTON.Location = New-Object System.Drawing.Point(305, 230)
		$BackupMenu_Sync_BUTTON.Size = New-Object System.Drawing.Size(150, 60)
		$BackupMenu_Sync_BUTTON.Text = 'Sync Job'
		$BackupMenu_Sync_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_Sync_BUTTON.Enabled = $false
		$BackupMenu_Sync_BUTTON.Add_Click({
			LogForm -LogFormJob "Sync_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			DiskVariablesBackup -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"
			$BackupMenu_ProfileList_LISTBOX.Tag = $null
		})
		$BackupMenu_FORM.AcceptButton = $BackupMenu_Sync_BUTTON
		$BackupMenu_FORM.Controls.Add($BackupMenu_Sync_BUTTON)
		######################################################################################################
		$BackupMenu_Sync_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_Sync_LABEL.Location = New-Object System.Drawing.Point(460, 230)
		$BackupMenu_Sync_LABEL.Size = New-Object System.Drawing.Size(350, 60)
		$BackupMenu_Sync_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_Sync_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_Sync_LABEL.Text = "This job synchronizes files from the source directory to the destination directory."
		$BackupMenu_Sync_LABEL.BorderStyle = "FixedSingle"
		$BackupMenu_FORM.Controls.Add($BackupMenu_Sync_LABEL)
		######################################################################################################
		$BackupMenu_Source_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_Source_LABEL.Location = New-Object System.Drawing.Point(10, 295)
		$BackupMenu_Source_LABEL.Size = New-Object System.Drawing.Size(745, 20)
		$BackupMenu_Source_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_Source_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_Source_LABEL.Text = "Source directory (file)"
		$BackupMenu_FORM.Controls.Add($BackupMenu_Source_LABEL)
		#######################################################################################################
		$BackupMenu_Source_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_Source_TEXTBOX.Location = New-Object System.Drawing.Point(10, 320)
		$BackupMenu_Source_TEXTBOX.Size = New-Object System.Drawing.Size(745, 25)
		$BackupMenu_Source_TEXTBOX.Text = ""
		$BackupMenu_Source_TEXTBOX.Name = "BackupMenu_Source_TEXTBOX"
		$BackupMenu_Source_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_Source_TEXTBOX.ReadOnly = $true
		$BackupMenu_FORM.Controls.Add($BackupMenu_Source_TEXTBOX)
		#######################################################################################################
		$BackupMenu_Source_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_Source_BUTTON.Location = New-Object System.Drawing.Point(760, 320)
		$BackupMenu_Source_BUTTON.Size = New-Object System.Drawing.Size(50, 26)
		$BackupMenu_Source_BUTTON.Text = "..."
		$BackupMenu_Source_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_Source_BUTTON.Enabled = $false
		$BackupMenu_Source_BUTTON.Add_Click({
			$Source = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)"}).Source)"
			if ($Source[-1] -eq '\') {
				Invoke-Item -Path "$Source"
			}
			else {
				Invoke-Item -Path "$(Split-Path $Source -Parent)"
			}
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_Source_BUTTON)
		######################################################################################################
		$BackupMenu_FirstDestination_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_FirstDestination_LABEL.Location = New-Object System.Drawing.Point(10, 350)
		$BackupMenu_FirstDestination_LABEL.Size = New-Object System.Drawing.Size(342, 20)
		$BackupMenu_FirstDestination_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_FirstDestination_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_FirstDestination_LABEL.Text = "First backup directory:"
		$BackupMenu_FORM.Controls.Add($BackupMenu_FirstDestination_LABEL)
		#######################################################################################################	
		$BackupMenu_FirstDestination_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_FirstDestination_TEXTBOX.Location = New-Object System.Drawing.Point(10, 375)
		$BackupMenu_FirstDestination_TEXTBOX.Size = New-Object System.Drawing.Size(342, 25)
		$BackupMenu_FirstDestination_TEXTBOX.Text = ""
		$BackupMenu_FirstDestination_TEXTBOX.Name = "BackupMenu_FirstDestination_TEXTBOX"
		$BackupMenu_FirstDestination_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_FirstDestination_TEXTBOX.ReadOnly = $true
		$BackupMenu_FORM.Controls.Add($BackupMenu_FirstDestination_TEXTBOX)
		#######################################################################################################
		$BackupMenu_FirstDestination_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_FirstDestination_BUTTON.Location = New-Object System.Drawing.Point(357, 375)
		$BackupMenu_FirstDestination_BUTTON.Size = New-Object System.Drawing.Size(50, 26)
		$BackupMenu_FirstDestination_BUTTON.Text = "..."
		$BackupMenu_FirstDestination_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_FirstDestination_BUTTON.Enabled = $false
		$BackupMenu_FirstDestination_BUTTON.Add_Click({
			$BackupDirectory = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)" }).BackupDirectory
			Invoke-Item -Path "$BackupDirectory"
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_FirstDestination_BUTTON)
		######################################################################################################
		$BackupMenu_SecondDestination_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_SecondDestination_LABEL.Location = New-Object System.Drawing.Point(413, 350)
		$BackupMenu_SecondDestination_LABEL.Size = New-Object System.Drawing.Size(342, 20)
		$BackupMenu_SecondDestination_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SecondDestination_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SecondDestination_LABEL.Text = "Second Backup directory:"
		$BackupMenu_FORM.Controls.Add($BackupMenu_SecondDestination_LABEL)
		#######################################################################################################	
		$BackupMenu_SecondDestination_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_SecondDestination_TEXTBOX.Location = New-Object System.Drawing.Point(413, 375)
		$BackupMenu_SecondDestination_TEXTBOX.Size = New-Object System.Drawing.Size(342, 25)
		$BackupMenu_SecondDestination_TEXTBOX.Text = ""
		$BackupMenu_SecondDestination_TEXTBOX.Name = "BackupMenu_SecondDestination_TEXTBOX"
		$BackupMenu_SecondDestination_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SecondDestination_TEXTBOX.ReadOnly = $true
		$BackupMenu_FORM.Controls.Add($BackupMenu_SecondDestination_TEXTBOX)
		#######################################################################################################
		$BackupMenu_SecondDestination_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SecondDestination_BUTTON.Location = New-Object System.Drawing.Point(760, 375)
		$BackupMenu_SecondDestination_BUTTON.Size = New-Object System.Drawing.Size(50, 26)
		$BackupMenu_SecondDestination_BUTTON.Text = "..."
		$BackupMenu_SecondDestination_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SecondDestination_BUTTON.Enabled = $false
		$BackupMenu_SecondDestination_BUTTON.Add_Click({
			$SecondBackupDirectory = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($BackupMenu_ProfileList_LISTBOX.SelectedItem)" }).SecondBackupDirectory
			Invoke-Item -Path "$SecondBackupDirectory"
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_SecondDestination_BUTTON)
		######################################################################################################
		$BackupMenu_SpaceLeftOnDisk_LABEL = New-Object System.Windows.Forms.Label
		$BackupMenu_SpaceLeftOnDisk_LABEL.Location = New-Object System.Drawing.Point(10, 405)
		$BackupMenu_SpaceLeftOnDisk_LABEL.Size = New-Object System.Drawing.Size(800, 60)
		$BackupMenu_SpaceLeftOnDisk_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SpaceLeftOnDisk_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SpaceLeftOnDisk_LABEL.Text = "There is __ MB of free space left on drive __.`nIf you want to use this script to automate your tasks, below are the commands on how to use this script in the command line or in the task scheduler."
		$BackupMenu_FORM.Controls.Add($BackupMenu_SpaceLeftOnDisk_LABEL)
		#######################################################################################################
		$BackupMenu_SimpleBackupCMDString_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Location = New-Object System.Drawing.Point(10, 470)
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Size = New-Object System.Drawing.Size(670, 25)
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Text = "The Backup checkbox for this profile is disabled"
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Name = "BackupMenu_SimpleBackupCMDString_TEXTBOX"
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.ReadOnly = $true
		$BackupMenu_SimpleBackupCMDString_TEXTBOX.Enabled = $false
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleBackupCMDString_TEXTBOX)
		#######################################################################################################
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Location = New-Object System.Drawing.Point(690, 470)
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Size = New-Object System.Drawing.Size(125, 22)
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Text = "Copy to clipboard"
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Font = New-Object System.Drawing.Font("Cascadia Mono", 8, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Enabled = $false
		$BackupMenu_SimpleBackupCMDStringClipboard_BUTTON.Add_Click({
			Set-Clipboard -Value $BackupMenu_SimpleBackupCMDString_TEXTBOX.Text
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleBackupCMDStringClipboard_BUTTON)
		#######################################################################################################
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Location = New-Object System.Drawing.Point(10, 500)
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Size = New-Object System.Drawing.Size(670, 25)
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Text = "The Backup checkbox for this profile is disabled"
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Name = "BackupMenu_TimeFiltredBackupCMDString_TEXTBOX"
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.ReadOnly = $true
		$BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Enabled = $false
		$BackupMenu_FORM.Controls.Add($BackupMenu_TimeFiltredBackupCMDString_TEXTBOX)
		#######################################################################################################
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Location = New-Object System.Drawing.Point(690, 500)
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Size = New-Object System.Drawing.Size(125, 22)
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Text = "Copy to clipboard"
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Font = New-Object System.Drawing.Font("Cascadia Mono", 8, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Enabled = $false
		$BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON.Add_Click({
			Set-Clipboard -Value $BackupMenu_TimeFiltredBackupCMDString_TEXTBOX.Text
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_TimeFiltredBackupCMDStringClipboard_BUTTON)
		#######################################################################################################
		$BackupMenu_SimpleCopyCMDString_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Location = New-Object System.Drawing.Point(10, 530)
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Size = New-Object System.Drawing.Size(670, 25)
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Text = "The Copy checkbox for this profile is disabled"
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Name = "BackupMenu_SimpleCopyCMDString_TEXTBOX"
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.ReadOnly = $true
		$BackupMenu_SimpleCopyCMDString_TEXTBOX.Enabled = $false
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleCopyCMDString_TEXTBOX)
		#######################################################################################################
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Location = New-Object System.Drawing.Point(690, 530)
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Size = New-Object System.Drawing.Size(125, 22)
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Text = "Copy to clipboard"
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Font = New-Object System.Drawing.Font("Cascadia Mono", 8, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Enabled = $false
		$BackupMenu_SimpleCopyCMDStringClipboard_BUTTON.Add_Click({
			Set-Clipboard -Value $BackupMenu_SimpleCopyCMDString_TEXTBOX.Text
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_SimpleCopyCMDStringClipboard_BUTTON)
		#######################################################################################################
		$BackupMenu_SyncCMDString_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$BackupMenu_SyncCMDString_TEXTBOX.Location = New-Object System.Drawing.Point(10, 560)
		$BackupMenu_SyncCMDString_TEXTBOX.Size = New-Object System.Drawing.Size(670, 25)
		$BackupMenu_SyncCMDString_TEXTBOX.Text = "The Copy checkbox for this profile is disabled"
		$BackupMenu_SyncCMDString_TEXTBOX.Name = "BackupMenu_SyncCMDString_TEXTBOX"
		$BackupMenu_SyncCMDString_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SyncCMDString_TEXTBOX.ReadOnly = $true
		$BackupMenu_SyncCMDString_TEXTBOX.Enabled = $false
		$BackupMenu_FORM.Controls.Add($BackupMenu_SyncCMDString_TEXTBOX)
		#######################################################################################################
		$BackupMenu_SyncCMDStringClipboard_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Location = New-Object System.Drawing.Point(690, 560)
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Size = New-Object System.Drawing.Size(125, 22)
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Text = "Copy to clipboard"
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Font = New-Object System.Drawing.Font("Cascadia Mono", 8, [System.Drawing.FontStyle]::Regular)
		$BackupMenu_SyncCMDStringClipboard_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Enabled = $false
		$BackupMenu_SyncCMDStringClipboard_BUTTON.Add_Click({
			Set-Clipboard -Value $BackupMenu_SyncCMDString_TEXTBOX.Text
		})
		$BackupMenu_FORM.Controls.Add($BackupMenu_SyncCMDStringClipboard_BUTTON)
		#######################################################################################################
		$BackupMenu_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$BackupMenu_Exit_BUTTON.Location = New-Object System.Drawing.Point(350, 590)
		$BackupMenu_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$BackupMenu_Exit_BUTTON.Text = 'Exit'
		$BackupMenu_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$BackupMenu_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$BackupMenu_FORM.AcceptButton = $BackupMenu_Exit_BUTTON
		$BackupMenu_FORM.Controls.Add($BackupMenu_Exit_BUTTON)
		######################################################################################################
		ListFiller -ProfileXmlObject $ProfileXmlObject -Menu 'BackupMenu'
		$BackupMenu_FORM.ShowDialog() > $null
	}

	function RestoreMenuList {
		param (
			$ProfileXmlObject,
			$RestoreMenuListObjects,
			[string]$RestoreMenuButton
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$RestoreMenuList_FORM = New-Object System.Windows.Forms.Form
		$RestoreMenuList_FORM.Text = $FormsVariables.FormsText
		$RestoreMenuList_FORM.Font = $FormsVariables.FormsFont
		$RestoreMenuList_FORM.BackColor = $FormsVariables.FormsBackColor
		$RestoreMenuList_FORM.ForeColor = $FormsVariables.FormsForeColor
		$RestoreMenuList_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$RestoreMenuList_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$RestoreMenuList_FORM.ClientSize = New-Object System.Drawing.Size(580, 245)
		#######################################################################################################
		$RestoreMenuList_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenuList_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$RestoreMenuList_LABEL.Size = New-Object System.Drawing.Size(560, 40)
		$RestoreMenuList_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenuList_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenuList_LABEL.Text = "Select one backup from the list that you want to restore and click OK to start the recovery process"
		$RestoreMenuList_FORM.Controls.Add($RestoreMenuList_LABEL)
		######################################################################################################
		$RestoreMenuList_List_LISTBOX = New-Object System.Windows.Forms.ListBox
		$RestoreMenuList_List_LISTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$RestoreMenuList_List_LISTBOX.FormattingEnabled = $true
		$RestoreMenuList_List_LISTBOX.Location = New-Object System.Drawing.Point(10, 55)
		$RestoreMenuList_List_LISTBOX.ScrollAlwaysVisible = $true
		$RestoreMenuList_List_LISTBOX.HorizontalScrollbar = $true
		$RestoreMenuList_List_LISTBOX.Size = New-Object System.Drawing.Size(560, 140)
		$RestoreMenuList_List_LISTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$RestoreMenuList_List_LISTBOX.Add_SelectedIndexChanged({
			if ($RestoreMenuList_List_LISTBOX.SelectedItem) {
				$RestoreMenuList_OK_BUTTON.Enabled = $true
			}
		})
		$RestoreMenuList_FORM.Controls.Add($RestoreMenuList_List_LISTBOX)
		#######################################################################################################
		$RestoreMenuList_OK_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenuList_OK_BUTTON.Location = New-Object System.Drawing.Point(10, 200)
		$RestoreMenuList_OK_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$RestoreMenuList_OK_BUTTON.Text = 'OK'
		$RestoreMenuList_OK_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenuList_OK_BUTTON.Enabled = $false
		$RestoreMenuList_OK_BUTTON.Add_Click({
			if ($RestoreMenuButton -eq "ClassicRestore") {
				LogForm -LogFormJob "Restore_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)" -SelectedBackup $RestoreMenuList_List_LISTBOX.SelectedItem
				DiskVariablesRestore -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)"
				$RestoreMenu_ProfileList_LISTBOX.Tag = $null
			}
			elseif ($RestoreMenuButton -eq "RestoreAfterDisaster") {
				LogForm -LogFormJob "Restore_Job" -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)" -SelectedBackup $RestoreMenuList_List_LISTBOX.SelectedItem
				DiskVariablesRestore -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)"
				$RestoreMenu_ProfileList_LISTBOX.Tag = $null
			}
		})
		$RestoreMenuList_FORM.AcceptButton = $RestoreMenuList_OK_BUTTON
		$RestoreMenuList_FORM.Controls.Add($RestoreMenuList_OK_BUTTON)
		#######################################################################################################
		$RestoreMenuList_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenuList_Exit_BUTTON.Location = New-Object System.Drawing.Point(470, 200)
		$RestoreMenuList_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$RestoreMenuList_Exit_BUTTON.Text = 'Exit'
		$RestoreMenuList_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenuList_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$RestoreMenuList_FORM.AcceptButton = $RestoreMenuList_Exit_BUTTON
		$RestoreMenuList_FORM.Controls.Add($RestoreMenuList_Exit_BUTTON)
		######################################################################################################
		ListFiller -RestoreMenuListObjects $RestoreMenuListObjects -Menu 'RestoreMenuList'
		$RestoreMenuList_FORM.ShowDialog() > $null
	}

	function RestoreMenu {
		param (
			$ProfileXmlObject
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$RestoreMenu_FORM = New-Object System.Windows.Forms.Form
		$RestoreMenu_FORM.Text = $FormsVariables.FormsText
		$RestoreMenu_FORM.Font = $FormsVariables.FormsFont
		$RestoreMenu_FORM.BackColor = $FormsVariables.FormsBackColor
		$RestoreMenu_FORM.ForeColor = $FormsVariables.FormsForeColor
		$RestoreMenu_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$RestoreMenu_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$RestoreMenu_FORM.ClientSize = New-Object System.Drawing.Size(820, 400)
		#######################################################################################################
		$RestoreMenu_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$RestoreMenu_LABEL.Size = New-Object System.Drawing.Size(790, 25)
		$RestoreMenu_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_LABEL.Text = "Select one of the options below"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_LABEL)
		#######################################################################################################
		$RestoreMenu_CheckBox_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$RestoreMenu_CheckBox_CHECKBOX.Checked = $true
		$RestoreMenu_CheckBox_CHECKBOX.CheckState = [System.Windows.Forms.CheckState]::Checked
		$RestoreMenu_CheckBox_CHECKBOX.Location = New-Object System.Drawing.Point(140, 35)
		$RestoreMenu_CheckBox_CHECKBOX.Size = New-Object System.Drawing.Size(660, 30)
		$RestoreMenu_CheckBox_CHECKBOX.Text = "Make a backup before restoring an archive copy?"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_CheckBox_CHECKBOX)
		#######################################################################################################
		$RestoreMenu_ProfileParameters_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_ProfileParameters_LABEL.Location = New-Object System.Drawing.Point(10, 70)
		$RestoreMenu_ProfileParameters_LABEL.Size = New-Object System.Drawing.Size(280, 25)
		$RestoreMenu_ProfileParameters_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$RestoreMenu_ProfileParameters_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$RestoreMenu_ProfileParameters_LABEL.Text = "Profile parameters list"
		$RestoreMenu_ProfileParameters_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_ProfileParameters_LABEL)
		#######################################################################################################
		$RestoreMenu_ProfileList_LISTBOX = New-Object System.Windows.Forms.ListBox
		$RestoreMenu_ProfileList_LISTBOX.Location = New-Object System.Drawing.Point(10, 100)
		$RestoreMenu_ProfileList_LISTBOX.Size = New-Object System.Drawing.Size(280, 236)
		$RestoreMenu_ProfileList_LISTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$RestoreMenu_ProfileList_LISTBOX.ScrollAlwaysVisible = $true
		$RestoreMenu_ProfileList_LISTBOX.HorizontalScrollbar = $true
		$RestoreMenu_ProfileList_LISTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_ProfileList_LISTBOX.Add_SelectedIndexChanged({
			RestoreMenuButtons -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)"
			[string]$DriveLetter = $(($ProfileXmlObject | Where-Object { $_.ProfileName -eq "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)" }).RestoreDirectory).split(':')[0]
			if ($RestoreMenu_ProfileList_LISTBOX.Tag.Keys -contains "$DriveLetter") {
				$RestoreMenu_SpaceLeftOnDisk_LABEL.Text = "There is $($RestoreMenu_ProfileList_LISTBOX.Tag[$DriveLetter]) MB of free space left on drive $DriveLetter."
			}
			else {
				$RestoreMenu_ProfileList_LISTBOX.Tag += $(DiskVariablesRestore -ProfileXmlObject $ProfileXmlObject -SelectedProfile "$($RestoreMenu_ProfileList_LISTBOX.SelectedItem)")
			}
		})
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_ProfileList_LISTBOX)
		#######################################################################################################
		$RestoreMenu_ClassicRestore_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenu_ClassicRestore_BUTTON.Location = New-Object System.Drawing.Point(295, 70)
		$RestoreMenu_ClassicRestore_BUTTON.Size = New-Object System.Drawing.Size(160, 65)
		$RestoreMenu_ClassicRestore_BUTTON.Text = 'Restore Job 1'
		$RestoreMenu_ClassicRestore_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_ClassicRestore_BUTTON.Add_Click({
			$SelectedBackupDir = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).BackupDirectory
			$SelectedBackupName = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).BackupName
			$ListWithPath = -join ($SelectedBackupDir, $SelectedBackupName)
			if (Test-Path "${ListWithPath}*") {
				$RestoreMenuListObjects = $(Get-ChildItem "${ListWithPath}*" -Filter "*.7z" | Sort-Object LastWriteTime -Descending).FullName
			} 
			RestoreMenuList -ProfileXmlObject $ProfileXmlObject -RestoreMenuListObjects $RestoreMenuListObjects -RestoreMenuButton 'ClassicRestore'
		})
		$RestoreMenu_ClassicRestore_BUTTON.Enabled = $false
		$RestoreMenu_FORM.AcceptButton = $RestoreMenu_ClassicRestore_BUTTON
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_ClassicRestore_BUTTON)
		######################################################################################################
		$RestoreMenu_ClassicRestore_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_ClassicRestore_LABEL.Location = New-Object System.Drawing.Point(460, 70)
		$RestoreMenu_ClassicRestore_LABEL.Size = New-Object System.Drawing.Size(350, 65)
		$RestoreMenu_ClassicRestore_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_ClassicRestore_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_ClassicRestore_LABEL.Text = "This Job allows you to recover files from an archive that was created during the Backup Job"
		$RestoreMenu_ClassicRestore_LABEL.BorderStyle = "FixedSingle"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_ClassicRestore_LABEL)
		#######################################################################################################
		$RestoreMenu_RestoreAfterDisaster_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenu_RestoreAfterDisaster_BUTTON.Location = New-Object System.Drawing.Point(295, 140)
		$RestoreMenu_RestoreAfterDisaster_BUTTON.Size = New-Object System.Drawing.Size(160, 65)
		$RestoreMenu_RestoreAfterDisaster_BUTTON.Text = "Restore Job 2"
		$RestoreMenu_RestoreAfterDisaster_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_RestoreAfterDisaster_BUTTON.Add_Click({
			$BackupBeforeRestoreDir = "Backups_before_restore\"
			$SelectedBackupDir = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).BackupDirectory
			$BackupCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).BackupCheckboxStatus
			$RestoreCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).RestoreCheckboxStatus
			$CopyCheckboxStatus = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).CopyCheckboxStatus
			if (-not $BackupCheckboxStatus -and -not $CopyCheckboxStatus -and $RestoreCheckboxStatus) {
				$SelectedBackupName = ''
			}
			else {
				$SelectedBackupName = $RestoreMenu_ProfileList_LISTBOX.SelectedItem
			}
			$ListWithPath = -join ($SelectedBackupDir, $BackupBeforeRestoreDir, $SelectedBackupName)
			if (Test-Path "${ListWithPath}*") {
				$RestoreMenuListObjects = $(Get-ChildItem "${ListWithPath}*" -Filter "*.7z" | Sort-Object LastWriteTime -Descending).FullName
			}
			RestoreMenuList -ProfileXmlObject $ProfileXmlObject -RestoreMenuListObjects $RestoreMenuListObjects -RestoreMenuButton 'RestoreAfterDisaster'
		})
		$RestoreMenu_RestoreAfterDisaster_BUTTON.Enabled = $false
		$RestoreMenu_FORM.AcceptButton = $RestoreMenu_RestoreAfterDisaster_BUTTON
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_RestoreAfterDisaster_BUTTON)
		######################################################################################################
		$RestoreMenu_RestoreAfterDisaster_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_RestoreAfterDisaster_LABEL.Location = New-Object System.Drawing.Point(460, 140)
		$RestoreMenu_RestoreAfterDisaster_LABEL.Size = New-Object System.Drawing.Size(350, 65)
		$RestoreMenu_RestoreAfterDisaster_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_RestoreAfterDisaster_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_RestoreAfterDisaster_LABEL.Text = "This button restores the backups created in Restore Jobs, if the `'Make a backup before restoring an archive copy?`' check box was selected."
		$RestoreMenu_RestoreAfterDisaster_LABEL.BorderStyle = "FixedSingle"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_RestoreAfterDisaster_LABEL)
		######################################################################################################
		$RestoreMenu_DestinationRestoreDirectory_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_DestinationRestoreDirectory_LABEL.Location = New-Object System.Drawing.Point(295, 210)
		$RestoreMenu_DestinationRestoreDirectory_LABEL.Size = New-Object System.Drawing.Size(460, 20)
		$RestoreMenu_DestinationRestoreDirectory_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_DestinationRestoreDirectory_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_DestinationRestoreDirectory_LABEL.Text = "Recovery directory"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_DestinationRestoreDirectory_LABEL)
		#######################################################################################################	
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Location = New-Object System.Drawing.Point(295, 240)
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Size = New-Object System.Drawing.Size(460, 30)
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Text = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq $ProfileXmlObject.SelectedProfile}).RestoreDirectory)"
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Name = 'RestoreMenu_DestinationRestoreDirectory_TEXTBOX'
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.ReadOnly = $true
		$RestoreMenu_DestinationRestoreDirectory_TEXTBOX.Enabled = $false
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_DestinationRestoreDirectory_TEXTBOX)
		#######################################################################################################
		$RestoreMenu_DestinationRestoreDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.Location = New-Object System.Drawing.Point(760, 240)
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.Size = New-Object System.Drawing.Size(50, 27)
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.Text = "..."
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.Enabled = $false
		$RestoreMenu_DestinationRestoreDirectory_BUTTON.Add_Click({
			$RestoreDirectory = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).RestoreDirectory
			Invoke-Item -Path "$RestoreDirectory"
		})
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_DestinationRestoreDirectory_BUTTON)
		######################################################################################################
		$RestoreMenu_SourceBackupDirectory_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_SourceBackupDirectory_LABEL.Location = New-Object System.Drawing.Point(295, 272)
		$RestoreMenu_SourceBackupDirectory_LABEL.Size = New-Object System.Drawing.Size(460, 20)
		$RestoreMenu_SourceBackupDirectory_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_SourceBackupDirectory_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_SourceBackupDirectory_LABEL.Text = "Backup Directory"
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_SourceBackupDirectory_LABEL)
		#######################################################################################################	
		$RestoreMenu_SourceBackupDirectory_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Location = New-Object System.Drawing.Point(295, 297)
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Size = New-Object System.Drawing.Size(460, 30)
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Text = "$(($ProfileXmlObject|Where-Object {$_.ProfileName -eq $ProfileXmlObject.SelectedProfile}).BackupDirectory)"
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Name = 'RestoreMenu_SourceBackupDirectory_TEXTBOX'
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.ReadOnly = $true
		$RestoreMenu_SourceBackupDirectory_TEXTBOX.Enabled = $false
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_SourceBackupDirectory_TEXTBOX)
		#######################################################################################################
		$RestoreMenu_SourceBackupDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenu_SourceBackupDirectory_BUTTON.Location = New-Object System.Drawing.Point(760, 297)
		$RestoreMenu_SourceBackupDirectory_BUTTON.Size = New-Object System.Drawing.Size(50, 27)
		$RestoreMenu_SourceBackupDirectory_BUTTON.Text = "..."
		$RestoreMenu_SourceBackupDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_SourceBackupDirectory_BUTTON.Enabled = $false
		$RestoreMenu_SourceBackupDirectory_BUTTON.Add_Click({
			$BackupDirectory = ($ProfileXmlObject | Where-Object { $_.ProfileName -eq $RestoreMenu_ProfileList_LISTBOX.SelectedItem }).BackupDirectory
			Invoke-Item -Path "$BackupDirectory"
		})
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_SourceBackupDirectory_BUTTON)
		######################################################################################################
		$RestoreMenu_SpaceLeftOnDisk_LABEL = New-Object System.Windows.Forms.Label
		$RestoreMenu_SpaceLeftOnDisk_LABEL.Location = New-Object System.Drawing.Point(10, 330)
		$RestoreMenu_SpaceLeftOnDisk_LABEL.Size = New-Object System.Drawing.Size(790, 20)
		$RestoreMenu_SpaceLeftOnDisk_LABEL.Font = New-Object System.Drawing.Font("Cascadia Mono", 12, [System.Drawing.FontStyle]::Regular)
		$RestoreMenu_SpaceLeftOnDisk_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_SpaceLeftOnDisk_LABEL.Text = "There is __ MB of free space left on drive __."
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_SpaceLeftOnDisk_LABEL)
		#######################################################################################################
		$RestoreMenu_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$RestoreMenu_Exit_BUTTON.Location = New-Object System.Drawing.Point(350, 355)
		$RestoreMenu_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$RestoreMenu_Exit_BUTTON.Text = 'Exit'
		$RestoreMenu_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$RestoreMenu_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$RestoreMenu_FORM.AcceptButton = $RestoreMenu_Exit_BUTTON
		$RestoreMenu_FORM.Controls.Add($RestoreMenu_Exit_BUTTON)
		######################################################################################################
		ListFiller -ProfileXmlObject $ProfileXmlObject -Menu 'RestoreMenu'
		$RestoreMenu_FORM.ShowDialog() > $null
	}

	function ProfileMenu {
		param (
			$ProfileXmlObject
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$ProfileMenu_FORM = New-Object System.Windows.Forms.Form
		$ProfileMenu_FORM.Text = $FormsVariables.FormsText
		$ProfileMenu_FORM.Font = $FormsVariables.FormsFont
		$ProfileMenu_FORM.BackColor = $FormsVariables.FormsBackColor
		$ProfileMenu_FORM.ForeColor = $FormsVariables.FormsForeColor
		$ProfileMenu_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$ProfileMenu_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$ProfileMenu_FORM.ClientSize = New-Object System.Drawing.Size(630, 373)
		$ProfileMenu_FORM.Tag = $ProfileXmlObject
		#######################################################################################################
		$ProfileMenu_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_LABEL.Location = New-Object System.Drawing.Point(0, 5)
		$ProfileMenu_LABEL.Size = New-Object System.Drawing.Size(630, 30)
		$ProfileMenu_LABEL.Text = "Profile configuration window"
		$ProfileMenu_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileList_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_ProfileList_LABEL.Location = New-Object System.Drawing.Point(10, 40)
		$ProfileMenu_ProfileList_LABEL.Size = New-Object System.Drawing.Size(305, 25)
		$ProfileMenu_ProfileList_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$ProfileMenu_ProfileList_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$ProfileMenu_ProfileList_LABEL.Text = "Profiles List"
		$ProfileMenu_ProfileList_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileList_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileParameters_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_ProfileParameters_LABEL.Location = New-Object System.Drawing.Point(320, 40)
		$ProfileMenu_ProfileParameters_LABEL.Size = New-Object System.Drawing.Size(300, 25)
		$ProfileMenu_ProfileParameters_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$ProfileMenu_ProfileParameters_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$ProfileMenu_ProfileParameters_LABEL.Text = "Profile parameters list"
		$ProfileMenu_ProfileParameters_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameters_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileList_LISTBOX = New-Object System.Windows.Forms.ListBox
		$ProfileMenu_ProfileList_LISTBOX.Location = New-Object System.Drawing.Point(10, 70)
		$ProfileMenu_ProfileList_LISTBOX.Size = New-Object System.Drawing.Size(305, 236)
		$ProfileMenu_ProfileList_LISTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$ProfileMenu_ProfileList_LISTBOX.ScrollAlwaysVisible = $true
		$ProfileMenu_ProfileList_LISTBOX.HorizontalScrollbar = $true
		$ProfileMenu_ProfileList_LISTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_ProfileList_LISTBOX.Add_SelectedIndexChanged({
			ProfileMenuProfileParametersList -ProfileXmlObject $ProfileXmlObject
			ProfileMenuButtonsActive
		})
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileList_LISTBOX)
		#######################################################################################################
		$ProfileMenu_ProfileParameterBackup_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$ProfileMenu_ProfileParameterBackup_CHECKBOX.Location = New-Object System.Drawing.Point(320, 70)
		$ProfileMenu_ProfileParameterBackup_CHECKBOX.Size = New-Object System.Drawing.Size(20, 30)
		$ProfileMenu_ProfileParameterBackup_CHECKBOX.Checked = $false
		$ProfileMenu_ProfileParameterBackup_CHECKBOX.Enabled = $false
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterBackup_CHECKBOX)
		#######################################################################################################
		$ProfileMenu_ProfileParameterBackup_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_ProfileParameterBackup_LABEL.Location = New-Object System.Drawing.Point(340, 70)
		$ProfileMenu_ProfileParameterBackup_LABEL.Size = New-Object System.Drawing.Size(120, 30)
		$ProfileMenu_ProfileParameterBackup_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$ProfileMenu_ProfileParameterBackup_LABEL.Text = "Backup function"
		$ProfileMenu_ProfileParameterBackup_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterBackup_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileParameterRestore_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.Location = New-Object System.Drawing.Point(470, 70)
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.Size = New-Object System.Drawing.Size(20, 30)
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.Checked = $false
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.CheckState = [System.Windows.Forms.CheckState]::Unchecked
		$ProfileMenu_ProfileParameterRestore_CHECKBOX.Enabled = $false
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterRestore_CHECKBOX)
		#######################################################################################################
		$ProfileMenu_ProfileParameterRestore_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_ProfileParameterRestore_LABEL.Location = New-Object System.Drawing.Point(490, 70)
		$ProfileMenu_ProfileParameterRestore_LABEL.Size = New-Object System.Drawing.Size(120, 30)
		$ProfileMenu_ProfileParameterRestore_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$ProfileMenu_ProfileParameterRestore_LABEL.Text = "Restore Function"
		$ProfileMenu_ProfileParameterRestore_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterRestore_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileParameterCopy_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Location = New-Object System.Drawing.Point(320, 100)
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Size = New-Object System.Drawing.Size(20, 30)
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Text = "Copy Function"
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Checked = $false
		$ProfileMenu_ProfileParameterCopy_CHECKBOX.Enabled = $false
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterCopy_CHECKBOX)
		#######################################################################################################
		$ProfileMenu_ProfileParameterCopy_LABEL = New-Object System.Windows.Forms.Label
		$ProfileMenu_ProfileParameterCopy_LABEL.Location = New-Object System.Drawing.Point(340, 100)
		$ProfileMenu_ProfileParameterCopy_LABEL.Size = New-Object System.Drawing.Size(120, 30)
		$ProfileMenu_ProfileParameterCopy_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$ProfileMenu_ProfileParameterCopy_LABEL.Text = "Copy Function"
		$ProfileMenu_ProfileParameterCopy_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterCopy_LABEL)
		#######################################################################################################
		$ProfileMenu_ProfileParameterList_LISTBOX = New-Object System.Windows.Forms.ListBox
		$ProfileMenu_ProfileParameterList_LISTBOX.Location = New-Object System.Drawing.Point(320, 138)
		$ProfileMenu_ProfileParameterList_LISTBOX.Size = New-Object System.Drawing.Size(300, 160)
		$ProfileMenu_ProfileParameterList_LISTBOX.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$ProfileMenu_ProfileParameterList_LISTBOX.ScrollAlwaysVisible = $false
		$ProfileMenu_ProfileParameterList_LISTBOX.HorizontalScrollbar = $true
		$ProfileMenu_ProfileParameterList_LISTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 10, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_ProfileParameterList_LISTBOX)
		#######################################################################################################
		$ProfileMenu_Edit_BUTTON = New-Object System.Windows.Forms.Button
		$ProfileMenu_Edit_BUTTON.Location = New-Object System.Drawing.Point(10, 303)
		$ProfileMenu_Edit_BUTTON.Size = New-Object System.Drawing.Size(145, 60)
		$ProfileMenu_Edit_BUTTON.Text = 'Edit Selected Profile'
		$ProfileMenu_Edit_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 12, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_Edit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$ProfileMenu_Edit_BUTTON.Add_Click({
			$ProfileMenu_FORM.Tag = AdvancedMenu -ProfileTask 'Edit' -ChosenProfile "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)" -ProfileXmlObject $ProfileMenu_FORM.Tag
		})
		$ProfileMenu_FORM.AcceptButton = $ProfileMenu_Edit_BUTTON
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_Edit_BUTTON)
		#######################################################################################################
		$ProfileMenu_Add_BUTTON = New-Object System.Windows.Forms.Button
		$ProfileMenu_Add_BUTTON.Location = New-Object System.Drawing.Point(165, 303)
		$ProfileMenu_Add_BUTTON.Size = New-Object System.Drawing.Size(145, 60)
		$ProfileMenu_Add_BUTTON.Text = 'Add New Profile'
		$ProfileMenu_Add_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$ProfileMenu_Add_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 12, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_Add_BUTTON.Add_Click({
			$ProfileMenu_FORM.Tag = AdvancedMenu -ProfileTask 'Add' -ProfileXmlObject $ProfileMenu_FORM.Tag
		})
		$ProfileMenu_FORM.AcceptButton = $ProfileMenu_Add_BUTTON
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_Add_BUTTON)
		#######################################################################################################
		$ProfileMenu_Delete_BUTTON = New-Object System.Windows.Forms.Button
		$ProfileMenu_Delete_BUTTON.Location = New-Object System.Drawing.Point(320, 303)
		$ProfileMenu_Delete_BUTTON.Size = New-Object System.Drawing.Size(145, 60)
		$ProfileMenu_Delete_BUTTON.Text = 'Delete Selected Profile'
		$ProfileMenu_Delete_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$ProfileMenu_Delete_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 12, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_Delete_BUTTON.Add_Click({
			$ProfileMenu_LABEL.Tag += 1
			switch ($ProfileXmlObject.Count) {
				1 {
					DeleteLastProfile
				}
				{ $_ -gt 1 } {
					$ProfileMenu_FORM.Tag = DeleteProfileGT1 -ProfileXmlObject $ProfileMenu_FORM.Tag -ChosenProfile "$($ProfileMenu_ProfileList_LISTBOX.SelectedItem)" 
				}
			}
		})
		$ProfileMenu_FORM.AcceptButton = $ProfileMenu_Delete_BUTTON
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_Delete_BUTTON)
		#######################################################################################################
		$ProfileMenu_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$ProfileMenu_Exit_BUTTON.Location = New-Object System.Drawing.Point(475, 303)
		$ProfileMenu_Exit_BUTTON.Size = New-Object System.Drawing.Size(145, 60)
		$ProfileMenu_Exit_BUTTON.Text = 'EXIT'
		$ProfileMenu_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$ProfileMenu_Exit_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 12, [System.Drawing.FontStyle]::Regular)
		$ProfileMenu_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$ProfileMenu_FORM.AcceptButton = $ProfileMenu_Exit_BUTTON
		$ProfileMenu_FORM.Controls.Add($ProfileMenu_Exit_BUTTON)
		#######################################################################################################
		ListFiller -ProfileXmlObject $ProfileXmlObject -Menu 'ProfileMenu'
		ProfileMenuProfileParametersList
		ProfileMenuButtonsActive
		$ProfileMenu_FORM.ShowDialog() > $null
		if ($ProfileMenu_LABEL.Tag -ge 1) {
			$ProfileMenu_FORM.Tag | Export-Clixml -Path ${Running_Folder}\ProfileList.xml
		}
		return ,$ProfileMenu_FORM.Tag
	}

	function AdvancedMenu {
		param (
			[string]$ProfileTask,
			[string]$ChosenProfile,
			$ProfileXmlObject
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$AdvancedMenu_FORM = New-Object System.Windows.Forms.Form
		$AdvancedMenu_FORM.Text = $FormsVariables.FormsText
		$AdvancedMenu_FORM.Font = $FormsVariables.FormsFont
		$AdvancedMenu_FORM.BackColor = $FormsVariables.FormsBackColor
		$AdvancedMenu_FORM.ForeColor = $FormsVariables.FormsForeColor
		$AdvancedMenu_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$AdvancedMenu_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$AdvancedMenu_FORM.ClientSize = New-Object System.Drawing.Size(980, 425)
		$AdvancedMenu_FORM.Add_Paint({
			param (
				$Source_Form, 
				$Event_Args
			)

			$Graphics = $Event_Args.Graphics
			$Rectangle = [System.Drawing.Rectangle]::new(237, 37, 735, 340)
			$BorderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 1)
			$Graphics.DrawRectangle($borderPen, $rectangle)
			$BorderPen.Dispose()
		})
		$AdvancedMenu_FORM.Tag = $ProfileXmlObject
		#######################################################################################################
		$AdvancedMenu_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_LABEL.Location = New-Object System.Drawing.Point(0, 5)
		$AdvancedMenu_LABEL.Size = New-Object System.Drawing.Size(980, 30)
		$AdvancedMenu_LABEL.Text = "Set all mandatory settings (*) before using the program."
		$AdvancedMenu_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_LABEL)
		#######################################################################################################
		$AdvancedMenu_ProfileName_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_ProfileName_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$AdvancedMenu_ProfileName_LABEL.Location = New-Object System.Drawing.Point(10, 40)
		$AdvancedMenu_ProfileName_LABEL.Size = New-Object System.Drawing.Size(220, 35)
		$AdvancedMenu_ProfileName_LABEL.Text = "Enter the profile name in the text box below"
		$AdvancedMenu_ProfileName_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_ProfileName_LABEL)
		#######################################################################################################
		$AdvancedMenu_BackupName_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_BackupName_TEXTBOX.Location = New-Object System.Drawing.Point(240, 40)
		$AdvancedMenu_BackupName_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_BackupName_TEXTBOX.Text = $null
		$AdvancedMenu_BackupName_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_BackupName_TEXTBOX.Enabled = $False
		$AdvancedMenu_BackupName_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_BackupName_TEXTBOX.Add_Leave({
			$AdvancedMenu_BackupName_TEXTBOX.Text = $AdvancedMenu_BackupName_TEXTBOX.Text -Replace '[\W]'
		})
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupName_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_BackupName_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_BackupName_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_BackupName_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_BackupName_LABEL.Location = New-Object System.Drawing.Point(560, 40)
		$AdvancedMenu_BackupName_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_BackupName_LABEL.Text = "* Backup name. This name will be used when creating the archive with the addition of the archive creation time."
		$AdvancedMenu_BackupName_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupName_LABEL)
		#######################################################################################################
		$AdvancedMenu_ProfileName_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_ProfileName_TEXTBOX.Location = New-Object System.Drawing.Point(10, 80)
		$AdvancedMenu_ProfileName_TEXTBOX.Size = New-Object System.Drawing.Size(220, 35)
		$AdvancedMenu_ProfileName_TEXTBOX.Text = $null
		$AdvancedMenu_ProfileName_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_ProfileName_TEXTBOX.Add_Leave({
			$AdvancedMenu_ProfileName_TEXTBOX.Text = $AdvancedMenu_ProfileName_TEXTBOX.Text -replace '[\W]'
		})
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_ProfileName_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_Source_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_Source_TEXTBOX.Location = New-Object System.Drawing.Point(240, 80)
		$AdvancedMenu_Source_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_Source_TEXTBOX.Text = $null
		$AdvancedMenu_Source_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_Source_TEXTBOX.ReadOnly = $true
		$AdvancedMenu_Source_TEXTBOX.Enabled = $False
		$AdvancedMenu_Source_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Source_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_SourceDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_SourceDirectory_BUTTON.Location = New-Object System.Drawing.Point(475, 80)
		$AdvancedMenu_SourceDirectory_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_SourceDirectory_BUTTON.Text = "Folder"
		$AdvancedMenu_SourceDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_SourceDirectory_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 7, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point, 204)
		$AdvancedMenu_SourceDirectory_BUTTON.Add_Click({
			$AdvancedMenu_SourceDirectory_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$AdvancedMenu_SourceDirectory_BUTTON_directoryname.RootFolder = "MyComputer"
			if ($AdvancedMenu_SourceDirectory_BUTTON_directoryname.ShowDialog() -eq "OK") {
				if ($($AdvancedMenu_SourceDirectory_BUTTON_directoryname.SelectedPath)[-1] -eq '\') {
					$AdvancedMenu_Source_TEXTBOX.Text = "$($AdvancedMenu_SourceDirectory_BUTTON_directoryname.SelectedPath)"
				}
				else {
					$AdvancedMenu_Source_TEXTBOX.Text = "$($AdvancedMenu_SourceDirectory_BUTTON_directoryname.SelectedPath)\"
				}
			}
		})
		$AdvancedMenu_SourceDirectory_BUTTON.Enabled = $SourceFolder_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_SourceDirectory_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SourceDirectory_BUTTON)
		#######################################################################################################
		$AdvancedMenu_SourceFile_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_SourceFile_BUTTON.Location = New-Object System.Drawing.Point(515, 80)
		$AdvancedMenu_SourceFile_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_SourceFile_BUTTON.Text = "File"
		$AdvancedMenu_SourceFile_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_SourceFile_BUTTON.Font = New-Object System.Drawing.Font("Times New Roman", 7, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point, 204)
		$AdvancedMenu_SourceFile_BUTTON.Add_Click({
			$AdvancedMenu_SourceFile_BUTTON_filename = New-Object System.Windows.Forms.OpenFileDialog
			if ($AdvancedMenu_SourceFile_BUTTON_filename.ShowDialog() -eq "OK") {
				$AdvancedMenu_Source_TEXTBOX.Text = $AdvancedMenu_SourceFile_BUTTON_filename.FileName
			}
		})
		$AdvancedMenu_SourceFile_BUTTON.Enabled = $SourceFolder_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_SourceFile_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SourceFile_BUTTON)
		#######################################################################################################
		$AdvancedMenu_Source_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_Source_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_Source_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_Source_LABEL.Location = New-Object System.Drawing.Point(560, 80)
		$AdvancedMenu_Source_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_Source_LABEL.Text = "* Source directory or a file. Select directory or a file you want to archive."
		$AdvancedMenu_Source_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Source_LABEL)
		#######################################################################################################
		$AdvancedMenu_CheckBox_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_CheckBox_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14)
		$AdvancedMenu_CheckBox_LABEL.Location = New-Object System.Drawing.Point(10, 120)
		$AdvancedMenu_CheckBox_LABEL.Size = New-Object System.Drawing.Size(220, 75)
		$AdvancedMenu_CheckBox_LABEL.Text = "Click on the appropriate checkbox to select the functionality you will use"
		$AdvancedMenu_CheckBox_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_CheckBox_LABEL)
		#######################################################################################################
		$AdvancedMenu_BackupDirectory_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_BackupDirectory_TEXTBOX.Location = New-Object System.Drawing.Point(240, 120)
		$AdvancedMenu_BackupDirectory_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_BackupDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_BackupDirectory_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_BackupDirectory_TEXTBOX.ReadOnly = $true
		$AdvancedMenu_BackupDirectory_TEXTBOX.Enabled = $False
		$AdvancedMenu_BackupDirectory_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupDirectory_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_BackupDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_BackupDirectory_BUTTON.Location = New-Object System.Drawing.Point(515, 120)
		$AdvancedMenu_BackupDirectory_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_BackupDirectory_BUTTON.Text = "..."
		$AdvancedMenu_BackupDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_BackupDirectory_BUTTON.Add_Click({
			$AdvancedMenu_BackupDirectory_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$AdvancedMenu_BackupDirectory_BUTTON_directoryname.RootFolder = "MyComputer"
			if ($AdvancedMenu_BackupDirectory_BUTTON_directoryname.ShowDialog() -eq "OK") {
				if ($($AdvancedMenu_BackupDirectory_BUTTON_directoryname.SelectedPath)[-1] -eq '\') {
					$AdvancedMenu_BackupDirectory_TEXTBOX.Text = "$($AdvancedMenu_BackupDirectory_BUTTON_directoryname.SelectedPath)"
				}
				else {
					$AdvancedMenu_BackupDirectory_TEXTBOX.Text = "$($AdvancedMenu_BackupDirectory_BUTTON_directoryname.SelectedPath)\"
				}
			}
		})
		$AdvancedMenu_BackupDirectory_BUTTON.Enabled = $BackupDirectory_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_BackupDirectory_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupDirectory_BUTTON)
		#######################################################################################################
		$AdvancedMenu_BackupDirectory_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_BackupDirectory_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_BackupDirectory_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_BackupDirectory_LABEL.Location = New-Object System.Drawing.Point(560, 120)
		$AdvancedMenu_BackupDirectory_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_BackupDirectory_LABEL.Text = "* Backup Directory. The directory where you would like to store your archive copies."
		$AdvancedMenu_BackupDirectory_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupDirectory_LABEL)
		#######################################################################################################
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Location = New-Object System.Drawing.Point(240, 160)
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.ReadOnly = $true
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Enabled = $False
		$AdvancedMenu_SecondBackupDirectory_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SecondBackupDirectory_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_SecondBackupDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_SecondBackupDirectory_BUTTON.Location = New-Object System.Drawing.Point(515, 160)
		$AdvancedMenu_SecondBackupDirectory_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_SecondBackupDirectory_BUTTON.Text = "..."
		$AdvancedMenu_SecondBackupDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_SecondBackupDirectory_BUTTON.Add_Click({
			$AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname.RootFolder = "MyComputer"
			if ($AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname.ShowDialog() -eq "OK") {
				if ($($AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname.SelectedPath)[-1] -eq '\') {
					$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = "$($AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname.SelectedPath)"
				}
				else {
					$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = "$($AdvancedMenu_SecondBackupDirectory_BUTTON_directoryname.SelectedPath)\"
				}
			}
		})
		$AdvancedMenu_SecondBackupDirectory_BUTTON.Enabled = $BackupSecondDirectory_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_SecondBackupDirectory_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SecondBackupDirectory_BUTTON)
		#######################################################################################################
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.Location = New-Object System.Drawing.Point(475, 160)
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.Text = "-"
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.Add_Click({
			$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = $null
		})
		$AdvancedMenu_SecondBackupDirectoryClear_BUTTON.Enabled = $BackupSecondDirectory_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_SecondBackupDirectoryClear_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SecondBackupDirectoryClear_BUTTON)
		#######################################################################################################
		$AdvancedMenu_SecondBackupDirectory_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_SecondBackupDirectory_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_SecondBackupDirectory_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_SecondBackupDirectory_LABEL.Location = New-Object System.Drawing.Point(560, 160)
		$AdvancedMenu_SecondBackupDirectory_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_SecondBackupDirectory_LABEL.Text = "Second Backup Directory. An additional directory where you would like to save your archive copies."
		$AdvancedMenu_SecondBackupDirectory_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_SecondBackupDirectory_LABEL)
		#######################################################################################################
		$AdvancedMenu_Backup_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$AdvancedMenu_Backup_CHECKBOX.Checked = $false
		$AdvancedMenu_Backup_CHECKBOX.Location = New-Object System.Drawing.Point(10, 200)
		$AdvancedMenu_Backup_CHECKBOX.Size = New-Object System.Drawing.Size(220, 45)
		$AdvancedMenu_Backup_CHECKBOX.Text = "Backup and Filtered Backup functionality"
		$AdvancedMenu_Backup_CHECKBOX.Font = New-Object System.Drawing.Font("Times New Roman", 12)
		$AdvancedMenu_Backup_CHECKBOX.Add_CheckStateChanged({
			AdvancedMenuSwitch
		})
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Backup_CHECKBOX)
		#######################################################################################################
		$AdvancedMenu_RestoreDirectory_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Location = New-Object System.Drawing.Point(240, 200)
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = $null
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_RestoreDirectory_TEXTBOX.ReadOnly = $true
		$AdvancedMenu_RestoreDirectory_TEXTBOX.Enabled = $False
		$AdvancedMenu_RestoreDirectory_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestoreDirectory_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_RestoreCopySource_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_RestoreCopySource_BUTTON.Location = New-Object System.Drawing.Point(475, 200)
		$AdvancedMenu_RestoreCopySource_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_RestoreCopySource_BUTTON.Text = "S"
		$AdvancedMenu_RestoreCopySource_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_RestoreCopySource_BUTTON.Add_Click({
			if ($AdvancedMenu_Source_TEXTBOX.Text.Length -eq 3 -or $AdvancedMenu_Source_TEXTBOX.Text -match '^[a-zA-Z]:\\+$') {
				ErrorForm -ErrorLabelText "The recovery directory cannot be the root of the disk.`n`nBecause during recovery, the program will try to delete all files from the disk root.`n`nPlease create a separate recovery directory at the root of the disk, even if it is the only one on the disk." -Height	240 -Width 500
				return
			} 
			$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = $($AdvancedMenu_Source_TEXTBOX.Text)
		})
		$AdvancedMenu_RestoreCopySource_BUTTON.Enabled = $Restore_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_RestoreCopySource_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestoreCopySource_BUTTON)
		#######################################################################################################
		$AdvancedMenu_RestoreDirectory_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_RestoreDirectory_BUTTON.Location = New-Object System.Drawing.Point(515, 200)
		$AdvancedMenu_RestoreDirectory_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_RestoreDirectory_BUTTON.Text = "..."
		$AdvancedMenu_RestoreDirectory_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_RestoreDirectory_BUTTON.Add_Click({
			$AdvancedMenu_RestoreDirectory_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$AdvancedMenu_RestoreDirectory_BUTTON_directoryname.RootFolder = "MyComputer"
			if ($AdvancedMenu_RestoreDirectory_BUTTON_directoryname.ShowDialog() -eq "OK") {
				if ($AdvancedMenu_RestoreDirectory_BUTTON_directoryname.SelectedPath.Length -eq 3 -or $AdvancedMenu_RestoreDirectory_BUTTON_directoryname.SelectedPath -match '^[a-zA-Z]:\\+$') {
					ErrorForm -ErrorLabelText "The recovery directory cannot be the root of the disk.`n`nBecause during recovery, the program will try to delete all files from the disk root.`n`nPlease create a separate recovery directory at the root of the disk, even if it is the only one on the disk." -Height	240 -Width 500
					return
				} 
				if ($($AdvancedMenu_RestoreDirectory_BUTTON_directoryname.SelectedPath)[-1] -eq '\') {
					$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = "$($AdvancedMenu_RestoreDirectory_BUTTON_directoryname.SelectedPath)"
				}
				else {
					$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = "$($AdvancedMenu_RestoreDirectory_BUTTON_directoryname.SelectedPath)\"
				}
			}
		})
		$AdvancedMenu_RestoreDirectory_BUTTON.Enabled = $Restore_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_RestoreDirectory_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestoreDirectory_BUTTON)
		#######################################################################################################
		$AdvancedMenu_RestoreDirectory_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_RestoreDirectory_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_RestoreDirectory_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_RestoreDirectory_LABEL.Location = New-Object System.Drawing.Point(560, 200)
		$AdvancedMenu_RestoreDirectory_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_RestoreDirectory_LABEL.Text = "* Restore Directory. Select the directory to restore the backups to. This directory is usually the same as the source directory."
		$AdvancedMenu_RestoreDirectory_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestoreDirectory_LABEL)
		#######################################################################################################
		$AdvancedMenu_RestorePoints_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_RestorePoints_TEXTBOX.Location = New-Object System.Drawing.Point(240, 240)
		$AdvancedMenu_RestorePoints_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_RestorePoints_TEXTBOX.Text = $null
		$AdvancedMenu_RestorePoints_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_RestorePoints_TEXTBOX.Add_Leave({
			$AdvancedMenu_RestorePoints_TEXTBOX.Text = $AdvancedMenu_RestorePoints_TEXTBOX.Text -Replace '[\D]'
			[decimal]$RestorePoints = $($AdvancedMenu_RestorePoints_TEXTBOX.Text)
			if ($RestorePoints -le 1) {
				$RestorePoints = 1
				$AdvancedMenu_RestorePoints_TEXTBOX.Text = $RestorePoints
			}
			elseif ($RestorePoints -ge 150000) {
				$RestorePoints = 150000
				$AdvancedMenu_RestorePoints_TEXTBOX.Text = $RestorePoints
			}
		})
		$AdvancedMenu_RestorePoints_TEXTBOX.Enabled = $False
		$AdvancedMenu_RestorePoints_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_RestorePoints_TEXTBOX.Name = 'AdvancedMenu_RestorePoints_TEXTBOX'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestorePoints_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_RestorePoints_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_RestorePoints_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_RestorePoints_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_RestorePoints_LABEL.Location = New-Object System.Drawing.Point(560, 240)
		$AdvancedMenu_RestorePoints_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_RestorePoints_LABEL.Text = "* Restore points. Specify how many backups you would like to keep. This value cannot be less than 1."
		$AdvancedMenu_RestorePoints_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_RestorePoints_LABEL)
		#######################################################################################################
		$AdvancedMenu_Restore_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$AdvancedMenu_Restore_CHECKBOX.Checked = $false
		$AdvancedMenu_Restore_CHECKBOX.Location = New-Object System.Drawing.Point(10, 250)
		$AdvancedMenu_Restore_CHECKBOX.Size = New-Object System.Drawing.Size(220, 45)
		$AdvancedMenu_Restore_CHECKBOX.Text = "Restore functionality"
		$AdvancedMenu_Restore_CHECKBOX.Font = New-Object System.Drawing.Font("Times New Roman", 12)
		$AdvancedMenu_Restore_CHECKBOX.Add_CheckStateChanged({
			AdvancedMenuSwitch
		})
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Restore_CHECKBOX)
		#######################################################################################################
		$AdvancedMenu_BackupDayFilter_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Location = New-Object System.Drawing.Point(240, 280)
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = $null
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Add_Leave({
			$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = $AdvancedMenu_BackupDayFilter_TEXTBOX.Text -Replace '[\D]'
			[decimal]$BackupDayFilter = $($AdvancedMenu_BackupDayFilter_TEXTBOX.Text)
			if ($BackupDayFilter -le 1) {
				$BackupDayFilter = 1
				$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = $BackupDayFilter
			}
			elseif ($BackupDayFilter -ge 150000) {
				$BackupDayFilter = 150000
				$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = $BackupDayFilter
			}
		})
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Enabled = $False
		$AdvancedMenu_BackupDayFilter_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_BackupDayFilter_TEXTBOX.Name = 'AdvancedMenu_BackupDayFilter_TEXTBOX'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupDayFilter_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_BackupDayFilter_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_BackupDayFilter_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_BackupDayFilter_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_BackupDayFilter_LABEL.Location = New-Object System.Drawing.Point(560, 280)
		$AdvancedMenu_BackupDayFilter_LABEL.Size = New-Object System.Drawing.Size(410, 35)
		$AdvancedMenu_BackupDayFilter_LABEL.Text = "Day Filter. Enter the number of days to backup recently updated files. For example, entering '7' will backup files modified in the last 7 days."
		$AdvancedMenu_BackupDayFilter_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_BackupDayFilter_LABEL)
		#######################################################################################################
		$AdvancedMenu_Copy_CHECKBOX = New-Object System.Windows.Forms.CheckBox
		$AdvancedMenu_Copy_CHECKBOX.Checked = $false
		$AdvancedMenu_Copy_CHECKBOX.Location = New-Object System.Drawing.Point(10, 300)
		$AdvancedMenu_Copy_CHECKBOX.Size = New-Object System.Drawing.Size(220, 45)
		$AdvancedMenu_Copy_CHECKBOX.Text = "Copy and Synchronize functionality"
		$AdvancedMenu_Copy_CHECKBOX.Font = New-Object System.Drawing.Font("Times New Roman", 12)
		$AdvancedMenu_Copy_CHECKBOX.Add_CheckStateChanged({
			AdvancedMenuSwitch
		})
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Copy_CHECKBOX)
		#######################################################################################################
		$AdvancedMenu_7zipExecutable_TEXTBOX = New-Object System.Windows.Forms.TextBox
		$AdvancedMenu_7zipExecutable_TEXTBOX.Location = New-Object System.Drawing.Point(240, 320)
		$AdvancedMenu_7zipExecutable_TEXTBOX.Size = New-Object System.Drawing.Size(230, 35)
		$AdvancedMenu_7zipExecutable_TEXTBOX.Text = $null
		$AdvancedMenu_7zipExecutable_TEXTBOX.Font = New-Object System.Drawing.Font("Cascadia Mono", 9, [System.Drawing.FontStyle]::Regular)
		$AdvancedMenu_7zipExecutable_TEXTBOX.ReadOnly = $true
		$AdvancedMenu_7zipExecutable_TEXTBOX.Enabled = $False
		$AdvancedMenu_7zipExecutable_TEXTBOX.BackColor = 'DarkGray'
		$AdvancedMenu_7zipExecutable_TEXTBOX.Name = 'AdvancedMenu_7zipExecutable_TEXTBOX'
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_7zipExecutable_TEXTBOX)
		#######################################################################################################
		$AdvancedMenu_7ZipExecutable_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_7ZipExecutable_BUTTON.Location = New-Object System.Drawing.Point(515, 320)
		$AdvancedMenu_7ZipExecutable_BUTTON.Size = New-Object System.Drawing.Size(40, 35)
		$AdvancedMenu_7ZipExecutable_BUTTON.Text = "..."
		$AdvancedMenu_7ZipExecutable_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_7ZipExecutable_BUTTON.Add_Click({
			$AdvancedMenu_7ZipExecutable_BUTTON_directoryname = New-Object System.Windows.Forms.FolderBrowserDialog
			$AdvancedMenu_7ZipExecutable_BUTTON_directoryname.RootFolder = "MyComputer"
			$AdvancedMenu_7ZipExecutable_BUTTON_directoryname.SelectedPath = "C:\Program Files\"
			if ($AdvancedMenu_7ZipExecutable_BUTTON_directoryname.ShowDialog() -eq "OK") {
				if ( -not (Test-Path -Path "$($AdvancedMenu_7ZipExecutable_BUTTON_directoryname.SelectedPath)\7z.exe")) {
					ErrorForm -ErrorLabelText "Wrong directory.`nThere are no 7z.exe in directory`n$($AdvancedMenu_7ZipExecutable_BUTTON_directoryname.SelectedPath)"
					$AdvancedMenu_7zipExecutable_TEXTBOX.Text = (Get-Command 7z).Source 2>$null
					return
				}
				$AdvancedMenu_7zipExecutable_TEXTBOX.Text = "$($AdvancedMenu_7ZipExecutable_BUTTON_directoryname.SelectedPath)\7z.exe"
			}
		})
		$AdvancedMenu_7ZipExecutable_BUTTON.Enabled = $7zipfolder_true
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_7ZipExecutable_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_7ZipExecutable_BUTTON)
		#######################################################################################################
		$AdvancedMenu_7zipExecutable_LABEL = New-Object System.Windows.Forms.Label
		$AdvancedMenu_7zipExecutable_LABEL.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
		$AdvancedMenu_7zipExecutable_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 10)
		$AdvancedMenu_7zipExecutable_LABEL.Location = New-Object System.Drawing.Point(560, 320)
		$AdvancedMenu_7zipExecutable_LABEL.Size = New-Object System.Drawing.Size(410, 55)
		$AdvancedMenu_7zipExecutable_LABEL.Text = "* 7-zip executable Folder. Specify the directory where the 7-zip archiving program is located. Or install it from the official site: `nhttps://www.7-zip.org"
		$AdvancedMenu_7zipExecutable_LABEL.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_7zipExecutable_LABEL)
		#######################################################################################################
		$AdvancedMenu_OK_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_OK_BUTTON.Location = New-Object System.Drawing.Point(12, 380)
		$AdvancedMenu_OK_BUTTON.Size = New-Object System.Drawing.Size(84, 35)
		$AdvancedMenu_OK_BUTTON.Text = "Ok"
		$AdvancedMenu_OK_BUTTON.UseVisualStyleBackColor = $true
		$AdvancedMenu_OK_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_OK_BUTTON.Add_Click({
			$FieldValidation = FieldValidation
			if ($FieldValidation -eq 'error') {
				return
			}
			if ( -not (Test-Path "${Running_Folder}\ProfileList.xml")) {
				CreateProfileListFile
			}
			switch ($ProfileTask) {
				'Edit' {
					$AdvancedMenu_FORM.Tag = EditProfile -ProfileXmlObject $ProfileXmlObject -ChosenProfile "$ChosenProfile"
					$AdvancedMenu_FORM.Close()
				}
				'Add' {
					if ($($AdvancedMenu_FORM.Tag.ProfileName) -eq $($AdvancedMenu_ProfileName_TEXTBOX.Text)) {
						ErrorForm -ErrorLabelText "A profile with the name: `"$($AdvancedMenu_ProfileName_TEXTBOX.Text)`" already exist`nPlease select a different name for this profile"
						return "error"
					}
					$AdvancedMenu_FORM.Tag = AddProfile -ProfileXmlObject $AdvancedMenu_FORM.Tag
					$AdvancedMenu_FORM.Close()
				}
			}
		})
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_OK_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_OK_BUTTON)
		#######################################################################################################
		$AdvancedMenu_ClearConfig_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_ClearConfig_BUTTON.Location = New-Object System.Drawing.Point(414, 380)
		$AdvancedMenu_ClearConfig_BUTTON.Size = New-Object System.Drawing.Size(154, 35)
		$AdvancedMenu_ClearConfig_BUTTON.Text = "Clear Config"
		$AdvancedMenu_ClearConfig_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_ClearConfig_BUTTON.Add_Click({
			ClearProfile
		})
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_ClearConfig_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_ClearConfig_BUTTON)
		#######################################################################################################
		$AdvancedMenu_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$AdvancedMenu_Exit_BUTTON.Location = New-Object System.Drawing.Point(887, 380)
		$AdvancedMenu_Exit_BUTTON.Size = New-Object System.Drawing.Size(84, 35)
		$AdvancedMenu_Exit_BUTTON.Text = "Exit"
		$AdvancedMenu_Exit_BUTTON.UseVisualStyleBackColor = $true
		$AdvancedMenu_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$AdvancedMenu_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$AdvancedMenu_FORM.AcceptButton = $AdvancedMenu_Exit_BUTTON
		$AdvancedMenu_FORM.Controls.Add($AdvancedMenu_Exit_BUTTON)
		#######################################################################################################
		switch ($ProfileTask) {
			'Add' {
				ClearProfile
			}
			'Edit' {
				$AdvancedMenu_Backup_CHECKBOX.Checked = $(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).BackupCheckboxStatus)
				$AdvancedMenu_Restore_CHECKBOX.Checked = $(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).RestoreCheckboxStatus)
				$AdvancedMenu_Copy_CHECKBOX.Checked = $(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).CopyCheckboxStatus)
				$AdvancedMenu_BackupName_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).BackupName)"
				$AdvancedMenu_ProfileName_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).ProfileName)"
				$AdvancedMenu_Source_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).Source)"
				$AdvancedMenu_BackupDirectory_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).BackupDirectory)"
				$AdvancedMenu_SecondBackupDirectory_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).SecondBackupDirectory)"
				$AdvancedMenu_RestoreDirectory_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).RestoreDirectory)"
				$AdvancedMenu_RestorePoints_TEXTBOX.Text = if ($(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).RestorePoints) -eq 0) { $null } else { $(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).RestorePoints) }
				$AdvancedMenu_BackupDayFilter_TEXTBOX.Text = if ($(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).BackupDayFilter) -eq 0) { $null } else { $(($AdvancedMenu_FORM.Tag | Where-Object { $_.ProfileName -eq "$ChosenProfile" }).BackupDayFilter) }
				$AdvancedMenu_7zipExecutable_TEXTBOX.Text = "$(($AdvancedMenu_FORM.Tag|Where-Object {$_.ProfileName -eq "$ChosenProfile"}).Executable_7z)"
			}
			Default {
				AdvancedMenuSwitch
			}
		}
		$AdvancedMenu_FORM.ShowDialog() > $null
		return ,$AdvancedMenu_FORM.Tag
	}

	function MainMenu {
		param (
			$ProfileXmlObject
		)

		$FormsVariables = FormsVariables
		#######################################################################################################
		$MainMenu_FORM = New-Object System.Windows.Forms.Form
		$MainMenu_FORM.Text = $FormsVariables.FormsText
		$MainMenu_FORM.Font = $FormsVariables.FormsFont
		$MainMenu_FORM.BackColor = $FormsVariables.FormsBackColor
		$MainMenu_FORM.ForeColor = $FormsVariables.FormsForeColor
		$MainMenu_FORM.StartPosition = $FormsVariables.FormsStartPosition
		$MainMenu_FORM.FormBorderStyle = $FormsVariables.FormsBorderStyle
		$MainMenu_FORM.ClientSize = New-Object System.Drawing.Size(430, 245)
		$MainMenu_FORM.Tag = $ProfileXmlObject
		#######################################################################################################
		$MainMenu_First_LABEL = New-Object System.Windows.Forms.Label
		$MainMenu_First_LABEL.Location = New-Object System.Drawing.Point(10, 10)
		$MainMenu_First_LABEL.Size = New-Object System.Drawing.Size(410, 40)
		$MainMenu_First_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 14, [System.Drawing.FontStyle]::Bold)
		$MainMenu_First_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_First_LABEL.Text = "Welcome to the`nPowerShell 7z Backup and Restore Script`nPlease select one of the options below."
		$MainMenu_FORM.Controls.Add($MainMenu_First_LABEL)
		#######################################################################################################
		$MainMenu_Second_LABEL = New-Object System.Windows.Forms.Label
		$MainMenu_Second_LABEL.Location = New-Object System.Drawing.Point(10, 50)
		$MainMenu_Second_LABEL.Size = New-Object System.Drawing.Size(410, 20)
		$MainMenu_Second_LABEL.Font = New-Object System.Drawing.Font("Times New Roman", 12, [System.Drawing.FontStyle]::Regular)
		$MainMenu_Second_LABEL.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Second_LABEL.Text = "Please select one of the options below"
		$MainMenu_FORM.Controls.Add($MainMenu_Second_LABEL)
		#######################################################################################################
		$MainMenu_Backup_BUTTON = New-Object System.Windows.Forms.Button
		$MainMenu_Backup_BUTTON.Location = New-Object System.Drawing.Point(10, 75)
		$MainMenu_Backup_BUTTON.Size = New-Object System.Drawing.Size(200, 40)
		$MainMenu_Backup_BUTTON.Text = 'Backup Menu'
		$MainMenu_Backup_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Backup_BUTTON.Add_Click({
			BackupMenu -ProfileXmlObject $($MainMenu_FORM.Tag | Where-Object { $_.BackupCheckboxStatus -or $_.CopyCheckboxStatus })
		})
		$MainMenu_FORM.AcceptButton = $MainMenu_Backup_BUTTON
		$MainMenu_FORM.Controls.Add($MainMenu_Backup_BUTTON)
		#######################################################################################################
		$MainMenu_Restore_BUTTON = New-Object System.Windows.Forms.Button
		$MainMenu_Restore_BUTTON.Location = New-Object System.Drawing.Point(215, 75)
		$MainMenu_Restore_BUTTON.Size = New-Object System.Drawing.Size(200, 40)
		$MainMenu_Restore_BUTTON.Text = 'Restore Menu'
		$MainMenu_Restore_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Restore_BUTTON.Add_Click({
			RestoreMenu -ProfileXmlObject $($MainMenu_FORM.Tag | Where-Object { $_.RestoreCheckboxStatus })
		})
		$MainMenu_FORM.AcceptButton = $MainMenu_Restore_BUTTON
		$MainMenu_FORM.Controls.Add($MainMenu_Restore_BUTTON)
		#######################################################################################################
		$MainMenu_Update_BUTTON = New-Object System.Windows.Forms.Button
		$MainMenu_Update_BUTTON.Location = New-Object System.Drawing.Point(10, 120)
		$MainMenu_Update_BUTTON.Size = New-Object System.Drawing.Size(410, 35)
		$MainMenu_Update_BUTTON.Text = 'Check for Updates?'
		$MainMenu_Update_BUTTON.Enabled = $true
		$MainMenu_Update_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Update_BUTTON.Add_Click({
			if ($MainMenu_Update_BUTTON.Tag.ScriptUpdate -eq $true){
				UpdateScript -ScriptPath $ScriptPath -GitScriptBody $GitScriptBody
			}
			$MainMenu_Update_BUTTON.Tag = CheckUpdate
		})
		$MainMenu_FORM.AcceptButton = $MainMenu_Update_BUTTON
		$MainMenu_FORM.Controls.Add($MainMenu_Update_BUTTON)
		#######################################################################################################
		$MainMenu_Profiles_BUTTON = New-Object System.Windows.Forms.Button
		$MainMenu_Profiles_BUTTON.Location = New-Object System.Drawing.Point(10, 160)
		$MainMenu_Profiles_BUTTON.Size = New-Object System.Drawing.Size(410, 35)
		$MainMenu_Profiles_BUTTON.Text = 'Profiles settings'
		$MainMenu_Profiles_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Profiles_BUTTON.Add_Click({
			$MainMenu_FORM.Tag = ProfileMenu -ProfileXmlObject $MainMenu_FORM.Tag
		})
		$MainMenu_FORM.AcceptButton = $MainMenu_Profiles_BUTTON
		$MainMenu_FORM.Controls.Add($MainMenu_Profiles_BUTTON)
		#######################################################################################################
		$MainMenu_Exit_BUTTON = New-Object System.Windows.Forms.Button
		$MainMenu_Exit_BUTTON.Location = New-Object System.Drawing.Point(165, 200)
		$MainMenu_Exit_BUTTON.Size = New-Object System.Drawing.Size(100, 35)
		$MainMenu_Exit_BUTTON.Text = 'Exit'
		$MainMenu_Exit_BUTTON.TextAlign = $FormsVariables.FormsTextAlign
		$MainMenu_Exit_BUTTON.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$MainMenu_FORM.AcceptButton = $MainMenu_Exit_BUTTON
		$MainMenu_FORM.Controls.Add($MainMenu_Exit_BUTTON)
		######################################################################################################
		$MainMenu_FORM.ShowDialog() > $null
	}
	#FUNCTIONS_FORMS#################################################################################END
	#SCRIPT_BODY#####################################################################################
	$ProfileXML = ProfileImporter
	$Profile7zExecCheck = Profile7zExecCheck -ProfileXmlObject $ProfileXML
	$Attention = "Please run the script at least once without parameters and fill in all required fields.`nAttention - if you have modified this script yourself, you have no guarantees that it works exactly as the author intended."

	if (-not (Test-Path "${Running_Folder}\ProfileList.xml") -and $ProfileName -and $AutomationType) {
		Write-Output $Attention
		exit
	} elseif ((Test-Path "${Running_Folder}\ProfileList.xml") -and $ProfileName -and $AutomationType) {
		foreach ($Profile in $Profiles_from_Pipeline) {
			$MessageStart = TextFiller -SingleMessage "$AutomationType Job for the profile - $Profile is running"
			$MessageFinish = TextFiller -SingleMessage "$AutomationType Job for the profile - $Profile is finished"
			$MessageError = TextFiller -SingleMessage "$AutomationType Job for the profile - $Profile is finished with errors"
			try {
				Write-Output "$($MessageStart.SingleMessage)`n`n"
				CMDAutomationTypeChecker -AutomationType $AutomationType -ProfileObject ($ProfileXML | Where-Object { $_.ProfileName -eq "$Profile" }) -ProfileXmlObject $ProfileXML -Automation_ProfileName $Profile
			}
			catch {
				Write-Output "$_"
				Write-Output "$($MessageError.SingleMessage)`n`n"
				Write-Output "`n╔$('═'*77)╗`n╠$('╬'*77)╣`n╚$('═'*77)╝`n`n"
				continue
			}
			CMDAutomationTypeExecutor -AutomationType $AutomationType -ProfileObject ($ProfileXML | Where-Object { $_.ProfileName -eq "$Profile" })
			Write-Output "$($MessageFinish.SingleMessage)`n`n"
			Write-Output "`n╔$('═'*77)╗`n╠$('╬'*77)╣`n╚$('═'*77)╝`n`n"
		}
		exit
	}

	if (-not (Test-Path "${Running_Folder}\ProfileList.xml")) {
		$ProfileXML = AdvancedMenu
	} elseif (-not ([string]::IsNullOrWhiteSpace($Profile7zExecCheck))) {
		$No7zip = No7zip -ProfileXmlObject $ProfileXML -Profile7zExecCheck $Profile7zExecCheck
		if ($No7zip.Count -eq 0) {
			exit
		}
		else {
			$ProfileXML = $No7zip
		}
	}

	if (Test-Path "${Running_Folder}\ProfileList.xml") {
		MainMenu -ProfileXmlObject $ProfileXML
	}
}
#SCRIPT_BODY#####################################################################################END