# How to Install (Update)

Covers two separately-installed programs: **Neovim** (the editor) and
**Neovide** (its GUI front-end). They upgrade independently.

# Neovim

## Latest stable

<https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz>


## Location of binary

```
/usr/local/bin/nvim
```


## Script to install


### Suggested by Gemini

```bash
#: NOTE: neovim self-contained; no clutter in /usr/local/bin/; FHS opt
#: for optional, self-contained software packages.

# 1. Download the latest Neovim Linux tarball
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

# 2. Extract the archive into /opt
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# 3. Create a symbolic link in /usr/local/bin
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# 4. Clean up the downloaded tarball
rm nvim-linux-x86_64.tar.gz
```

**Note:** this uses a different layout than what's actually installed here — it
symlinks `/usr/local/bin/nvim` into `/opt`, whereas the current install is a
real binary copied to `/usr/local/bin` with its runtime at
`/usr/local/share/nvim`. Both layouts work on their own; mixing them leaves a
stale orphaned runtime behind. See below.


### What Claude Code recommends (and has done before — 0.12.2 upgrade)

Neovim finds its runtime files relative to wherever its binary resolves to, so
the binary and the runtime must always be replaced together. That's the one
rule this approach is built around.

Install the new version alongside the old one first, and only swap once it's
been smoke-tested:

```bash
# 1. Unpack the new version somewhere harmless (X.Y.Z = target version)
mkdir -p ~/.local/share/nvim-X.Y.Z
cd /tmp && curl -L -o nvim.tar.gz \
  https://github.com/neovim/neovim/releases/download/vX.Y.Z/nvim-linux-x86_64.tar.gz
tar xzf nvim.tar.gz -C ~/.local/share/nvim-X.Y.Z --strip-components=1

# 2. Smoke test it without touching the live install
~/.local/share/nvim-X.Y.Z/bin/nvim --version
```

Once happy, back up the old install and copy **both** halves into place:

```bash
sudo cp /usr/local/bin/nvim /usr/local/bin/nvim-OLD-backup
sudo mv /usr/local/share/nvim /usr/local/share/nvim-OLD-backup
sudo cp ~/.local/share/nvim-X.Y.Z/bin/nvim /usr/local/bin/nvim
sudo cp -r ~/.local/share/nvim-X.Y.Z/share/nvim /usr/local/share/

# Verify the binary and runtime are the same version
md5sum /usr/local/share/nvim/runtime/lua/vim/treesitter/languagetree.lua \
       ~/.local/share/nvim-X.Y.Z/share/nvim/runtime/lua/vim/treesitter/languagetree.lua
# Hashes MUST match.
```

If the hashes differ, the runtime copy didn't take. The symptom shows up later
as a confusing Lua error (e.g. `attempt to call method 'set_timeout' (a nil
value)`), not as an install failure — which is why it's worth checking here.

Finally, the tarball ships **four** things under `share/`, not just `nvim`.
Copying only the runtime leaves the launcher, icon, and man page pinned at
whatever version last touched them:

```bash
sudo cp ~/.local/share/nvim-X.Y.Z/share/applications/nvim.desktop /usr/local/share/applications/
sudo cp ~/.local/share/nvim-X.Y.Z/share/man/man1/nvim.1          /usr/local/share/man/man1/
sudo cp ~/.local/share/nvim-X.Y.Z/share/icons/hicolor/128x128/apps/nvim.png \
        /usr/local/share/icons/hicolor/128x128/apps/

# Refresh the caches that index them
sudo mandb -q
sudo update-desktop-database /usr/local/share/applications 2>/dev/null || true
```

Skipping this breaks nothing — the drift is cosmetic. But it's silent and
cumulative: on 2026-07-21 these were found four months behind the binary,
having been missed across several upgrades.

Once done, the install is finished. Sanity check it:

```bash
nvim --version | head -1
nvim --headless -c 'echo $VIMRUNTIME' -c 'q'    # must be /usr/local/share/nvim/runtime
man -w nvim                                      # /usr/local/man is a symlink to share/man
```

Then remove the staging tree (`rm -rf ~/.local/share/nvim-X.Y.Z`) — but not
before the copies above are done, since it's their source.

**Tarball naming:** pre-0.12 it was `nvim-linux64.tar.gz`. From 0.12 onward
it's `nvim-linux-x86_64.tar.gz`.

**For a major version bump** (0.11 → 0.12 and the like), this is only part of
the job — plugins and treesitter parsers need their own migration. Full
procedure with sandbox config, lazy-lock handling, and a troubleshooting table:
[`.claude/playbook/runbooks/nvim-major-version-upgrade.md`](.claude/playbook/runbooks/nvim-major-version-upgrade.md)


---

# Neovide (GUI front-end)

Neovide is a separate program from Neovim and upgrades independently. It is
only a front-end: it launches whatever `nvim` it finds on `$PATH` (override
with `NEOVIDE_NEOVIM_BIN`). So upgrading Neovim needs no Neovide action — the
GUI picks up the new version on its next launch.

## Latest stable

<https://github.com/neovide/neovide/releases/latest/download/neovide.AppImage>

## Location of binary

```
/usr/local/bin/neovide            # symlink
  -> /usr/local/bin/neovide.AppImage   # the real 13 MB file
```

Installed as a hand-placed **AppImage** — not dpkg, snap, or flatpak. Nothing
will upgrade it for you.

## Script to install

None of the binary/runtime pairing discipline from the Neovim section applies
here. An AppImage bundles the app and its libraries into one file, so there is
no second half to fall out of sync — the upgrade is a single `cp`:

```bash
cd /tmp && curl -LO https://github.com/neovide/neovide/releases/latest/download/neovide.AppImage
chmod +x neovide.AppImage
./neovide.AppImage --version                 # smoke test BEFORE swapping

sudo cp /usr/local/bin/neovide.AppImage /usr/local/bin/neovide.AppImage-OLD
sudo cp neovide.AppImage /usr/local/bin/neovide.AppImage
rm neovide.AppImage

neovide --version                            # confirm the swap took
```

The `neovide` symlink needs no touching — it points at a stable filename.

**Delta updates (optional, not set up).** The AppImage carries embedded update
info, so `appimageupdatetool` can zsync only the changed blocks with no URL:

```bash
neovide.AppImage --appimage-updateinformation
# gh-releases-zsync|neovide|neovide|latest|neovide.AppImage.zsync
```

FUSE is present so this would work, but `appimageupdatetool` isn't installed
and for a 13 MB file the saving doesn't justify the dependency.

## Desktop entry and icon

```
~/.local/share/applications/neovide.desktop
~/.local/share/icons/hicolor/128x128/apps/neovide.png
```

Both user-level (the Neovim equivalents are system-wide under `/usr/local`).
Neither is touched by an AppImage swap, so there's no per-upgrade drift to
chase the way there is for Neovim's man page and launcher.

The `.desktop` file carries two local customizations worth preserving across
any future reinstall: `Path=/home/bernie/Downloads-work` (working directory for
GUI-opened files) and a commented-out `Exec` experiment for `cd`-ing to the
opened file's own directory.

**If the icon ever needs reinstalling:** `hicolor` here has an
`icon-theme.cache`, and GTK trusts that cache over reading the directory.
Dropping in a new PNG without refreshing leaves the icon unresolvable with no
error shown anywhere:

```bash
cp neovide.png ~/.local/share/icons/hicolor/128x128/apps/neovide.png
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor   # REQUIRED
```

Verify it actually resolves rather than assuming the copy was enough:

```bash
python3 -c "
import gi; gi.require_version('Gtk','3.0')
from gi.repository import Gtk
i = Gtk.IconTheme.get_default().lookup_icon('neovide', 128, 0)
print(i.get_filename() if i else 'NOT FOUND')"
```

Note `Icon=` takes the bare theme name (`neovide`), not a filename or path.
