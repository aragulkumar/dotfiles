# dotfiles

Personal Arch Linux + Hyprland configuration, managed with Git and symlinks.

The repository is the **source of truth**. Real config files in `$HOME` are
symlinks pointing back here, so editing `~/.config/hypr/hyprland.lua` edits
`~/dotfiles/config/.config/hypr/hyprland.lua` directly.

## Repository structure

```text
dotfiles/
├── config/
│   └── .config/
│       ├── nvim/          # Neovim
│       ├── hypr/          # Hyprland (hyprland.lua)
│       ├── waybar/        # Waybar (config.jsonc, style.css)
│       ├── kitty/         # Kitty terminal
│       └── zellij/        # Zellij multiplexer
├── shell/
│   ├── .bashrc
│   ├── .bashrc.legacy     # archived previous bashrc (not linked)
│   └── .zshrc
├── git/
│   ├── .gitconfig         # local/private, git-ignored
│   └── .gitconfig.example # tracked template
├── scripts/
│   └── export-packages.sh # regenerate packages/pkglist.txt
├── wallpapers/
├── packages/
│   └── pkglist.txt        # pacman -Qqe output
├── install.sh
└── README.md
```

Empty config directories contain a `.gitkeep` so Git preserves them.

## How the symlinks work

| Repository path                  | Linked from            |
| -------------------------------- | ---------------------- |
| `config/.config/hypr`            | `~/.config/hypr`       |
| `config/.config/waybar`          | `~/.config/waybar`     |
| `config/.config/kitty`           | `~/.config/kitty`      |
| `config/.config/nvim`            | `~/.config/nvim`       |
| `config/.config/zellij`          | `~/.config/zellij`     |
| `shell/.bashrc`                  | `~/.bashrc`            |
| `shell/.zshrc`                   | `~/.zshrc`             |
| `git/.gitconfig`                 | `~/.gitconfig`         |

A symlink is a pointer, not a copy. `~/.config/waybar` *is* the directory
`~/dotfiles/config/.config/waybar`. There is only one copy of every file, so
there is nothing to sync back and forth.

`install.sh` is idempotent: it skips links that are already correct, and it
never overwrites a real file — it moves it to a timestamped backup first.

## Fresh Arch Linux installation

1. Install Git and clone the repository:

   ```bash
   sudo pacman -S --needed git
   git clone git@github.com:aragulkumar/dotfiles.git ~/dotfiles
   ```

   (Use the HTTPS URL if SSH keys are not set up yet.)

2. Preview what will happen:

   ```bash
   cd ~/dotfiles
   ./install.sh --dry-run
   ```

3. Apply it:

   ```bash
   ./install.sh
   ```

   Existing files are backed up to `~/.dotfiles-backup/<timestamp>/`.

4. Restore your Git identity (it is intentionally not committed):

   ```bash
   cp ~/dotfiles/git/.gitconfig.example ~/dotfiles/git/.gitconfig
   $EDITOR ~/dotfiles/git/.gitconfig
   ```

5. Install packages (optional, review the list first):

   ```bash
   less ~/dotfiles/packages/pkglist.txt
   sudo pacman -S --needed - < ~/dotfiles/packages/pkglist.txt
   ```

   `install.sh` never installs packages.

6. Reload your shell:

   ```bash
   exec bash
   ```

   Log out and back in (or restart Hyprland) for Hyprland/Waybar changes.

## Adding a new configuration

1. Create the directory inside the repository, for example:

   ```bash
   mkdir -p ~/dotfiles/config/.config/rofi
   ```

2. Move the existing config in (back it up first if you want to be cautious),
   then replace the original with a symlink. Either add the mapping to
   `MAPPINGS` in `install.sh` and re-run it:

   ```bash
   # add this line to the MAPPINGS array:
   #   "config/.config/rofi|.config/rofi"
   ./install.sh
   ```

   or link manually:

   ```bash
   mv ~/.config/rofi ~/dotfiles/config/.config/rofi
   ln -s ~/dotfiles/config/.config/rofi ~/.config/rofi
   ```

3. Commit the change (see below).

## Updating and pushing changes

Because `$HOME` points into the repository, normal edits are already changes
in the repo.

```bash
cd ~/dotfiles
git status
git add -A
git commit -m "hypr: adjust gaps"
git push
```

Check what you are about to commit — never commit secrets:

```bash
git diff --cached
```

## Packages

`packages/pkglist.txt` lists explicitly installed packages from `pacman -Qqe`.
Regenerate it after installing or removing packages:

```bash
~/dotfiles/scripts/export-packages.sh
```

The file is informational only; setup never installs anything automatically.

## Restoring backups

Every run of `install.sh` stores replaced files under:

```text
~/.dotfiles-backup/<timestamp>/
```

The directory mirrors your home layout, so to restore one file:

```bash
ls ~/.dotfiles-backup/
cp -a ~/.dotfiles-backup/20260101-120000/.config/waybar ~/.config/waybar
```

To restore everything from one backup, first remove the corresponding
symlinks, then copy the backup back:

```bash
mv ~/.config/waybar ~/.config/waybar.current   # keep the symlink target safe
cp -a ~/.dotfiles-backup/<timestamp>/.config/waybar ~/.config/waybar
```

Nothing is ever silently deleted: originals are moved, not removed.

## Secrets

`git/.gitconfig` is listed in `.gitignore` and is **never tracked**. Keep
`user.email`, credential helpers, tokens and signing keys there. The tracked
`git/.gitconfig.example` is a safe template.

Do not put API keys, passwords or tokens in any tracked file. If a secret is
committed, rotate it immediately — removing it from a later commit does not
remove it from history.

## Troubleshooting

Check every link at once:

```bash
find ~ -maxdepth 2 -type l -lname "$HOME/dotfiles/*" -printf '%p -> %l\n'
```

Find broken links pointing into the repository:

```bash
find ~/dotfiles -xtype l
```

Re-running `./install.sh` repairs links that are missing or point elsewhere,
without touching correct ones.
