@echo off
setlocal enabledelayedexpansion

:: Colors for terminal output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[96m"
set "NC=[0m"

:: Enable ANSI color codes in Windows terminal
reg add HKEY_CURRENT_USER\Console /v VirtualTerminalLevel /t REG_DWORD /d 0x00000001 /f >nul 2>&1

echo %GREEN%QPulse Downloader%NC%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

:: Repository information
set "REPO=quantum-production-limited/QuantumPulse"

:: Check for required commands
call :check_command curl curl
call :check_command jq jq
call :check_command tar tar

:: Determine appropriate user home directory
set "USER_HOME=%USERPROFILE%"
set "OUTPUT_DIR=%USER_HOME%\.qpulse"

:: Parse command line arguments
set "TOKEN="
set "VERSION="

:parse_args
if "%~1"=="" goto end_parse_args

if "%~1"=="--help" (
    call :show_help
    exit /b 0
) else if "%~1"=="-h" (
    call :show_help
    exit /b 0
) else if "%~1:~0,8%"=="--token=" (
    set "TOKEN=%~1:~8%"
) else if "%~1"=="--token" (
    set "TOKEN=%~2"
    shift
) else if "%~1:~0,10%"=="--version=" (
    set "VERSION=%~1:~10%"
) else if "%~1"=="--version" (
    set "VERSION=%~2"
    shift
) else (
    echo %RED%Unknown option: %~1%NC%
    echo Use --help for usage information
    exit /b 1
)

shift
goto parse_args

:end_parse_args

:: Check if token is provided
if "%TOKEN%"=="" (
    echo %RED%Error: GitHub token is required%NC%
    echo Please provide a GitHub personal access token with the --token option
    echo You can create a token at: https://github.com/settings/tokens
    echo %YELLOW%Note: This script requires a token with repository content read access%NC%
    exit /b 1
)

:: Check if version is provided
if "%VERSION%"=="" (
    echo %RED%Error: Version is required%NC%
    echo Please provide a specific version to download with the --version option
    echo Example: %0 --token=your_token --version=0.4.6
    exit /b 1
)

set "ASSET_NAME=qpulse-docker-%VERSION%.tar.gz"
set "TEMP_RESPONSE=%TEMP%\github_api_response.json"

echo Setting up %BLUE%QPulse v%VERSION%%NC% in %BLUE%%OUTPUT_DIR%%NC%

:: Create output directory if it doesn't exist
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: Validate token has sufficient permissions to access the repository
echo Validating token permissions...
curl -s -o nul -w "%%{http_code}" -H "Authorization: token %TOKEN%" ^
    "https://api.github.com/repos/%REPO%" > "%TEMP%\repo_check.txt"

set /p REPO_CHECK=<"%TEMP%\repo_check.txt"
del "%TEMP%\repo_check.txt"

if not "%REPO_CHECK%"=="200" (
    echo %RED%Error: Unable to access repository %REPO%%NC%
    echo Please verify:
    echo 1. Your token has appropriate repository access permissions
    echo 2. The repository name is correct
    echo 3. Your token hasn't expired
    exit /b 1
)

:: Step 1: Get the release information
echo Looking up version %BLUE%%VERSION%%NC%...
curl -s -H "Authorization: token %TOKEN%" ^
     -H "Accept: application/vnd.github.v3+json" ^
     "https://api.github.com/repos/%REPO%/releases/tags/v%VERSION%" > "%TEMP_RESPONSE%"

:: Check if release exists
findstr /C:"Not Found" "%TEMP_RESPONSE%" > nul
if not errorlevel 1 (
    echo %RED%Error: Release v%VERSION% not found%NC%
    
    :: List available releases
    echo Available releases:
    curl -s -H "Authorization: token %TOKEN%" ^
        "https://api.github.com/repos/%REPO%/releases" > "%TEMP%\releases.json"
    
    jq -r ".[] | .tag_name" "%TEMP%\releases.json" | findstr /B /C:"v" > "%TEMP%\release_tags.txt"
    if exist "%TEMP%\release_tags.txt" (
        type "%TEMP%\release_tags.txt" | findstr /B /C:"v" | sed "s/v//g"
        del "%TEMP%\release_tags.txt"
    ) else (
        echo No releases found or insufficient permissions to list releases
    )
    del "%TEMP%\releases.json"
    exit /b 1
)

:: Step 2: Find the asset download URL and size
echo Locating the asset you're looking for...
jq -r ".assets[] | select(.name == \"%ASSET_NAME%\") | {url: .url, size: .size}" "%TEMP_RESPONSE%" > "%TEMP%\asset_info.json"

:: Extract URL and size from the asset info
jq -r ".url" "%TEMP%\asset_info.json" > "%TEMP%\asset_url.txt"
jq -r ".size" "%TEMP%\asset_info.json" > "%TEMP%\asset_size.txt"

set /p ASSET_URL=<"%TEMP%\asset_url.txt"
set /p ASSET_SIZE=<"%TEMP%\asset_size.txt"

del "%TEMP%\asset_info.json"
del "%TEMP%\asset_url.txt"
del "%TEMP%\asset_size.txt"

if "%ASSET_URL%"=="" (
    echo %YELLOW%Warning: Asset %ASSET_NAME% not found in release v%VERSION%%NC%
    echo Available assets:
    jq -r ".assets[].name" "%TEMP_RESPONSE%"
    exit /b 1
)

:: Calculate size in MB for display
set /a SIZE_MB_INT=%ASSET_SIZE% / 1048576
set /a SIZE_MB_DEC=(%ASSET_SIZE% * 100 / 1048576) %% 100
set "SIZE_MB=%SIZE_MB_INT%.%SIZE_MB_DEC:~0,2%"

:: Step 3: Download the asset
echo Downloading %BLUE%%ASSET_NAME%%NC% (%BLUE%%SIZE_MB% MB%NC%) from %BLUE%%REPO%%NC%...
curl -L -o "%OUTPUT_DIR%\%ASSET_NAME%" ^
     -H "Accept: application/octet-stream" ^
     -H "Authorization: token %TOKEN%" ^
     --progress-bar ^
     "%ASSET_URL%"

:: Check if download was successful
if not exist "%OUTPUT_DIR%\%ASSET_NAME%" (
    echo %RED%Error: Failed to download %ASSET_NAME%%NC%
    exit /b 1
)

:: Get downloaded file size
for %%A in ("%OUTPUT_DIR%\%ASSET_NAME%") do set DOWNLOADED_SIZE=%%~zA

:: Calculate downloaded size in MB
set /a DOWNLOADED_SIZE_MB_INT=%DOWNLOADED_SIZE% / 1048576
set /a DOWNLOADED_SIZE_MB_DEC=(%DOWNLOADED_SIZE% * 100 / 1048576) %% 100
set "DOWNLOADED_SIZE_MB=%DOWNLOADED_SIZE_MB_INT%.%DOWNLOADED_SIZE_MB_DEC:~0,2%"

echo Download complete. File size: %BLUE%%DOWNLOADED_SIZE_MB% MB%NC%

echo Extracting files...

:: Create temporary directory for extraction
set "EXTRACT_DIR=%TEMP%\qpulse_extract"
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%"
mkdir "%EXTRACT_DIR%"

:: Extract the tarball
tar -xzf "%OUTPUT_DIR%\%ASSET_NAME%" -C "%EXTRACT_DIR%"

if %errorlevel% equ 0 (
    :: Copy extracted files to output dir
    xcopy /E /I /Y "%EXTRACT_DIR%\*" "%OUTPUT_DIR%\"
    
    :: Make install scripts executable if they exist
    if exist "%OUTPUT_DIR%\install.sh" (
        attrib +x "%OUTPUT_DIR%\install.sh"
    ) else (
        echo %YELLOW%Warning: install.sh not found in the extracted files.%NC%
        
        :: Try to find install.sh recursively
        for /r "%OUTPUT_DIR%" %%F in (install.sh) do (
            echo %GREEN%Found install script at: %%F%NC%
            attrib +x "%%F"
            set "FOUND_INSTALL_SCRIPT=%%F"
        )
    )
    
    :: Remove the original tar.gz file and temp extract dir
    del "%OUTPUT_DIR%\%ASSET_NAME%"
    rmdir /s /q "%EXTRACT_DIR%"
    
    echo %GREEN%QPulse v%VERSION% has been downloaded and prepared for installation.%NC%
    
    :: For Windows users, we need special instructions
    echo To install QPulse on Windows:
    echo 1. Make sure you have Windows Subsystem for Linux (WSL) installed
    
    if exist "%OUTPUT_DIR%\install.sh" (
        echo 2. Run the following in WSL: %BLUE%cd "%OUTPUT_DIR%" ^&^& sudo ./install.sh --help%NC%
    ) else if defined FOUND_INSTALL_SCRIPT (
        echo 2. Run the following in WSL: %BLUE%sudo "%FOUND_INSTALL_SCRIPT%" --help%NC%
    )
    
    echo %YELLOW%Note: For full functionality, WSL with Ubuntu is recommended%NC%
) else (
    echo %RED%Error: Failed to extract the archive.%NC%
    echo The file may be corrupt or in an unexpected format.
    exit /b 1
)

:: Clean up temp file
del "%TEMP_RESPONSE%"

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

exit /b 0

:check_command
where %1 >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%Error: Required command '%1' not found.%NC%
    echo Please install it using an appropriate method for Windows:
    echo - curl: included in Windows 10+ or download from https://curl.se/windows/
    echo - jq: download from https://stedolan.github.io/jq/download/
    echo - tar: included in Windows 10+ or use 7-Zip
    echo.
    echo For the easiest installation, we recommend using winget or chocolatey:
    echo   winget install %2
    echo   or
    echo   choco install %2
    exit /b 1
)
exit /b 0

:show_help
echo Usage: %0 [OPTIONS]
echo Options:
echo   --token=TOKEN, --token TOKEN    GitHub personal access token with appropriate permissions
echo   --version=VERSION, --version VERSION    Version to download (required)
echo   --help, -h                      Show this help message
exit /b 0
