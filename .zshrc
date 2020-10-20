# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/alex/.zshrc'

autoload -Uz compinit
compinit

# End of lines added by compinstall

# prompt themes
autoload -Uz promptinit
promptinit

# syntax highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# auto suggentions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# persistent reharsh
zstyle ':completion:*' rehash true

# prompt string one
PROMPT='%F{blue}%n%f@%M %B%1~%b %(!.#.$) '

# colored manual
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;34m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

case $TERM in
    xterm*)
	bindkey "^[[1;5C" forward-word # Ctrl + Left
	bindkey "^[[1;5D" backward-word # Ctrl + Right
	bindkey "^[[1;5A" history-beginning-search-backward # Ctrl + UP
	bindkey "^[[1;5B" history-beginning-search-forward # Ctrl +Down
	bindkey "^H" backward-kill-word # Ctrl + Backspace
    ;;
    linux)
# so sad but true, in default terminal, it doesn't seperate Ctrl + Key from Key.
#	bindkey "^[[C" forward-word # Ctrl + Left
#	bindkey "^[[D" backward-word # Ctrl + Right
#	bindkey "^[[A" history-beginning-search-backward # Ctrl + UP
#	bindkey "^[[B" history-beginning-search-forward # Ctrl +Down
#	bindkey "^?" backward-kill-word # Ctrl + Backspace
    ;;
esac
    
# menu select
zstyle ':completion:*' menu select

# regard lower as upper in completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# alias
alias ls='ls --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
alias nt='cat >> ~/Documents/note'	 #append msg to the note
alias glance='glances --disable-plugin fs --disable-quicklook --process-short-name --byte'
