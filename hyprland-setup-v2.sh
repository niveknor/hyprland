#!/usr/bin/env bash
# hyprland-setup-v2.sh – installerer Hyprland-pakker på Arch (også Arch ARM)
# Kjør som vanlig bruker (IKKE som root):  bash hyprland-setup-v2.sh
#
# Hva dette scriptet gjør:
#   1. Sjekker at alt er i orden (bruker, rettigheter, pacman)
#   2. Installerer pakker ÉN OG ÉN, så en manglende pakke ikke stopper alt
#   3. Lager ~/.config/hypr og kopierer eksempel-configen hvis du ikke har en
#   4. Skriver ut hvilke pakker som feilet
#
# Det overskriver ALDRI en config du allerede har.

set -euo pipefail

# ---------- Hjelpefunksjoner ----------
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn() { echo -e "\e[1;33m[ADVARSEL]\e[0m $*"; }
fail() { echo -e "\e[1;31m[FEIL]\e[0m $*" >&2; exit 1; }

# ---------- Sjekker ----------
[[ $EUID -eq 0 ]] && fail "Ikke kjør dette som root. Scriptet bruker sudo der det trengs."
command -v pacman >/dev/null || fail "Dette scriptet krever Arch (pacman ikke funnet)."
command -v sudo   >/dev/null || fail "sudo mangler. Installer det som root: pacman -S sudo"

# Fanger rettighetsfeil tidlig (f.eks. hvis hjemmemappen eies av root)
[[ -w "$HOME" ]] || fail "Du har ikke skrivetilgang til $HOME. Fiks som root: chown -R $USER:$USER $HOME"
if [[ -e "$HOME/.config" && ! -w "$HOME/.config" ]]; then
    fail "Du har ikke skrivetilgang til ~/.config. Fiks som root: chown -R $USER:$USER $HOME"
fi

# ---------- Pakkelister (rediger fritt) ----------
PAKKER=(
    # Hyprland og nødvendige støttepakker
    hyprland
    xdg-desktop-portal-hyprland
    polkit-kde-agent
    qt5-wayland
    qt6-wayland

    # Verktøy
    kitty          # terminal
    waybar         # statuslinje
    wofi           # app-launcher
    hyprpaper      # bakgrunnsbilde
    dunst          # varsler

    # Lyd
    pipewire
    pipewire-pulse
    wireplumber

    # Fonter
    ttf-jetbrains-mono-nerd
    noto-fonts
)

# ---------- Installasjon ----------
info "Oppdaterer pakkedatabasen..."
sudo pacman -Sy

FEILET=()

for pakke in "${PAKKER[@]}"; do
    info "Installerer: $pakke"
    # 'if' gjør at set -e ikke stopper scriptet hvis en pakke feiler
    if sudo pacman -S --needed --noconfirm "$pakke"; then
        :
    else
        warn "Kunne ikke installere: $pakke"
        FEILET+=("$pakke")
    fi
done

# ---------- Config ----------
CONF_DIR="$HOME/.config/hypr"
LUA_FIL="$CONF_DIR/hyprland.lua"
CONF_FIL="$CONF_DIR/hyprland.conf"
EKSEMPEL="/usr/share/hypr/hyprland.lua"   # eksempel-config som følger med Hyprland

mkdir -p "$CONF_DIR"

if [[ -f "$LUA_FIL" ]]; then
    info "Fant $LUA_FIL – lar den være urørt."
elif [[ -f "$EKSEMPEL" ]]; then
    info "Kopierer eksempel-config til $LUA_FIL"
    cp "$EKSEMPEL" "$LUA_FIL"
else
    warn "Fant ingen eksempel-config. Start Hyprland én gang, så lager den en standard hyprland.lua."
fi

# hyprland.lua har prioritet over hyprland.conf i Hyprland 0.55+
if [[ -f "$LUA_FIL" && -f "$CONF_FIL" ]]; then
    warn "Både hyprland.lua og hyprland.conf finnes. Bare .lua blir brukt."
fi

# ---------- Oppsummering ----------
echo
if (( ${#FEILET[@]} > 0 )); then
    warn "Disse pakkene ble ikke installert: ${FEILET[*]}"
    warn "Sjekk om de finnes for din plattform (pacman -Ss <navn>), eller fjern dem fra listen."
fi

info "Ferdig! Rediger configen med:  nano $LUA_FIL"
info "Start Hyprland fra TTY med:    start-hyprland"
