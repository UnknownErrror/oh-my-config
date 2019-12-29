autoload -Uz is-at-least

# *-magic is known buggy in some versions; disable if so
if [[ $DISABLE_MAGIC_FUNCTIONS != true ]]; then
	for d in $fpath; do
		if [[ -e "$d/url-quote-magic" ]]; then
			if is-at-least 5.1; then
				autoload -Uz bracketed-paste-magic
				zle -N bracketed-paste bracketed-paste-magic
			fi
			autoload -Uz url-quote-magic
			zle -N self-insert url-quote-magic
			break
		fi
	done
fi

env_default 'PAGER' 'less'
env_default 'LESS' '-R'

which ack-grep &> /dev/null && alias afind='ack-grep -il' || alias afind='ack -il' # more intelligent acking for ubuntu users

setopt LONG_LIST_JOBS
setopt INTERACTIVE_COMMENTS
