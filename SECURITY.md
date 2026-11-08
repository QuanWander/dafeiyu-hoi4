# Security

## API Key

- The DeepSeek API key is stored locally under `%LOCALAPPDATA%\DaFeiYuHOI4`.
- It is protected with Windows DPAPI for the current user.
- The key is never written to the repository, release ZIP, `game.log`, or chat history.
- The app talks directly to the configured API endpoint; there is no project server.

## Game Data

- The companion mod writes `DFY|...` lines to the local HOI4 `game.log`.
- The app reads the local log and local save metadata to detect the player country.
- No game data is uploaded except the chat context sent to the configured API provider.

## Installer

- The installer is plain PowerShell / CMD; it does not install a service, driver, or scheduled task.
- It copies the app, mod, shortcuts, and updates `dlc_load.json` after making a backup.
- It does not modify the HOI4 installation.

## Reporting

If you find a security issue, open a private report or contact the maintainer rather than posting API keys or save files publicly.

## Scope

This project is not affiliated with Paradox Interactive. Hearts of Iron IV is a trademark of Paradox Interactive.
