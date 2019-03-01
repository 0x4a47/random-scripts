# Step 1a: Check if i'm an admin user when running this script.
$current_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $current_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if($isAdmin -eq $False){
    Write-Output "Please run me as Admin!"
    exit(1)
}

# Step 1b: Determine OS architecture
$architecture_str = (Get-WmiObject Win32_OperatingSystem ).OSArchitecture

if($architecture -eq "64-bit"){
    $architecture_num = 64
}else{
   $architecture_num = 32
}

# Step 1c: create output folder and determine C:\path
$working_path = (Get-Item -Path ".\").FullName
$output_folder = $working_path + "\.installer_temp"
New-Item -ItemType Directory -path $output_folder | Out-Null

# Step 1d: Determine that we have internet + dns connection!
# TODO

# Step 2: install dependencies for the tools i'll be using
# Current list:
<#
    - git
    - python3
    - IDA7.0 Freeware
    - x64dbg
    - pwntools
    #>

function Download-File {
    
    <#
    Download Method #1 (Slow and not asynchronous) 
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $git_url -UseBasicParsing > "git_installer.exe"
    #>

    #Download Method #2 (Fast and asynchronous)
    $output = $args[1]
    $url = $args[0]

    $web_client = New-Object System.Net.WebClient 
    #Not using the async one here because the script will continue through and attempt to install without the files being done !
    $web_client.DownloadFile($url, $output)
    Write-Output "~~ Download Complete ~~"
}

#DOWNLOAD GIT
$git_url = (-join("https://github.com/git-for-windows/git/releases/download/v2.21.0.windows.1/Git-2.21.0-", $architecture_num, "-bit.exe"))
$git_output_path = (-join($output_folder, "\git_installer.exe"))
Download-File $git_url $git_output_path


# Sadly the Python URL doesn't play nice like the git URL does so we need this logic
if ($architecture_num -eq 64){
    $python3_url = "https://www.python.org/ftp/python/3.7.2/python-3.7.2-amd64.exe"
}else{
    $python3_url = "https://www.python.org/ftp/python/3.7.2/python-3.7.2.exe"
}

# DOWNLOAD PYTHON3
$python3_output_path = (-join($output_folder + "\python3_installer.exe"))
Download-File $python3_url $python3_output_path

# DOWNLOAD IDA7.0
$ida7_url = "https://out7.hex-rays.com/files/idafree70_windows.exe"
$ida_output_path = (-join($output_folder, "\ida7_installer.exe"))
Download-File $ida7_url $ida_output_path

# DOWNLOAD x64dbg
$x64_url = "https://github.com/x64dbg/x64dbg/releases/download/snapshot/snapshot_2019-01-20_22-50.zip"
$x64_output_path = (-join($output_folder, "\x64dbg.zip"))
$x64_unzip_path = (-join($output_folder, "\x64dbg_unzipped\"))
Download-File $x64_url $x64_output_path

# Unzip x64
Expand-Archive $x64_output_path -DestinationPath $x64_unzip_path

# Remove the archive after unzipping
Remove-Item -path $x64_output_path 

# Now, We can start running the installers
#   1. git
#   2. python
#   3. IDA7
#   4. dbg is a standalone exe anyway...

Start-Process -FilePath $git_output_path -ArgumentList "/S /v/qn"
Start-Process -FilePath $python3_output_path 
Start-Process -FilePath $ida_output_path

#Once we install, we can then setup pip and start install pwntools and stuff!