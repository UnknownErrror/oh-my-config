source $ZSH/themes/agnor-icons.zsh

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

function normalize_exit_status() {
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
	result=$(normalize_exit_status "${code_sum}")
	for code in "${(@)RETVALS[2,-1]}"; do
		result="${result}|$(normalize_exit_status "$code")"
		code_sum=$(( $code_sum + $code ))
	done
	
	local pre_result=$(echo $result | sed -r 's/^0\|0\|(0\|)+/..0|/')
	if [[ pre_result == result ]]; then
		pre_result=$(echo $result | sed -r 's/(\|0)+\|0\|0$/|0../')
	fi
	result=${pre_result}

	if (( code_sum > 0 )); then
		prompt_segment red white "$(print_icon FAIL_ICON) $result"
	else
		prompt_segment green white "$(print_icon OK_ICON)"
	fi
}
prompt_retval_status_lite() { # Return Value (Lite): (✘ <code> / ✘ SIG<sig>(<code>) / ✔)
	if (( RETVAL > 0 )); then
		prompt_segment red white "$(print_icon FAIL_ICON) $(normalize_exit_status "${RETVAL}")"
	else
		prompt_segment green white "$(print_icon OK_ICON)"
	fi
}

prompt_root_status() { # Status of root: (⚡ / )
	if [[ ${(%):-%#} == '#' ]]; then
		prompt_segment black yellow "$(print_icon ROOT_ICON)"
	elif [[ -n "$SUDO_COMMAND" ]]; then
		prompt_segment black yellow "$(print_icon SUDO_ICON)"
	fi
}
prompt_jobs_status() { # Status of jobs: (⚙ <count> / ⚙)
	local jobs_count="${$(jobs -l | wc -l)// /}"
	local wrong_lines="$(jobs -l | awk '/pwd now/{ count++ } END {print count}')"
	if [[ wrong_lines -gt 0 ]]; then
		jobs_count=$(( $jobs_count - $wrong_lines ))
	fi
	if [[ jobs_count -gt 0 ]]; then # default cyan
		local icon="$(print_icon BACKGROUND_JOBS_ICON)"
		if [[ "$jobs_count" -gt 1 ]]; then
			prompt_segment cyan white "$icon $jobs_count"
		else
			prompt_segment cyan white "$icon"
		fi
	fi
}

prompt_context() { # Context: ((ssh) <user>@<hostname> / <user>@<hostname>)
	if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		prompt_segment black yellow "(ssh) %(!..%{%F{default}%})$USER@%m" # "$(print_icon SSH_ICON)"
	elif [[ "$USER" != "$DEFAULT_USER" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
	fi
}


prompt_dir() { # Dir: ( / WO) + (PWD)
	local icon r w
	[[ -r "$PWD" ]] && r=true || r=false
	[[ -w "$PWD" ]] && w=true || w=false
	
	if [[ $r == true && $w == true ]]; then
		# pass
	elif [[ $r == true ]]; then
		icon="%{%F{yellow}%}$(print_icon LOCK_ICON)%{%F{default}%} "
	elif [[ $w == true ]]; then
		icon="WO "
	else
		icon="$(print_icon LOCK_ICON) "
	fi
	
	prompt_segment blue default "$icon%~"
}
prompt_dir_lite() { # Dir (Lite): () + (PWD)
	local icon
	if [[ ! -w "$PWD" ]]; then
		icon="$(print_icon LOCK_ICON) "
	fi
	prompt_segment blue default "$icon%~"
}
prompt_dir_simple() { # Dir (Simple): (PWD)
	prompt_segment blue default "%~"
}

prompt_time() { # System time
	prompt_segment black default "$(primt_icon TIME_ICON) %D{%H:%M:%S}"
}
prompt_date() { # System date
	prompt_segment black default "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}

# Configurable: DISABLE_UNTRACKED_FILES_DIRTY, GIT_STATUS_IGNORE_SUBMODULES
function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]] && FLAGS+='--untracked-files=no'
	[[ "$GIT_STATUS_IGNORE_SUBMODULES" != "git" ]] && FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	local STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
	[[ -n $STATUS ]] && echo '*'
}
prompt_git_def() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local repo_path=$(git rev-parse --git-dir 2>/dev/null)
		local dirty=$(agnor_parse_git_dirty)
		local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
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
		zstyle ':vcs_info:*' stagedstr $'\u271A' # ✚ # VCS_UNSTAGED_ICON
		zstyle ':vcs_info:*' unstagedstr $'\u25CF' # ● # VCS_STAGED_ICON
		zstyle ':vcs_info:*' formats ' %u%c'
		zstyle ':vcs_info:*' actionformats ' %u%c'
		vcs_info
		
		local PL_BRANCH_CHAR=$'\uE0A0' #  # VCS_BRANCH_ICON
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
	fi
}



# Git statuses:
# - Dirty working directory (orange (dirty) / green)
# - Branch () or detached head (➦)
# - Current branch / SHA1 in detached head state
# - Remote branch name (if you're tracking a remote branch)
# - Number of commit ahead HEAD and behind remote tracking branch (remote tracking segment will be magenta if merge/rebase is needed)
# - Stashes count

prompt_git() { # «»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
	local modified untracked added deleted tagged stashed
	local ready_commit git_status bgclr fgclr

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local clean
		if [[ -n $dirty ]]; then
			clean=''
			bgclr='yellow'
			fgclr='white'
		else
			clean=" $(print_icon OK_ICON)" # ✔
			bgclr='green'
			fgclr='white'
		fi

		local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

		local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
		# if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
		if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

		local number_added=$(\grep -c "^A" <<< "${git_status}")
		[[ $number_added -gt 0 ]] && added=" $number_added✚"

		local number_modified=$(\grep -c "^.M" <<< "${git_status}")
		if [[ $number_modified -gt 0 ]]; then
			modified=" $number_modified●"
		fi

		local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
		local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
		if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
			modified="$modified$((number_added_modified+number_added_renamed))±"
		elif [[ $number_added_modified -gt 0 ]]; then
			modified=" ●$((number_added_modified+number_added_renamed))±"
		fi

		local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
		if [[ $number_deleted -gt 0 ]]; then
			deleted=" $number_deleted‒"
		fi

		local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
		if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
			deleted="$deleted$number_added_deleted±"
		elif [[ $number_added_deleted -gt 0 ]]; then
			deleted=" ‒$number_added_deleted±"
		fi

		local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
		[[ -n $tag_at_current_commit ]] && tagged=" ☗$tag_at_current_commit ";

		local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
		[[ $number_of_stashes -gt 0 ]] && stashed=" ${number_of_stashes##*(  )}$(print_icon ETC_ICON)" # ⚙

		[[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]] && ready_commit=' ⚑'
		
		
		local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
		local commits_ahead commits_behind
		if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then
			local commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
			commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
			commits_behind=$(\grep -c "^>" <<< "$commits_diff")
		fi
		
		prompt_segment $bgclr $fgclr
		
		# ➦        head
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀  ●1±
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1±  ‒1±
		
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1± 3‒1± 12✚ ⚑
		#           master              ✔ ☗tag 2⚙ 12☀ 3●1± 3‒1± 12✚ ⚑
		
		
		# |> +2
		# ➦ head
		#  master ·↑12 ● ✚ <B>             ||> origin ·↓2
		#  master ·↑12 <B>    ||> ● ✚      ||> origin ·↓2
		
		print -n "%{$fg_bold[$fgclr]%}"
		print -n "${ref/refs\/heads\//$PL_BRANCH_CHAR}$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit"
		print -n "%{$fg_no_bold[$fgclr]%}"
	fi
}



(( $+parameters[SHOW_SEGMENT_REMOTE] )) || SHOW_SEGMENT_REMOTE=true # default value
prompt_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local dirty=$(agnor_parse_git_dirty)
		
		# if [[ $SHOW_STASH_SEGMENT -eq 1 ]]; then
			local stash_size=$(git stash list | wc -l | tr -d ' ')
			if [[ stash_size -ne 0 ]]; then
				prompt_segment white black
				echo -n "+${stash_size}"
			fi
		# fi
		
		local ref_symbol ref=$(git symbolic-ref HEAD 2> /dev/null)
		if [[ -z $ref ]]; then
			ref=$(git rev-parse --short HEAD 2> /dev/null) || return 0
			# ref=$(git show-ref --head -s --abbrev |head -n1 2> /dev/null) || return 0
			ref_symbol="➦"
		else
			ref="${ref/refs\/heads\//}"
			ref_symbol=$'\uE0A0' #  # VCS_BRANCH_ICON
		fi
		
		local mode repo_path=$(git rev-parse --git-dir 2>/dev/null)
		if [[ -e "${repo_path}/BISECT_LOG" ]]; then
			mode=" <B>"
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			mode=" >M<"
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
			mode=" >R>"
		fi
		
		local remote="${$(git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/}"
		local ahead behind
		if [[ -n ${remote} ]]; then
			remote="${remote/\/$ref/}"
			ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
			behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | tr -d ' ')
		fi

		if [[ $behind -ne 0 ]] && [[ $ahead -ne 0 ]]; then
			prompt_segment red white # diverged state
		elif [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
		fi
		
		(){ # vcs_info
			setopt PROMPT_SUBST
			autoload -Uz vcs_info
			zstyle ':vcs_info:*' enable git
			zstyle ':vcs_info:*' get-revision true
			zstyle ':vcs_info:*' check-for-changes true
			zstyle ':vcs_info:*' stagedstr $'\u271A' # ✚ # VCS_UNSTAGED_ICON
			zstyle ':vcs_info:*' unstagedstr $'\u25CF' # ● # VCS_STAGED_ICON
			zstyle ':vcs_info:*' formats ' %u%c'
			zstyle ':vcs_info:*' actionformats ' %u%c'
			vcs_info
		}
		
		echo -n "${ref_symbol} ${ref}"
		[[ $ahead -ne "0" ]] && echo -n " ·\u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ ${SHOW_SEGMENT_REMOTE} == false && $behind -ne 0 ]] && echo -n " ·\u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		echo -n "${mode}"
		
		local tag=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
		[[ -n $tag ]] && echo -n " ☗ $tag "
		
		prompt_segment yellow black "${vcs_info_msg_0_%% }"
		
		if [[ ${SHOW_SEGMENT_REMOTE} != false && -n ${remote} ]]; then
			if [[ $behind -ne 0 ]]; then
				prompt_segment magenta white
			else
				prompt_segment cyan black
			fi
			echo -n "\uE0A0 $remote" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && echo -n " ·\u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		fi
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
			# $'\u263F' # ☿ # VCS_BOOKMARK_ICON
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


prompt_end_chars() { # Prompt newline and ending characters ($ / #)
	echo ''
	[[ $UID -eq 0 ]] && echo -n ' #' || echo -n ' $'
	echo -n " ❯"
}

build_prompt() {
	RETVAL=$?
	
	prompt_retval_status_lite
	prompt_root_status
	prompt_context
	prompt_dir_lite
	prompt_git
	prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '

build_right_prompt() {
	prompt_date
	prompt_time
	prompt_right_end
}
# RPROMPT='%{'$'\e[1A''%}%{%f%b%k%}$(build_right_prompt)%{$reset_color%}%{'$'\e[1B''%}'


