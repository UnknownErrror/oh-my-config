source ${0%/*}/base.zsh-theme

setopt transient_rprompt

CURRENT_RIGHT_BG='NONE'
SEGMENT_SEPARATOR_RIGHT=$'\ue0b2'

prompt_segment_right() {
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}" || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	
	echo -n "%K{$CURRENT_RIGHT_BG}%F{$1}$SEGMENT_SEPARATOR_RIGHT%{$bg%}%{$fg%} "
	CURRENT_RIGHT_BG=$1
	[[ -n $3 ]] && echo -n $3
}

prompt_vi() {
	if [[ -n $N_MODE || -n $MODE_INDICATOR ]]; then
		N_MODE="[N] "
		I_MODE="[I] "
		prompt_segment_right 246 black "`vi_mode_prompt_info`"
	fi
}


build_rprompt() {
	prompt_vi
	prompt_time
}

# RPROMPT='%{%f%b%k%}$(build_rprompt)'



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
