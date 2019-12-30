### Segment drawing # A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
CURRENT_RIGHT_BG='NONE'
case ${SOLARIZED_THEME:-dark} in
	light) CURRENT_FG='white' ;;
	*)     CURRENT_FG='black' ;;
esac

# Special Powerline characters # Do not change this!
SEGMENT_SEPARATOR=$'\ue0b0'
RIGHT_SEGMENT_SEPARATOR=$'\ue0b2'

prompt_segment() { # prompt_segment bg fg segment
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}" || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
		echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
	else
		echo -n "%{$bg%}%{$fg%} "
	fi
	CURRENT_BG=$1
	[[ -n $3 ]] && echo -n $3
}
prompt_end() {
	if [[ -n $CURRENT_BG ]]; then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''
}

prompt_right_segment() { # prompt_right_segment bg fg segment
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}" || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	
	# [[ $CURRENT_RIGHT_BG == "NONE" ]] && echo -n "%F{$1}$RIGHT_SEGMENT_SEPARATOR" || echo -n "%F{$1}$RIGHT_SEGMENT_SEPARATOR"
	echo -n "%F{$1}$RIGHT_SEGMENT_SEPARATOR"
	echo -n "%{$bg%}%{$fg%}"
	[[ $CURRENT_RIGHT_BG != "NONE" ]] && echo -n " "
	
	CURRENT_RIGHT_BG=$1
	[[ -n $3 ]] && echo -n "$3 "
}
prompt_right_end() {
	#echo -n "%{%f%}"
	echo -n "%{%k%}"
	CURRENT_RIGHT_BG=''
}


### Prompt components # Each component will draw itself, and hide itself if no information needs to be shown

prompt_virtualenv() { # [-] Virtualenv: (<VIRTUAL_ENV>)
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		prompt_segment blue black "(`basename $virtualenv_path`)"
	fi
}
prompt_aws() { # [-] AWS Profile: (Current AWS_PROFILE, yellow on red if production, black on green otherwise) (☁️ <profile>)
	[[ -z "$AWS_PROFILE" ]] && return
	case "$AWS_PROFILE" in
		*-prod|*production*) prompt_segment red   yellow "☁️ $AWS_PROFILE" ;; # - profile contains 'production' or ends in '-prod' # [MOD]
		*)                   prompt_segment green black  "☁️ $AWS_PROFILE" ;; # [MOD]
	esac
}


function exit_code_or_status() {
	local RETVAL=$1
	if (( $RETVAL <= 128 )); then
		echo "$RETVAL"
	else
		local sig=$(( $RETVAL - 128 ))
		local idx=$(( sig + 1 ))
		echo "SIG${signals[$idx]}(${sig})"
	fi
}
prompt_retval_status() { # Return Value: (✘ <codes> / ✘ <code> / ✘ SIG<sig>(<code>) / ✔)
	local result code_sum code
	if (( $#RETVALS > 1 )); then
		code_sum=${RETVALS[1]}
	else
		code_sum=${RETVAL}
	fi
	result=$(exit_code_or_status "${code_sum}")
	for code in "${(@)RETVALS[2,-1]}"; do
		result="${result}|$(exit_code_or_status "$code")"
		code_sum=$(( $code_sum + $code ))
	done
	
	result=$(echo $result | sed -r 's/^(0\|)+/..0|/' | sed -r 's/(\|0)+/|0../')

	if (( code_sum > 0 )); then
		prompt_segment red white "✘ $result"
	else
		prompt_segment green white "✔"
	fi
}
prompt_retval_status_lite() { # Return Value (Lite): (✘ <code> / ✘ SIG<sig>(<code>) / ✔)
	if (( RETVAL > 0 )); then
		prompt_segment red white "✘ $(exit_code_or_status "${RETVAL}")"
	else
		prompt_segment green white "✔"
	fi
}

prompt_root_status() { # Status of root: (⚡)
	if [[ $UID -eq 0 ]]; then #
		prompt_segment black default "%{%F{yellow}%}⚡"
	fi
}
prompt_jobs_status() { # Status of jobs: (<count> ⚙ / ⚙)
	local jobs_count="${$(jobs -l | wc -l)// /}"
	local wrong_lines="$(jobs -l | awk '/pwd now/{ count++ } END {print count}')"
	if [[ wrong_lines -gt 0 ]]; then
		jobs_count=$(( $jobs_count - $wrong_lines ))
	fi
	if [[ jobs_count -gt 0 ]]; then
		if [[ "$jobs_count" -gt 1 ]]; then
			prompt_segment cyan white "$jobs_count ⚙"
		else
			prompt_segment cyan white "⚙"
		fi
	fi
}

prompt_tmux_context() { # [-] TMUX Context (tmux / tmux@<session_nsame>)
	if [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			prompt_segment black default "%{%F{magenta}%}tmux@$session_name"
		else
			prompt_segment black default "%{%F{magenta}%}tmux"
		fi
	fi
}
prompt_context() { # Context: (<user>@<hostname> (ssh) / <user>@<hostname>)
	if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m (ssh)"
	elif [[ "$USER" != "$DEFAULT_USER" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
	fi
}

function pwd_abbr() {
	tilda_notation=${PWD//$HOME/\~}
	pwd_list=(${(s:/:)tilda_notation})
	list_len=${#pwd_list}
	
	if [[ $list_len -le 1 ]]; then
		echo $tilda_notation
		return
	fi
	
	[[ ${pwd_list[1]} != '~' ]] && formed_pwd='/'
	firstchar=$(echo ${pwd_list[1]} | cut -c1)
	[[ $firstchar == '.' ]] && firstchar=$(echo ${pwd_list[1]} | cut -c1,2)
	
	formed_pwd=${formed_pwd}$firstchar
	for ((i=2; i <= $list_len; i++)); do
		if [[ $i != ${list_len} ]]; then
			firstchar=$(echo ${pwd_list[$i]} | cut -c1)
			[[ $firstchar == '.' ]] && firstchar=$(echo ${pwd_list[$i]} | cut -c1,2)
			formed_pwd=${formed_pwd}/$firstchar
		else
			formed_pwd=${formed_pwd}/${pwd_list[$i]}
		fi
	done
	echo $formed_pwd
}
prompt_dir() { # Dir: (PWD)
	prompt_segment blue $CURRENT_FG '%~'
}
prompt_dir_abbr() { # Dir (Abbreviated): (PWD)
	prompt_segment blue $CURRENT_FG $(pwd_abbr)
}

prompt_dir_rw_status() { # Dir RW status: (RO / WO / *LOCKED*)
	local r w
	[[ -r "$PWD" ]] && r=true || r=false
	[[ -w "$PWD" ]] && w=true || w=false
	
	if [[ $r == true && $w == true ]]; then
		# pass
	elif [[ $r == true ]]; then
		prompt_segment red white 'RO'
	elif [[ $w == true ]]; then
		prompt_segment red white 'WO'
	else
		prompt_segment red yellow1 $'\ue0a2'
	fi
}
prompt_dir_rw_status_lite() { # Dir RW status (Lite): (*LOCKED*)
	if [[ ! -r "$PWD" || ! -w "$PWD" ]]; then
		prompt_segment red yellow1 $'\ue0a2'
	fi
}


prompt_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
		return
	fi
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local repo_path=$(git rev-parse --git-dir 2>/dev/null)
		local dirty=$(parse_git_dirty)
		local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green $CURRENT_FG
		fi
		local mode
		if [[ -e "${repo_path}/BISECT_LOG" ]]; then
			mode=" <B>"
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			mode=" >M<"
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
			mode=" >R>"
		fi
		
		setopt PROMPT_SUBST
		autoload -Uz vcs_info
		zstyle ':vcs_info:*' enable git
		zstyle ':vcs_info:*' get-revision true
		zstyle ':vcs_info:*' check-for-changes true
		zstyle ':vcs_info:*' stagedstr '✚'
		zstyle ':vcs_info:*' unstagedstr '●'
		zstyle ':vcs_info:*' formats ' %u%c'
		zstyle ':vcs_info:*' actionformats ' %u%c'
		vcs_info
		
		local PL_BRANCH_CHAR=$'\ue0a0' # 
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
	fi
}
prompt_bzr() { # [-] Bzr
	(( $+commands[bzr] )) || return
	if ( bzr status >/dev/null 2>&1 ); then
		local revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
		if [[ $(bzr status | head -n1 | grep "modified" | wc -m) -gt 0 ]] ; then
			prompt_segment yellow black "bzr@$revision ✚ "
		else
			if [[ $(bzr status | head -n1 | wc -m) -gt 0 ]] ; then
				prompt_segment yellow black "bzr@$revision"
			else
				prompt_segment green black "bzr@$revision"
			fi
		fi
	fi
}
prompt_hg() {  # [-] Mercurial
	(( $+commands[hg] )) || return
	if $(hg id >/dev/null 2>&1); then
		local rev status branch
		if $(hg prompt >/dev/null 2>&1); then
			if [[ $(hg prompt "{status|unknown}") = "?" ]]; then # files are not added
				prompt_segment red white
				status='±'
			elif [[ -n $(hg prompt "{status|modified}") ]]; then # any modification
				prompt_segment yellow black
				status='±'
			else # working copy is clean
				prompt_segment green $CURRENT_FG
			fi
			echo -n $(hg prompt "☿ {rev}@{branch}") $status
		else
			status=""
			rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
			branch=$(hg id -b 2>/dev/null)
			if $(hg st | grep -q "^\?"); then
				prompt_segment red black
				status='±'
			elif $(hg st | grep -q "^[MA]"); then
				prompt_segment yellow black
				status='±'
			else
				prompt_segment green $CURRENT_FG
			fi
			echo -n "☿ $rev@$branch $status"
		fi
	fi
}


prompt_end_chars() { # Prompt newlie and ending characters ($ / #)
	echo ''
	[[ $UID -eq 0 ]] && echo -n ' #' || echo -n ' $'
}

build_prompt() {
	RETVAL=$?
	
	prompt_retval_status_lite
	prompt_root_status
	prompt_context
	prompt_dir
	prompt_git
	prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '

build_right_prompt() {
	prompt_right_end
}
# RPROMPT='%{'$'\e[1A''%}%{%f%b%k%}$(build_right_prompt)%{$reset_color%}%{'$'\e[1B''%}'