#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# opencode
export PATH=/home/ragul/.opencode/bin:$PATH

# Local binaries (fetch is installed here)
export PATH="$HOME/.local/bin:$PATH"

# Animated Arch Linux system dashboard (interactive terminals only)
if [[ $- == *i* ]] && [[ -t 0 && -t 1 ]] && [[ -z ${FETCH_NO_AUTOSTART:-} ]] && command -v fetch >/dev/null 2>&1; then
    fetch -l arch
fi
