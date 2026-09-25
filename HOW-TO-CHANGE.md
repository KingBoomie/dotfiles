# How to change this setup

## Desktop

- Edit `niri/config.kdl` for keybindings, output scaling, input, and window rules. The active Noctalia include is `niri/noctalia.kdl`.
- Edit `noctalia/config.toml` for the shell, panels, and appearance. Check available commands with `noctalia msg --help`.
- Edit `alacritty/alacritty.toml` for terminal appearance and window size. Its SF Mono fonts are in `fonts/SFMono/`.

Validate before reloading:

```sh
niri validate --config niri/config.kdl
noctalia config validate noctalia/config.toml
niri msg action load-config-file
```

Use `niri msg outputs` to inspect connected displays and `niri msg windows` to inspect window IDs and sizes. Run `niri/scale-connected-outputs.sh` after connecting a new display if it needs the configured 1.0 scale before the next login.

## Shell and tools

- Edit `.zshrc` for shell behavior, `zsh/zle.zsh` for movement and selection keys, and `.p10k.zsh` for the prompt.
- Edit `.tool-versions` to change the Node.js version installed by asdf.
- Edit `io.datasette.llm/default_model.txt` to change the default `llm` model, or `io.datasette.llm/templates/cmd.yaml` to change the `cmd` alias prompt.
- Edit `bootstrap-new-ubuntu.sh` to change what a fresh Ubuntu setup installs or restores.

Keep API keys and other credentials outside this repository. See [README.md](README.md) for manual setup.
