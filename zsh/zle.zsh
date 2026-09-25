# ============================================================
# Desktop-editor-ish ZLE
# ============================================================

bindkey -e


# ------------------------------------------------------------
# Word semantics
#
# Default zsh considers a frankly deranged amount of punctuation
# part of a "word". Make Ctrl+Left/Right behave more like an editor.
#
# '_' remains part of identifiers.
# '/', '.', '-', ':', etc. become useful jump boundaries.
# ------------------------------------------------------------

autoload -Uz select-word-style
select-word-style normal

zstyle ':zle:*' word-style normal
zstyle ':zle:*' word-chars '_'
zstyle ':zle:forward-word*' skip-whitespace-first true


# ------------------------------------------------------------
# Selection primitives
# ------------------------------------------------------------

_zle_selection_begin() {
    if (( ! REGION_ACTIVE )); then
        MARK=$CURSOR
        REGION_ACTIVE=1
    fi
}

# Delete selection WITHOUT contaminating the kill ring.
#
# ZLE's "_" vi buffer is the black-hole register.
_zle_selection_delete() {
    (( REGION_ACTIVE )) || return 1

    zle vi-set-buffer _
    zle kill-region

    REGION_ACTIVE=0
    return 0
}


# ------------------------------------------------------------
# Whole-buffer motions
# ------------------------------------------------------------

_zle_buffer_home() {
    CURSOR=0
}

_zle_buffer_end() {
    CURSOR=$#BUFFER
}

zle -N buffer-home _zle_buffer_home
zle -N buffer-end  _zle_buffer_end


# ------------------------------------------------------------
# Shift + movement = extend selection
# ------------------------------------------------------------

typeset -gA _ZLE_SELECT_MOTION=(
    select-left         backward-char
    select-right        forward-char

    # Deliberately NOT *-or-history.
    select-up           up-line
    select-down         down-line

    # vi-* versions stay on this logical line.
    select-home         vi-beginning-of-line
    select-end          vi-end-of-line

    select-word-left    backward-word
    select-word-right   forward-word

    select-buffer-home  buffer-home
    select-buffer-end   buffer-end
)

_zle_select_motion() {
    _zle_selection_begin
    zle "${_ZLE_SELECT_MOTION[$WIDGET]}"
}

for _widget in ${(k)_ZLE_SELECT_MOTION}; do
    zle -N "$_widget" _zle_select_motion
done
unset _widget


# ------------------------------------------------------------
# Ordinary Left/Right:
#
# If selected:
#
#    abc[DEF]ghi
#
# Left  -> abc|DEFghi
# Right -> abcDEF|ghi
#
# This is what basically every graphical editor does.
# ------------------------------------------------------------

_zle_left() {
    if (( REGION_ACTIVE )); then
        CURSOR=$(( CURSOR < MARK ? CURSOR : MARK ))
        REGION_ACTIVE=0
    else
        zle backward-char
    fi
}

_zle_right() {
    if (( REGION_ACTIVE )); then
        CURSOR=$(( CURSOR > MARK ? CURSOR : MARK ))
        REGION_ACTIVE=0
    else
        zle forward-char
    fi
}

zle -N move-left  _zle_left
zle -N move-right _zle_right


# ------------------------------------------------------------
# Other unshifted movement:
# clear selection, then actually perform the movement.
# ------------------------------------------------------------

typeset -gA _ZLE_MOVE=(
    move-up           up-line-or-history
    move-down         down-line-or-history

    move-home         vi-beginning-of-line
    move-end          vi-end-of-line

    move-word-left    backward-word
    move-word-right   forward-word

    move-buffer-home  buffer-home
    move-buffer-end   buffer-end
)

_zle_move() {
    REGION_ACTIVE=0
    zle "${_ZLE_MOVE[$WIDGET]}"
}

for _widget in ${(k)_ZLE_MOVE}; do
    zle -N "$_widget" _zle_move
done
unset _widget


# ------------------------------------------------------------
# Editing replaces selection
# ------------------------------------------------------------

_zle_self_insert() {
    _zle_selection_delete
    zle .self-insert
}

_zle_backspace() {
    _zle_selection_delete || zle .backward-delete-char
}

_zle_delete() {
    _zle_selection_delete || zle .delete-char
}

_zle_yank() {
    if (( REGION_ACTIVE )); then
        zle put-replace-selection
    else
        zle .yank
    fi
}

_zle_bracketed_paste() {
    _zle_selection_delete
    zle .bracketed-paste
}

zle -N self-insert          _zle_self_insert
zle -N backward-delete-char _zle_backspace
zle -N delete-char          _zle_delete
zle -N yank                 _zle_yank
zle -N bracketed-paste      _zle_bracketed_paste


# ------------------------------------------------------------
# Optional: M-w copies the ZLE selection to both the ZLE
# kill ring and the Wayland clipboard.
#
# M-w is already "copy-region-as-kill" in emacs ZLE, so this
# merely makes it useful outside this one tiny kingdom.
# ------------------------------------------------------------

_zle_copy_selection() {
    (( REGION_ACTIVE )) || return 0

    zle copy-region-as-kill

    if (( $+commands[wl-copy] )); then
        print -rn -- "$CUTBUFFER" | command wl-copy
    fi

    REGION_ACTIVE=0
}

zle -N copy-selection _zle_copy_selection
bindkey $'\ew' copy-selection


# ------------------------------------------------------------
# Key sequences
# ------------------------------------------------------------

_zle_bind_many() {
    local widget=$1
    shift

    local seq
    for seq in "$@"; do
        bindkey "$seq" "$widget"
    done
}


# Plain arrows

_zle_bind_many move-left  \
    $'\e[D' $'\eOD'

_zle_bind_many move-right \
    $'\e[C' $'\eOC'

_zle_bind_many move-up    \
    $'\e[A' $'\eOA'

_zle_bind_many move-down  \
    $'\e[B' $'\eOB'


# Home / End
#
# Note the '[' in ESC [ 1 ~ / ESC [ 4 ~.

_zle_bind_many move-home \
    $'\e[H' $'\eOH' $'\e[1~'

_zle_bind_many move-end \
    $'\e[F' $'\eOF' $'\e[4~'


# Shift + arrows

_zle_bind_many select-left  $'\e[1;2D'
_zle_bind_many select-right $'\e[1;2C'
_zle_bind_many select-up    $'\e[1;2A'
_zle_bind_many select-down  $'\e[1;2B'


# Shift + Home / End = select to logical line boundary

_zle_bind_many select-home \
    $'\e[1;2H' $'\e[1;2~'

_zle_bind_many select-end \
    $'\e[1;2F' $'\e[4;2~'


# Ctrl + Left / Right = word movement

_zle_bind_many move-word-left  $'\e[1;5D'
_zle_bind_many move-word-right $'\e[1;5C'


# Ctrl + Home / End = whole editable buffer

_zle_bind_many move-buffer-home \
    $'\e[1;5H' $'\e[1;5~'

_zle_bind_many move-buffer-end \
    $'\e[1;5F' $'\e[4;5~'


# Ctrl + Shift + Left / Right = select by word

_zle_bind_many select-word-left  $'\e[1;6D'
_zle_bind_many select-word-right $'\e[1;6C'


# Ctrl + Shift + Home / End = select to whole-buffer boundary

_zle_bind_many select-buffer-home \
    $'\e[1;6H' $'\e[1;6~'

_zle_bind_many select-buffer-end \
    $'\e[1;6F' $'\e[4;6~'


# Delete. Backspace already resolves to backward-delete-char
# in the emacs keymap.

bindkey $'\e[3~' delete-char
