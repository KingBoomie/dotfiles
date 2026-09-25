#!/usr/bin/env bash
set -Eeuo pipefail

# Fresh Ubuntu 26.04+ workstation. Run as the normal user from this directory.
# Keep credentials outside this folder; install does not restore API keys.
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.pixi/bin:$HOME/.cargo/bin:$PATH"

if (( EUID == 0 )); then
  echo 'Run as the normal user, without sudo.' >&2
  exit 1
fi

if ! command -v apt-get >/dev/null; then
  echo 'This bootstrap supports Ubuntu with APT.' >&2
  exit 1
fi

sudo -v
sudo apt-get update
sudo apt-get install -y \
  software-properties-common ca-certificates curl wget git gpg gawk jq \
  zsh alacritty eza nautilus xdg-desktop-portal-gnome \
  lxqt-policykit openssh-client rsync unzip tar xz-utils \
  build-essential cmake ninja-build pkg-config ccache \
  python3-dev python3-venv python3-full libssl-dev libffi-dev \
  libcurl4-openssl-dev zlib1g-dev libsqlite3-dev gfortran \
  micro glances ripgrep bat fd-find just parallel net-tools \
  lua5.3 liblua5.3-dev direnv \
  ffmpeg fonts-firacode xclip wl-clipboard

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
for plugin in evalcache history-search-multi-word z.lua; do
  case "$plugin" in
    evalcache) url=https://github.com/mroth/evalcache ;;
    history-search-multi-word) url=https://github.com/zdharma-continuum/history-search-multi-word ;;
    z.lua) url=https://github.com/skywind3000/z.lua ;;
  esac
  if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin" ]]; then
    git clone --depth=1 "$url" "$HOME/.oh-my-zsh/custom/plugins/$plugin"
  fi
done
if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

# niri's Ubuntu package is supplied by the DankLinux PPA on Ubuntu 26.04+.
if ! command -v niri >/dev/null; then
  sudo add-apt-repository -y ppa:avengemedia/danklinux
  sudo apt-get update
  sudo apt-get install -y niri
fi

# Noctalia v5 uses its native executable and APT repository on Ubuntu 26.04.
if ! command -v noctalia >/dev/null; then
  . /etc/os-release
  if [[ "${VERSION_CODENAME:-}" != resolute ]]; then
    echo "Check https://docs.noctalia.dev/noctalia/getting-started/installation/ for $VERSION_CODENAME." >&2
    exit 1
  fi
  keyring="$(mktemp --suffix=.deb)"
  curl -fsSL https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb -o "$keyring"
  sudo dpkg -i "$keyring"
  rm -f -- "$keyring"
  sudo wget -q -O /etc/apt/sources.list.d/noctalia-resolute.sources \
    https://pkg.noctalia.dev/deb/noctalia-resolute.sources
  sudo apt-get update
  sudo apt-get install -y noctalia noctalia-greeter
else
  sudo apt-get install -y noctalia-greeter
fi

if ! command -v pixi >/dev/null; then
  curl -fsSL https://pixi.sh/install.sh | bash
fi
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$HOME/.pixi/bin:$PATH"

# asdf is separate from Pixi: it provides the pinned Node version in .tool-versions.
if ! command -v asdf >/dev/null; then
  case "$(uname -m)" in
    x86_64) asdf_arch=amd64 ;;
    aarch64|arm64) asdf_arch=arm64 ;;
    *) echo "Unsupported asdf architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  asdf_url="$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest \
    | jq -r --arg arch "$asdf_arch" '.assets[] | select(.name | endswith("linux-" + $arch + ".tar.gz")) | .browser_download_url' \
    | head -n1)"
  [[ -n "$asdf_url" ]] || { echo 'Could not find an asdf release archive.' >&2; exit 1; }
  asdf_tmp="$(mktemp -d)"
  curl -fsSL "$asdf_url" -o "$asdf_tmp/asdf.tar.gz"
  tar -xzf "$asdf_tmp/asdf.tar.gz" -C "$asdf_tmp"
  install -Dm755 "$asdf_tmp/asdf" "$HOME/.local/bin/asdf"
  rm -rf -- "$asdf_tmp"
fi
if ! asdf plugin list | grep -qx nodejs; then
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
fi
node_version="$(awk '$1 == "nodejs" {print $2; exit}' "$DOTFILES_DIR/.tool-versions")"
if [[ -n "$node_version" ]]; then
  asdf install nodejs "$node_version"
fi

if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

if ! command -v julia >/dev/null; then
  curl -fsSL https://install.julialang.org | sh -s -- --yes
fi
export PATH="$HOME/.juliaup/bin:$PATH"

if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
if ! command -v duckdb >/dev/null; then
  curl -fsSL https://install.duckdb.org | bash
fi
if ! command -v codex >/dev/null; then
  curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
fi

# uv provides isolated global CLI tools; no pipx setup is needed.
if ! command -v llm >/dev/null; then
  uv tool install llm
fi
llm install llm-groq llm-anthropic llm-cmd-comp

# Copy the curated, non-secret configuration. Existing files get dated copies.
restore_file() {
  local source="$DOTFILES_DIR/$1"
  local target="$HOME/$2"
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" && ! -L "$target" ]]; then
    cp -a -- "$target" "$target.before-dotfiles-$(date +%Y%m%d%H%M%S)"
  fi
  install -m "$3" -- "$source" "$target"
}

restore_file .zshrc .zshrc 644
restore_file zsh/zle.zsh .config/zsh/zle.zsh 644
restore_file .p10k.zsh .p10k.zsh 644
restore_file .tool-versions .tool-versions 644
restore_file niri/config.kdl .config/niri/config.kdl 644
restore_file niri/scale-connected-outputs.sh .config/niri/scale-connected-outputs.sh 755
restore_file niri/noctalia.kdl .config/niri/noctalia.kdl 644
restore_file noctalia/config.toml .config/noctalia/config.toml 644
restore_file alacritty/alacritty.toml .config/alacritty/alacritty.toml 644
restore_file io.datasette.llm/default_model.txt .config/io.datasette.llm/default_model.txt 600
restore_file io.datasette.llm/templates/cmd.yaml .config/io.datasette.llm/templates/cmd.yaml 600

# Register Groq models only when a key is already present. The default model
# file above can be restored without a key, but commands need a model refresh.
if [[ -n "${LLM_GROQ_KEY:-}" ]] || llm keys list | grep -qx groq; then
  if ! llm groq refresh; then
    echo 'Groq model refresh failed; retry with: llm groq refresh' >&2
  fi
else
  echo 'To activate the default LLM model: llm keys set groq; llm groq refresh'
fi

# Alacritty is configured for SF Mono, supplied from this local font bundle.
for font in "$DOTFILES_DIR"/fonts/SFMono/*.otf; do
  [[ -f "$font" ]] || continue
  relative="${font#"$DOTFILES_DIR"/fonts/}"
  restore_file "fonts/$relative" ".local/share/fonts/$relative" 644
done
fc-cache -f "$HOME/.local/share/fonts/SFMono"

# Ubuntu names these binaries fdfind and batcat; keep the existing shell commands.
mkdir -p "$HOME/.local/bin"
[[ -e "$HOME/.local/bin/fd" ]] || ln -s /usr/bin/fdfind "$HOME/.local/bin/fd"
[[ -e "$HOME/.local/bin/bat" ]] || ln -s /usr/bin/batcat "$HOME/.local/bin/bat"
sudo chsh -s "$(command -v zsh)" "$USER"
niri validate --config "$HOME/.config/niri/config.kdl"
noctalia config validate "$HOME/.config/noctalia/config.toml"
echo 'Done. Log out, select the niri session, then log in. Add API keys through each tool separately.'
echo 'Tailscale sign-in, if wanted: sudo tailscale up'
