source ${0%/*}/base.zsh-theme

setopt transient_rprompt

CURRENT_RIGHT_BG='NONE'
SEGMENT_SEPARATOR_RIGHT=$'\ue0b2'

prompt_segment_right() {
	local bg=$1 fg$2
	
	if [[ $CURRENT_RIGHT_BG == 'NONE' ]]; then
		echo -n "%K{008}%F{$bg}$SEGMENT_SEPARATOR_RIGHT%f%{%K{$bg}%F{$fg}%} "
	elif [[ $CURRENT_RIGHT_BG != $bg ]]; then
		echo -n " %K{$CURRENT_RIGHT_BG}%F{$bg}$SEGMENT_SEPARATOR_RIGHT%f%{%K{$bg}%F{$fg}%} "
	else
		echo -n " %{%K{$bg}%F{$fg}%} "
	fi
	CURRENT_RIGHT_BG=$bg
	[[ -n $3 ]] && echo -n "$3"
}


build_rprompt() {
	prompt_time
	prompt_date
}

prompt_time() { # System time
	prompt_segment_right black white "$(print_icon TIME_ICON) %D{%H:%M:%S}"
}
prompt_date() { # System date
	prompt_segment_right white black "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}


(){
	local LC_ALL="" LC_CTYPE="en_US.UTF-8" # Set the right locale to protect special characters
	RPROMPT_PREFIX=$'%{\e[1A%}' # one line up
	RPROMPT_SUFFIX=$'%{\e[1B%}' # one line down
}
RPROMPT="$RPROMPT_PREFIX"'%{%f%b%k%}$(build_rprompt)%{%E%}'"$RPROMPT_SUFFIX"



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
