# DOTFILES

Portable setup for this Ubuntu niri + Noctalia v5 desktop. Run `./bootstrap-new-ubuntu.sh` as your normal user on Ubuntu 26.04+ to install the desktop, Pixi, uv, asdf with the pinned Node version, Rust, Julia, Tailscale, DuckDB, Codex, `llm`, Lua 5.3, direnv, and the common shell and build tools. The script restores the files in this folder, makes dated copies of existing target files, and validates niri and Noctalia at the end.

The shell and desktop files are snapshots of the current setup. The Noctalia configuration is a v5 `noctalia config export`; old Quickshell JSON files are excluded. `io.datasette.llm/default_model.txt` selects `groq/openai/gpt-oss-120b`, and `io.datasette.llm/templates/cmd.yaml` is the `llm -t cmd` prompt used by the `cmd` shell alias.

Niri identifies the two current Samsung monitors by model and serial, so their 1.0 scale and positions survive connector changes. At session startup, `niri/scale-connected-outputs.sh` discovers all connected outputs and sets each to scale 1.0; rerun it after hotplugging an unlisted screen.

The shell also restores the custom completion files in `.zfunc/` and `.zsh/completions/`. Its asdf completion path and Bun completion script load when those tools are installed. Oh My Zsh runs `compinit` once after the custom paths are registered.

Alacritty uses **SF Mono**. The bootstrap installs the OTF files copied from this machine's `~/.fonts/` into `~/.local/share/fonts/SFMono/` and refreshes fontconfig. The font source's licensing note restricts use; keep the font files in a private copy of this bundle.

`.tool-versions` pins the asdf Node version. Tailscale authentication remains a manual `sudo tailscale up` after installation. The script links CloudCompare and ccViewer when their existing source builds are available; rebuilding those and RTKLIB still requires the separate source trees.

## Credentials to add on a new machine

- **Required for the default `llm` model and `cmd` alias:** a Groq API key. On a fresh machine, run `llm keys set groq`, then `llm groq refresh`. The bootstrap installs `llm-groq`, restores `groq/openai/gpt-oss-120b` as the default model file, and restores the `cmd` template. It refreshes Groq models during setup only if a key is already present.
- **Optional for other `llm` models:** use `llm keys set openai` for OpenAI models and `llm keys set anthropic` for Anthropic models. The bootstrap installs `llm-anthropic`. Add DeepSeek or other provider keys only if you configure a matching model or plugin.
- **Separate shell credentials:** `DOTOKEN`, `GHTOKEN`, `FITOKEN`, `BORG_PASSPHRASE`, `ANTHROPIC_TOKEN`, and `BRAVE_API_KEY` are currently kept in `~/.config/shell-secrets.env` with mode `0600`. Restore that file through a secure channel only if you use the corresponding services. It is not part of this bundle.

`llm` stores keys in its own private `keys.json`; keep that file out of DOTFILES. The script installs `noctalia-greeter` but leaves display-manager selection to the machine owner.

See [HOW-TO-CHANGE.md](HOW-TO-CHANGE.md) for editing and validation commands. The prior CloudCompare and RTKLIB source-build restore flow depends on large external source trees and manifests, so it is outside this portable dotfiles bundle.

[ZSHRC-CHANGE-REVIEW.md](ZSHRC-CHANGE-REVIEW.md) records the full redacted diff from the reconstructed pre-edit `.zshrc` and explains the shell changes.
