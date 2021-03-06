source ${0%/*}/base.zsh-theme

prompt_vi() {
	if [[ -n $N_MODE || -n $MODE_INDICATOR ]]; then
		N_MODE="[N] "
		I_MODE="[I] "
		prompt_segment_right 246 black "`vi_mode_prompt_info`"
	fi
}

prompt_virtualenv() { # [-] Virtualenv: (<VIRTUAL_ENV>)
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		prompt_segment blue black "(`basename $virtualenv_path`)"
	fi
}
prompt_aws() { # [-] AWS Profile: (☁️ <aws-profile>)
	local AWS="${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}"
	if [[ -n "$AWS" ]]; then
		local content="$(print_icon AWS_ICON) $AWS"
		case "$AWS" in # red white
			*-prod|*production*) prompt_segment red   yellow $constent ;; # - profile contains 'production' or ends in '-prod'
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
