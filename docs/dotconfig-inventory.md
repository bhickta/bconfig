# Dotconfig Inventory

Generated from the current machine on 2026-07-05.

## Already Managed

- `~/.config/nvim` -> `nvim/nvim`
- `~/.config/bvim` -> `nvim/bvim`
- `~/.config/avim` -> `nvim/avim`

## Best Candidates To Add First

These are small, portable, and useful across PCs/laptops:

- `~/.zshrc`
- `~/.zshenv`
- `~/.zsh_aliases`
- `~/.bashrc`
- `~/.profile`
- `~/.gitconfig`
- `~/.yarnrc`
- `~/.gtkrc-2.0`
- `~/.config/kitty/`
- `~/.config/rofi/`
- `~/.config/i3/`
- `~/.config/htop/`
- `~/.config/git/`
- `~/.config/gtk-3.0/`
- `~/.config/gtk-4.0/`
- `~/.config/xsettingsd/`
- `~/.config/ytermusic/`
- `~/.config/Code/User/settings.json`
- `~/.config/Antigravity/User/settings.json`

## Add With Review

These are likely useful but may be machine-specific, noisy, or partially stateful:

- `~/.config/autostart/`
- `~/.config/dconf/`
- `~/.config/kdeglobals`
- `~/.config/kglobalshortcutsrc`
- `~/.config/khotkeysrc`
- `~/.config/kcminputrc`
- `~/.config/kded5rc`
- `~/.config/kscreenlockerrc`
- `~/.config/kwinrc`
- `~/.config/kwinrulesrc`
- `~/.config/kxkbrc`
- `~/.config/mimeapps.list`
- `~/.config/plasma-localerc`
- `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
- `~/.config/plasmashellrc`
- `~/.config/powerdevilrc`
- `~/.config/powermanagementprofilesrc`
- `~/.config/spectaclerc`
- `~/.config/systemd/`
- `~/.config/user-dirs.dirs`
- `~/.config/xdg-terminals.list`
- `~/.config/vlc/`

## Do Not Commit As-Is

These contain credentials, account state, databases, caches, browser profiles, or large generated state:

- `~/.config/rclone/rclone.conf` contains live credential material.
- `~/.config/gh/hosts.yml` may contain GitHub authentication state.
- `~/.config/fabric/.env` may contain environment secrets.
- `~/.aws/`, `~/.ssh/`, `~/.gnupg/`, `~/.docker/`, `~/.terraform.d/`
- Browser/Electron app state: `Antigravity`, `Code`, `Slack`, `google-chrome`, `microsoft-edge`, `obsidian`, `pcloud`, `balenaEtcher`, `frappe-books`
- KDE/app session state: `session`, `akonadi`, `evolution`, `goa-1.0`, `libaccounts-glib`, `pulse`
- Package/runtime/cache dirs: `opencode/node_modules`, `go/telemetry`, `uv/uv-receipt.json`

For these, commit a sanitized template only if needed, such as `rclone.conf.example`.

## Top-Level `~/.config` Entries Found

```text
.gsd-keyboard.settings-ported
.jira
Antigravity
Code
Code Industry
KDE
KDE-xdg-terminals.list
Meilisearch
PlasmaDiscoverUpdates
Proton
QtProject.conf
Slack
Trolltech.conf
Unknown Organization
aicli
akonadi
akonadi-firstrunrc
akonadi-migrationrc
akonadi_akonotes_resource_0rc
akonadi_contacts_resource_0rc
akonadi_ical_resource_0rc
akonadi_indexing_agentrc
akonadi_maildir_resource_0rc
akregatorrc
arkrc
autostart
avim
balena-etcher-electron
balenaEtcher
baloofileinformationrc
bluedevilglobalrc
bunkus.org
bvim
configstore
custompatterns
dconf
discoverrc
dolphinrc
drkonqirc
emaildefaults
emailidentities
enchant
eog
evolution
fabric
frappe-books
gh
git
gnome-initial-setup-done
gnome-session
go
goa-1.0
google-chrome
gtk-3.0
gtk-4.0
gtkrc
gtkrc-2.0
gwenviewrc
htop
i3
ibus
kactivitymanagerdrc
kalarmrc
kalarmresources
kalendaracrc
kate
katemetainfos
katerc
kateschemarc
katevirc
kcminputrc
kconf_updaterc
kde.org
kded5rc
kdedefaults
kdeglobals
kdfrc
kglobalshortcutsrc
kgpgrc
khelpcenterrc
khotkeysrc
killbotsrc
kitenrc
kitty
kmagrc
kmail2rc
kmixrc
knotesrc
konsolerc
konsolesshconfig
krunnerrc
kscreenlockerrc
ksmserverrc
ktimerrc
ktimezonedrc
kwalletrc
kwinrc
kwinrulesrc
kxkbrc
libaccounts-glib
libreoffice
microsoft-edge
mimeapps.list
mps-youtube
nautilus
nitrogen
obs-studio
obsidian
okularpartrc
okularrc
opencode
orage
pcloud
phishingurlrc
plasma-localerc
plasma-nm
plasma-org.kde.plasma.desktop-appletsrc
plasma-workspace
plasmanotifyrc
plasmaparc
plasmashellrc
powerdevilrc
powermanagementprofilesrc
pulse
rclone
regolith3
rofi
semantra
session
shotwell
simple-update-notifier
specialmailcollectionsrc
spectaclerc
systemd
systemsettingsrc
totem
touchpadxlibinputrc
transmission
trashrc
umbrellorc
update-notifier
user-dirs.dirs
user-dirs.locale
uv
vlc
vscode-sqltools
webengineurlinterceptoradblockrc
xdg-desktop-portal-kderc
xdg-terminals.list
xsettingsd
yelp
ytermusic
```

## Home Dotfiles Found

Good candidates:

```text
~/.bashrc
~/.gitconfig
~/.gtkrc-2.0
~/.profile
~/.yarnrc
~/.zsh_aliases
~/.zshenv
~/.zshrc
```

Do not track shell history/cache/state:

```text
~/.bash_history
~/.lesshst
~/.mysql_history
~/.psql_history
~/.python_history
~/.viminfo
~/.wget-hsts
~/.zcompdump*
~/.zsh_history
```
