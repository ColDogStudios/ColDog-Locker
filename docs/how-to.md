# 1. Installation

## 1.1 Important Notice
   ***ColDog Locker Windows*** and ***ColDog Locker Console*** are not designed to be used together, you must use one or the other.

## 1.2 Fresh Install
  Run ***ColDog Locker Setup*** and go through each prompt carefully. **IT IS IMPORTANT TO LEAVE THE INSTALLATION PATH DEFAULT** ```C:/Program Files (x86)/ColDog Studios/ColDog Locker```

## 1.3 Updating Previous Install
  There are two methods to update:
  
### 1.3.1 Uninstall Previous Installation
  Go through section (3.1) to uninstall you previous installation. Afterward, go through section (1.2) for a fresh installation.

### 1.3.2 Use ***ColDog Locker Setup*** to update (Not Tested)
  Run ***ColDog Locker Setup*** and select the update option. Go through the prompts to finish the update.

# 2. UI
  Most of the UI is navigated using a mouse and keyboard. Left click the top headers to open their respective menu. Once a menu is open, you can left click on an option, or left click on the red ***X*** to close that menu.

## 2.1 File Menu

### 2.1.1 New
  Selecting the ***New*** option will allow you to create a new folder if you have not already created a folder previously or have deleted your previous folder’s configuration (2.1.2).
  
  ***IMPORTANT*** - All the letters in your password will end up lowercase. Read the [FAQ](https://github.com/ColDogStudios/ColDog-Locker-Windows/edit/CDS/docs/FAQ.md) for explanation.

### 2.1.2 Delete
  Selecting the ***Delete*** option will allow you to remove configuration for a folder that is unlocked (2.3.2).

### 2.1.3 Exit
  Selecting the ***Exit*** option will close out of the application.

## 2.2 Home Menu

### 2.2.1 CDS Website
  Selecting the ***CDS Website*** option will open your default web browser to the ColDog Studios [Home Page](https://ColDogStudios.github.io).

### 2.2.2 CDS GitHub
  Selecting the ***CDS GitHub*** option will open your default web browser to the ColDog Studios [GitHub Page](https://github.com/ColDogStudios).

## 2.3 ColDog Locker Menu

### 2.3.1 Lock Folder
  Selecting the ***Lock Folder*** option will allow you to lock your password-protected folder.

### 2.3.2 Unlock Folder
  Selecting the ***Unlock Folder*** option will allow you to unlock your folder with your password.
  
  ***IMPORTANT*** - Your password will be all lowercase. Read the [FAQ](https://github.com/ColDogStudios/ColDog-Locker-Windows/edit/CDS/docs/FAQ.md) for explanation.

## 2.4 Tools Menu

### 2.4.1 System Info
  Selecting the ***System Info*** option will display basic Windows, Hardware, and Network information about your computer.

### 2.4.2 Custom Input
  Selecting the ***Custom Input*** option will allow you to input a command to ColDog Locker.

## 2.5 Help Menu

### 2.5.1 About
  Selecting the ***About*** option will show some information about ColDog Locker.
  
### 2.5.2 How to Use
  Selecting the ***[How to Use](https://github.com/ColDogStudios/ColDog-Locker-Windows/docs/how-to-use.md)*** option will open your default web browser to this file.

### 2.5.3 Check for Updates
  Selecting the ***Check for Updates*** option will run bitsadmin.exe, a built-in Windows executable, to get text from the [CDS Website](https://ColDogStudios.github.io/projects/coldog-locker/windows/gui-latest.txt) and store it as a variable.

# 3. Uninstallation
  The difference between a Normal Uninstall (3.1) and a Full Uninstall (3.2) is the configuration aspect. If you want to keep your special advancements, it is best to continue with a Normal Uninstall.

## 3.1 Normal Uninstall (Keep Configuration)
  Before you run uninstall ColDog Locker, be sure to remove your folder configuration by selecting the ***Delete*** option (2.1.2) in ColDog Locker. Then use your preferred method (Control Panel, Settings App, ColDog Locker Setup.msi) to remove the program files.

## 3.2 Full Uninstall
  To fully remove ColDog Locker, select the ***Custom Input*** option (2.4.2) and input ```DeleteAllCFG``` Accept the warning prompt, the use your preferred method (Control Panel, Settings App, ColDog Locker Setup.msi) to remove the program files.
 
