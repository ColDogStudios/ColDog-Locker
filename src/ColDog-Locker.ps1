﻿#MARK: ----------[ Assemblies ]----------#

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import the necessary .NET methods
Add-Type -TypeDefinition @"
    using System.IO;
    using System.Security.Cryptography;

    public class cdlEncryptor
    {
        public static void EncryptDirectory(string directory, string password)
        {
            foreach (string file in Directory.GetFiles(directory))
            {
                EncryptFile(file, password);
            }

            foreach (string subDirectory in Directory.GetDirectories(directory))
            {
                EncryptDirectory(subDirectory, password);
            }
        }

        public static void EncryptFile(string inputFile, string password)
        {
            using (Aes aes = Aes.Create())
            {
                Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(password, new byte[] {0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76}, 10000, HashAlgorithmName.SHA256);
                aes.Key = pdb.GetBytes(32);
                aes.IV = pdb.GetBytes(16);

                using (FileStream fsIn = new FileStream(inputFile, FileMode.Open))
                {
                    using (FileStream fsCrypt = new FileStream(inputFile + ".enc", FileMode.Create))
                    {
                        using (CryptoStream cs = new CryptoStream(fsCrypt, aes.CreateEncryptor(), CryptoStreamMode.Write))
                        {
                            byte[] buffer = new byte[1048576]; // 1MB buffer
                            int read;
                            while ((read = fsIn.Read(buffer, 0, buffer.Length)) > 0)
                            {
                                cs.Write(buffer, 0, read);
                            }
                        }
                    }
                }

                File.Delete(inputFile);
                File.Move(inputFile + ".enc", inputFile);
            }
        }

        public static void DecryptDirectory(string directory, string password)
        {
            foreach (string file in Directory.GetFiles(directory))
            {
                DecryptFile(file, password);
            }

            foreach (string subDirectory in Directory.GetDirectories(directory))
            {
                DecryptDirectory(subDirectory, password);
            }
        }

        public static void DecryptFile(string inputFile, string password)
        {
            using (Aes aes = Aes.Create())
            {
                Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(password, new byte[] {0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76}, 10000, HashAlgorithmName.SHA256);
                aes.Key = pdb.GetBytes(32);
                aes.IV = pdb.GetBytes(16);

                using (FileStream fsCrypt = new FileStream(inputFile, FileMode.Open))
                {
                    using (CryptoStream cs = new CryptoStream(fsCrypt, aes.CreateDecryptor(), CryptoStreamMode.Read))
                    {
                        using (var fsOut = new FileStream(inputFile + ".dec", FileMode.Create))
                        {
                            byte[] buffer = new byte[1048576]; // 1MB buffer
                            int read;
                            while ((read = cs.Read(buffer, 0, buffer.Length)) > 0)
                            {
                                fsOut.Write(buffer, 0, read);
                            }
                        }
                    }
                }

                File.Delete(inputFile);
                File.Move(inputFile + ".dec", inputFile);
            }
        }
    }
"@

#MARK: ----------[ Variables ]----------#

$version = "v0.0.5-Alpha"
$currentVersion = ($version.TrimStart("v")).TrimEnd("-Alpha")
$dateMod = "7/2/2024"
$roamingConfig = "$env:AppData\ColDog Studios\ColDog Locker"
$localConfig = "$env:LocalAppData\ColDog Studios\ColDog Locker"
$cdlDir = Get-Location

$Host.UI.RawUI.WindowTitle = "ColDog Locker $version"

#MARK: ----------[ Initialization ]----------#

# Create CDL directories if they do not already exist
#if (-not(Test-Path "$roamingConfig" -PathType Container)) { New-Item -ItemType Directory "$roamingConfig" }
if (-not(Test-Path "$localConfig" -PathType Container)) { New-Item -ItemType Directory "$localConfig" }

Get-Settings
if (Test-Path "$localConfig\logs\*.log") { Resize-Log }
if ($cdlSettings.autoUpdate) { Update-ColDogLocker }

#MARK: ----------[ Main Functions ]----------#

function Show-Menu {
    while ($true) {

        Show-MenuTitle -subMenu "Main Menu"

        $menuChoices = " 1) New Locker`n" +
        " 2) Remove Locker`n" +
        " 3) Lock Locker`n" +
        " 4) Unlock Locker`n" +
        " 5) About ColDog Locker`n" +
        " 6) ColDog Locker Help`n" +
        " 7) Check for Updates`n" +
        " 9) Update ColDog Locker Settings`n"

        Write-Output "Choose an option from the following:`n" -ForegroundColor White
        Write-Output $menuChoices
        $menuChoice = Read-Host -Prompt ">"

        switch ($menuChoice) {
            1 { New-Locker }
            2 { Remove-Locker }
            3 { Lock-CDL }
            4 { Unlock-CDL }
            5 { Show-About }
            6 { Show-Help }
            7 { Update-ColDogLocker }
            9 { Update-Settings }
            "dev" { Show-Dev }
            #"sysinfo" { Get-SystemInformation }
            default {
                Show-Message -type "Warning" -message "Please select a valid option." -title "ColDog Locker"
            }
        }
    }
}

#MARK: ----------[ New-Locker ]----------#
function New-Locker {

    Show-MenuTitle -subMenu "Main Menu > New File"

    # User Input
    $script:inputLockerName = Read-Host -Prompt "Locker Name"
    Write-Output "`n    Minimum Password Length: 8 characters"
    Write-Output "Recommended Password Length: 15 characters`n"
    $inputPassword = Read-Host -Prompt " Locker Password" -AsSecureString
    $confirmPassword = Read-Host -Prompt "Confirm Password" -AsSecureString

    # Convert SecureString to Clear Text for Password
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputPassword)
    $script:inputPassClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    # Convert SecureString to Clear Text for Confirmation
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword)
    $confirmPassClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    # Check User Input, if all checks pass, configuration is created
    if ($script:inputLockerName -eq "" -or $script:inputPassClear -eq "" -or $confirmPassClear -eq "") {
        Show-Message -type "Warning" -message "Input cannot be empty, blank, or null. Please try again." -title "ColDog Locker"
    }
    elseif ($inputPassClear.Length -lt 8) {
        Show-Message -type "Warning" -message "Password must be at least 8 characters long. Please try again." -title "ColDog Locker"
    }
    elseif ("$inputPassClear" -cne "$confirmPassClear") {
        Show-Message -type "Warning" -message "Passwords do not match. Please try again." -title "ColDog Locker"
    }
    elseif ("$inputPassClear" -ceq "$confirmPassClear") {
        try {
            # Password hashing
            Invoke-PasswordHashing

            # Create config
            Add-LockerMetadata
        }
        catch {
            # Handle any errors that occurred during the script execution
            Add-LogEntry -message "An error occurred while creating your locker: $($_.Exception.Message)" -level "Error"
            Show-Message -type "Error" -message "An error occurred while creating your locker: $($_.Exception.Message)" -title "Error - ColDog Locker"
            exit 1
        }
    }
    else {
        Show-Message -type "Warning" -message "Invalid input. Please try again." -title "ColDog Locker"
    }
}

#MARK: ----------[ Remove-Locker ]----------#
function Remove-Locker {

    $result = Show-Lockers -action "Remove"

    if (-not $result.success) {
        return
    }

    $selectedPair = $result.selectedPair

    # Show confirmation prompt
    $confirmation = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove $($selectedPair.lockerName)?", "Remove Locker", "YesNo", "Warning")

    if ($confirmation -eq "Yes") { Remove-LockerMetadata }
}

#MARK: ----------[ Lock-CDL ]----------#
function Lock-CDL {

    $result = Show-Lockers -action "Lock"

    if (-not $result.success) {
        return
    }

    $selectedPair = $result.selectedPair

    while ($true) {
        $inputPassword = Read-Host -Prompt "Enter the password to lock $($selectedPair.lockerName)" -AsSecureString

        # Convert SecureString to Clear Text for Password
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputPassword)
        $script:inputPassClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

        # Check if the entered password is correct
        Invoke-PasswordHashing

        if ($selectedPair.password -ceq $script:hex512) {
            try {
                # Encrypt the Locker by calling the EncryptDirectory method
                [cdlEncryptor]::EncryptDirectory($selectedPair.cdlLocation, $script:inputPassClear)

                # Lock the Locker
                Set-ItemProperty -Path $selectedPair.cdlLocation -Name Attributes -Value "Hidden, System"
                $selectedPair.isLocked = $true
                Rename-Item -Path $selectedPair.cdlLocation -NewName ".$($selectedPair.lockerName)"
                $selectedPair.cdlLocation = "$cdlDir\.$($selectedPair.lockerName)"

                # Convert the updated array to JSON and write it to the file
                $json = $LockerPasswordPairs | ConvertTo-Json -Depth 3
                Set-Content -Path "$localConfig\lockers.json" -Value $json

                Add-LogEntry -message "Locker $($selectedPair.lockerName) locked successfully." -level "Success"
                Show-Message -type "Info" -message "Locker $($selectedPair.lockerName) locked successfully." -title "ColDog Locker"
                break
            }
            catch {
                # Handle any errors that occurred during the script execution
                Add-LogEntry -message "An error occurred while locking $selectedPair.lockerName: $($_.Exception.Message)" -level "Error"
                Show-Message -type "Error" -message "An error occurred while locking $selectedPair.lockerName: $($_.Exception.Message)" -title "Error - ColDog Locker"
                exit 1
            }
        }
        else {
            Add-LogEntry -message "Failed password attempt" -level "Warning"
            Show-Message -type "Warning" -message "Failed password atttept. Please try again." -title "Warning"
        }
    }
}

#MARK: ----------[ Unlock-CDL ]----------#
function Unlock-CDL {

    $result = Show-Lockers -action "Unlock"

    if (-not $result.success) {
        return
    }

    $selectedPair = $result.selectedPair
    $failedAttempts = 0

    while ($true) {
        # Show confirmation prompt
        $inputPassword = Read-Host -Prompt "Enter the password to unlock $($selectedPair.lockerName)" -AsSecureString

        # Convert SecureString to Clear Text for Password
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputPassword)
        $script:inputPassClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

        # Check if the entered password is correct
        Invoke-PasswordHashing

        if ($selectedPair.password -ceq $script:hex512) {
            try {
                # Decrypt the Locker by calling the DecryptDirectory method
                [cdlEncryptor]::DecryptDirectory($selectedPair.cdlLocation, $script:inputPassClear)

                # Unlock the Locker
                Set-ItemProperty -Path $selectedPair.cdlLocation -Name Attributes -Value "Normal"
                $selectedPair.isLocked = $false
                Rename-Item -Path $selectedPair.cdlLocation -NewName $selectedPair.lockerName
                $selectedPair.cdlLocation = "$cdlDir\$($selectedPair.lockerName)"

                # Convert the updated array to JSON and write it to the file
                $json = $LockerPasswordPairs | ConvertTo-Json -Depth 3
                Set-Content -Path "$localConfig\lockers.json" -Value $json

                Add-LogEntry -message "Locker $($selectedPair.lockerName) unlocked successfully." -level "Success"
                Show-Message -type "Info" -message "Locker $($selectedPair.lockerName) unlocked successfully." -title "ColDog Locker"
                break
            }
            catch {
                # Handle any errors that occurred during the script execution
                Add-LogEntry -message "An error occurred while unlocking $($selectedPair.lockerName): $($_.Exception.Message)" -level "Error"
                Show-Message -type "Error" -message "An error occurred while unlocking $($selectedPair.lockerName): $($_.Exception.Message)" -title "Error - ColDog Locker"
                exit 1
            }
        }
        else {
            $failedAttempts++
            if ($failedAttempts -ge 10) {
                Add-LogEntry -message "10 failed password attempts. Locking $selectedPair.lockerName permanently." -level "Error"
                Show-Message -type "Error" -message "10 failed password attempts. Locking $selectedPair.lockerName permanently." -title "ColDog Locker"

                break
            }
            else {
                $remainingAttempts = 10 - $failedAttempts
                Add-LogEntry -message "Failed password attempt. $remainingAttempts attempts remaining." -level "Warning"
                Show-Message -type "Warning" -message "Failed password atttept. $remainingAttempts attempts remaining." -title "Warning"
            }
        }
    }
}

#MARK: ----------[ Utility Functions ]----------#

function Show-About {

    $message = "The idea of ColDog Locker was created by Collin 'ColDog' Laney on 11/17/21, for a security project in Cybersecurity class.`n" +
    "Collin Laney is the Founder and CEO of ColDog Studios"

    Show-Message -type "Info" -message $message -title "About ColDog Locker"
}

function Show-Help {

    $message = "ColDog Locker is a simple file locker that allows you to encrypt and decrypt the contents of a 'managed' directory with a password.`n`n" +
    "To lock a directory, select the 'Lock Locker' option from the main menu and follow the prompts.`n`n" +
    "To unlock a directory, select the 'Unlock Locker' option from the main menu and follow the prompts.`n`n" +
    "To remove a directory from ColDog Locker management, select the 'Remove Locker' option from the main menu and follow the prompts.`n`n" +
    "To check for updates, select the 'Check for Updates' option from the main menu."

    Show-Message -type "Info" -message $message -title "ColDog Locker Help"
}

function Update-ColDogLocker {
    [Parameter(Mandatory = $false)]
    [string]$owner = "ColDogStudios"
    [Parameter(Mandatory = $false)]
    [string]$repository = "ColDog-Locker"
    [Parameter(Mandatory = $false)]
    [string]$downloadDirectory = "$env:userprofile\Downloads"
    [Parameter(Mandatory = $false)]
    [string]$uri = "https://api.github.com/repos/$owner/$repository/releases/latest"
    try {
        # Get the release info using the GitHub API
        $releaseInfo = Invoke-RestMethod -Uri $uri
        $downloadVersion = $releaseInfo.tag_name
        $latestVersion = ($downloadVersion.TrimStart("v")).TrimEnd("-alpha")
        #$asset = $releaseInfo.assets | Where-Object { $_.name -eq "ColDog_Locker_${downloadVersion}_setup.msi" }
        $asset = $releaseInfo.assets | Where-Object { $_.name -eq "ColDog_Locker_${downloadVersion}.exe" }

        # Check if the latest version is newer than the current version and prompt the user to download it if avaliable
        if ([version]$latestVersion -gt [version]$currentVersion) {
            $message = "A newer version is available: `n`n" +
            "Current Version: $currentVersion`n" +
            "Latest Version: $latestVersion`n`n" +
            "Do you want to download the latest version?"

            $updatePromptChoice = [System.Windows.Forms.MessageBox]::Show($message, "Update Available", "YesNo", "Question")

            if ("$updatePromptChoice" -eq "Yes" ) {
                try {
                    # Download the latest version
                    #$fileName = Join-Path $downloadDirectory "ColDog_Locker_${downloadVersion}_setup.msi"
                    $fileName = Join-Path $downloadDirectory "ColDog_Locker_${downloadVersion}.exe"
                    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $fileName

                    Add-LogEntry -message "Downloaded the latest version to: $fileName" -level "Success"
                    Show-Message -type "Info" -message "Downloaded the latest version to: $fileName.`nPlease run the installer to update ColDog Locker." -title "Download Complete"
                }
                catch {
                    Add-LogEntry -message "An error occurred while downloading the latest version: $($_.Exception.Message)" -level "Error"
                    Show-Message -type "Error" -message "An error occurred while downloading the latest version: $($_.Exception.Message)" -title "Error - ColDog Locker"
                    exit 1
                }
            }
        }
        else {
            $message = "ColDog Locker is up to date: `n`n" +
            "Current Version: $currentVersion `n" +
            "Latest Version: $latestVersion"

            Show-Message -type "Info" -message $message -title "ColDog Locker Update Check"
        }
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -Message "An error occurred while checking for updates: $($_.Exception.Message)" -Level "Error"
        Show-Message -type "Error" -message "An error occurred while checking for updates: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

function Show-Dev {

    $message = "Current Version: $version `n" +
    "Date Modified: $dateMod `n" +
    "Alpha Build `n`n" +
    "Metadata Location: $localConfig`n" +
    "Old Metadata Location: $roamingConfig"


    Show-Message -type "Info" -message $message -title "Development"
}

#MARK: ----------[ Reference Functions ]----------#

function Show-MenuTitle {
    param (
        [string]$subMenu = ""
    )

    Clear-Host
    $width = (Get-Host).UI.RawUI.WindowSize.Width
    $title = "ColDog Locker $version"
    $copyright = "Copyright (c) ColDog Studios. All Rights Reserved."
    $line = "#" * $width
    $separatorLength = $width / 2.2
    $separator = "-" * $separatorLength
    $emptyLine = " " * $width

    Write-Output $line -ForegroundColor Blue
    Write-Output $emptyLine
    Write-Output ($title.PadLeft(($width + $title.Length) / 2)).PadRight($width) -ForegroundColor White
    Write-Output ($subMenu.PadLeft(($width + $subMenu.Length) / 2)).PadRight($width) -ForegroundColor Yellow
    Write-Output ($separator.PadLeft(($width + $separator.Length) / 2)).PadRight($width) -ForegroundColor DarkGray
    Write-Output ($copyright.PadLeft(($width + $copyright.Length) / 2)).PadRight($width) -ForegroundColor White
    Write-Output $emptyLine
    Write-Output $line -ForegroundColor Blue
    Write-Output $emptyLine
}

# used by: New-Locker, Unlock-CDL
function Invoke-PasswordHashing {
    try {
        # Convert the input string to a byte array
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($script:inputPassClear)

        # Compute the SHA-256 hash of the byte array
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hash256 = $sha256.ComputeHash($bytes)

        # Convert the SHA-256 hash to a hexadecimal string
        $hex256 = [System.BitConverter]::ToString($hash256).Replace("-", "").ToLower()

        # Compute the SHA-512 hash of the SHA-256 hash
        $sha512 = [System.Security.Cryptography.SHA512]::Create()
        $hash512 = $sha512.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hex256))

        # Convert the SHA-512 hash to a hexadecimal string
        $script:hex512 = [System.BitConverter]::ToString($hash512).Replace("-", "").ToLower()

        # Hide Clear Text Password
        #$script:inputPassClear = $null
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -Message "An error occurred with password hashing: $($_.Exception.Message)" -Level "Error"
        Show-Message -type "Error" -message "An error occurred with password hashing: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

function Watch-Config {
    $settingsWatcher = New-Object System.IO.FileSystemWatcher
    $settingsWatcher.Path = "$localConfig"
    $settingsWatcher.Filter = "settings.json"
    $settingsWatcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'
    $settingsWatcher.EnableRaisingEvents = $true

    $lockersWatcher = New-Object System.IO.FileSystemWatcher
    $lockersWatcher.Path = "$localConfig"
    $lockersWatcher.Filter = "lockers.json"
    $lockersWatcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'
    $lockersWatcher.EnableRaisingEvents = $true

    Register-ObjectEvent -InputObject $settingsWatcher -EventName "Changed" -Action { Get-Settings }
    Register-ObjectEvent -InputObject $lockersWatcher -EventName "Changed" -Action { Get-LockerMetadata }
}

# Continue with the rest of your script...

<#
function ConvertSecureStringToClearText {
    param (
        [System.Security.SecureString]$secureString
    )
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$script:inputPassClear = ConvertSecureStringToClearText $inputPassword
$confirmPassClear = ConvertSecureStringToClearText $confirmPassword
#>

#MARK: ----------[ Add-LockerMetadata ]----------#
function Add-LockerMetadata {
    try {
        # If the JSON table exists, read it from the file, otherwise initialize an empty array
        if (Test-Path "$localConfig\lockers.json") {
            $content = Get-Content "$localConfig\lockers.json" | ForEach-Object { $_.Trim() }
            if ($content -eq '') {
                $LockerPasswordPairs = @()
            }
            else {
                $LockerPasswordPairs = $content | ConvertFrom-Json
            }
        }
        else {
            $LockerPasswordPairs = @()
        }

        # Ensure $LockerPasswordPairs is an array
        if (-not $LockerPasswordPairs) {
            $LockerPasswordPairs = @()
        }
        elseif ($LockerPasswordPairs -isnot [System.Collections.IEnumerable]) {
            $LockerPasswordPairs = @($LockerPasswordPairs)
        }

        # Check if Locker name already exists
        $LockerExists = $LockerPasswordPairs | Where-Object { $_.lockerName -eq $script:inputLockerName }

        if ($LockerExists) {
            Add-LogEntry -message "A locker with the name '$script:inputLockerName' already exists." -level "Warning"
            Show-Message -type "Warning" -message "A locker with the name '$script:inputLockerName' already exists. Please choose a different name." -title "ColDog Locker"
            return
        }

        # Create a hashtable with the guid, Locker name, password, location, and isLocked attribute
        $LockerPasswordPair = [PSCustomObject]@{
            guid        = [guid]::NewGuid().ToString()
            LockerName  = $script:inputLockerName
            password    = $script:hex512
            cdlLocation = "$cdlDir\$script:inputLockerName"
            isLocked    = $false
        }

        # Add the hashtable to the array
        $updatedLockerPasswordPairs = @($LockerPasswordPairs + $LockerPasswordPair)

        # Convert the array to JSON and write it to the file
        $json = $updatedLockerPasswordPairs | ConvertTo-Json
        Set-Content -Path "$localConfig\lockers.json" -Value $json

        # Assign the modified array back to the script-scoped variable
        $LockerPasswordPairs = $updatedLockerPasswordPairs

        # Create the Locker
        New-Item -ItemType Directory -Path "$cdlDir\$script:inputLockerName" | Out-Null

        Add-LogEntry -message "$script:inputLockerName created successfully." -level "Success"
        Show-Message -type "Info" -message "$script:inputLockerName created successfully." -title "ColDog Locker"
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -Message "An error occurred while adding $script:inputLockerName to the JSON table: $($_.Exception.Message)" -Level "Error"
        Show-Message -type "Error" -message "An error occurred while adding $script:inputLockerName to the JSON table: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

#MARK: ----------[ Remove-LockerMetadata ]----------#
function Remove-LockerMetadata {
    try {
        # Remove the selected Locker-password pair
        $lockers = $lockers | Where-Object { $_.lockerName -ne $selectedPair.lockerName }

        # Convert the updated array to JSON and write it to the file
        $json = $lockers | ConvertTo-Json -Depth 3
        Set-Content -Path "$localConfig\lockers.json" -Value $json

        Add-LogEntry -message "Locker $($selectedPair.lockerName) removed successfully." -level "Success"
        Show-Message -type "Info" -message "Locker $($selectedPair.lockerName) removed successfully." -title "ColDog Locker"
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -Message "An error occurred while removing $selectedPair to the JSON table: $($_.Exception.Message)" -Level "Error"
        Show-Message -type "Error" -message "An error occurred while removing $selectedPair to the JSON table: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

function Get-LockerMetadata {
    try {
        if (-not (Test-Path "$localConfig\lockers.json")) {
            return
        }

        $script:cdlLockers = Get-Content "$localConfig\lockers.json" | ConvertFrom-Json

        # Ensure the content is an array
        if ($script:cdlLockers -isnot [System.Collections.IEnumerable]) {
            $script:cdlLockers = @($script:cdlLockers)
        }
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -message "An error occurred while reading the lockers from the JSON file: $($_.Exception.Message)" -level "Error"
        Show-Message -type "Error" -message "An error occurred while reading the lockers from the JSON file: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

#MARK: ----------[ Show-Lockers ]----------#
function Show-Lockers {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Remove", "Lock", "Unlock")]
        [string]$action
    )

    try {
        # If the JSON file does not exist, return early, otherwise read its contents
        if (-not (Test-Path "$localConfig\lockers.json")) {
            Show-Message -type "Warning" -message "There are no lockers created." -title "ColDog Locker"
            return @{ success = $false }
        }

        # Get and Convert the JSON content to an array of Locker-password pairs
        $jsonContent = Get-Content "$localConfig\lockers.json"
        $lockers = $jsonContent | ConvertFrom-Json

        # Ensure the content is an array
        if ($lockers -isnot [System.Collections.IEnumerable]) {
            $lockers = @($lockers)
        }

        # Specify Locked and Unlocked lockers
        $unlockedLockers = $lockers | Where-Object { $_.isLocked -eq $false }
        $unlockedLockers = @($unlockedLockers)
        $lockedLockers = $lockers | Where-Object { $_.isLocked -eq $true }
        $lockedLockers = @($lockedLockers)

        # Check if there are any lockers of each type
        if ($null -eq $lockers -or $lockers.Count -eq 0) {
            Show-Message -type "Warning" -message "There are no lockers created." -title "ColDog Locker"
            return @{ success = $false }
        }
        elseif ($action -eq "Lock" -and ($null -eq $unlockedLockers -or $unlockedLockers.Count -eq 0)) {
            Show-Message -type "Warning" -message "There are no unlocked lockers to lock." -title "ColDog Locker"
            return @{ success = $false }
        }
        elseif ($action -eq "Unlock" -and ($null -eq $lockedLockers -or $lockedLockers.Count -eq 0)) {
            Show-Message -type "Warning" -message "There are no locked lockers to unlock." -title "ColDog Locker"
            return @{ success = $false }
        }

        Show-MenuTitle -subMenu "Main Menu > $action Locker"

        # Display each Locker name to the console based on the action
        switch ($action) {
            "Remove" {
                Write-Output "Lockers:"
                Write-Output ""
                for ($i = 0; $i -lt $lockers.Count; $i++) {
                    Write-Output "$($i + 1). $($lockers[$i].lockerName)"
                }
            }
            "Lock" {
                Write-Output "Unlocked Lockers:"
                Write-Output ""
                for ($i = 0; $i -lt $unlockedLockers.Count; $i++) {
                    Write-Output "$($i + 1). $($unlockedLockers[$i].lockerName)"
                }
            }
            "Unlock" {
                Write-Output "Locked Lockers:"
                Write-Output ""
                for ($i = 0; $i -lt $lockedLockers.Count; $i++) {
                    Write-Output "$($i + 1). $($lockedLockers[$i].lockerName)"
                }
            }
        }

        # Prompt the user to choose a Locker to remove, lock, or unlock
        $selectedPairIndex = Read-Host "`nEnter the number corresponding to the locker you want to $($action.ToLower())"
        Write-Output ""

        # Validate user input
        if (-not [int]::TryParse($selectedPairIndex, [ref]$null)) {
            Show-Message -type "Warning" -message "Invalid selection. Please choose a valid number from the list." -title "ColDog Locker"
            return @{ success = $false }
        }

        $selectedPairIndex = [int]$selectedPairIndex - 1

        # Check if the selected index is within the valid range
        switch ($action) {
            "Remove" {
                if ($selectedPairIndex -lt 0 -or $selectedPairIndex -ge $lockers.Count) {
                    Show-Message -type "Warning" -message "Invalid selection. Please choose a valid number from the list." -title "ColDog Locker"
                    return @{ success = $false }
                }
            }
            "Lock" {
                if ($selectedPairIndex -lt 0 -or $selectedPairIndex -ge $unlockedLockers.Count) {
                    Show-Message -type "Warning" -message "Invalid selection. Please choose a valid number from the list." -title "ColDog Locker"
                    return @{ success = $false }
                }
            }
            "Unlock" {
                if ($selectedPairIndex -lt 0 -or $selectedPairIndex -ge $lockedLockers.Count) {
                    Show-Message -type "Warning" -message "Invalid selection. Please choose a valid number from the list." -title "ColDog Locker"
                    return @{ success = $false }
                }
            }
        }

        # Show confirmation prompt
        switch ($action) {
            "Remove" { $selectedPair = $lockers[$selectedPairIndex] }
            "Lock" { $selectedPair = $unlockedLockers[$selectedPairIndex] }
            "Unlock" { $selectedPair = $lockedLockers[$selectedPairIndex] }
        }

        return @{ success = $true; selectedPair = $selectedPair }
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -message "An error occurred while $($action)ing $($selectedPair): $($_.Exception.Message)" -level "Error"
        Show-Message -type "Error" -message "An error occurred while $($action)ing $($selectedPair): $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1
    }
}

#MARK: ----------[ Logging ]----------#
function Add-LogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$level,

        [string]$logDirectory = "$localConfig\logs"
    )

    # Ensure the log folder exists
    if (!(Test-Path -Path $logFolder)) {
        New-Item -ItemType Directory -Path $logDirectory
    }

    # Create the log entry
    $logEntry = "[$(Get-Date)] [$level] $message"

    # Check if Debug mode is enabled
    Get-Settings

    # If Debug mode is enabled, add the line of code causing the error to the log entry
    if ($cdlSettings.debugMode) {
        $logEntry += " Line: $($Error[0].InvocationInfo.ScriptLineNumber)"
    }

    # Write the log entry to the level-specific log file and the combined log file
    Add-Content -Path "$logDirectory\cdl$level.log" -Value $logEntry
    Add-Content -Path "$logDirectory\cdl.log" -Value $logEntry
}

function Resize-Log {
    param(
        [string]$logDirectory = "$localConfig\logs"
    )

    try {
        # Resize each log file if it's larger than 10MB
        Get-ChildItem -Path $logDirectory -Filter "*.log" | ForEach-Object {
            $logFilePath = $_.FullName

            # Get the file size in bytes
            $fileSizeBytes = (Get-Item $logFilePath).Length

            # Convert the file size to megabytes
            $fileSizeMB = $fileSizeBytes / 1MB

            # Check if the file size is greater than 10MB
            if ($fileSizeMB -gt 10) {
                # Keep the last 1000 lines and overwrite the file
                Get-Content $logFilePath | Select-Object -Last 1000 | Set-Content $logFilePath
            }
        }
    }
    # catch if no log files exist
    catch [System.Management.Automation.ItemNotFoundException] {
        Add-LogEntry -message "No log files found in the log directory." -level "Info"
        return
    }
    catch {
        # Handle any errors that occurred during the script execution
        Add-LogEntry -message "An error occurred while resizing the log files: $($_.Exception.Message)" -level "Error"
        Show-Message -type "Error" -message "An error occurred while resizing the log files: $($_.Exception.Message)" -title "Error - ColDog Locker"
        exit 1

    }
}

#MARK: ----------[ Settings ]----------#
function Initialize-Settings {
    $script:cdlSettings = @{
        $debugMode  = $false
        $maxLogSize = 10485760 # 10MB
        $autoUpdate = $true
    }

    $script:cdlSettings | ConvertTo-Json | Set-Content "$localConfig\settings.json"
}

function Get-Settings {
    if (Test-Path "$localConfig\settings.json") {
        $script:cdlSettings = Get-Content "$localConfig\settings.json" | ConvertFrom-Json
    }
    else {
        Initialize-Settings
    }
}

function Update-Settings {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DebugMode,

        [Parameter(Mandatory = $false)]
        [int]$MaxLogSize,

        [Parameter(Mandatory = $false)]
        [bool]$AutoUpdate
    )

    Get-Settings

    $debugMode = [System.Windows.Forms.MessageBox]::Show("Enable Debug Mode?", "Debug Mode", "YesNo", "Question")

    if ($debugMode -eq "Yes") {
        $cdlSettings.debugMode = $true
    }
    elseif ($debugMode -eq "No") {
        $cdlSettings.debugMode = $false
    }

    $maxLogSize = Read-Host "Enter the maximum log file size in MB"
    $maxLogSize = [int]$maxLogSize
    $cdlSettings.maxLogSize = $maxLogSize * 1048576

    $autoUpdate = [System.Windows.Forms.MessageBox]::Show("Enable Auto Update?", "Auto Update", "YesNo", "Question")

    if ($autoUpdate -eq "Yes") {
        $cdlSettings.autoUpdate = $true
    }
    elseif ($autoUpdate -eq "No") {
        $cdlSettings.autoUpdate = $false
    }

    # Update the settings file with the new settings
    $cdlSettings | ConvertTo-Json | Set-Content "$localConfig\settings.json"

    Add-LogEntry -message "Settings updated successfully. Debug mode: $debugMode. Max log file size: $($cdlSettings.maxLogSize). Auto update: $autoUpdate" -level "Success"
    Show-Message -type "Info" -message "Settings updated successfully." -title "ColDog Locker"
}

#MARK: ----------[ Msg Boxes ]----------#
function Show-Message {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$type,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $true)]
        [string]$title
    )

    switch ($type) {
        "Info" { [System.Windows.Forms.MessageBox]::Show($message, $title, "OK", "Information") }
        "Warning" { [System.Windows.Forms.MessageBox]::Show($message, $title, "OK", "Warning") }
        "Error" { [System.Windows.Forms.MessageBox]::Show($message, $title, "OK", "Error") }
    }
}

#MARK: ----------[ Run Program ]----------#

Watch-Config
Show-Menu
