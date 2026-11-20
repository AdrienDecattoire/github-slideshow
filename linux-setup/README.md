# Linux setup

One script that sets up a fresh Linux install with **Firefox** and **Steam**
(plus the NVIDIA graphics driver if your computer has an NVIDIA card).

Works on Ubuntu, Linux Mint, Pop!_OS, Debian and Fedora.

## Before you wipe your computer

1. **Back up your files**: documents, photos, passwords and anything not in the cloud.
   Steam games themselves can be re-downloaded, and most saves sync through Steam Cloud.
2. **Try Linux from a USB stick first** (every installer offers "Try without installing").
   Check that Wi-Fi, sound and your screen work. If they work there, they'll work after installing.
3. **Check your games** at <https://www.protondb.com>. Most games run fine. The ones that
   usually don't are multiplayer games with strict anti-cheat (e.g. Valorant, Fortnite).

## After installing Linux

Open a terminal and run:

```bash
wget https://raw.githubusercontent.com/adriendecattoire/github-slideshow/main/linux-setup/setup.sh
bash setup.sh
```

It will ask for your password, then take a few minutes. If anything fails, just run
it again: steps that already worked are skipped.
