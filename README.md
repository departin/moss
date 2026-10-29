<p align="center">
  <img src="static/icon.png" width="96" alt="">
</p>

<h1 align="center">Moss</h1>

<p align="center">
  A Discord desktop client for Windows with a cleaner design and tools for managing servers and notifications.
  <br><br>
  <a href="https://github.com/departin/moss/releases/latest"><b>Download the latest release</b></a>
</p>

---

Moss runs the regular Discord app in its own window and builds on top of it. You log in with your normal account, everything you're used to still works, and Moss adds a calmer look along with a few features that make large server lists and busy notifications easier to deal with.

## Features

- **Appearance.** Choose between Moss's own colour palette, Discord's default colours, or your own colour or gradient, and pick one of five animation styles. A short setup takes you through this the first time you log in, and you can change it any time in settings.
- **Server Manager.** Lists every server you're in along with when you last opened it, so you can clean out old ones in bulk. Servers are left one at a time with a delay between each, and anything you leave stays under "Recently left" for 30 days in case you want to rejoin.
- **Quick Actions.** A button at the top of the server list for marking every server or DM as read, muting all servers for a set time, or switching every server to mentions only.
- **Focus Mode.** Sets you to Do Not Disturb and hides the member list until you turn it off or the timer runs out. Toggle it with Ctrl+Shift+F.
- **Catch Up.** Summarises the unread messages in a channel or DM using an AI model through [OpenRouter](https://openrouter.ai). Requires a free OpenRouter API key.
- **Bookmarks.** Drag any channel or DM onto the tab bar to bookmark it.
- **Plugins.** Around 20 popular plugins are enabled out of the box, with several hundred more available in settings.
- **Languages.** Moss is available in English, Spanish, French, German, Portuguese, Italian, Dutch, Polish, Turkish, Russian and Japanese.
- **Automatic updates.** The Moss app downloads new versions in the background and installs them the next time it restarts.

## Installation

Moss comes in two versions with the same features. Both are on the [releases page](https://github.com/departin/moss/releases/latest).

| | Moss app | Moss for Discord |
| --- | --- | --- |
| Download | `Moss-Setup-<version>.exe` | `Moss-for-Discord-Setup-<version>.exe` |
| What it does | Installs Moss as its own app, alongside Discord | Adds Moss to the Discord app you already have |
| Updates | Automatic | Run the newest setup again |

Neither installer is code-signed yet, so Windows SmartScreen may show a warning. Click **More info**, then **Run anyway**.

### Moss app

1. Run `Moss-Setup-<version>.exe`.
2. The installer asks whether Moss should start with Windows, and whether the official Discord app should stop launching at startup. Both can be changed later.

Moss keeps itself up to date and can be removed from **Settings → Apps** like any other program.

### Moss for Discord

1. Run `Moss-for-Discord-Setup-<version>.exe` and pick which Discord apps get Moss (Stable, PTB or Canary). Discord closes for a moment while Moss is added.
2. If BetterDiscord, Vencord or another mod is already installed, the setup offers to replace it. Your BetterDiscord plugins and settings are left alone, so you can switch back later.

Moss stays in place when Discord updates itself. To update Moss, run the newest setup again. Uninstalling **Moss for Discord** from **Settings → Apps** puts Discord back the way it was.

## Building from source

Moss is split across two repositories. This one contains the desktop app, and [moss-core](https://github.com/departin/moss-core) contains the client mod with all of the features listed above. Clone them next to each other:

```sh
git clone https://github.com/departin/moss-core moss
git clone https://github.com/departin/moss moss-desktop
```

You'll need [Node.js](https://nodejs.org) 22 or newer, [pnpm](https://pnpm.io) and [Bun](https://bun.sh). Build moss-core first, then the app:

```sh
cd moss
pnpm install --frozen-lockfile
pnpm build --standalone --disable-updater

cd ../moss-desktop
bun install
bun run build
bunx electron-builder --win nsis --x64 --publish never
bun run patcher
```

Both installers are written to `moss-desktop/dist`. The last step builds Moss for Discord and needs NSIS, which electron-builder downloads on its first run.

## Disclaimer

Moss is an unofficial client and is not affiliated with or endorsed by Discord. Using a modified client goes against Discord's Terms of Service, so use it at your own discretion.

## License

Moss is released under the [GNU General Public License v3.0](LICENSE). It is based on Equibop and Equicord, which are forks of Vesktop and Vencord.
