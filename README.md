# DOTFILES

Run `./bootstrap-new-ubuntu.sh` as your normal user on Ubuntu 26.04 or newer.

## Features

- Niri desktop with Noctalia, Alacritty, and SF Mono.
- Zsh with Oh My Zsh and Powerlevel10k.
- Development tools including Pixi, uv, asdf and Node.js, Rust, Julia, DuckDB, and Codex.
- `llm` with Groq as its default provider, plus optional Anthropic support.
- Tailscale and common command-line utilities.

## Manual setup

- Add a Groq API key with `llm keys set groq`, then run `llm groq refresh` to use the default model and `cmd` alias.
- Add optional provider keys with `llm keys set openai` or `llm keys set anthropic` if you use those models.
- Sign in to Codex when you first run `codex`.
- Run `sudo tailscale up` if you want to connect this machine to your tailnet.
- Keep any other service credentials in `~/.config/shell-secrets.env`, outside this repository.

See [HOW-TO-CHANGE.md](HOW-TO-CHANGE.md) for configuration changes.
