Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
####################################Variables.Changeble###############################################
function VariablesAdvancedMenu{
$Script:BackupFolder="" #1
$Script:7z_directory="C:\Program Files\7-Zip\" #2
$Script:SecondBackupFolder="" #3
$Script:BackupName="" #4
$Script:WhatToBackup="" #5
$Script:RestoreDirectory="" #6
$Script:NumberOfBackups="2" #7
$Script:BackupDayFilter="15" #8
}
####################################Variables.Changeble.END############################################
####################################Variables##########################################################
$Path_to_Script=$MyInvocation.MyCommand.Path
function VariablesDoNotTouch{
$Script:Shell_command=Write-Output "powershell -file `"$Path_to_Script`" 1"
$Script:Shell_command2=Write-Output "powershell -file `"$Path_to_Script`" 2"
$Script:ChangeMe1=$(Get-Content $Path_to_Script|Select-Object -Skip 4 -First 1)
$Script:ChangeMe2=$(Get-Content $Path_to_Script|Select-Object -Skip 5 -First 1)
$Script:ChangeMe3=$(Get-Content $Path_to_Script|Select-Object -Skip 6 -First 1)
$Script:ChangeMe4=$(Get-Content $Path_to_Script|Select-Object -Skip 7 -First 1)
$Script:ChangeMe5=$(Get-Content $Path_to_Script|Select-Object -Skip 8 -First 1)
$Script:ChangeMe6=$(Get-Content $Path_to_Script|Select-Object -Skip 9 -First 1)
$Script:ChangeMe7=$(Get-Content $Path_to_Script|Select-Object -Skip 10 -First 1)
$Script:ChangeMe8=$(Get-Content $Path_to_Script|Select-Object -Skip 11 -First 1)
}
function DiskVariablesBackup {
$Script:DriveLetter_backups=($BackupFolder).split(':')[0]
$Script:DriveSpaceArray=(Get-PSDrive $DriveLetter_backups).Free
$Script:DriveBackupLeftSpace=[math]::round($DriveSpaceArray[0]/1Mb, 3)
}
function DiskVariablesRestore {
$Script:DriveLetter_restore=($RestoreDirectory).split(':')[0]
$Script:DriveSpaceArray=(Get-PSDrive $DriveLetter_restore).Free
$Script:DriveRestoreLeftSpace=[math]::round($DriveSpaceArray[0] /1Mb, 3)
}
VariablesAdvancedMenu
VariablesDoNotTouch
####################################Variables.END######################################################
#BackupMenu#####################################################################################
function check_directories{
    if ( Test-Path -Path $BackupFolder ){
	}
	else{
		New-Item -ItemType Directory $BackupFolder
	}
}

function 7z_save0 {
	$Script:Time=(Get-Date -format "dd/MM/yyyy/HH/mm/ss")
	& "$7z_directory\7z.exe" a "$BackupFolder\$BackupName`_$Time.7z" "$WhatToBackup`*" -bsp1
	if ( !$? ){
		Write-Output "####################################################`nSomesing go wrong. When archiving $WhatToBackup to $BackupFolder\$BackupName`_$Time.7z"
	}
	Get-ChildItem $BackupFolder -Exclude Backups_before_restore| Sort-Object -Property CreationTime | Select-Object -SkipLast $NumberOfBackups | Remove-Item
}

function Backup_According_to_day_filter0 {
	$Script:Time=(Get-Date -format "dd/MM/yyyy/HH/mm/ss")
	foreach ($file in (Get-ChildItem $WhatToBackup| Where-Object -FilterScript {$_.LastWriteTime -gt (Get-date).adddays(-$BackupDayFilter)})){
		$fullname=$file.FullName
		& "$7z_directory\7z.exe" a "$BackupFolder\$BackupName`_$Time.7z" "$fullname" -bsp1
		if ( !$? ){
			Write-Output "####################################################`nSomesing go wrong. When archiving $fullname to $BackupFolder\$BackupName`_$Time.7z"
		}
	}
	Get-ChildItem $BackupFolder -Exclude Backups_before_restore| Sort-Object -Property CreationTime | Select-Object -SkipLast $NumberOfBackups | Remove-Item
}

If ([string]::IsNullOrEmpty($SecondBackupFolder)){
	function 7z_save {
		7z_save0
	}
}
else{
	function 7z_save{
		7z_save0
		if ( Test-Path -Path $SecondBackupFolder ){
			Copy-Item "$BackupFolder\$BackupName`_$Time.7z" "$SecondBackupFolder"
			if ( !$? ){
				Write-Output "####################################################`nSomesing go wrong. When copying $BackupFolder\$BackupName`_$Time.7z to $SecondBackupFolder"
			}
			Get-ChildItem $SecondBackupFolder | Sort-Object -Property CreationTime | Select-Object -SkipLast $NumberOfBackups | Remove-Item
		}
	}
}

If ([string]::IsNullOrEmpty($SecondBackupFolder)){
	function Backup_According_to_day_filter {
		Backup_According_to_day_filter0
	}
}
else{
	function Backup_According_to_day_filter {
		Backup_According_to_day_filter0
		if ( Test-Path -Path $SecondBackupFolder ){
			if ( Test-Path -Path $BackupFolder\$BackupName`_$Time.7z ){
				Copy-Item "$BackupFolder\$BackupName`_$Time.7z" "$SecondBackupFolder"
				if ( !$? ){
					Write-Output "####################################################`nSomesing go wrong. When copying $BackupFolder\$BackupName`_$Time.7z to $SecondBackupFolder"
				}
			}
		}
		Get-ChildItem $SecondBackupFolder | Sort-Object -Property CreationTime | Select-Object -SkipLast $NumberOfBackups | Remove-Item
	}
}
#BackupMenu#####################################################################################
#RestoreMenu####################################################################################
function 7z_BackupBeforeRestore{
	$Time=(Get-Date -format "dd/MM/yyyy/HH/mm/ss")
	& "$7z_directory\7z.exe" a "$BackupFolder\Backups_before_restore\$BackupName`_$Time.7z" "$RestoreDirectory`*" -bsp1
	if ( !$? ){
		$Script:7z_BackupBeforeRestoreExecution='False'
		Write-Output "Somesing go wrong. When archiving $RestoreDirectory to $BackupFolder\Backups_before_restore\$BackupName`_$Time.7z"
	}
	else
	{
		$Script:7z_BackupBeforeRestoreExecution='True'
		Get-ChildItem $BackupFolder\Backups_before_restore\ | Sort-Object -Property CreationTime | Select-Object -SkipLast $NumberOfBackups | Remove-Item
	}
	
}

function 7z_restore{
	if ( Test-Path -Path "$RestoreDirectory" ){
		Remove-Item "$RestoreDirectory`*" -Recurse
	}
	& "$7z_directory\7z.exe" x $RestoreMenuListSelectedItem -o"$RestoreDirectory" -bsp1
	if ( !$? ){
			Write-Output "Somesing go wrong. When restoring $RestoreMenuListSelectedItem to $RestoreDirectory"
	}
}
#RestoreMenu####################################################################################

function LogForm {
	$LogForm = New-Object System.Windows.Forms.Form
	$LogForm.Text = 'PowerShell 7z Backup and Restore'
	$LogForm.ClientSize = New-Object System.Drawing.Size(566, 371)
	$LogForm.Font = New-Object System.Drawing.Font("Times New Roman",12,[System.Drawing.FontStyle]::Bold)
	$LogForm.BackColor = 'Black'
	$LogForm.ForeColor = 'White'
	$LogForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$LogExitButton = New-Object System.Windows.Forms.Button
	$LogExitButton.Location = New-Object System.Drawing.Point(208, 323)
	$LogExitButton.Size = New-Object System.Drawing.Size(157, 40)
	$LogExitButton.Text = "Ok"
	$LogExitButton.TextAlign = 'MiddleCenter'
	$LogExitButton.UseVisualStyleBackColor = $true
	$LogExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	#######################################################################################################
	$LogLabel = New-Object System.Windows.Forms.Label
	$LogLabel.Location = New-Object System.Drawing.Point(146, 9)
	$LogLabel.AutoSize = $true
	$LogLabel.Size = New-Object System.Drawing.Size(163, 32)
	$LogLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",22,[System.Drawing.FontStyle]::Regular)
	$LogLabel.TextAlign = 'MiddleCenter'
	$LogLabel.Text = "Operational Log"
	#######################################################################################################
	$LogTextBox = New-Object System.Windows.Forms.TextBox
	$LogTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$LogTextBox.Location = New-Object System.Drawing.Point(12, 44)
	$LogTextBox.Multiline = $true
	$LogTextBox.ReadOnly = $true
	$LogTextBox.Size = New-Object System.Drawing.Size(542, 273)
	$LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
	$LogTextBox.Text = ''
	#######################################################################################################
	$LogForm.AcceptButton = $LogExitButton
	$LogForm.Controls.Add($LogExitButton)
	$LogForm.Controls.Add($LogTextBox)
	$LogForm.Controls.Add($LogLabel)
	$LogForm.Topmost = $true
	#######################################################################################################
	function LogFormJobBackup1{
		$LogTextBox.Text = ''
		$LogTextBox.Text = check_directories|Out-String
		7z_save|Out-String -Stream|select-string -Pattern "\S"|ForEach-Object {
			$LogTextBox.Text += "$_"
			$LogTextBox.Text += "`r`n"
			$LogTextBox.SelectionStart = $LogTextBox.TextLength
			$LogTextBox.ScrollToCaret()
		}
	}
	function LogFormJobBackup2{
		$LogTextBox.Text = ''
		$LogTextBox.Text = check_directories|Out-String
		Backup_According_to_day_filter|Out-String -Stream|select-string -Pattern "\S"|ForEach-Object {
			$LogTextBox.Text += "$_"
			$LogTextBox.Text += "`r`n"
			$LogTextBox.SelectionStart = $LogTextBox.TextLength
			$LogTextBox.ScrollToCaret()
		}
		if ([string]::IsNullOrEmpty($LogTextBox.Text)){
			$LogTextBox.Text="There are nothing to backup"
		}
	}
	function LogFormJobRestore1{
		$LogTextBox.Text = ''
		if ( Test-Path -Path $BackupFolder\Backups_before_restore ){}
		else{
			$LogTextBoxText+=New-Item -ItemType Directory $BackupFolder\Backups_before_restore|Out-String
			$LogTextBoxText+=$(Write-Output "#####################################")|Out-String
			$LogTextBox.Text += $LogTextBoxText
		}
		7z_BackupBeforeRestore|Out-String -Stream|select-string -Pattern "\S"|ForEach-Object {
			$LogTextBox.Text += "$_"
			$LogTextBox.Text += "`r`n"
			$LogTextBox.SelectionStart = $LogTextBox.TextLength
			$LogTextBox.ScrollToCaret()
		}
		$LogTextBox.Text += $(Write-Output "#####################################")|Out-String
		$LogTextBox.SelectionStart = $LogTextBox.TextLength
		$LogTextBox.ScrollToCaret()
		if ($7z_BackupBeforeRestoreExecution -eq 'True'){
			7z_restore|Out-String -Stream|select-string -Pattern "\S"|ForEach-Object {
				$LogTextBox.Text += "$_"
				$LogTextBox.Text += "`r`n"
				$LogTextBox.SelectionStart = $LogTextBox.TextLength
				$LogTextBox.ScrollToCaret()
			}
			$LogTextBox.Text += $(Write-Output "#####################################")|Out-String
			$LogTextBox.SelectionStart = $LogTextBox.TextLength
			$LogTextBox.ScrollToCaret()
		}
	}
	function LogFormJobRestore2{
		$LogTextBox.Text = ''
		7z_restore|Out-String -Stream|select-string -Pattern "\S"|ForEach-Object {
			$LogTextBox.Text += "$_"
			$LogTextBox.Text += "`r`n"
			$LogTextBox.SelectionStart = $LogTextBox.TextLength
			$LogTextBox.ScrollToCaret()
		}
		$LogTextBox.Text += $(Write-Output "#####################################")|Out-String
		$LogTextBox.SelectionStart = $LogTextBox.TextLength
		$LogTextBox.ScrollToCaret()
	}
	#######################################################################################################
	$LogForm.add_Shown({
		& $LogFormJob
	})
	$Script:LogResult = $LogForm.ShowDialog()
}

function ErrorForm {
	$ErrorForm = New-Object System.Windows.Forms.Form
	$ErrorForm.Text = 'PowerShell 7z Backup and Restore'
	$ErrorForm.Size = New-Object System.Drawing.Size(516,179)
	$ErrorForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$ErrorForm.BackColor = 'Black'
	$ErrorForm.ForeColor = 'White'
	$ErrorForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$ErrorExitButton = New-Object System.Windows.Forms.Button
	$ErrorExitButton.Location = New-Object System.Drawing.Point(190,95)
	$ErrorExitButton.Size = New-Object System.Drawing.Size(100,35)
	$ErrorExitButton.Text = 'Exit'
	$ErrorExitButton.TextAlign = 'MiddleCenter'
	$ErrorExitButton.Add_Click({
		$ErrorForm.Close()
	})
	#######################################################################################################
	$ErrorLabel = New-Object System.Windows.Forms.Label
	$ErrorLabel.Location = New-Object System.Drawing.Point(10,5)
	$ErrorLabel.Size = New-Object System.Drawing.Size(480,80)
	$ErrorLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$ErrorLabel.TextAlign = 'MiddleCenter'
	$ErrorLabel.Text = "$ErrorLabelText"
	#######################################################################################################
	$ErrorForm.Controls.Add($ErrorExitButton)
	$ErrorForm.AcceptButton = $ErrorExitButton
	$ErrorForm.Controls.Add($ErrorLabel)
	$ErrorForm.Topmost = $true
	#######################################################################################################
	$Script:ErrorResult = $ErrorForm.ShowDialog()
}

function No7zip {
	#######################################################################################################
	$No7zipForm = New-Object System.Windows.Forms.Form
	$No7zipForm.Text = 'PowerShell 7z Backup and Restore'
	$No7zipForm.Size = New-Object System.Drawing.Size(536,219)
	$No7zipForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$No7zipForm.BackColor = 'Black'
	$No7zipForm.ForeColor = 'White'
	$No7zipForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$No7zipExitButton = New-Object System.Windows.Forms.Button
	$No7zipExitButton.Location = New-Object System.Drawing.Point(410,135)
	$No7zipExitButton.Size = New-Object System.Drawing.Size(100,35)
	$No7zipExitButton.Text = 'Exit'
	$No7zipExitButton.TextAlign = 'MiddleCenter'
	$No7zipExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Ok
	#######################################################################################################
	$No7zipOkButton = New-Object System.Windows.Forms.Button
	$No7zipOkButton.Location = New-Object System.Drawing.Point(10,135)
	$No7zipOkButton.Size = New-Object System.Drawing.Size(100,35)
	$No7zipOkButton.Text = 'Ok'
	$No7zipOkButton.TextAlign = 'MiddleCenter'
	$No7zipOkButton.Add_Click({
		if ( Test-Path -Path "$7z_directory\7z.exe" ){
			$Script:run='False'
			VariablesDoNotTouch
			(Get-Content $Path_to_Script).Replace("$ChangeMe2","`$Script:7z_directory`=`"$7z_directory\`" `#2") | Set-Content $Path_to_Script
			$No7zipForm.Close()
		}
		else{
			$Script:ErrorLabelText = "Wrong directory.`nThere are no 7z.exe in directory`n$7z_directory"
			ErrorForm
		}
	})
	#######################################################################################################
	$No7zipFolderButton = New-Object System.Windows.Forms.Button
	$No7zipFolderButton.Location = New-Object System.Drawing.Point(470,95)
	$No7zipFolderButton.Size = New-Object System.Drawing.Size(40,27)
	$No7zipFolderButton.Text = '...'
	$No7zipFolderButton.TextAlign = 'MiddleCenter'
	$No7zipFolderButton.Add_Click({
		$No7zipFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$No7zipFoldername.RootFolder = "MyComputer"
		$No7zipFoldername.SelectedPath = "C:\Program Files\"
		if($No7zipFoldername.ShowDialog() -eq "OK"){
			$Script:7z_directory = $No7zipFoldername.SelectedPath
		}
		(Get-Variable -Name No7zipTextBox -Scope 1).Value.Text = $7z_directory
	})
	#######################################################################################################
	$No7zipLabel = New-Object System.Windows.Forms.Label
	$No7zipLabel.Location = New-Object System.Drawing.Point(10,5)
	$No7zipLabel.Size = New-Object System.Drawing.Size(500,80)
	$No7zipLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$No7zipLabel.TextAlign = 'MiddleCenter'
	$No7zipLabel.Text = "Please install 7-zip from the official website`nhttps://www.7-zip.org/download.html`nOr change the 7-zip folder below, to the path where the executable for 7-Zip is located"
	#######################################################################################################
	$No7zipTextBox = New-Object System.Windows.Forms.TextBox
	$No7zipTextBox.Location = New-Object System.Drawing.Point(10,95)
	$No7zipTextBox.Size = New-Object System.Drawing.Size(450,20)
	$No7zipTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$No7zipTextBox.TextAlign = 'Center'
	$No7zipTextBox.Text = "$7z_directory"
	$No7zipTextBox.ReadOnly = 'True'
	#######################################################################################################
	$No7zipForm.AcceptButton = $No7zipExitButton
	$No7zipForm.Controls.Add($No7zipExitButton)
	$No7zipForm.AcceptButton = $No7zipFolderButton
	$No7zipForm.Controls.Add($No7zipFolderButton)
	$No7zipForm.AcceptButton = $No7zipOkButton
	$No7zipForm.Controls.Add($No7zipOkButton)
	$No7zipForm.Controls.Add($No7zipLabel)
	$No7zipForm.Controls.Add($No7zipTextBox)
	$No7zipForm.Topmost = $true
	######################################################################################################
	$Global:No7zipResult = $No7zipForm.ShowDialog()
}

function BackupMenu {
	DiskVariablesBackup
	#######################################################################################################
	$BackupMenuForm = New-Object System.Windows.Forms.Form
	$BackupMenuForm.Text = 'PowerShell 7z Backup and Restore'
	$BackupMenuForm.Size = New-Object System.Drawing.Size(836,474)
	$BackupMenuForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$BackupMenuForm.BackColor = 'Black'
	$BackupMenuForm.ForeColor = 'White'
	$BackupMenuForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$BackupMenuExitButton = New-Object System.Windows.Forms.Button
	$BackupMenuExitButton.Location = New-Object System.Drawing.Point(360,390)
	$BackupMenuExitButton.Size = New-Object System.Drawing.Size(100,35)
	$BackupMenuExitButton.Text = 'Exit'
	$BackupMenuExitButton.TextAlign = 'MiddleCenter'
	$BackupMenuExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	#######################################################################################################
	$BackupMenuClassicBackupButton = New-Object System.Windows.Forms.Button
	$BackupMenuClassicBackupButton.Location = New-Object System.Drawing.Point(10,30)
	$BackupMenuClassicBackupButton.Size = New-Object System.Drawing.Size(200,60)
	$BackupMenuClassicBackupButton.Text = 'Simple Backup Job'
	$BackupMenuClassicBackupButton.TextAlign = 'MiddleCenter'
	$BackupMenuClassicBackupButton.Add_Click({
		$Script:LogFormJob = {LogFormJobBackup1}
		LogForm
		DiskVariablesBackup
		$BackupMenuSpaceLeftOnDiskLabel.Text = "There is $DriveBackupLeftSpace MB of free space left on drive $DriveLetter_backups.`nFor Automation, you can use this parammetres in command line:`n$Shell_command`nFor Simple Backup Job or`n$Shell_command2`nFor Time Filtred Backup Job"
	})
	#######################################################################################################
	$BackupMenuTimeFiltredBackupButton = New-Object System.Windows.Forms.Button
	$BackupMenuTimeFiltredBackupButton.Location = New-Object System.Drawing.Point(10,100)
	$BackupMenuTimeFiltredBackupButton.Size = New-Object System.Drawing.Size(200,60)
	$BackupMenuTimeFiltredBackupButton.Text = 'Time Filtred Backup Job'
	$BackupMenuTimeFiltredBackupButton.TextAlign = 'MiddleCenter'
	$BackupMenuTimeFiltredBackupButton.Add_Click({
		$Script:LogFormJob = {LogFormJobBackup2}
		LogForm
		DiskVariablesBackup
		$BackupMenuSpaceLeftOnDiskLabel.Text = "There is $DriveBackupLeftSpace MB of free space left on drive $DriveLetter_backups.`nFor Automation, you can use this parammetres in command line:`n$Shell_command`nFor Simple Backup Job or`n$Shell_command2`nFor Time Filtred Backup Job"
	})
	#######################################################################################################
	$BackupMenuLabel = New-Object System.Windows.Forms.Label
	$BackupMenuLabel.Location = New-Object System.Drawing.Point(10,5)
	$BackupMenuLabel.Size = New-Object System.Drawing.Size(800,20)
	$BackupMenuLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$BackupMenuLabel.TextAlign = 'MiddleCenter'
	$BackupMenuLabel.Text = "Please select one of the options below."
	######################################################################################################
	$BackupMenuClassicBackupLabel = New-Object System.Windows.Forms.Label
	$BackupMenuClassicBackupLabel.Location = New-Object System.Drawing.Point(220,30)
	$BackupMenuClassicBackupLabel.Size = New-Object System.Drawing.Size(590,60)
	$BackupMenuClassicBackupLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$BackupMenuClassicBackupLabel.TextAlign = 'MiddleCenter'
	$BackupMenuClassicBackupLabel.Text = "Click this button if you want to make a regular backup copy of the directory specified below"
	$BackupMenuClassicBackupLabel.BorderStyle = "FixedSingle"
	######################################################################################################
	$BackupMenuTimeFiltredBackupLabel = New-Object System.Windows.Forms.Label
	$BackupMenuTimeFiltredBackupLabel.Location = New-Object System.Drawing.Point(220,100)
	$BackupMenuTimeFiltredBackupLabel.Size = New-Object System.Drawing.Size(590,60)
	$BackupMenuTimeFiltredBackupLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$BackupMenuTimeFiltredBackupLabel.TextAlign = 'MiddleCenter'
	$BackupMenuTimeFiltredBackupLabel.Text = "If you want to archive only files older than $BackupDayFilter days in the folder specified below, click this button."
	$BackupMenuTimeFiltredBackupLabel.BorderStyle = "FixedSingle"
	######################################################################################################
	$BackupMenuFromToBackupLabel = New-Object System.Windows.Forms.Label
	$BackupMenuFromToBackupLabel.Location = New-Object System.Drawing.Point(10,170)
	$BackupMenuFromToBackupLabel.Size = New-Object System.Drawing.Size(800,80)
	$BackupMenuFromToBackupLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$BackupMenuFromToBackupLabel.TextAlign = 'MiddleCenter'
	$BackupMenuFromToBackupLabel.Text = "Folder to be archived:`n$WhatToBackup`nBackup folder are located in:`n$BackupFolder"
	######################################################################################################
	$BackupMenuSpaceLeftOnDiskLabel = New-Object System.Windows.Forms.Label
	$BackupMenuSpaceLeftOnDiskLabel.Location = New-Object System.Drawing.Point(10,260)
	$BackupMenuSpaceLeftOnDiskLabel.Size = New-Object System.Drawing.Size(800,120)
	$BackupMenuSpaceLeftOnDiskLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$BackupMenuSpaceLeftOnDiskLabel.TextAlign = 'MiddleCenter'
	$BackupMenuSpaceLeftOnDiskLabel.Text = "There is $DriveBackupLeftSpace MB of free space left on drive $DriveLetter_backups.`nFor Automation, you can use this parammetres in command line:`n$Shell_command`nFor Simple Backup Job or`n$Shell_command2`nFor Time Filtred Backup Job"
	######################################################################################################
	$BackupMenuForm.AcceptButton = $BackupMenuExitButton
	$BackupMenuForm.Controls.Add($BackupMenuExitButton)
	$BackupMenuForm.AcceptButton = $BackupMenuClassicBackupButton
	$BackupMenuForm.Controls.Add($BackupMenuClassicBackupButton)
	$BackupMenuForm.AcceptButton = $BackupMenuTimeFiltredBackupButton
	$BackupMenuForm.Controls.Add($BackupMenuTimeFiltredBackupButton)
	$BackupMenuForm.Controls.Add($BackupMenuLabel)
	$BackupMenuForm.Controls.Add($BackupMenuClassicBackupLabel)
	$BackupMenuForm.Controls.Add($BackupMenuTimeFiltredBackupLabel)
	$BackupMenuForm.Controls.Add($BackupMenuSpaceLeftOnDiskLabel)
	$BackupMenuForm.Controls.Add($BackupMenuFromToBackupLabel)
	$BackupMenuForm.Topmost = $true
	######################################################################################################
	$Script:BackupMenuResult = $BackupMenuForm.ShowDialog()
}

function RestoreMenuList {
	$RestoreMenuListForm = New-Object System.Windows.Forms.Form
	$RestoreMenuListForm.Text = 'PowerShell 7z Backup and Restore'
	$RestoreMenuListForm.ClientSize = New-Object System.Drawing.Size(579, 245)
	$RestoreMenuListForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$RestoreMenuListForm.BackColor = 'Black'
	$RestoreMenuListForm.ForeColor = 'White'
	$RestoreMenuListForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$RestoreMenuListExitButton = New-Object System.Windows.Forms.Button
	$RestoreMenuListExitButton.Location = New-Object System.Drawing.Point(458, 198)
	$RestoreMenuListExitButton.Size = New-Object System.Drawing.Size(100,35)
	$RestoreMenuListExitButton.Text = 'Exit'
	$RestoreMenuListExitButton.TextAlign = 'MiddleCenter'
	$RestoreMenuListExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	#######################################################################################################
	$RestoreMenuListOKButton = New-Object System.Windows.Forms.Button
	$RestoreMenuListOKButton.Location = New-Object System.Drawing.Point(16, 198)
	$RestoreMenuListOKButton.Size = New-Object System.Drawing.Size(100,35)
	$RestoreMenuListOKButton.Text = 'OK'
	$RestoreMenuListOKButton.TextAlign = 'MiddleCenter'
	$RestoreMenuListOKButton.Add_Click({
		$RestoreMenuListSelectedItem=$RestoreMenuList.SelectedItem
		if ($RestoreMenuCheckBox.Checked -and $RestoreAfterDisasterClick -eq 'False'){
			$Script:LogFormJob = {LogFormJobRestore1}
			LogForm
			DiskVariablesRestore
		}
		else{
			$Script:LogFormJob = {LogFormJobRestore2}
			LogForm
			DiskVariablesRestore
		}
	})
	#######################################################################################################
	$RestoreMenuListLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuListLabel.Location = New-Object System.Drawing.Point(12, 9)
	$RestoreMenuListLabel.Size = New-Object System.Drawing.Size(555, 42)
	$RestoreMenuListLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuListLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuListLabel.Text = "Select one backup from the list that you want to restore and click OK to start the recovery process"
	######################################################################################################
	$RestoreMenuList = New-Object System.Windows.Forms.ListBox
	$RestoreMenuList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$RestoreMenuList.FormattingEnabled = $true
	$RestoreMenuList.Location = New-Object System.Drawing.Point(16, 55)
	$RestoreMenuList.ScrollAlwaysVisible = $true
	$RestoreMenuList.HorizontalScrollbar = $true
	$RestoreMenuList.Size = New-Object System.Drawing.Size(549, 132)
	$RestoreMenuList.Font = New-Object System.Drawing.Font("Cascadia Mono",10,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuListObjectsCount=($RestoreMenuListObjects|Measure-Object).Count
	if ($RestoreMenuListObjectsCount -eq 1){
		$RestoreMenuList.Items.Add("$RestoreMenuListObjects")
	}
	elseif ($RestoreMenuListObjectsCount -eq 0){}
	else{
		$RestoreMenuList.Items.AddRange(@(
			$RestoreMenuListObjects
		))
	}
	$RestoreMenuList.Add_Click({
		if ($RestoreMenuList.SelectedItem){
			$RestoreMenuListOKButton.Enabled = $true
		}
	})
	######################################################################################################
	$RestoreMenuListForm.AcceptButton = $RestoreMenuListExitButton
	$RestoreMenuListForm.Controls.Add($RestoreMenuListExitButton)
	$RestoreMenuListForm.AcceptButton = $RestoreMenuListOKButton
	$RestoreMenuListForm.Controls.Add($RestoreMenuListOKButton)
	$RestoreMenuListForm.Controls.Add($RestoreMenuListLabel)
	$RestoreMenuListForm.Controls.Add($RestoreMenuList)
	$RestoreMenuListForm.Topmost = $true
	######################################################################################################
	if ($RestoreMenuList.SelectedItem){}
		else{
			$RestoreMenuListOKButton.Enabled = $false
		}
	$Script:RestoreMenuListResult = $RestoreMenuListForm.ShowDialog()
}

function RestoreMenu {
	DiskVariablesRestore
	#######################################################################################################
	$RestoreMenuForm = New-Object System.Windows.Forms.Form
	$RestoreMenuForm.Text = 'PowerShell 7z Backup and Restore'
	$RestoreMenuForm.ClientSize = New-Object System.Drawing.Size(812, 396)
	$RestoreMenuForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$RestoreMenuForm.BackColor = 'Black'
	$RestoreMenuForm.ForeColor = 'White'
	$RestoreMenuForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$RestoreMenuExitButton = New-Object System.Windows.Forms.Button
	$RestoreMenuExitButton.Location = New-Object System.Drawing.Point(363, 355)
	$RestoreMenuExitButton.Size = New-Object System.Drawing.Size(100,35)
	$RestoreMenuExitButton.Text = 'Exit'
	$RestoreMenuExitButton.TextAlign = 'MiddleCenter'
	$RestoreMenuExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	#######################################################################################################
	$RestoreMenuClassicRestoreButton = New-Object System.Windows.Forms.Button
	$RestoreMenuClassicRestoreButton.Location = New-Object System.Drawing.Point(12, 71)
	$RestoreMenuClassicRestoreButton.Size = New-Object System.Drawing.Size(175, 65)
	$RestoreMenuClassicRestoreButton.Text = 'Restore Backup Job'
	$RestoreMenuClassicRestoreButton.TextAlign = 'MiddleCenter'
	$RestoreMenuClassicRestoreButton.Add_Click({
		$Script:RestoreMenuListObjects = @($((Get-ChildItem $BackupFolder -Exclude Backups_before_restore).FullName))
		$Script:RestoreAfterDisasterClick = 'False'
		RestoreMenuList
	})
	#######################################################################################################
	$RestoreMenuRestoreAfterDisasterButton = New-Object System.Windows.Forms.Button
	$RestoreMenuRestoreAfterDisasterButton.Location = New-Object System.Drawing.Point(12, 143)
	$RestoreMenuRestoreAfterDisasterButton.Size = New-Object System.Drawing.Size(175, 65)
	$RestoreMenuRestoreAfterDisasterButton.Text = 'Restore After Disaster Job'
	$RestoreMenuRestoreAfterDisasterButton.TextAlign = 'MiddleCenter'
	$RestoreMenuRestoreAfterDisasterButton.Add_Click({
		if ( Test-Path -Path $BackupFolder\Backups_before_restore ){}
		else{
			New-Item -ItemType Directory $BackupFolder\Backups_before_restore
		}
		$Script:RestoreMenuListObjects = @($((Get-ChildItem $BackupFolder\Backups_before_restore).FullName))
		$Script:RestoreAfterDisasterClick = 'True'
		RestoreMenuList
	})
	#######################################################################################################
	$RestoreMenuCheckBox = New-Object System.Windows.Forms.CheckBox
	$RestoreMenuCheckBox.Checked = $true
	$RestoreMenuCheckBox.CheckState = [System.Windows.Forms.CheckState]::Checked
	$RestoreMenuCheckBox.Location = New-Object System.Drawing.Point(129, 35)
	$RestoreMenuCheckBox.Size = New-Object System.Drawing.Size(555, 33)
	$RestoreMenuCheckBox.Text = "Make a backup before restoring an archive copy?"
	$RestoreMenuCheckBox.Add_CheckStateChanged({
		if ($RestoreMenuCheckBox.Checked){
			$RestoreMenuRestoreAfterDisasterButton.Enabled = $true
		}
		else{
			$RestoreMenuRestoreAfterDisasterButton.Enabled = $false
		}
	})
	#######################################################################################################
	$RestoreMenuLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuLabel.Location = New-Object System.Drawing.Point(211, 9)
	$RestoreMenuLabel.Size = New-Object System.Drawing.Size(391, 23)
	$RestoreMenuLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuLabel.Text = "Please select one of the options below"
	######################################################################################################
	$RestoreMenuClassicRestoreLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuClassicRestoreLabel.Location = New-Object System.Drawing.Point(193, 71)
	$RestoreMenuClassicRestoreLabel.Size = New-Object System.Drawing.Size(607, 65)
	$RestoreMenuClassicRestoreLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuClassicRestoreLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuClassicRestoreLabel.Text = "Click this button if you want to restore one of your backups selected from the list to the directory specified below."
	$RestoreMenuClassicRestoreLabel.BorderStyle = "FixedSingle"
	######################################################################################################
	$RestoreMenuRestoreAfterDisasterLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuRestoreAfterDisasterLabel.Location = New-Object System.Drawing.Point(193, 143)
	$RestoreMenuRestoreAfterDisasterLabel.Size = New-Object System.Drawing.Size(607, 65)
	$RestoreMenuRestoreAfterDisasterLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuRestoreAfterDisasterLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuRestoreAfterDisasterLabel.Text = "It works only if you check the box `'Make a backup before restoring an archive copy?`'. By clicking this button, you can restore the backup that was made before the previous restore."
	$RestoreMenuRestoreAfterDisasterLabel.BorderStyle = "FixedSingle"
	######################################################################################################
	$RestoreMenuFromToRestoreLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuFromToRestoreLabel.Location = New-Object System.Drawing.Point(103, 213)
	$RestoreMenuFromToRestoreLabel.Size = New-Object System.Drawing.Size(607, 86)
	$RestoreMenuFromToRestoreLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuFromToRestoreLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuFromToRestoreLabel.Text = "Folder to which to restore the backup:`n$RestoreDirectory`nBackup folder are located in:`n$BackupFolder"
	######################################################################################################
	$RestoreMenuSpaceLeftOnDiskLabel = New-Object System.Windows.Forms.Label
	$RestoreMenuSpaceLeftOnDiskLabel.Location = New-Object System.Drawing.Point(103, 309)
	$RestoreMenuSpaceLeftOnDiskLabel.Size = New-Object System.Drawing.Size(607, 43)
	$RestoreMenuSpaceLeftOnDiskLabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$RestoreMenuSpaceLeftOnDiskLabel.TextAlign = 'MiddleCenter'
	$RestoreMenuSpaceLeftOnDiskLabel.Text = "There is $DriveRestoreLeftSpace MB of free space left on drive $DriveLetter_restore."
	######################################################################################################
	$RestoreMenuForm.AcceptButton = $RestoreMenuExitButton
	$RestoreMenuForm.Controls.Add($RestoreMenuExitButton)
	$RestoreMenuForm.Controls.Add($RestoreMenuCheckBox)
	$RestoreMenuForm.AcceptButton = $RestoreMenuClassicRestoreButton
	$RestoreMenuForm.Controls.Add($RestoreMenuClassicRestoreButton)
	$RestoreMenuForm.AcceptButton = $RestoreMenuRestoreAfterDisasterButton
	$RestoreMenuForm.Controls.Add($RestoreMenuRestoreAfterDisasterButton)
	$RestoreMenuForm.Controls.Add($RestoreMenuLabel)
	$RestoreMenuForm.Controls.Add($RestoreMenuClassicRestoreLabel)
	$RestoreMenuForm.Controls.Add($RestoreMenuRestoreAfterDisasterLabel)
	$RestoreMenuForm.Controls.Add($RestoreMenuSpaceLeftOnDiskLabel)
	$RestoreMenuForm.Controls.Add($RestoreMenuFromToRestoreLabel)
	$RestoreMenuForm.Topmost = $true
	######################################################################################################
	if ($RestoreMenuCheckBox.Checked){
		$RestoreMenuRestoreAfterDisasterButton.Enabled = $true
	}
	else{
		$RestoreMenuRestoreAfterDisasterButton.Enabled = $false
	}
	$Script:RestoreMenuResult = $RestoreMenuForm.ShowDialog()
}

function AdvancedMenu {
	$AdvancedMenuForm = New-Object System.Windows.Forms.Form
	$AdvancedMenuForm.Text = 'PowerShell 7z Backup and Restore'
	$AdvancedMenuForm.ClientSize = New-Object System.Drawing.Size(983, 466)
	$AdvancedMenuForm.Font = New-Object System.Drawing.Font("Times New Roman", 18,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point, 204)
	$AdvancedMenuForm.BackColor = [System.Drawing.Color]::Black
	$AdvancedMenuForm.ForeColor = [System.Drawing.Color]::White
	$AdvancedMenuForm.StartPosition = 'CenterScreen'
	$AdvancedMenuForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
	$AdvancedMenuForm.Margin = New-Object System.Windows.Forms.Padding(7, 6, 7, 6)
	#######################################################################################################
	$AdvancedMenuExitButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuExitButton.Location = New-Object System.Drawing.Point(887, 422)
	$AdvancedMenuExitButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuExitButton.Text = "Exit"
	$AdvancedMenuExitButton.UseVisualStyleBackColor = $true
	$AdvancedMenuExitButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuExitButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	#######################################################################################################
	$AdvancedMenuOkButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuOkButton.Location = New-Object System.Drawing.Point(12, 422)
	$AdvancedMenuOkButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuOkButton.Text = "Ok"
	$AdvancedMenuOkButton.UseVisualStyleBackColor = $true
	$AdvancedMenuOkButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuOkButton.Add_Click({
		$Script:BackupName = $AdvancedMenuBackupNameTextBox.Text
		$Script:BackupName = $BackupName -Replace '[\W]',''
		if ([string]::IsNullOrEmpty($BackupFolder) -or [string]::IsNullOrEmpty($BackupName) -or [string]::IsNullOrEmpty($WhatToBackup) -or [string]::IsNullOrEmpty($NumberOfBackups)){
			$Script:ErrorLabelText = "Please fill in all required fields"
			ErrorForm
		}
		else{
			VariablesDoNotTouch
			(Get-Content $Path_to_Script).Replace("$ChangeMe4","`$Script:BackupName`=`"$BackupName`" `#4") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe2","`$Script:7z_directory`=`"$7z_directory`" `#2") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe6","`$Script:RestoreDirectory`=`"$RestoreDirectory`" `#6") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe3","`$Script:SecondBackupFolder`=`"$SecondBackupFolder`" `#3") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe8","`$Script:BackupDayFilter`=`"$BackupDayFilter`" `#8") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe7","`$Script:NumberOfBackups`=`"$NumberOfBackups`" `#7") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe1","`$Script:BackupFolder`=`"$BackupFolder`" `#1") | Set-Content $Path_to_Script
			(Get-Content $Path_to_Script).Replace("$ChangeMe5","`$Script:WhatToBackup`=`"$WhatToBackup`" `#5") | Set-Content $Path_to_Script
			$ErrorLabelText = 'The configurations are set, please restart the script'
			ErrorForm
			$AdvancedMenuForm.Close()
		}
	})
	#######################################################################################################
	$AdvancedMenuClearConfigButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuClearConfigButton.Location = New-Object System.Drawing.Point(414, 422)
	$AdvancedMenuClearConfigButton.Size = New-Object System.Drawing.Size(154, 35)
	$AdvancedMenuClearConfigButton.Text = "Clear Config"
	$AdvancedMenuClearConfigButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuClearConfigButton.Add_Click({
		VariablesDoNotTouch
		$Script:BackupFolder=""
		$Script:7z_directory="C:\Program Files\7-Zip\"
		$Script:SecondBackupFolder=""
		$Script:BackupName=""
		$Script:WhatToBackup=""
		$Script:RestoreDirectory=""
		$Script:NumberOfBackups="2"
		$Script:BackupDayFilter="15"
		(Get-Content $Path_to_Script).Replace("$ChangeMe4","`$Script:BackupName`=`"$BackupName`" `#4") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe2","`$Script:7z_directory`=`"$7z_directory`" `#2") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe6","`$Script:RestoreDirectory`=`"$RestoreDirectory`" `#6") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe3","`$Script:SecondBackupFolder`=`"$SecondBackupFolder`" `#3") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe8","`$Script:BackupDayFilter`=`"$BackupDayFilter`" `#8") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe7","`$Script:NumberOfBackups`=`"$NumberOfBackups`" `#7") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe1","`$Script:BackupFolder`=`"$BackupFolder`" `#1") | Set-Content $Path_to_Script
		(Get-Content $Path_to_Script).Replace("$ChangeMe5","`$Script:WhatToBackup`=`"$WhatToBackup`" `#5") | Set-Content $Path_to_Script
		(Get-Variable -Name AdvancedMenuBackupFolderTextBox -Scope 1).Value.Text = $BackupFolder
		(Get-Variable -Name AdvancedMenuSecondBackupFolderTextBox -Scope 1).Value.Text = $SecondBackupFolder
		(Get-Variable -Name AdvancedMenuWhatToBackupTextBox -Scope 1).Value.Text = $WhatToBackup
		(Get-Variable -Name AdvancedMenu7zDirectoryTextBox -Scope 1).Value.Text = $7z_directory
		(Get-Variable -Name AdvancedMenuRestoreFolderTextBox -Scope 1).Value.Text = $RestoreDirectory
		(Get-Variable -Name AdvancedMenuBackupNameTextBox -Scope 1).Value.Text = $BackupName
		(Get-Variable -Name AdvancedMenuBackupAmountTextBox -Scope 1).Value.Text = $NumberOfBackups
		(Get-Variable -Name AdvancedMenuBackupDayFilterTextBox -Scope 1).Value.Text = $BackupDayFilter
	})
	#######################################################################################################
	$AdvancedMenuBackupFolderButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuBackupFolderButton.Location = New-Object System.Drawing.Point(472, 83)
	$AdvancedMenuBackupFolderButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuBackupFolderButton.Text = "..."
	$AdvancedMenuBackupFolderButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuBackupFolderButton.Add_Click({
		$AdvancedMenuBackupFolderButtonFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$AdvancedMenuBackupFolderButtonFoldername.RootFolder = "MyComputer"
		if($AdvancedMenuBackupFolderButtonFoldername.ShowDialog() -eq "OK"){
			$Script:BackupFolder = $AdvancedMenuBackupFolderButtonFoldername.SelectedPath
			$Script:BackupFolder += '\'
		}
		(Get-Variable -Name AdvancedMenuBackupFolderTextBox -Scope 1).Value.Text = $BackupFolder
	})
	
	#######################################################################################################
	$AdvancedMenuSecondBackupFolderButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuSecondBackupFolderButton.Location = New-Object System.Drawing.Point(472, 124)
	$AdvancedMenuSecondBackupFolderButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuSecondBackupFolderButton.Text = "..."
	$AdvancedMenuSecondBackupFolderButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuSecondBackupFolderButton.Add_Click({
		$AdvancedMenuSecondBackupFolderButtonFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$AdvancedMenuSecondBackupFolderButtonFoldername.RootFolder = "MyComputer"
		if($AdvancedMenuSecondBackupFolderButtonFoldername.ShowDialog() -eq "OK"){
			$Script:SecondBackupFolder = $AdvancedMenuSecondBackupFolderButtonFoldername.SelectedPath
			$Script:SecondBackupFolder += '\'
		}
		(Get-Variable -Name AdvancedMenuSecondBackupFolderTextBox -Scope 1).Value.Text = $SecondBackupFolder
	})
	#######################################################################################################
	$AdvancedMenuBackupAmountPlusButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuBackupAmountPlusButton.Font = New-Object System.Drawing.Font("Times New Roman", 14)
	$AdvancedMenuBackupAmountPlusButton.Location = New-Object System.Drawing.Point(472, 165)
	$AdvancedMenuBackupAmountPlusButton.Size = New-Object System.Drawing.Size(39, 35)
	$AdvancedMenuBackupAmountPlusButton.Text = "+1"
	$AdvancedMenuBackupAmountPlusButton.UseVisualStyleBackColor = $true
	$AdvancedMenuBackupAmountPlusButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuBackupAmountPlusButton.Add_Click({
		[decimal]$Script:NumberOfBackups +=1
		$AdvancedMenuBackupAmountTextBox.Text = "$NumberOfBackups"
	})
	#######################################################################################################
	$AdvancedMenuBackupAmountMinusButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuBackupAmountMinusButton.Font = New-Object System.Drawing.Font("Times New Roman", 14)
	$AdvancedMenuBackupAmountMinusButton.Location = New-Object System.Drawing.Point(516, 165)
	$AdvancedMenuBackupAmountMinusButton.Size = New-Object System.Drawing.Size(39, 35)
	$AdvancedMenuBackupAmountMinusButton.Text = "-1"
	$AdvancedMenuBackupAmountMinusButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuBackupAmountMinusButton.Add_Click({
		[decimal]$Script:NumberOfBackups -=1
		if ($NumberOfBackups -eq '0'){
			$Script:NumberOfBackups = 1
		}
		$AdvancedMenuBackupAmountTextBox.Text = "$NumberOfBackups"
	})
	#######################################################################################################
	$AdvancedMenuBackupDayFilterPlusButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuBackupDayFilterPlusButton.Font = New-Object System.Drawing.Font("Times New Roman", 14)
	$AdvancedMenuBackupDayFilterPlusButton.Location = New-Object System.Drawing.Point(472, 214)
	$AdvancedMenuBackupDayFilterPlusButton.Size = New-Object System.Drawing.Size(39, 35)
	$AdvancedMenuBackupDayFilterPlusButton.Text = "+1"
	$AdvancedMenuBackupDayFilterPlusButton.UseVisualStyleBackColor = $true
	$AdvancedMenuBackupDayFilterPlusButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuBackupDayFilterPlusButton.Add_Click({
		[decimal]$Script:BackupDayFilter +=1
		$AdvancedMenuBackupDayFilterTextBox.Text = "$BackupDayFilter"
	})
	#######################################################################################################
	$AdvancedMenuBackupDayFilterMinusButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuBackupDayFilterMinusButton.Font = New-Object System.Drawing.Font("Times New Roman", 14)
	$AdvancedMenuBackupDayFilterMinusButton.Location = New-Object System.Drawing.Point(516, 214)
	$AdvancedMenuBackupDayFilterMinusButton.Size = New-Object System.Drawing.Size(39, 35)
	$AdvancedMenuBackupDayFilterMinusButton.Text = "-1"
	$AdvancedMenuBackupDayFilterMinusButton.UseVisualStyleBackColor = $true
	$AdvancedMenuBackupDayFilterMinusButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuBackupDayFilterMinusButton.Add_Click({
		[decimal]$Script:BackupDayFilter -=1
		if ($BackupDayFilter -eq '0'){
			$Script:BackupDayFilter = 1
		}
		$AdvancedMenuBackupDayFilterTextBox.Text = "$BackupDayFilter"
	})
	#######################################################################################################
	$AdvancedMenuWhatToBackupButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuWhatToBackupButton.Location = New-Object System.Drawing.Point(471, 271)
	$AdvancedMenuWhatToBackupButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuWhatToBackupButton.Text = "..."
	$AdvancedMenuWhatToBackupButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuWhatToBackupButton.Add_Click({
		$AdvancedMenuWhatToBackupButtonFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$AdvancedMenuWhatToBackupButtonFoldername.RootFolder = "MyComputer"
		if($AdvancedMenuWhatToBackupButtonFoldername.ShowDialog() -eq "OK"){
			$Script:WhatToBackup = $AdvancedMenuWhatToBackupButtonFoldername.SelectedPath
			$Script:WhatToBackup += '\'
		}
		(Get-Variable -Name AdvancedMenuWhatToBackupTextBox -Scope 1).Value.Text = $WhatToBackup
	})
	#######################################################################################################
	$AdvancedMenuRestoreFolderButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuRestoreFolderButton.Location = New-Object System.Drawing.Point(472, 312)
	$AdvancedMenuRestoreFolderButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenuRestoreFolderButton.Text = "..."
	$AdvancedMenuRestoreFolderButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuRestoreFolderButton.Add_Click({
		$AdvancedMenuRestoreFolderButtonFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$AdvancedMenuRestoreFolderButtonFoldername.RootFolder = "MyComputer"
		if($AdvancedMenuRestoreFolderButtonFoldername.ShowDialog() -eq "OK"){
			$Script:RestoreDirectory = $AdvancedMenuRestoreFolderButtonFoldername.SelectedPath
			$Script:RestoreDirectory += '\'
		}
		(Get-Variable -Name AdvancedMenuRestoreFolderTextBox -Scope 1).Value.Text = $RestoreDirectory
	})
	#######################################################################################################
	$AdvancedMenu7ZipButton = New-Object System.Windows.Forms.Button
	$AdvancedMenu7ZipButton.Location = New-Object System.Drawing.Point(472, 370)
	$AdvancedMenu7ZipButton.Size = New-Object System.Drawing.Size(84, 35)
	$AdvancedMenu7ZipButton.Text = "..."
	$AdvancedMenu7ZipButton.TextAlign = 'MiddleCenter'
	$AdvancedMenu7ZipButton.Add_Click({
		$AdvancedMenu7ZipButtonFoldername = New-Object System.Windows.Forms.FolderBrowserDialog
		$AdvancedMenu7ZipButtonFoldername.RootFolder = "MyComputer"
		$AdvancedMenu7ZipButtonFoldername.SelectedPath = "C:\Program Files\"
		if($AdvancedMenu7ZipButtonFoldername.ShowDialog() -eq "OK"){
			$Script:7z_directory = $AdvancedMenu7ZipButtonFoldername.SelectedPath
			$Script:7z_directory += '\'
		}
		(Get-Variable -Name AdvancedMenu7zDirectoryTextBox -Scope 1).Value.Text = $7z_directory
		if ( Test-Path -Path "$7z_directory\7z.exe" ){}
		else{
			$Script:ErrorLabelText = "Wrong directory.`nThere are no 7z.exe in directory`n$7z_directory"
			ErrorForm
			$Script:7z_directory="C:\Program Files\7-Zip\"
			(Get-Variable -Name AdvancedMenu7zDirectoryTextBox -Scope 1).Value.Text = $7z_directory
		}
	})
	#######################################################################################################
	$AdvancedMenuLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuLabel.Location = New-Object System.Drawing.Point(60, 9)
	$AdvancedMenuLabel.Size = New-Object System.Drawing.Size(862, 30)
	$AdvancedMenuLabel.Text = "Welcome. Set all the settings before using the program."
	$AdvancedMenuLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
	#######################################################################################################
	$AdvancedMenuBackupNameLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuBackupNameLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuBackupNameLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuBackupNameLabel.Location = New-Object System.Drawing.Point(562, 42)
	$AdvancedMenuBackupNameLabel.Size = New-Object System.Drawing.Size(409, 35)
	$AdvancedMenuBackupNameLabel.Text = "* Enter a backup name here. *This is Mandatory field"
	$AdvancedMenuBackupNameLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuBackupFolderLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuBackupFolderLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuBackupFolderLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuBackupFolderLabel.Location = New-Object System.Drawing.Point(562, 83)
	$AdvancedMenuBackupFolderLabel.Size = New-Object System.Drawing.Size(409, 35)
	$AdvancedMenuBackupFolderLabel.Text = "* Select a folder to store your backups. *This is Mandatory field"
	$AdvancedMenuBackupFolderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuSecondBackupFolderLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuSecondBackupFolderLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuSecondBackupFolderLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuSecondBackupFolderLabel.Location = New-Object System.Drawing.Point(562, 124)
	$AdvancedMenuSecondBackupFolderLabel.Size = New-Object System.Drawing.Size(409, 35)
	$AdvancedMenuSecondBackupFolderLabel.Text = "If you want to create a copy of your backup in another directory, specify it here."
	$AdvancedMenuSecondBackupFolderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuBackupAmountLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuBackupAmountLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuBackupAmountLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuBackupAmountLabel.Location = New-Object System.Drawing.Point(562, 165)
	$AdvancedMenuBackupAmountLabel.Size = New-Object System.Drawing.Size(409, 35)
	$AdvancedMenuBackupAmountLabel.Text = "* Specify how many backups you would like to keep. *This is Mandatory field"
	$AdvancedMenuBackupAmountLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuBackupDayFilterLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuBackupDayFilterLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuBackupDayFilterLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuBackupDayFilterLabel.Location = New-Object System.Drawing.Point(562, 206)
	$AdvancedMenuBackupDayFilterLabel.Size = New-Object System.Drawing.Size(409, 54)
	$AdvancedMenuBackupDayFilterLabel.Text = "If you want to archive only files in the directory that were created several days ago. In this field, specify the number of days that will be used as a filter for archiving."
	$AdvancedMenuBackupDayFilterLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuWhatToBackupLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuWhatToBackupLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuWhatToBackupLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuWhatToBackupLabel.Location = New-Object System.Drawing.Point(562, 270)
	$AdvancedMenuWhatToBackupLabel.Size = New-Object System.Drawing.Size(409, 35)
	$AdvancedMenuWhatToBackupLabel.Text = "* Select the directory you want to archive. *This is Mandatory field"
	$AdvancedMenuWhatToBackupLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft#######################################################################################################
	$AdvancedMenuRestoreFolderLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenuRestoreFolderLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenuRestoreFolderLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenuRestoreFolderLabel.Location = New-Object System.Drawing.Point(562, 314)
	$AdvancedMenuRestoreFolderLabel.Size = New-Object System.Drawing.Size(409, 36)
	$AdvancedMenuRestoreFolderLabel.Text = "Select the directory that will be used when restoring the archive. Usually this directory is the same as the folder that will be archived."
	$AdvancedMenuRestoreFolderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft#######################################################################################################
	$AdvancedMenu7zDirectoryLabel = New-Object System.Windows.Forms.Label
	$AdvancedMenu7zDirectoryLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
	$AdvancedMenu7zDirectoryLabel.Font = New-Object System.Drawing.Font("Times New Roman", 10)
	$AdvancedMenu7zDirectoryLabel.Location = New-Object System.Drawing.Point(562, 359)
	$AdvancedMenu7zDirectoryLabel.Size = New-Object System.Drawing.Size(409, 60)
	$AdvancedMenu7zDirectoryLabel.Text = "* Specify the directory where the 7-zip archiving program is located. Or install it from the official source: https://www.7-zip.org/download.html. *This is Mandatory field"
	$AdvancedMenu7zDirectoryLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	#######################################################################################################
	$AdvancedMenuBackupNameTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuBackupNameTextBox.Location = New-Object System.Drawing.Point(12, 42)
	$AdvancedMenuBackupNameTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuBackupNameTextBox.Text = "$BackupName"
	$AdvancedMenuBackupNameTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	#######################################################################################################
	$AdvancedMenuBackupFolderTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuBackupFolderTextBox.Location = New-Object System.Drawing.Point(11, 83)
	$AdvancedMenuBackupFolderTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuBackupFolderTextBox.Text = "$BackupFolder"
	$AdvancedMenuBackupFolderTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuBackupFolderTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuSecondBackupFolderTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuSecondBackupFolderTextBox.Location = New-Object System.Drawing.Point(12, 124)
	$AdvancedMenuSecondBackupFolderTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuSecondBackupFolderTextBox.Text = "$SecondBackupFolder"
	$AdvancedMenuSecondBackupFolderTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuSecondBackupFolderTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuBackupAmountTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuBackupAmountTextBox.Location = New-Object System.Drawing.Point(12, 165)
	$AdvancedMenuBackupAmountTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuBackupAmountTextBox.Text = "$NumberOfBackups"
	$AdvancedMenuBackupAmountTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuBackupAmountTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuBackupDayFilterTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuBackupDayFilterTextBox.Location = New-Object System.Drawing.Point(12, 214)
	$AdvancedMenuBackupDayFilterTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuBackupDayFilterTextBox.Text = "$BackupDayFilter"
	$AdvancedMenuBackupDayFilterTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuBackupDayFilterTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuWhatToBackupTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuWhatToBackupTextBox.Location = New-Object System.Drawing.Point(11, 271)
	$AdvancedMenuWhatToBackupTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuWhatToBackupTextBox.Text = "$WhatToBackup"
	$AdvancedMenuWhatToBackupTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuWhatToBackupTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuRestoreFolderTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenuRestoreFolderTextBox.Location = New-Object System.Drawing.Point(12, 312)
	$AdvancedMenuRestoreFolderTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenuRestoreFolderTextBox.Text = "$RestoreDirectory"
	$AdvancedMenuRestoreFolderTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenuRestoreFolderTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenu7zDirectoryTextBox = New-Object System.Windows.Forms.TextBox
	$AdvancedMenu7zDirectoryTextBox.Location = New-Object System.Drawing.Point(11, 370)
	$AdvancedMenu7zDirectoryTextBox.Size = New-Object System.Drawing.Size(454, 35)
	$AdvancedMenu7zDirectoryTextBox.Text = "$7z_directory"
	$AdvancedMenu7zDirectoryTextBox.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$AdvancedMenu7zDirectoryTextBox.ReadOnly = $true
	#######################################################################################################
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuExitButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuExitButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuOkButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuOkButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuClearConfigButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuClearConfigButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuBackupFolderButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupFolderButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuSecondBackupFolderButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuSecondBackupFolderButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuBackupAmountPlusButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupAmountPlusButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuBackupAmountMinusButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupAmountMinusButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuBackupDayFilterPlusButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupDayFilterPlusButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuBackupDayFilterMinusButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupDayFilterMinusButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuWhatToBackupButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuWhatToBackupButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenuRestoreFolderButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenuRestoreFolderButton)
	$AdvancedMenuForm.AcceptButton = $AdvancedMenu7ZipButton
	$AdvancedMenuForm.Controls.Add($AdvancedMenu7ZipButton)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupNameLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupFolderLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuSecondBackupFolderLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupAmountLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupDayFilterLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuWhatToBackupLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuRestoreFolderLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenu7zDirectoryLabel)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupNameTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupFolderTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuSecondBackupFolderTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupAmountTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuBackupDayFilterTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuWhatToBackupTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenuRestoreFolderTextBox)
	$AdvancedMenuForm.Controls.Add($AdvancedMenu7zDirectoryTextBox)
	$AdvancedMenuForm.Topmost = $true
	#######################################################################################################
	$Script:AdvancedMenuResult = $AdvancedMenuForm.ShowDialog()
}

function Backup_directory {
	explorer "$BackupFolder"
}

function Restore_directory {
	explorer "$RestoreDirectory"
}

function MainMenu {
	$MainMenuForm = New-Object System.Windows.Forms.Form
	$MainMenuForm.Text = 'PowerShell 7z Backup and Restore'
	$MainMenuForm.Size = New-Object System.Drawing.Size(436,284)
	$MainMenuForm.Font = New-Object System.Drawing.Font("Times New Roman",18,[System.Drawing.FontStyle]::Bold)
	$MainMenuForm.BackColor = 'Black'
	$MainMenuForm.ForeColor = 'White'
	$MainMenuForm.StartPosition = 'CenterScreen'
	#######################################################################################################
	$ExitButton = New-Object System.Windows.Forms.Button
	$ExitButton.Location = New-Object System.Drawing.Point(160,205)
	$ExitButton.Size = New-Object System.Drawing.Size(100,35)
	$ExitButton.Text = 'Exit'
	$ExitButton.TextAlign = 'MiddleCenter'
	$ExitButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	#######################################################################################################
	$BackupButton = New-Object System.Windows.Forms.Button
	$BackupButton.Location = New-Object System.Drawing.Point(5,50)
	$BackupButton.Size = New-Object System.Drawing.Size(200,40)
	$BackupButton.Text = 'Backup menu'
	$BackupButton.TextAlign = 'MiddleCenter'
	$BackupButton.Add_Click({
		BackupMenu
	})
	#######################################################################################################
	$RestoreButton = New-Object System.Windows.Forms.Button
	$RestoreButton.Location = New-Object System.Drawing.Point(215,50)
	$RestoreButton.Size = New-Object System.Drawing.Size(200,40)
	$RestoreButton.Text = 'Restore Menu'
	$RestoreButton.TextAlign = 'MiddleCenter'
	$RestoreButton.Add_Click({
		if ([string]::IsNullOrEmpty($RestoreDirectory)){
			$Script:ErrorLabelText = "Please fill in the optional field in the settings menu associated with the recovery directory."
			ErrorForm
		}
		else{		
			RestoreMenu
		}
	})
	#######################################################################################################
	$OpenBackupFolderButton = New-Object System.Windows.Forms.Button
	$OpenBackupFolderButton.Location = New-Object System.Drawing.Point(5,95)
	$OpenBackupFolderButton.Size = New-Object System.Drawing.Size(200,65)
	$OpenBackupFolderButton.Text = 'Open Backup Folder'
	$OpenBackupFolderButton.TextAlign = 'MiddleCenter'
	$OpenBackupFolderButton.Add_Click({
		Backup_directory
	})
	#######################################################################################################
	$OpenRestoreFolderButton = New-Object System.Windows.Forms.Button
	$OpenRestoreFolderButton.Location = New-Object System.Drawing.Point(215,95)
	$OpenRestoreFolderButton.Size = New-Object System.Drawing.Size(200,65)
	$OpenRestoreFolderButton.Text = 'Open Restore Folder'
	$OpenRestoreFolderButton.TextAlign = 'MiddleCenter'
	$OpenRestoreFolderButton.Add_Click({
		if ([string]::IsNullOrEmpty($RestoreDirectory)){
			$Script:ErrorLabelText = "Please fill in the optional field in the settings menu associated with the recovery directory."
			ErrorForm
		}
		else{
			Restore_directory
		}
	})
	#######################################################################################################
	$AdvancedMenuButton = New-Object System.Windows.Forms.Button
	$AdvancedMenuButton.Location = New-Object System.Drawing.Point(145,165)
	$AdvancedMenuButton.Size = New-Object System.Drawing.Size(130,35)
	$AdvancedMenuButton.Text = 'Settings'
	$AdvancedMenuButton.TextAlign = 'MiddleCenter'
	$AdvancedMenuButton.Add_Click({
		AdvancedMenu
	})
	#######################################################################################################
	$MainMenulabel = New-Object System.Windows.Forms.Label
	$MainMenulabel.Location = New-Object System.Drawing.Point(5,5)
	$MainMenulabel.Size = New-Object System.Drawing.Size(410,40)
	$MainMenulabel.Font = New-Object System.Drawing.Font("Cascadia Mono",12,[System.Drawing.FontStyle]::Regular)
	$MainMenulabel.TextAlign = 'MiddleCenter'
	$MainMenulabel.Text = "Welcome to the 'PowerShell 7z Backup and Restore Script'.`nPlease select one of the options below."
	######################################################################################################
	$MainMenuForm.AcceptButton = $ExitButton
	$MainMenuForm.Controls.Add($ExitButton)
	$MainMenuForm.AcceptButton = $BackupButton
	$MainMenuForm.Controls.Add($BackupButton)
	$MainMenuForm.AcceptButton = $RestoreButton
	$MainMenuForm.Controls.Add($RestoreButton)
	$MainMenuForm.AcceptButton = $OpenBackupFolderButton
	$MainMenuForm.Controls.Add($OpenBackupFolderButton)
	$MainMenuForm.AcceptButton = $OpenRestoreFolderButton
	$MainMenuForm.Controls.Add($OpenRestoreFolderButton)
	$MainMenuForm.AcceptButton = $AdvancedMenuButton
	$MainMenuForm.Controls.Add($AdvancedMenuButton)
	$MainMenuForm.Controls.Add($MainMenulabel)
	#######################################################################################################
	$MainMenuForm.Topmost = $true
	$Script:MainMenuResult = $MainMenuForm.ShowDialog()
}

If ([string]::IsNullOrEmpty($args[0])){
	$run='True'
	while ($run -eq 'True'){
		if ([string]::IsNullOrEmpty($BackupFolder) -or [string]::IsNullOrEmpty($BackupName) -or [string]::IsNullOrEmpty($WhatToBackup) -or [string]::IsNullOrEmpty($NumberOfBackups)){
			AdvancedMenu
			if ($AdvancedMenuResult -eq [System.Windows.Forms.DialogResult]::OK){
				exit
			}
		}
		else{
			$run='False'
		}
	}
	$run='True'
	while ($run -eq 'True'){
		if ( Test-Path -Path "$7z_directory" ){
			$run='False'
		}
		else{
			No7zip
			if ($No7zipResult -eq [System.Windows.Forms.DialogResult]::Ok){
				Exit
			}
		}
	}
	MainMenu
}
elseif ( "1" -eq $args[0] ){
	check_directories
	7z_save
}
elseif ( "2" -eq $args[0] ){
	check_directories
	Backup_According_to_day_filter
}
