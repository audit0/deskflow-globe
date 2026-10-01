# Deskflow Globe

A small macOS menu bar app that makes a short **Fn / Globe** tap switch input sources while a Deskflow server controls another computer.

Deskflow can consume keyboard events before a conventional language switcher's global monitor receives them. Deskflow Globe installs a passive observer ahead of Deskflow and selects the next enabled macOS keyboard layout. Deskflow's client language synchronization then carries that language with the next key press. This app does not connect to Windows directly.

## Download and install

Download the universal ZIP from [Releases](https://github.com/audit0/deskflow-globe/releases), extract it, and run `Install.command`. It installs for the current user in `~/Library/Application Support/DeskflowGlobe` and registers a LaunchAgent. It requires no administrator privileges and does not edit Deskflow settings.

1. Allow **Deskflow Globe** under **System Settings → Privacy & Security → Input Monitoring**. If it is absent, use **+** and select the installed app from the location above. Launch it again after granting permission.
2. Under **Keyboard → Press Globe key to**, choose **Do Nothing**.
3. Enable **language synchronization** on the Deskflow client. Enable the same languages on both computers.
4. Quit LangSwitch or another Fn language switcher to avoid double switching. To opt into automatically stopping LangSwitch while Deskflow Globe runs, install from Terminal with `./Install.command --replace-langswitch`.
5. Start your Deskflow server. Tap Fn briefly (less than 0.2 seconds), then type in an empty editor on the client. The Windows language indicator may update only with the next key press.

The launcher waits for a stable Deskflow server process and relaunches the observer after the server restarts. Long Fn presses and Fn combinations with other keys do not switch languages. Without the installer, you may run the app directly; launch it after Deskflow, and relaunch it after server restarts.

### macOS download warning

The release is locally/ad-hoc signed, **not Developer ID signed or notarized**. macOS may block an Internet-downloaded build. Use Apple's documented [Open Anyway process](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac) only if you trust this release, or build from source. The installer does not disable Gatekeeper or remove quarantine.

## If mouse sharing works but typing stays on the Mac

Check the Deskflow log for `application "…" is blocking the keyboard`. macOS Secure Input can prevent keyboard forwarding even though the connection and mouse still work. Finish or cancel any pending authentication dialog yourself. If Secure Input remains stuck after unlocking, save your work and restart the Mac. This was observed with `UserNotificationCenter` and `loginwindow` during validation; the keyboard recovered after Secure Input cleared.

Deskflow Globe does **not** disable or bypass Secure Input. It also cannot fix Wi-Fi latency, Thunderbolt cable detection, or Deskflow client permissions.

## Privacy and permissions

- Passive `CGEventTap` observer; no keyboard or mouse event injection.
- Examines Fn/modifier state and whether another key was pressed during Fn; no text or key-code history is retained.
- No keystroke logs, network communication, analytics, or automatic updates.
- Input Monitoring is needed to receive the Fn events. No Accessibility, administrator, or Full Disk Access permission is requested by the app.
- The optional launcher polls server process IDs and writes only process-launch errors. Automatic stopping of LangSwitch is opt-in.

## Remove or roll back

Run `Uninstall.command` from the release folder or the installed support folder. It stops this release's launcher and app, and moves installed files and its LaunchAgent to a dated backup in Application Support. Deskflow, your layouts, and your previous switcher's login item are left intact. You can restart your former switcher and remove Deskflow Globe from Input Monitoring.

The earlier local prototype (`local.deskflow.globe.launcher`) is a separate installation. The release installer refuses to install while that prototype's LaunchAgent is installed, even if temporarily stopped; use the prototype's own rollback command first. An existing release installation is also preserved instead of silently overwritten.

## Build and verify

Requirements: macOS with Xcode Command Line Tools and Swift.

```sh
bash scripts/test.sh
bash scripts/build.sh
```

The build creates a macOS 13+ universal app (arm64 and x86_64), a portable install/remove package, and SHA-256 checksums under `build/`. Verify a download with `shasum -a 256 -c SHA256SUMS`.

Functional testing: Apple Silicon Mac with macOS 27, Deskflow 1.26 server, and Windows 11 with Deskflow 1.26 client. Input language changes `en → ru → en` were confirmed in the client log and by the user. Intel and older macOS builds are compiled but have not been tested on physical hardware. CI checks gesture regressions, shell syntax, both architectures, and ad-hoc code signatures; it does not simulate the physical Fn key.

## Credits

[Deskflow](https://github.com/deskflow/deskflow) provides input sharing and language synchronization. [LangSwitch](https://github.com/Nikeev/LangSwitch) was the existing switcher that motivated investigating the Fn event ordering. This is an independent companion app, not an official Deskflow distribution.

MIT license. Copyright © 2026 audit0.
