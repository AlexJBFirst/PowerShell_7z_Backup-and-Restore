
# Description:  

The PowerShell_7z_Backup-and-Restore script will allow you to backup your files using the 7-zip archiver.  

### Script features:  

- Creating backup profiles with different functionality: Archiving, Copying, Synchronizing, Restoring.  
- Creating archives from a directory or a file, with the ability to select the number of restore points and save the archive in one or two different paths  
- Creating archives from files in the selected directory filtered by the time of their creation.   
- Create copies of directories (files) in 2 different locations at the same time  
- Creating synchronized directories  
- Restoring archive copies created in 7z format  
- Ability to create archive copies before performing restoration tasks  
- Has an update function  
- Has a graphical interface  
- Can be used in both graphical and console modes (after creating profiles for automation)  
- Can be used to create archives or copies of directories (files) on a schedule (you need to create tasks in the task scheduler)  
- Can accept profile names as input to run automated tasks for a batch of profiles, from properties, and from a pipeline  
- Can output the terminal task log to a log file with the desired name  

### Prerequisites  

1. [7-zip archiver.](https://www.7-zip.org/download.html)  
  You must have a free 7z archiver installed, I recommend doing it in one of the ways listed below:  
    - From the official website https://www.7-zip.org/download.html ;  
    - Using the chocolatey commandlets: "choco install 7zip -y"  
    - With the help of WinGet commandlets: "winget install --id 7zip.7zip --accept-package-agreements -h"  
2. PowerShell must be at least version 5.1 or later (To check the version, use the command:)  

       $PSVersionTable.PSVersion
		
      The script is tested on versions 5.1 and 7.4  

### Warning  

1.  This program is not a professional data archiving tool;  
2.  This program is not able to create incremental backups, backups are always full!  
3.  This program may not archive data correctly if the file is occupied by another system process;  
4.  This program can crash like any other;  
5.  Before recovery, data from the directory to which the data will be restored will be deleted, so it is better to always leave the data archiving checkbox checked before recovery;  
6.  All text boxes can contain only uppercase and lowercase letters, numbers, and the "_" symbol, all other characters will be deleted automatically;  

## Installing the script and interacting with it:  

1. You must have a policy set up that allows scripts to run, to check your PowerShell policy, enter the command in a terminal with a **PowerShell interpreter with ADMINISTRATOR rights**:  

       Get-ExecutionPolicy
   >Restricted
   
   If the policy is set to Restricted, you need to change it to one that allows scripts to run.    

   To do this, you can use the “RemoteSigned” policy - but this policy only allows you to run your own scripts on your PC or unlocked scripts downloaded from the Internet. Or you can use the “Bypass” policy - but this policy can reduce the security of your PC by allowing any powershell scripts to be executed (not recommended!);  

    All examples will be shown for the "RemoteSigned" policy. If you use other policies, I recommend that you refer to the official [Microsoft documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1).  

       Set-ExecutionPolicy RemoteSigned  
   or   

       Set-ExecutionPolicy RemoteSigned -Force  

   Make sure that the policy is installed:   

       Get-ExecutionPolicy 
   >RemoteSigned
		
   You can now download the script file to your PC from github or via the powershell shell. To do this, use the following command:  

       Invoke-WebRequest https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/raw/main/PowerShell-7zBackup_and_Restore.ps1 -OutFile "$env:UserProfile\Downloads\PowerShell-7zBackup_and_Restore.ps1"

   Now you need to unlock this file to use it:  
		
       Unblock-File "$env:UserProfile\Downloads\PowerShell-7zBackup_and_Restore.ps1"

   If using a different file path, specify your path instead of “$env:UserProfile\Downloads\”  

2. **This script has 2 forms of interaction:**  

   - Graphical;  
   - Terminal.   

##  Graphical Mode  
  Before running the script in terminal mode, you must execute it at least once in graphical mode to create the necessary profiles, after which the script can be used in terminal mode.  

  The easiest way is to run this script from the PowerShell command shell as follows:  

      .\PowerShell-7zBackup_and_Restore.ps1

  or  

      & .\PowerShell-7zBackup_and_Restore.ps1

  After that, you will be greeted with a graphical shell for creating your first profile:  
  ![image](https://github.com/user-attachments/assets/08d1b90f-cf5a-4014-b381-ea9bdd1ef2e6)  

  In this window:   
  1 Create a name for your profile  
  2 Select the checkboxes with the functionality you will use  
  3 Fill in all required fields marked with an asterisk  

  Abbreviations:  
  > { Folder, File, ... } - Select a directory (file)    
  > { \- }  - Clear the text field    
  > { S } - Copy the value of the text field 'Source directory or a file'    
  > { Clear Config } - Clear all entered data in all fields  
  > { Exit } - Exit without saving the settings  
  > { OK } - Save all settings in the directory where the script is located to the file ProfileList.xml  
	
  ![image](https://github.com/user-attachments/assets/de3d3d0a-86fe-48d6-b753-b83f19e5e2a4)  

  After filling in all the fields and clicking on the 'Ok' button, you will be greeted by the main menu of the program:  

  ![image](https://github.com/user-attachments/assets/955d90cd-f957-46fd-a875-5e362f453e61)  

  Let's go through the Menu:  
  
### Button '**Check for Updates**'
  
  This button is dynamic, so if you click on it once, it will change its state and tell you if there are any new updates to the program. Updates are checked using this link:    
  `https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/raw/main/PowerShell-7zBackup_and_Restore.ps1`  
  
  ![image](https://github.com/user-attachments/assets/29ea285a-1aef-46e0-8bda-64a23ace63fa)  
  
### Button '**Profiles settings**' 
  
  Here we can create new profiles, delete unnecessary ones, or edit selected ones.  
  ![image](https://github.com/user-attachments/assets/6f5c52f4-96da-4e7e-9c0d-9a2c2120719c)  
  
  Clicking on a profile on the right will display all its settings in a compact form.  
  ![image](https://github.com/user-attachments/assets/16841c82-06db-46b1-b76e-bd0371f85828)  
  
### Button '**Backup Menu**'  
  
  In this menu we can choose the job we can do on our files by selecting a profile:  
  ![image](https://github.com/user-attachments/assets/a40d13cd-c56d-4a7e-a765-556749b73925)  
  
  Initially, all fields are inactive, but when you select a profile, depending on the selected profile functionality, the buttons will become available  
	
  It will also be possible to copy the commandlets for processing profiles from the terminal:  
  ![image](https://github.com/user-attachments/assets/ffec3a33-9d7f-4841-8282-3afda9db1667)  
  By clicking on any of the buttons, a log window will open where you can view the progress of the work.  
  ![image](https://github.com/user-attachments/assets/34da158b-3ace-4b73-98c0-5d9ebd5ae4cd)  
	
### Button '**Restore Menu**'

  The recovery menu works in a similar way.  
  ![image](https://github.com/user-attachments/assets/f8c98199-2a29-4e4f-95eb-cfea55366b8e)  
  
  After selecting a profile, the restore menu will become available if there is at least 1 backup created:  
  ![image](https://github.com/user-attachments/assets/160afa8c-cf37-47af-abae-b3d6873af367)  
  
  By selecting the checkbox above, each time you restore an archive copy, a new archive copy will be created in the directory with the name: Backups_before_restore  
  
  By clicking on the button: 'Restore Job 1', a menu with a backup selection will open:  
  ![image](https://github.com/user-attachments/assets/6ded572c-c95c-4f1d-a751-92287f478be1)  
  
  By selecting a specific archive copy and clicking OK, the process of restoring this copy will be carried out in the form of opening the log window. (Before recovery, the directory to which the data will be restored will be cleared)   
  ![image](https://github.com/user-attachments/assets/8b91f83a-a3b5-493d-b4fe-12f6612542d4)  
  
  If the 'Make a backup before restoring an archive copy' checkbox was enabled after restoring a copy, clicking on our profile in the restore menu again, we will see that the 'Restore Job 2' button is unlocked, thanks to this button we can restore our backups that were created when this checkbox was enabled:  
  ![image](https://github.com/user-attachments/assets/68fe7a32-8fc5-4f0c-94ad-3dde78338dee)  
  ![image](https://github.com/user-attachments/assets/cde183e9-28e7-4a43-a2db-1fe02734c694)  
  
  **This completes the introduction to the GUI.**  

## Terminal mode:  

In this mode, when calling a script, you need to fill in 2 parameters:  
- AutomationType   
- ProfileName.   

AutomationType can take on the following parameters:  
- SimpleBackup  
- TimeFilteredBackup  
- Copy  
- Sync  

There are alse one optional parameter:  
- OutputLogFileName  

ProfileName, when entering a non-existent profile, will display a message with all existing profiles in your saved list  

Examples of commands for creating archive copies via the terminal:  

    .\PowerShell-7zBackup_and_Restore.ps1 -AutomationType SimpleBackup -ProfileName test

or   

    .\PowerShell-7zBackup_and_Restore.ps1 -AutomationType SimpleBackup -ProfileName test,1,2,'another profile'

or  

    'test','1','2','another profile' | .\PowerShell-7zBackup_and_Restore.ps1 -AutomationType SimpleBackup

The recovery function is not supported in terminal mode!!!  

If you need the logging functionality, use the 'OutputLogFileName' property and specify a name for the log file. The logs will be overwritten each time the script is run.  

    .\PowerShell-7zBackup_and_Restore.ps1 -AutomationType SimpleBackup -ProfileName test,1,2,'another profile' -OutputLogFileName 'Log.txt'  

The logging file will be created in the same directory as the script.  

### Enjoy!  

# If you want to support me  

I have a link to BuyMeaCoffee    
>https://www.buymeacoffee.com/alexwight4w  

Or QR code:    
>![bmc_qr (Phone)](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/c74029e7-0ad8-461a-b1bb-1dc61e0077a1)
