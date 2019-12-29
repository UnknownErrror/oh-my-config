# Make sure that the terminal is in application mode when zle is active, since only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
	function zle-line-init() {
		echoti smkx
	}
	function zle-line-finish() {
		echoti rmkx
	}
	zle -N zle-line-init
	zle -N zle-line-finish
fi

bindkey -e # Use emacs key bindings

bindkey '\ew' kill-region # [Esc-w] - Kill from the cursor to the mark
bindkey -s '\el' 'ls\n'   # [Esc-l] - Run command: ls
bindkey '^r' history-incremental-search-backward # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.
[[ "${terminfo[kpp]}" != "" ]] && bindkey "${terminfo[kpp]}" up-line-or-history   # [PageUp]   - Up a line of history
[[ "${terminfo[knp]}" != "" ]] && bindkey "${terminfo[knp]}" down-line-or-history # [PageDown] - Down a line of history

if [[ "${terminfo[kcuu1]}" != "" ]]; then # start typing + [Up-Arrow] - fuzzy find history forward
	autoload -U up-line-or-beginning-search
	zle -N up-line-or-beginning-search
	bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
if [[ "${terminfo[kcud1]}" != "" ]]; then # start typing + [Down-Arrow] - fuzzy find history backward
	autoload -U down-line-or-beginning-search
	zle -N down-line-or-beginning-search
	bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

[[ "${terminfo[khome]}" != "" ]] && bindkey "${terminfo[khome]}" beginning-of-line # [Home] - Go to beginning of line
[[ "${terminfo[kend]}" != "" ]] && bindkey "${terminfo[kend]}"	end-of-line        # [End]  - Go to end of line

bindkey ' ' magic-space # [Space] - do history expansion
bindkey '^[[1;5C' forward-word  # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word

[[ "${terminfo[kcbt]}" != "" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete # [Shift-Tab] - move through the completion menu backwards

bindkey '^?' backward-delete-char # [Backspace] - delete backward
if [[ "${terminfo[kdch1]}" != "" ]]; then
	bindkey "${terminfo[kdch1]}" delete-char # [Delete] - delete forward
else
	bindkey "^[[3~" delete-char
	bindkey "^[3;5~" delete-char
	bindkey "\e[3~" delete-char
fi

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-e' edit-command-line

bindkey "^[m" copy-prev-shell-word # file rename magick

# consider emacs keybindings:
#bindkey -e	## emacs key bindings
#
#bindkey '^[[A' up-line-or-search
#bindkey '^[[B' down-line-or-search
#bindkey '^[^[[C' emacs-forward-word
#bindkey '^[^[[D' emacs-backward-word
#
#bindkey -s '^X^Z' '%-^M'
#bindkey '^[e' expand-cmd-path
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
#bindkey '^W' kill-region
#bindkey '^I' complete-word
## Fix weird sequence that rxvt produces
#bindkey -s '^[[Z' '\t'
#
