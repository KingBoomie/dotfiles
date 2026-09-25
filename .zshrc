# use below only when profiling
# zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  evalcache
  ssh-agent
  asdf
  command-not-found
  copyfile
  python
  npm
  history-search-multi-word
  z.lua
  sudo
  rust
  dotenv
  direnv
  extract
)

# Register asdf completions before Oh My Zsh runs compinit.
[[ -d "${ASDF_DATA_DIR:-$HOME/.asdf}/completions" ]] && fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath)

source $ZSH/oh-my-zsh.sh

export HISTSIZE=100000
export SAVEHIST=100000

alias la="eza -lh"
alias laa="eza -lha"
alias please="sudo"
alias copy="xclip -sel c"
alias ports="sudo netstat -tulpn | grep LISTEN"
alias pullall="ls | parallel git -C {} pull"
alias open="xdg-open"
alias bat="bat --paging=never"
alias cmd="llm -t cmd"

autoload zmv

makegif() {
    ffmpeg -i "$1" -filter_complex "[0:v] fps=12,scale=480:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" "$1.gif"
}

alias help='echo "la, please, copy, micro, rg, makegif, ports, zmv, pullall, fd, open, alt+\\"'
help

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$HOME/.local/bin:$HOME/.pixi/bin:$HOME/.cargo/bin:$HOME/.juliaup/bin:${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$HOME/.duckdb/cli/latest:$HOME/bin:$PATH"

source "$HOME/.config/zsh/zle.zsh"

# Bind Alt-\ to LLM command completion
bindkey '\e\\' __llm_cmdcomp

__llm_cmdcomp() {
  local old_cmd=$BUFFER
  local cursor_pos=$CURSOR
  echo # Start the program on a blank line
  local result=$(llm cmdcomp "$old_cmd")
  if [ $? -eq 0 ] && [ ! -z "$result" ]; then
    BUFFER=$result
  else
    BUFFER=$old_cmd
  fi
  zle reset-prompt
}

zle -N __llm_cmdcomp
# --------

export CCACHE_DIR="$HOME/.cache/ccache"
export CCACHE_MAXSIZE=50G
export CMAKE_C_COMPILER_LAUNCHER=ccache
export CMAKE_CXX_COMPILER_LAUNCHER=ccache

zstyle ':completion:*' menu select

# Local credentials are stored outside DOTFILES.
[[ -r "$HOME/.config/shell-secrets.env" ]] && source "$HOME/.config/shell-secrets.env"
