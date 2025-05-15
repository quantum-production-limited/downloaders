# Quantum Production Limited Downloaders

This repository contains official downloaders for Quantum Production Limited software products. These downloaders help you fetch and install our software products securely from their respective repositories.

## Available Downloaders

| Script                     | Description                                    | Supported Platforms |
| -------------------------- | ---------------------------------------------- | ------------------- |
| [qpulse.sh](./qpulse.sh)   | Downloads and prepares QPulse for installation | Linux, macOS        |
| [qpulse.bat](./qpulse.bat) | Downloads and prepares QPulse for installation | Windows             |

## QPulse Downloader

### Requirements

- A GitHub Personal Access Token (PAT) with `Contents: Read-only` permission
- Required utilities:
  - Linux/macOS: `curl`, `jq`, `tar`
  - Windows: `curl`, `jq`, `tar` (included in Windows 10+)

### Usage

#### Quick Start (One-Line Commands)

**Linux/macOS:**

```bash
bash <(curl -s https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.sh) --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER
```

**Windows (PowerShell):**

```powershell
powershell -Command "& { iwr https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.bat -OutFile $env:TEMP\qpulse.bat; & $env:TEMP\qpulse.bat --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER }"
```

**Windows (Command Prompt):**

```cmd
curl -s -o %TEMP%\qpulse.bat https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.bat && %TEMP%\qpulse.bat --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER
```

#### Alternative Method

If you prefer to save the script first:

##### Linux/macOS

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.sh
chmod +x qpulse.sh
```

2. Run the script:

```bash
./qpulse.sh --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER
```

##### Windows

1. Download the script:

```cmd
curl -o qpulse.bat https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.bat
```

2. Run the script:

```cmd
qpulse.bat --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER
```

Replace:

- `YOUR_GITHUB_TOKEN` with your GitHub Personal Access Token
- `VERSION_NUMBER` with the specific version you want to download (e.g., `0.4.6`)

#### 3. Install QPulse

After the downloader completes successfully, follow the installation instructions provided by the script. Typically:

```bash
cd ~/.qpulse && sudo ./install.sh --help
```

### Options

| Option              | Description                                              |
| ------------------- | -------------------------------------------------------- |
| `--token=TOKEN`     | GitHub Personal Access Token with repository read access |
| `--version=VERSION` | Version of QPulse to download (required)                 |
| `--help`, `-h`      | Show help message                                        |

Both scripts support using either `--token=VALUE` or `--token VALUE` format for all options.

### Example

**Linux/macOS:**

```bash
./qpulse.sh --token=ghp_ABCdef123456789 --version=0.4.6
```

**Windows:**

```cmd
qpulse.bat --token=ghp_ABCdef123456789 --version=0.4.6
```

### Notes

- The script downloads QPulse to the following locations:
  - Linux/macOS: `~/.qpulse` directory
  - Windows: `%USERPROFILE%\.qpulse` directory
- If running as root/admin with sudo, it will use the appropriate user's home directory
- The original archive file is removed after extraction
- On Windows, Windows Subsystem for Linux (WSL) is recommended for installation

## Creating a GitHub Personal Access Token

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token" (classic)
3. Give your token a descriptive name
4. Select the `Contents: Read-only` permission
5. Click "Generate token"
6. Copy your token immediately (you won't be able to see it again)

## Platform-Specific Instructions

### Linux/macOS

After the downloader completes, you can install QPulse by following the instructions provided in the terminal.

```bash
cd ~/.qpulse
sudo ./install.sh --help
```

### Windows

QPulse is primarily designed for Linux environments, but can be used on Windows through Windows Subsystem for Linux (WSL):

1. Make sure you have [WSL installed](https://learn.microsoft.com/en-us/windows/wsl/install)
2. Open your WSL terminal (Ubuntu recommended)
3. Navigate to the download location
   ```bash
   cd /mnt/c/Users/YourUsername/.qpulse
   ```
4. Run the installer
   ```bash
   sudo ./install.sh --help
   ```

## Troubleshooting

If you encounter issues with the downloader:

### Linux/macOS

- Ensure your GitHub token has the correct permissions
- Verify that you're using a valid version number
- Check that all required utilities are installed
  - For Debian/Ubuntu: `sudo apt install curl jq`
  - For macOS: `brew install jq`

### Windows

- Ensure you have Windows 10 or newer (for built-in curl and tar)
- Install required tools if missing:
  - Using winget: `winget install curl` and `winget install jqlang.jq`
  - Using chocolatey: `choco install curl` and `choco install jq`
- If you encounter ANSI color issues, try running the command with `-NoNewWindow` PowerShell parameter

## Coming Soon

- Downloaders for other Quantum Production Limited products (Polaris, Horizon, etc.)
- Additional installation options and configurations
- Automated dependency checking and installation

## License

Copyright © 2025 Quantum Production Limited. All rights reserved.
