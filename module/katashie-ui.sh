#!/bin/bash
# KATASHIE VPN — Premium terminal UI
K_GREEN='\033[0;32m'; K_BRIGHT_GREEN='\033[1;32m'; K_RED='\033[1;31m'; K_CYAN='\033[0;36m'; K_MAGENTA='\033[0;35m'; K_YELLOW='\033[1;33m'; K_WHITE='\033[1;37m'; K_DIM='\033[2m'; K_RESET='\033[0m'; K_BLINK='\033[5m'
K_WIDTH=66

k_box_line(){ printf '%b\n' "${K_GREEN}╭$(printf '─%.0s' $(seq 1 $((K_WIDTH-2))) )╮${K_RESET}"; }
k_box_bottom(){ printf '%b\n' "${K_GREEN}╰$(printf '─%.0s' $(seq 1 $((K_WIDTH-2))) )╯${K_RESET}"; }
k_red_title(){ local t="$1"; printf '%b\n' "${K_GREEN}╭$(printf '─%.0s' $(seq 1 $((K_WIDTH-2))) )╮${K_RESET}"; printf '%b\n' "${K_GREEN}│${K_RED}$(printf ' %*s' $((K_WIDTH-3)) '' | sed "s/ / /g")${K_GREEN}│${K_RESET}"; printf '\033[1A\r%b' "${K_GREEN}│${K_RED} $(printf '%-*s' $((K_WIDTH-4)) "$t") ${K_GREEN}│${K_RESET}"; k_box_bottom; }
k_sep(){ local c="$1"; printf '%b\n' "${!c}$(printf '━%.0s' $(seq 1 "$K_WIDTH"))${K_RESET}"; }
k_signature(){
  local lines=(
'██╗  ██╗ █████╗ ████████╗ █████╗ ███████╗██╗  ██╗██╗███████╗'
'██║ ██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║  ██║██║██╔════╝'
'█████╔╝ ███████║   ██║   ███████║███████╗███████║██║█████╗  '
'██╔═██╗ ██╔══██║   ██║   ██╔══██║╚════██║██╔══██║██║██╔══╝  '
'██║  ██╗██║  ██║   ██║   ██║  ██║███████║██║  ██║██║███████╗'
'╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝')
  local i; for i in "${!lines[@]}"; do printf '%b\n' "${K_CYAN}${lines[$i]}${K_RESET}"; sleep .035; done
}
k_brand(){
  clear
  k_signature
  k_spinner "Initialisation de KATASHIE VPN" 5
  printf '%b\n' "${K_MAGENTA}╭$(printf '─%.0s' $(seq 1 $((K_WIDTH-2))) )╮${K_RESET}"
  printf '%b\n' "${K_MAGENTA}│${K_RED}  WELCOME TO KATASHIE VPN • PREMIUM EDITION  ${K_MAGENTA}│${K_RESET}"
  printf '%b\n' "${K_MAGENTA}╰$(printf '─%.0s' $(seq 1 $((K_WIDTH-2))) )╯${K_RESET}"
  printf '%b\n' "${K_GREEN}           KATASHIE VPN — SECURE SERVER CONTROL${K_RESET}"
  k_sep K_YELLOW
}
k_status(){ local label="$1" value="$2"; printf '%b\n' "${K_GREEN}│ ${K_WHITE}$(printf '%-12s' "$label")${K_RESET}: ${value}"; }
k_ok(){ printf '%b\n' "${K_GREEN}  ✔${K_RESET} %s" "$*"; }
k_err(){ printf '%b\n' "${K_RED}  ✘${K_RESET} %s" "$*"; }
k_info(){ printf '%b\n' "${K_CYAN}  ›${K_RESET} %s" "$*"; }
k_step(){ printf '%b' "${K_YELLOW}  ◐${K_RESET} $*"; }
k_done(){ printf '%b\n' " ${K_GREEN}✔${K_RESET}"; }
k_wait(){ printf '%b' "${K_GREEN}  Select From Options [01-26] » ${K_RESET}"; }
k_spinner(){ local msg="$1" loops="${2:-8}"; local frames=('◐' '◓' '◑' '◒'); local i; for i in $(seq 1 "$loops"); do printf '\r%b' "${K_CYAN}  ${frames[$(((i-1)%4))]}${K_RESET} ${msg}"; sleep .12; done; printf '\r%b\n' "${K_GREEN}  ✔${K_RESET} ${msg}"; }
k_progress(){ local label="$1"; local i bars; for i in $(seq 0 20 100); do bars=$((i/10)); if [ $bars -gt 0 ]; then bar=$(printf '█%.0s' $(seq 1 $bars)); else bar=''; fi; printf '\r%b' "${K_CYAN}  ${label} [${i}%] ${K_GREEN}${bar}${K_RESET}"; sleep .04; done; printf '\n'; }
k_header(){ local title="$1"; clear; k_signature; k_sep K_MAGENTA; printf '%b\n' "${K_GREEN}┌────────────────────────────────────────────────────────────────┐"; printf '%b\n' "│ ${K_RED}$(printf '%-62s' " $title")${K_GREEN}│"; printf '%b\n' '└────────────────────────────────────────────────────────────────┘'; k_sep K_YELLOW; }
