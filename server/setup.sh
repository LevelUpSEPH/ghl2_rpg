#!/usr/bin/env bash
# HL2:RPG server setup for a fresh Ubuntu 20.04 / 22.04 VDS. Run it from the unpacked hlrpg-server folder:
#
#     sudo bash setup.sh                      # install or update
#     sudo bash setup.sh STEAM_0:1:12345678   # same, and make that SteamID superadmin
#
# Safe to run again: it updates the game files, the addon and Lambda, and keeps player data (sv.db),
# server.cfg once it exists, and anything else changed on the server.
set -euo pipefail

BUNDLE="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="gmod"
HOME_DIR="/home/$USER_NAME"
STEAMCMD="$HOME_DIR/steamcmd"
SERVER="$HOME_DIR/server"        # Garry's Mod dedicated server
SDKBASE="$HOME_DIR/sdkbase"      # Source SDK Base 2013 Dedicated Server: Half-Life 2 (hl2)
CONTENT="$HOME_DIR/content"      # Episode One and Two (episodic, ep2), uploaded from your own Half-Life 2 install
GMOD="$SERVER/garrysmod"
ADMIN_STEAMID="${1:-}"

# Start parameters. Change the map to start on Episode One (ep1_citadel_00) or Two (ep2_outland_01).
PORT=27015
MAXPLAYERS=12
START_MAP="d1_trainstation_01"

# FastDL: players without Half-Life 2's maps (and everyone, for the addon's textures) download them over HTTP
# from this server instead of through the game connection. Leave FASTDL_HOST empty to use this server's IP.
FASTDL_DIR="/var/www/fastdl"
FASTDL_PORT=80
FASTDL_HOST=""

say() { echo -e "\n\033[1;36m==> $*\033[0m"; }

[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo bash setup.sh"; exit 1; }
for part in addon lambda server.cfg; do
    [[ -e "$BUNDLE/$part" ]] || { echo "Missing $part next to setup.sh. Unpack the whole hlrpg-server.zip."; exit 1; }
done

say "Installing system packages"
# A fresh server runs its own updates on first boot and holds the package lock meanwhile: wait up to 15 min
APT=(apt-get -o DPkg::Lock::Timeout=900)
dpkg --add-architecture i386
"${APT[@]}" update -y
DEBIAN_FRONTEND=noninteractive "${APT[@]}" install -y \
    curl ca-certificates tar tmux rsync bzip2 nginx \
    lib32gcc-s1 lib32stdc++6 lib32z1 libncurses5:i386 libtinfo5:i386

if ! id "$USER_NAME" &>/dev/null; then
    say "Creating user '$USER_NAME' (the server never runs as root)"
    useradd -m -s /bin/bash "$USER_NAME"
fi

as_gmod() { sudo -u "$USER_NAME" -H bash -c "$1"; }

if [[ ! -x "$STEAMCMD/steamcmd.sh" ]]; then
    say "Installing SteamCMD"
    as_gmod "mkdir -p '$STEAMCMD' && cd '$STEAMCMD' && curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz"
fi

# SteamCMD updates itself on its first runs, and a download started in the same run often fails with
# "Missing configuration". So: let it update first, then retry each download a few times.
as_gmod "'$STEAMCMD/steamcmd.sh' +quit" || true

steam_install() { # <app id> <folder>
    for attempt in 1 2 3; do
        if as_gmod "'$STEAMCMD/steamcmd.sh' +force_install_dir '$2' +login anonymous +app_update $1 validate +quit"; then
            return 0
        fi
        echo "SteamCMD failed (attempt $attempt of 3), retrying..."
        sleep 5
    done
    echo "Could not install app $1. Run setup.sh again; if it keeps failing, paste the output."
    exit 1
}

say "Installing / updating the Garry's Mod server (app 4020)"
steam_install 4020 "$SERVER"

say "Installing / updating Source SDK Base 2013 Dedicated Server (app 244310: Half-Life 2)"
steam_install 244310 "$SDKBASE"
# Each game is mounted from the SDK Base install if it has it, otherwise from $CONTENT (the uploaded folders)
mkdir -p "$CONTENT"
game_dir() {
    if [[ -d "$SDKBASE/$1" ]]; then echo "$SDKBASE/$1"; else echo "$CONTENT/$1"; fi
}

say "Mounting HL2 and the episodes (mount.cfg)"
cat > "$GMOD/cfg/mount.cfg" <<EOF
"mountcfg"
{
	"hl2"		"$(game_dir hl2)"
	"episodic"	"$(game_dir episodic)"
	"ep2"		"$(game_dir ep2)"
}
EOF
MISSING_EPISODES=0
for game in hl2 episodic ep2; do
    if ! ls "$(game_dir $game)"/*_dir.vpk &>/dev/null; then
        echo "WARNING: $game content not found in $(game_dir $game)"
        MISSING_EPISODES=1
    fi
done

# The SDK Base has Half-Life 2's content but not its campaign maps: those are loose .bsp files in your own
# Half-Life 2 install (hl2\maps\d1_*, d2_*, d3_*), uploaded into the mounted hl2 folder
HL2_MAPS="$(game_dir hl2)/maps"
mkdir -p "$HL2_MAPS"
MISSING_HL2_MAPS=0
[[ -f "$HL2_MAPS/d1_trainstation_01.bsp" ]] || MISSING_HL2_MAPS=1

say "Installing the HL2:RPG addon and the Lambda gamemode"
mkdir -p "$GMOD/addons" "$GMOD/gamemodes"
rsync -a --delete "$BUNDLE/addon/" "$GMOD/addons/halflife_rpg/"
rsync -a --delete "$BUNDLE/lambda/" "$GMOD/gamemodes/lambda/"

say "Preparing FastDL (compressed maps and addon files for players to download)"
# Once a download URL is set, players fetch every file from it (falling back to the game server doesn't work
# reliably), so it mirrors everything the server sends: the HL2 campaign maps, the addon's materials and
# Lambda's content. Each file is stored bzip2-compressed (players' downloads are a third of the size) next to
# the original. Only new or changed files are compressed again.
mkdir -p "$FASTDL_DIR/maps"
for bsp in "$HL2_MAPS"/d?_*.bsp; do
    [[ -f "$bsp" ]] || continue
    target="$FASTDL_DIR/maps/$(basename "$bsp").bz2"
    if [[ ! -f "$target" || "$bsp" -nt "$target" ]]; then
        echo "  compressing $(basename "$bsp")"
        bzip2 -c -9 "$bsp" > "$target.tmp" && mv "$target.tmp" "$target"
    fi
done
# The game server only offers players maps from Garry's Mod's own maps folder, not from mounted games: link them
mkdir -p "$GMOD/maps"
for bsp in "$HL2_MAPS"/d?_*.bsp; do
    if [[ -f "$bsp" ]]; then ln -sf "$bsp" "$GMOD/maps/$(basename "$bsp")"; fi
done
rsync -a "$BUNDLE/addon/materials/" "$FASTDL_DIR/materials/"
for dir in materials models sound; do
    if [[ -d "$BUNDLE/lambda/content/$dir" ]]; then rsync -a "$BUNDLE/lambda/content/$dir/" "$FASTDL_DIR/$dir/"; fi
done
find "$FASTDL_DIR" -type f ! -name '*.bz2' ! -path "$FASTDL_DIR/maps/*" | while read -r f; do
    if [[ ! -f "$f.bz2" || "$f" -nt "$f.bz2" ]]; then bzip2 -k -f -9 "$f"; fi
done
chmod -R a+rX "$FASTDL_DIR"
echo "  $(ls "$FASTDL_DIR/maps" | wc -l) maps ready, $(du -sh "$FASTDL_DIR" | cut -f1) in total"

# nginx serves the folder as static files only (no listing)
cat > /etc/nginx/sites-available/fastdl <<EOF
server {
    listen $FASTDL_PORT default_server;
    listen [::]:$FASTDL_PORT default_server;
    root $FASTDL_DIR;
    autoindex off;
    location / { try_files \$uri =404; }
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/fastdl /etc/nginx/sites-enabled/fastdl
nginx -t && systemctl enable nginx && systemctl reload-or-restart nginx

[[ -n "$FASTDL_HOST" ]] || FASTDL_HOST="$(hostname -I | awk '{print $1}')"
FASTDL_URL="http://$FASTDL_HOST"
[[ "$FASTDL_PORT" == "80" ]] || FASTDL_URL="$FASTDL_URL:$FASTDL_PORT"
echo "  Download URL: $FASTDL_URL/"

# GMod creates an empty placeholder server.cfg itself, so only one with a hostname counts as already set up
if ! grep -q '^[[:space:]]*hostname' "$GMOD/cfg/server.cfg" 2>/dev/null; then
    cp "$BUNDLE/server.cfg" "$GMOD/cfg/server.cfg"
    say "server.cfg installed. Edit the CHANGE ME lines: nano $GMOD/cfg/server.cfg"
else
    echo "Keeping the existing server.cfg (the bundled one is not copied over it)."
fi

if [[ -n "$ADMIN_STEAMID" ]]; then
    say "Making $ADMIN_STEAMID superadmin"
    mkdir -p "$GMOD/settings"
    cat > "$GMOD/settings/users.txt" <<EOF
"Users"
{
	"superadmin"
	{
		"Owner"	"$ADMIN_STEAMID"
	}
}
EOF
fi

chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR"
# Zips made on Windows can unpack folders without the "enter" (x) permission, so GMod sees them but can't load
# anything inside: make every folder enterable and every file readable (executables keep their x bit)
chmod -R u+rwX,go+rX "$GMOD/addons/halflife_rpg" "$GMOD/gamemodes/lambda" "$CONTENT" "$HL2_MAPS"

say "Creating the start script and the boot service"
# Steam login token (GSLT): it must be on the command line (server.cfg runs after the Steam login), so it's read
# from its own file, kept out of server.cfg and the repository. Put the token in $HOME_DIR/gslt.txt.
GSLT_FILE="$HOME_DIR/gslt.txt"
GSLT_ARG=""
if [[ -s "$GSLT_FILE" ]]; then
    GSLT_ARG="+sv_setsteamaccount $(tr -d ' \r\n' < "$GSLT_FILE")"
    chown "$USER_NAME:$USER_NAME" "$GSLT_FILE"
    chmod 600 "$GSLT_FILE"
    echo "Using the Steam login token from $GSLT_FILE"
fi

cat > "$HOME_DIR/start.sh" <<EOF
#!/usr/bin/env bash
# srcds_run restarts the server by itself if it crashes
cd "$SERVER"
exec ./srcds_run -game garrysmod -console -port $PORT -tickrate 66 +maxplayers $MAXPLAYERS $GSLT_ARG +sv_downloadurl "$FASTDL_URL/" +sv_allowdownload 1 +gamemode hl2campaign +map $START_MAP
EOF
chmod 700 "$HOME_DIR/start.sh"
chown "$USER_NAME:$USER_NAME" "$HOME_DIR/start.sh"

# The server runs inside a tmux session, so its console can be opened any time (see the end of this script)
cat > /etc/systemd/system/hlrpg.service <<EOF
[Unit]
Description=HL2:RPG Garry's Mod server
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=$USER_NAME
ExecStart=/usr/bin/tmux new-session -d -s hlrpg $HOME_DIR/start.sh
ExecStop=/usr/bin/tmux kill-session -t hlrpg
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable hlrpg.service

if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    say "Opening the game ports in the firewall"
    ufw allow 22/tcp
    ufw allow $PORT/udp
    ufw allow $PORT/tcp
    ufw allow $FASTDL_PORT/tcp
fi

say "Starting the server"
systemctl restart hlrpg.service

if [[ $MISSING_HL2_MAPS -eq 1 ]]; then
    cat <<EOF

The Half-Life 2 campaign maps are still missing. From PowerShell on your PC, upload your own copies:
  \$maps = Get-ChildItem "D:\\SteamLibrary\\steamapps\\common\\Half-Life 2\\hl2\\maps\\d?_*.bsp" | ForEach-Object FullName
  scp -o ServerAliveInterval=30 \$maps root@SERVER_IP:$HL2_MAPS/
then run this setup again.
EOF
fi

if [[ $MISSING_EPISODES -eq 1 ]]; then
    cat <<EOF

The Episode One / Two content is still missing. From PowerShell on your PC, upload your own copies:
  scp -r "D:\SteamLibrary\steamapps\common\Half-Life 2\episodic" root@SERVER_IP:$CONTENT/
  scp -r "D:\SteamLibrary\steamapps\common\Half-Life 2\ep2" root@SERVER_IP:$CONTENT/
then run this setup again.
EOF
fi

cat <<EOF

Done. The server is starting on port $PORT (connect with: connect <this server's IP>:$PORT).

  Open its console:     sudo -u $USER_NAME tmux attach -t hlrpg      (leave it running: Ctrl+B, then D)
  Restart / stop:       sudo systemctl restart hlrpg   /   sudo systemctl stop hlrpg
  Settings:             nano $GMOD/cfg/server.cfg      (then restart)
  Back up regularly:    $GMOD/sv.db  and  $GMOD/data/hlrpg/
EOF
