source $ZSH/themes/base.zsh-theme

prompt_virtualenv() { # [-] Virtualenv: (<VIRTUAL_ENV>)
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		prompt_segment blue black "(`basename $virtualenv_path`)"
	fi
}
prompt_aws() { # [-] AWS Profile: (Current AWS_PROFILE, yellow on red if production, black on green otherwise) (☁️ <profile>)
	local AWS="${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}"
	if [[ -n "$AWS" ]]; then
		local content="$(print_icon AWS_ICON) $AWS"
		case "$AWS" in # red white
			*-prod|*production*) prompt_segment red   yellow $constent ;; # - profile contains 'production' or ends in '-prod' # [MOD]
			*)                   prompt_segment green black  $constent ;; # [MOD]
		esac
	fi
}
prompt_aws() {
	profile="default"
	region=""
	[[ -n $AWS_PROFILE ]] && profile=$AWS_PROFILE
	[[ -n $AWS_REGION ]] && region=$AWS_REGION
	text="$profile"
	[[ -n $region ]] && text="$text [$region]"
	prompt_segment magenta $PRIMARY_FG " $CLOUD $text "
}

prompt_tmux_context() { # [-] TMUX Context (tmux / tmux@<session_nsame>)
	if [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			prompt_segment black magenta "tmux@$session_name"
		else
			prompt_segment black magenta "tmux"
		fi
	fi
}