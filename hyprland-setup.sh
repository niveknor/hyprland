#!/usr/bin/env bash
# hyprland-setup.sh – enkelt startpunkt for Hyprland på Arch
# Kjør som vanlig bruker (IKKE som root):  bash hyprland-setup.sh

# Stopp ved feil, feil på udefinerte variabler, og feil i pipes
set -euo pipefail

# ---------- Hjelpefunksjoner ----------
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn() { echo -e "\e[1;33m[ADVARSEL]\e[0m $*"; }
fail() { echo -e "\e[1;31m[FEIL]\e[0m $*" >&2; exit 1; }

# ---------- Sjekker ----------
[[ $EUID -eq 0 ]] && fail "Ikke kjør dette som root. Scriptet bruker sudo der det trengs."
command -v pacman >/dev/null || fail "Dette scriptet krever Arch (pacman ikke funnet)."

# ---------- Pakkelister (rediger fritt) ----------
# Legg til eller fjern pakker her, resten av scriptet trenger ikke endres
PAKKER_KJERNE=(
    hyprland
    xdg-desktop-portal-hyprland
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
)

PAKKER_VERKTOY=(
    kitty        # terminal
    waybar       # statuslinje
    wofi         # app-launcher
    hyprpaper    # bakgrunnsbilde
    dunst        # varsler
    firefox
)

PAKKER_LYD=(
    pipewire
    pipewire-pulse
    wireplumber
)

PAKKER_FONTER=(
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
)

# ---------- Installasjon ----------
info "Oppdaterer systemet..."
sudo pacman -Syu --noconfirm

info "Installerer pakker..."
sudo pacman -S --needed --noconfirm \
    "${PAKKER_KJERNE[@]}" \
    "${PAKKER_VERKTOY[@]}" \
    "${PAKKER_LYD[@]}" \
    "${PAKKER_FONTER[@]}"

# ---------- Konfigurasjon ----------
CONF_DIR="$HOME/.config/hypr"
CONF_FIL="$CONF_DIR/hyprland.conf"

mkdir -p "$CONF_DIR"

# Ta backup hvis det allerede finnes en config
if [[ -f "$CONF_FIL" ]]; then
    BACKUP="$CONF_FIL.bak.$(date +%Y%m%d-%H%M%S)"
    warn "Fant eksisterende config, tar backup: $BACKUP"
    cp "$CONF_FIL" "$BACKUP"
fi

# Skriv en minimal config (bygg videre på denne)
cat > "$CONF_FIL" << 'EOF'
# Minimal Hyprland-config
monitor = , preferred, auto, 1

$terminal = kitty
$menu     = wofi --show drun
$mod      = SUPER

exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = /usr/lib/polkit-kde-authentication-agent-1

input {
    kb_layout = no
}

bind = $mod, Return, exec, $terminal
bind = $mod, D, exec, $menu
bind = $mod, Q, killactive
bind = $mod SHIFT, E, exit

# Bytt arbeidsområde 1-5
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
EOF

# ---------- Ferdig ----------
info "Ferdig! Logg ut og start Hyprland fra TTY ved å skrive:  Hyprland"
