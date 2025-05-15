# Quantum Production Limited Downloaders

This repository contains official downloaders for Quantum Production Limited software products. These downloaders help you fetch and install our software products securely from their respective repositories.

## Available Downloaders

| Script                   | Description                                    | Supported Platforms |
| ------------------------ | ---------------------------------------------- | ------------------- |
| [qpulse.sh](./qpulse.sh) | Downloads and prepares QPulse for installation | Linux, macOS        |

## QPulse Downloader (qpulse.sh)

### Requirements

- A GitHub Personal Access Token (PAT) with `Contents: Read-only` permission
- Bash shell environment
- Required utilities: `curl`, `jq`, `tar`

### Usage

#### Quick Start (One-Line Command)

Run QPulse downloader directly without saving the script first:

```bash
bash <(curl -s https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.sh) --token YOUR_GITHUB_TOKEN --version VERSION_NUMBER
```

#### Alternative Method

If you prefer to save the script first:

##### 1. Download the script

```bash
curl -O https://raw.githubusercontent.com/quantum-production-limited/downloaders/main/qpulse.sh
chmod +x qpulse.sh
```

##### 2. Run the script

```bash
./qpulse.sh --token=YOUR_GITHUB_TOKEN --version=VERSION_NUMBER
```

Or alternatively:

```bash
./qpulse.sh --token YOUR_GITHUB_TOKEN --version VERSION_NUMBER
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
| `--token TOKEN`     | GitHub Personal Access Token with repository read access |
| `--version VERSION` | Version of QPulse to download (required)                 |
| `--help`, `-h`      | Show help message                                        |

### Example

```bash
./qpulse.sh --token ghp_ABCdef123456789 --version 0.4.6
```

### Notes

- The script downloads QPulse to the `~/.qpulse` directory by default
- If running as root with sudo, it will use the appropriate user's home directory
- The original archive file is removed after extraction
- Works on Linux distributions and macOS

## Creating a GitHub Personal Access Token

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token" (classic)
3. Give your token a descriptive name
4. Select the following permission:
   - `repo` > `public_repo` (for public repositories)
   - Or `repo` (for private repositories)
5. Click "Generate token"
6. Copy your token immediately (you won't be able to see it again)

## Coming Soon

- Windows support for QPulse (`qpulse.bat`)
- Downloaders for other Quantum Production Limited products

## Troubleshooting

If you encounter issues with the downloader:

1. Ensure your GitHub token has the correct permissions
2. Verify that you're using a valid version number
3. Check that all required utilities are installed
4. For Linux users: `sudo apt install curl jq`
5. For macOS users: `brew install jq`

## License

Copyright © 2025 Quantum Production Limited. All rights reserved.
