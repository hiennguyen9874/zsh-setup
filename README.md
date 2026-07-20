# Minimal Zsh Setup

A small, interactive Linux installer for a fast Zsh environment with:

- Native Zsh completion and history
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [Starship](https://starship.rs/) with a minimal, Nerd Font-free prompt

## Install

Run as your normal user, not with `sudo`:

```bash
curl -fsSL https://raw.githubusercontent.com/hiennguyen9874/zsh-setup/main/install.sh | bash
```

The installer shows its plan and asks for confirmation before making changes. Review [`install.sh`](install.sh) before piping it into Bash.

## Supported systems

- Ubuntu and Debian
- Fedora
- Arch Linux

The installer requires an interactive terminal and `sudo`. It uses `sudo` only to install system packages and change the default shell.

## What it does

1. Backs up existing Zsh, Oh My Zsh, Powerlevel10k, and Starship configuration.
2. Optionally removes backed-up Oh My Zsh and Powerlevel10k files.
3. Installs Zsh, Git, and Curl using the system package manager.
4. Installs the two Zsh plugins under `~/.local/share/zsh/plugins`.
5. Installs Starship under `~/.local/bin`.
6. Writes a minimal `~/.zshrc` and `~/.config/starship.toml`.
7. Sets Zsh as the default shell.

Backups are stored in `~/zsh-backup-YYYYMMDD-HHMMSS`. Restore personal exports, aliases, and development-tool initialization from the backup after installation.

## License

No license has been specified.
