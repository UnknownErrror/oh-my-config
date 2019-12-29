function omz_history {
	local clear list
	zparseopts -E c=clear l=list
	
	if [[ -n "$clear" ]]; then # if -c provided, clobber the history file
		echo -n >| "$HISTFILE"
		echo >&2 History file deleted. Reload the session to see its effects.
	elif [[ -n "$list" ]]; then # if -l provided, run as if calling `fc' directly
		builtin fc "$@"
	else # unless a number is provided, show all history events (starting from 1)
		[[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
	fi
}
case ${HIST_STAMPS-} in # Timestamp format
	"mm/dd/yyyy") alias history='omz_history -f' ;;
	"dd.mm.yyyy") alias history='omz_history -E' ;;
	"yyyy-mm-dd") alias history='omz_history -i' ;;
	'')           alias history='omz_history'    ;;
	*)            alias history="omz_history -t '$HIST_STAMPS'" ;;
esac

[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY