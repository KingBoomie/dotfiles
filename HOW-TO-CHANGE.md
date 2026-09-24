# How To Change This Desktop Setup

This setup is mainly `niri` + `Noctalia` + `Alacritty`.

## Files

- `niri/config.kdl`: compositor behavior, keybinds, output scale, input scroll, window rules.
- `noctalia/config.toml`: exported Noctalia v5 user configuration.
- `niri/noctalia.kdl`: color/layout include required by `niri/config.kdl`.
- `noctalia msg --help`: the installed Noctalia v5 IPC command reference.
- `noctalia config validate`: validate the v5 config.
- `alacritty/alacritty.toml`: terminal startup mode and requested dimensions.
- `fonts/SFMono/`: local SF Mono OTF files required by Alacritty's font configuration.
- `.zshrc`, `.p10k.zsh`: shell and prompt settings. Local credentials belong in `~/.config/shell-secrets.env` (mode `0600`), which is outside this bundle.
- `.zfunc/`, `.zsh/completions/`: custom completion definitions loaded through `.zshrc` before Oh My Zsh initializes completion.
- `io.datasette.llm/default_model.txt`: `groq/openai/gpt-oss-120b`.
- `io.datasette.llm/templates/cmd.yaml`: prompt used by `llm -t cmd` and the `cmd` alias.
- `.tool-versions`: Node version installed by asdf during bootstrap.
- `bootstrap-new-ubuntu.sh`: Ubuntu 26.04+ setup script for niri, Noctalia v5, Pixi, uv, and these configs.

## Validate And Reload

- Validate niri config before reloading:
  ```sh
  niri validate --config niri/config.kdl
  ```
- Reload active niri config:
  ```sh
  niri msg action load-config-file
  ```
- Inspect active outputs and scaling:
  ```sh
  niri msg outputs
  ```
- Inspect live windows, app IDs, floating state, and sizes:
  ```sh
  niri msg windows
  ```
- Inspect available niri actions:
  ```sh
  niri msg action --help
  niri msg action help <action-name>
  ```
- Read packaged niri examples:
  ```sh
  zcat /usr/share/doc/niri/default-config.kdl.gz | sed -n '1,220p'
  ```

## Niri Syntax Gotchas

- Niri uses KDL, not Hyprland/Sway syntax. Do not add blocks like:
  ```kdl
  rule {
      app = "Alacritty"
      default-size = { width = 80 }
  }
  ```
- Use niri window rules instead:
  ```kdl
  window-rule {
      match app-id=r#"^Alacritty$"#
      default-column-width {}
  }
  ```
- `default-column-width {}` means: let the app request its natural width.
- `open-floating true` makes the app leave the normal tiled column flow. Do not use it if the goal is “small but still tiled”.
- Some actions shown by `niri msg action --help` may not parse directly as bind actions on this installed version. If direct bind validation fails, invoke via:
  ```kdl
  spawn "niri" "msg" "action" "load-config-file"
  ```

## Noctalia v5 IPC Pattern

- Noctalia v5 is started with:
  ```kdl
  spawn-at-startup "noctalia"
  ```
- Noctalia v5 is a native shell, not a Quickshell configuration. Use
  `noctalia msg <command>` for compositor bindings.
- Example niri bind:
  ```kdl
  Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
  ```
- Useful v5 commands:
  - `panel-toggle launcher` or `panel-toggle launcher "/win "`
  - `panel-toggle control-center <notifications|bluetooth|monitor|network>`
  - `settings-toggle`, `bar-toggle`, `panel-toggle session`, `session lock`
  - `volume-up`, `volume-down`, `volume-mute`, `mic-mute`
  - `brightness-up`, `brightness-down`
  - `media toggle`, `media next`, `media previous`, `media stop`
  - `screenshot-annotate`
- Run `noctalia msg --help` after upgrades; v5 command names are not compatible
  with the v4 Quickshell IPC targets.

## Keybind Workflow

- Keep binds grouped by purpose: launchers, panels, focus/move, workspaces, sizing, session, hardware.
- `Mod` means the Super/Windows key. `Mod+E` opens a new GNOME Files (`nautilus`) window:
  ```kdl
  Mod+E hotkey-overlay-title="Launch Files" repeat=false { spawn "nautilus"; }
  ```
- Use `hotkey-overlay-title` on non-obvious binds so `show-hotkey-overlay` stays useful.
- Prefer preserving muscle memory when changing mappings.
- If stealing a key, make sure the old action still has another sensible bind.
- Example: `Mod+Shift+R` was changed to `maximize-column`, while reload stayed on `Mod+Ctrl+R` and `Mod+Shift+C`.
- Validate after every bind edit. A single invalid action or invalid KDL block breaks the whole config.

## Sizing And Layout

- Niri is column-based, not i3-container-based. Map old “layout” ideas to niri concepts:
  - maximize a column: `maximize-column`
  - maximize a window to screen edges: `maximize-window-to-edges`
  - cycle column widths: `switch-preset-column-width`
  - reverse cycle widths: `switch-preset-column-width-back`
  - expand into unused space: `expand-column-to-available-width`
  - center column: `center-column`
  - tab a column: `toggle-column-tabbed-display`
  - consume/expel windows: `consume-window-into-column`, `expel-window-from-column`
- Useful sizing binds in this config:
  - `Mod+R`: next column width preset.
  - `Mod+Alt+R`: previous column width preset.
  - `Mod+Shift+R`: maximize column.
  - `Mod+M`: maximize window to edges.
  - `Mod+Minus` / `Mod+Equal`: shrink/grow column width.
  - `Mod+Shift+Minus` / `Mod+Shift+Equal`: shrink/grow window height.

## Scaling And Scroll

- Output scaling belongs in `niri/config.kdl`:
  ```kdl
  output "Samsung Electric Company LS27D70xE HK2L105430" {
      scale 1.0
  }
  ```
- Niri matches the monitor name (including its serial) independently of the connector. The startup script `niri/scale-connected-outputs.sh` also sets scale `1.0` for every connected output when the session starts, including screens without a named rule. For a newly attached screen, run the script again or add its name to `config.kdl` for a persistent rule.
- Confirm current output names and scales with:
  ```sh
  niri msg outputs
  ```
- Touchpad natural scroll belongs in `input.touchpad`:
  ```kdl
  input {
      touchpad {
          tap
          natural-scroll
      }
      mouse {}
      trackpoint {}
  }
  ```
- Mouse and touchpad scroll can be handled separately. Do not “fix” one by accidentally changing both.

## Alacritty Size

- If Alacritty opens huge, check Alacritty first, not only niri.
- Current compact config:
  ```toml
  [window]
  startup_mode = "Windowed"

  [window.dimensions]
  columns = 80
  lines = 24
  ```
- If Alacritty should stay tiled but start compact, use niri:
  ```kdl
  window-rule {
      match app-id=r#"^Alacritty$"#
      default-column-width {}
  }
  ```
- Do not add `open-floating true` unless the user explicitly wants Alacritty outside normal tiling.
- Confirm app ID with:
  ```sh
  niri msg windows
  ```
  Alacritty reports `App ID: "Alacritty"` here.

## New Ubuntu Setup

- Run `./bootstrap-new-ubuntu.sh` from this directory on Ubuntu 26.04+ as your normal user. It installs niri from the DankLinux PPA and `noctalia noctalia-greeter` from the Noctalia APT repository.
- The script installs Pixi and uv. Global Python CLI tools use `uv tool install`.
- `llm` defaults to `groq/openai/gpt-oss-120b`. On a fresh setup run `llm keys set groq` followed by `llm groq refresh`; the model cannot be resolved before the refresh.
- Select the niri session at login. Installing `noctalia-greeter` does not change the active display manager; see Noctalia's greeter documentation if you want to switch it.
- Do not add secrets to this directory or `.zshrc`. Review `noctalia/config.toml` before sharing it after future edits.
- Installation references: [niri's Ubuntu setup](https://github.com/niri-wm/niri/wiki/Getting-Started), [Noctalia's Debian/Ubuntu setup](https://docs.noctalia.dev/noctalia/getting-started/installation/), [Pixi installation](https://pixi.sh/latest/installation/), [uv installation](https://docs.astral.sh/uv/getting-started/installation/).

## Practical Debug Loop

1. Identify owner: compositor behavior goes in niri; shell panels go through Noctalia IPC; terminal size goes in Alacritty.
2. Inspect live state with `niri msg outputs` or `niri msg windows`.
3. Use packaged examples from `/usr/share/doc/niri/default-config.kdl.gz` for exact KDL syntax.
4. Patch the smallest relevant file.
5. Run `niri validate --config niri/config.kdl`.
6. Reload with `niri msg action load-config-file`.
7. Open a new window or trigger the bind; existing windows may not reflect startup/window-rule changes.
