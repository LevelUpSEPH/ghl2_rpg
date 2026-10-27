# Running HL2:RPG on a Linux VDS

A plain Ubuntu **20.04 or 22.04** server with SSH (e.g. SAGANETWORK Ryzen VDS). `setup.sh` installs and updates
everything: SteamCMD, the Garry's Mod server, Source SDK Base 2013 (Half-Life 2's base content), this addon with
its **Half-Life 2 Campaign** gamemode (Lambda under its own name), Lambda itself, and a service that starts the
server on boot. Commands below: PowerShell ones run on your PC, the rest in SSH.

## First install

1. **Fresh server:** Ubuntu installs updates on first boot and locks the package manager meanwhile; `setup.sh`
   waits for it. Reboot once afterwards if it installed a new kernel.

2. **Build and upload the bundle** (PC):
   ```
   powershell -ExecutionPolicy Bypass -File server\pack.ps1
   scp D:\Games\hlrpg-server.zip root@SERVER_IP:/root/
   ```

3. **Upload the game content you own** (PC). Source SDK Base has Half-Life 2's content but not its campaign
   maps or the episodes, so they come from your own Half-Life 2 install (about 5 GB):
   ```
   ssh root@SERVER_IP "mkdir -p /home/gmod/sdkbase/hl2/maps /home/gmod/content"
   $maps = Get-ChildItem "D:\SteamLibrary\steamapps\common\Half-Life 2\hl2\maps\d?_*.bsp" | ForEach-Object FullName
   scp -o ServerAliveInterval=30 $maps root@SERVER_IP:/home/gmod/sdkbase/hl2/maps/
   scp -o ServerAliveInterval=30 -r "D:\SteamLibrary\steamapps\common\Half-Life 2\episodic" root@SERVER_IP:/home/gmod/content/
   scp -o ServerAliveInterval=30 -r "D:\SteamLibrary\steamapps\common\Half-Life 2\ep2" root@SERVER_IP:/home/gmod/content/
   ```
   If a connection drops, upload just the missing files again; `scp` overwrites what's there. Check on the
   server: `ls /home/gmod/sdkbase/hl2/maps/d?_*.bsp | wc -l` should say 70, and `ls /home/gmod/content/ep2/*.vpk
   | wc -l` 22, `ls /home/gmod/content/episodic/*.vpk | wc -l` 11.

4. **Steam login token** (optional, keeps the server ranked in the browser): create one at
   steamcommunity.com/dev/managegameservers (App ID `4000`) and put it on the server:
   ```
   echo "YOUR_TOKEN" > /home/gmod/gslt.txt
   ```

5. **Run the setup** (SSH), with your SteamID (steamid.io) to become superadmin:
   ```
   apt-get install -y unzip
   cd /root && rm -rf hlrpg-server && unzip -o hlrpg-server.zip
   cd hlrpg-server && sudo bash setup.sh STEAM_0:1:12345678
   ```
   It tells you if any of the game content from step 3 is missing. The first run downloads several GB.

6. **Set the rcon password** (a long random one) in the server's `server.cfg`, then restart:
   ```
   nano /home/gmod/server/garrysmod/cfg/server.cfg
   sudo systemctl restart hlrpg
   ```

7. **Join** from Garry's Mod's console: `connect SERVER_IP:27015`.

## Updating

Build and upload the zip again (PC), then (SSH):
```
cd /root && rm -rf hlrpg-server && unzip -o hlrpg-server.zip && cd hlrpg-server && sudo bash setup.sh
```
Updates the game files, the addon and Lambda, and restarts. Kept: player progress and leaderboards (`sv.db`), the
welcome message, the token, and `server.cfg` once it has a hostname.

## Map downloads (FastDL)

`setup.sh` also runs a small web server (nginx, port 80) that hands players the Half-Life 2 campaign maps and the
addon's textures, compressed, so players without Half-Life 2's maps can join. It compresses the maps the first time
(a few minutes), then only new or changed files. The download URL is this server's IP; if that's wrong (the server
sits behind NAT), set `FASTDL_HOST` at the top of `setup.sh` and run it again. Check it from your PC: opening
`http://SERVER_IP/maps/d1_trainstation_01.bsp.bz2` in a browser should download a file.

Episode maps aren't served: players need to own and install the episodes for their content anyway.

## Everyday use

| What | Command |
|---|---|
| Server console | `sudo -u gmod tmux attach -t hlrpg` (leave with **Ctrl+B**, then **D**; never Ctrl+C) |
| Last console lines | `sudo -u gmod tmux capture-pane -pt hlrpg -S -60` |
| Restart / stop / start | `sudo systemctl restart hlrpg` / `stop` / `start` |
| Settings | `/home/gmod/server/garrysmod/cfg/server.cfg` |

The server restarts itself after a crash and starts when the VDS boots. To start on another campaign, change
`START_MAP` at the top of `setup.sh` (`ep1_citadel_00` or `ep2_outland_01`) and run it again.

Admin commands work in the server console, over rcon, or in game for admins; `rpg_help` lists them, e.g.
`rpg_welcome Welcome {name}! Join us at https://discord.gg/yourcode`, `rpg_setdiff 1-5`, `rpg_players`.

## Backups

Download now and then (e.g. with WinSCP): `/home/gmod/server/garrysmod/sv.db` (all progress and leaderboards) and
`/home/gmod/server/garrysmod/data/hlrpg/` (welcome message). Losing `sv.db` resets everyone.

## Troubleshooting

- **No welcome message / no TAB menu / "unknown entity type" errors:** folder permissions; `setup.sh` fixes them,
  so run it again.
- **"map ... not found":** the campaign maps from step 3 are missing.
- **Still "anonymous game server account":** the token in `/home/gmod/gslt.txt` is missing or wrong; fix it and run
  `setup.sh` again.

## Files in this folder

- `setup.sh`: installs / updates the server (run on the VDS).
- `pack.ps1`: builds the upload bundle on Windows.
- `server.cfg`: default settings, installed when the server has none with a hostname.
- `mount.cfg`: reference for mounting the content by hand (`setup.sh` writes the real one).
