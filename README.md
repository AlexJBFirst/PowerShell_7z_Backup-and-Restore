# Description  

Hello everyone!  

Today I present you my little project that will help you make 7z backups from a convenient graphical interface.  
This project was originally created to save game save files in a compact form, without GUI, and all settings had to be entered into the script itself. It was convenient for me, but when I passed it on to my friends, it was not easy to set up for an unskilled user.  
After a while, the project grew a little, it got a graphical interface and, in principle, it can be used to archive any data you want.  

You are presented with a program that:  
1) Stores its settings in itself;  
2) It can make two types of archive copies, with the ability to choose the number of backups to store.:  
- Regular - when you need to archive the entire directory with subdirectories;  
- Time-based - is used to archive multiple files from a directory, where you can use a filter by file creation date. Only those files whose creation date differs from the date of the script launch by the selected number of days, will be included in the archive;  
3) It can restore archive copies created by this program:
- Before restoring the archived copies, you can also enable the option to create backups of the directory to which the files will be restored.  
- If the option to create an archive before restoring was selected, these archives can also be restored using a separate menu!)  
4) And it allows you to observe the log of both the recovery and the backup process.  

And all of this, of course, in a "dark mode" or a "dark theme", call it what you will!  

# Warning

1) After running the script for the first time and saving the settings, go back to the script and make sure that all the settings are saved, if not, go through the configuration procedure again and make sure that the changes are saved;
2) This program is not a professional data archiving tool;
3) This program is not able to create incremental backups, backups are always full!
4) This program may not archive data correctly if the file is occupied by another system process;
5) This program can crash like any other and may incorrectly archive or unarchive your data, so instead of blind trust, when restoring archive copies, make sure that the directory to which you will restore your archive does not contain critical data that needs to be saved;
6) Before recovery, data from the directory to which the data will be restored will be deleted, so it is better to always leave the data archiving checkbox checked before recovery;
7) The archive name can contain only uppercase and lowercase letters, numbers, and the "_" symbol, all other characters will be deleted automatically;

# Prerequisites

1) You must have a policy set up that allows scripts to run, to check your PowerShell policy, enter the command in your terminal with a PowerShell interpreter:  
>Get-ExecutionPolicy  
>![image](https://github.com/AlexJBFirst/PowerShell_Timer/assets/155481723/95d0195f-2578-4a85-90f7-4e03dc30bea4)  

If the policy is set to "Restricted", you need to change it to one that allows scripts to run.  
To do this, you can use the "RemoteSigned" policy, to set this policy, run PowerShell as administrator and run the following command:  
>Set-ExecutionPolicy RemoteSigned  
>![image](https://github.com/AlexJBFirst/PowerShell_Timer/assets/155481723/2657d142-9937-4217-bff7-1c42b464807b)  

or  
>Set-ExecutionPolicy RemoteSigned -Force  
>![image](https://github.com/AlexJBFirst/PowerShell_Timer/assets/155481723/41368f6a-ac42-46af-8342-ad2473e6f850)  

Make sure that the policy is installed:  
>Get-ExecutionPolicy  
>![image](https://github.com/AlexJBFirst/PowerShell_Timer/assets/155481723/d9f5cc52-7973-4355-a350-7fc79e202557)  

If you managed to set the scripting policy to "RemoteSigned", then we can move on to the next step, but if you still have problems, I advise you to read more about the policies from the official Microsoft website:  
>https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.4  

2) You must have a free 7z archiver installed, I recommend doing it in one of the ways listed below:
- From the official website https://www.7-zip.org/download.html ;
- Using the chocolatey commandlets: "choco install 7zip -y"
- With the help of WinGet commandlets: "winget install --id 7zip.7zip --accept-package-agreements -h"

3) PowerShell must be at least version 5.1, on which everything was tested and this script was created, to do this, enter the following in the command shell:
>$PSVersionTable

And make sure you get something like this:  

>![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/dc1ac734-c78a-4e90-9ae0-46e48a0be40d)  

# Running the script

The easiest way is to run our script from the PowerShell command shell as follows:  
>D:\Scripts\PowerShell-7zBackup_and_Restore.ps1  
>![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/431fab7f-8949-4999-97f5-470c891727ed)  

Or in the case when we have spaces in the directories where our script is saved:  
>& 'D:\Scripts\PowerShell-7zBackup_and_Restore.ps1'  
>![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/900f6bb9-326e-477c-9467-e0ad68cb572e)  


But this is not convenient.   
"OldStyle" bat scripts allowed using the .bat\\.cmd extension to run our scripts with a double click, let's do the same, but for PowerShell.  
To do this, we need to:  
1) Save our PowerShell script in some directory, for example, I will use the Scripts directory on drive D;  
2) Create a shortcut to our script;  
3) Modify the shortcut of our script as follows:  
By clicking on "Properties" in the context menu of our shortcut, in the "Object" field, change its content to the following  
>Powershell -WindowStyle hidden -file "D:\Scripts\PowerShell-7zBackup_and_Restore.ps1"  
>![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/6dd33da8-1e79-492c-9655-7b03f798fee0)  

### Where:  
***PowerShell - command line interpreter  
-WindowStyle hidden - used to make the powershell window hide in the system tray when the script is launched  
-file "D:\Scripts\PowerShell-7zBackup_and_Restore.ps1" - In quotes, set the full path to the script***  

The working directory does not metter;  

4) Apply the changes to the shortcut and check that everything works by double-clicking on the created shortcut and make sure that the GUI of the timer appears. 

# Run the script after the first configuration from the command line

This method will be useful for those who would like to make archive copies of their directories via the command line, without a graphical interface. 
In order for the script to work, it must be run at least once in graphical form, as the script will save all the necessary directory settings.

After the first run, you can use the following command to perform a regular directory backup:  
>powershell -file "$Path_to_Script" 1  

Or in the case of a time-based backup:
>powershell -file "$Path_to_Script" 2  

$Path_to_Script - the full path to the script, for example "D:\Scripts\PowerShell-7zBackup_and_Restore.ps1"

All other variations of the argument are ignored and will lead to the launch of the GUI

You can also set up scheduled tasks and perform data archiving according to a set schedule.
To accomplish this task, we need:  
1) Open windows task scheduler;  
2) Click on button 'Create Task';  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/9114f0c7-f25c-4506-87e3-dd643fe92ef9)  
3) In the General tab, configure the Name field and all the radio buttons you need;  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/43572c40-7aef-4041-8734-8645e703aee6)
4) In the Triggers tab, set up a new trigger, for example, create a task to trigger the script every day at 12pm;  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/f46a1257-ccae-4110-b445-e499222e377c)  
5) On the actions tab, create a task using the example below:  
In arguments field put one of the commands below:  
>-file "D:\Scripts\PowerShell-7zBackup_and_Restore.ps1" 1  

OR  
>-file "D:\Scripts\PowerShell-7zBackup_and_Restore.ps1" 2  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/9c3aa59f-b6f0-4ad9-b65a-2d7209157feb)  

File recovery can be done exclusively from the GUI!

# Screenshots of the program:
### Configuration Menu  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/0b3a9500-6503-4787-8fbb-15aaae6deeed)  
### Main Menu  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/73737767-c103-498f-bc8c-9d682800d69f)  
### Backup Menu  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/d7c704cc-38cf-4c62-907a-a13c4d0cf824)  
### Simple Backup Job  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/49c46152-a2f3-4d84-8406-fa2eaa6d265c)  
### Restore Menu  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/2b4d5687-72ca-48ca-857e-3943c75b1141)  
### Restore Backup Job  
![image](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/158e4893-d6e0-438a-b685-24aa74658c0d)  

### Enjoy!

# If you want to support me

I have a link to BuyMeaCoffee  
>https://www.buymeacoffee.com/alexwight4w

Or QR code:  
>![bmc_qr (Phone)](https://github.com/AlexJBFirst/PowerShell_7z_Backup-and-Restore/assets/155481723/c74029e7-0ad8-461a-b1bb-1dc61e0077a1)

