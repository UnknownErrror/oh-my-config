autoload -U colors && colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# TODO organise this chaotic logic
if [[ "$DISABLE_LS_COLORS" != "true" ]]; then # Find the option for using colors in ls, depending on the version
	if [[ "$OSTYPE" == netbsd* ]]; then # On NetBSD, test if "gls" (GNU ls) is installed (this one supports colors); otherwise, leave ls as is, because NetBSD's ls doesn't support -G
		gls --color -d . &>/dev/null && alias ls='gls --color=tty'
	elif [[ "$OSTYPE" == openbsd* ]]; then # On OpenBSD, "gls" (ls from GNU coreutils) and "colorls" (ls from base, with color and multibyte support) are available from ports. "colorls" will be installed on purpose and can't be pulled in by installing coreutils, so prefer it to "gls".
		gls --color -d . &>/dev/null && alias ls='gls --color=tty'
		colorls -G -d . &>/dev/null && alias ls='colorls -G'
	elif [[ "$OSTYPE" == (darwin|freebsd)* ]]; then # this is a good alias, it works by default just using $LSCOLORS
		ls -G . &>/dev/null && alias ls='ls -G'

		# only use coreutils ls if there is a dircolors customization present ($LS_COLORS or .dircolors file) otherwise, gls will use the default color scheme which is ugly af
		[[ -n "$LS_COLORS" || -f "$HOME/.dircolors" ]] && gls --color -d . &>/dev/null && alias ls='gls --color=tty'
	else # For GNU ls, we use the default ls color theme. They can later be overwritten by themes.
		if [[ -z "$LS_COLORS" ]]; then
			(( $+commands[dircolors] )) && eval "$(dircolors -b)"
		fi
		ls --color -d . &>/dev/null && alias ls='ls --color=tty' || { ls -G . &>/dev/null && alias ls='ls -G' }
		
		zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Take advantage of $LS_COLORS for completion as well.
	fi
fi

setopt AUTO_CD
setopt MULTIOS
setopt PROMPT_SUBST

[[ -n "$WINDOW" ]] && SCREEN_NO="%B$WINDOW%b " || SCREEN_NO=""
