# KATASHIE VPN — Adaptation audit

## Basis
This package was adapted directly from the supplied `nexTPro-ScriptAll-main.zip` reference project.

## Preserved
- Core protocol scripts and their functional structure.
- Xray, OpenVPN, ZIVPN, SlowDNS, UDP Custom, BadVPN, Nginx and WebSocket modules from the supplied project.
- External upstream dependency URLs used by those modules.

## Adapted
- Project identity: **KATASHIE VPN**.
- Repository endpoints: `abesskamer237/KATASHIE_VPN`.
- Project-owned service/path names: `katashie-*`.
- Web panel branding and project paths.
- Cameroon/Yaoundé timezone: `Africa/Douala`.
- Terminal presentation: green/red/cyan/magenta/yellow reference style.
- Animated KATASHIE ASCII signature.
- Installer progress/error presentation and per-component log files.
- OTA updater to refresh menu/core/UI/launcher and update the web panel without deleting its configuration.
- Complete KATASHIE uninstaller.

## Static checks performed
- `bash -n` on all shell scripts: passed.
- Python compilation check on all Python files: passed.
- JSON parsing checks: passed for JSON configuration files checked.
- No remaining project-owned references to `RootNexTPro`, `nexTPro-ScriptAll`, `Nexus Tunnel Pro`, `nexus-web`, or `nexus_bot` were found outside excluded upstream/binary data.

## Important
Static checks do not replace a real VPS installation test. Network-dependent protocol binaries, certificates, DNS records and provider-specific firewall behavior must still be validated on the target VPS.
