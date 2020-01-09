source ${0%/*}/agnor-icons.zsh

######################################
### Utilities ###

AGNOR_ASYNC_PROC=0
AGNOR_ASYNC_READY=0

# Configurable: AGNOR_DISABLE_UNTRACKED_FILES_DIRTY, AGNOR_GIT_STATUS_IGNORE_SUBMODULES
function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ AGNOR_DISABLE_UNTRACKED_FILES_DIRTY == true ]] && FLAGS+='--untracked-files=no'
	[[ AGNOR_GIT_STATUS_IGNORE_SUBMODULES != "git" ]] && FLAGS+="--ignore-submodules=${AGNOR_GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	[[ -n $(git status ${FLAGS} 2>/dev/null | tail -n1) ]] && echo '*'
}
function agnor_get_async_filename() {
	echo "${TMPPREFIX}-$(whoami)-agnor_prompt.$$"
}


######################################
### Segment drawing ###
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

# Special Powerline characters # Do not change this!
SEGMENT_SEPARATOR=$'\ue0b0'

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
	CURRENT_BG='NONE'
}


######################################
### Prompt components ###
# Each component will draw itself, and hide itself if no information needs to be shown


function normalize_exit_status() {
	local RETVAL=$1
	if (( RETVAL <= 128 )); then
		echo "${RETVAL}"
	else
		local sig=$(( RETVAL - 128 ))
		local idx=$(( sig + 1 ))
		echo "SIG${signals[$idx]}(${sig})"
	fi
}
prompt_retval_status() { # Return Value: (✘ <codes> / ✘ <code> / ✘ SIG<sig>(<code>) / ✔)
	local code_sum code
	if (( $#RETVALS > 1 )); then
		code_sum="${RETVALS[1]}"
	else
		code_sum="${RETVAL}"
	fi
	local result=$(normalize_exit_status "${code_sum}")
	for code in "${(@)RETVALS[2,-1]}"; do
		result="${result}|$(normalize_exit_status "$code")"
		code_sum=$(( code_sum + code ))
	done
	
	local pre_result=$(echo $result | sed -r 's/^0\|0\|(0\|)+/..0|/')
	if [[ pre_result == result ]]; then
		pre_result=$(echo $result | sed -r 's/(\|0)+\|0\|0$/|0../')
	fi
	result="${pre_result}"

	if (( code_sum > 0 )); then
		prompt_segment red white "$(print_icon FAIL_ICON) ${result}"
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
	elif [[ -n $SUDO_COMMAND ]]; then
		prompt_segment black yellow "$(print_icon SUDO_ICON)"
	fi
}
prompt_jobs_status() { # Status of jobs: (⚙ <count> / ⚙)
	local jobs_count="${$(jobs -l | wc -l)// /}"
	local wrong_lines="$(jobs -l | awk '/pwd now/{ count++ } END {print count}')"
	if [[ wrong_lines -gt 0 ]]; then
		jobs_count=$(( jobs_count - wrong_lines ))
	fi
	if [[ jobs_count -gt 0 ]]; then
		local icon="$(print_icon BACKGROUND_JOBS_ICON)"
		if [[ jobs_count -gt 1 ]]; then
			prompt_segment cyan white "${icon} ${jobs_count}"
		else
			prompt_segment cyan white "${icon}"
		fi
	fi
}

prompt_context() { # Context: ((ssh) <user>@<hostname> / (screen) <user>@<hostname> / (tmux) <user>@<hostname> / <user>@<hostname>)
	local shell_deep=${(%):-%L}
	[[ shell_deep -gt 1 ]] && prompt_segment black default "${shell_deep}"
	
	if [[ -n $SSH_CONNECTION ]] || [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		prompt_segment black yellow "(ssh) %(!..%{%F{default}%})${USER}@%m"
	elif [[ -n $STY ]]; then
		prompt_segment black white "(screen) %(!.%{%F{yellow}%}.)${USER}@%m"
	elif [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			prompt_segment black magenta "(tmux@${session_name}) %(!.%{%F{yellow}%}.%{%F{default}%})${USER}@%m"
		else
			prompt_segment black magenta "(tmux) %(!.%{%F{yellow}%}.%{%F{default}%})${USER}@%m"
		fi
	elif [[ $USER != $DEFAULT_USER ]]; then
		prompt_segment black white "%(!.%{%F{yellow}%}.)${USER}@%m"
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
	prompt_segment blue white "${icon}%~"
}
prompt_dir_lite() { # Dir (Lite): () + (PWD)
	local icon
	if [[ ! -w "$PWD" ]]; then
		icon="$(print_icon LOCK_ICON) "
	fi
	prompt_segment blue white "${icon}%~"
}
prompt_dir_simple() { # Dir (Simple): (PWD)
	prompt_segment blue white "%~"
}

prompt_time() { # System time
	prompt_segment black default "$(primt_icon TIME_ICON) %D{%H:%M:%S}"
}
prompt_date() { # System date
	prompt_segment white black "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}


(( $+parameters[AGNOR_GIT_SHOW_SEGMENT_REMOTE] )) || AGNOR_GIT_SHOW_SEGMENT_REMOTE=true
(( $+parameters[AGNOR_GIT_SHOW_SEGMENT_STASH] ))  || AGNOR_GIT_SHOW_SEGMENT_STASH=true
prompt_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if [[ AGNOR_ASYNC_READY -ne 0 ]]; then
		cat $(agnor_get_async_filename)
		return
	fi
	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]; then
		local dirty=$(agnor_parse_git_dirty)
		
		if [[ AGNOR_GIT_SHOW_SEGMENT_STASH != false ]]; then
			# local stashes=$(git stash list | wc -l)
			local stashes=$(git stash list -n1 | wc -l)
			if [[ stashes -ne 0 ]]; then
				prompt_segment white black "+$stashes$(print_icon ETC_ICON)" # ⚙
			fi
		fi
		
		local ref_symbol ref=$(git symbolic-ref HEAD 2>/dev/null)
		if [[ -z $ref ]]; then # Branch () / detached head (➦)
			ref=$(git rev-parse --short HEAD 2>/dev/null) || return 1
			ref_symbol="➦"
		else
			ref="${ref/refs\/heads\//}"
			ref_symbol=$'\uE0A0' #  # VCS_BRANCH_ICON
		fi
		
		# local ahead behind remote="$(git rev-parse --abbrev-ref --verify @{upstream} 2>/dev/null)"
		local ahead behind remote="$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)"
		if [[ -n ${remote} ]]; then
			remote="${remote/\/$ref/}"
			ahead=$(git rev-list @{upstream}..HEAD 2>/dev/null | wc -l)
			behind=$(git rev-list HEAD..@{upstream} 2>/dev/null | wc -l)
		fi
		
		if [[ behind -ne 0 ]] && [[ ahead -ne 0 ]]; then # [EXPERIMENT]
			prompt_segment red white # diverged state
		elif [[ AGNOR_GIT_SHOW_SEGMENT_REMOTE == false && behind -ne 0 ]]; then
			prompt_segment magenta white # merge/rebase is needed
		elif [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green white # black
		fi
		
		echo -n "${ref_symbol} ${ref}"
		
		local tag=$(git describe --exact-match --tags 2> /dev/null)
		[[ -n $tag ]] && echo -n " ☗ ${tag}"
		
		[[ ahead -ne 0 ]] && echo -n " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ AGNOR_GIT_SHOW_SEGMENT_REMOTE == false && behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		
		[[ ! -n $dirty ]] && echo -n " $(print_icon OK_ICON)" # ✔
		
		local git_dir=$(git rev-parse --git-dir 2>/dev/null)
		if [[ -e "${git_dir}/BISECT_LOG" ]]; then # Modes
			echo -n " <B>"
		elif [[ -e "${git_dir}/MERGE_HEAD" ]]; then
			echo -n " >M<"
		elif [[ -e "${git_dir}/rebase" || -e "${git_dir}/../.dotest" ]]; then
			echo -n " >R>"
		elif [[ -e "${git_dir}/rebase-merge" ]]; then
			if [[ -e "${git_dir}/rebase-merge/interactive" ]]; then
				echo -n " >R[i]>"
			else
				echo -n " >R[m]>"
			fi
		elif [[ -e "${git_dir}/rebase-apply" ]]; then
			if [[ -e "${git_dir}/rebase-apply/rebasing" ]]; then
				echo -n " >R>"
			elif [[ -e "${git_dir}/rebase-apply/applying" ]]; then
				echo -n " <A<"
			else
				echo -n " <A</>R>"
			fi
		elif [[ -e "${git_dir}/CHERRY_PICK_HEAD" ]]; then
			echo -n " <C<"
		elif [[ -e "${git_dir}/REVERT_HEAD" ]]; then
			echo -n " [Revert]"
		elif local result=$(local todo; if [[ -r "${git_dir}/sequencer/todo" ]] && read todo < "${git_dir}/sequencer/todo"; then
				case "$todo" in (p[\ \	]|pick[\ \	]*) echo -n "<C<" ;; (revert[\ \	]*) echo -n "[Revert]" ;; esac
			fi) && [[ -n ${result} ]]; then
			# see if a cherry-pick or revert is in progress, if the user has committed a
			# conflict resolution with 'git commit' in the middle of a sequence of picks or
			# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read the todo file.
			echo -n " ${result}"
		fi
		
		(){
			local porcelain=$(git status --porcelain 2> /dev/null)
			
			local num_untracked=$(echo $porcelain | grep -c "^??")
			[[ num_untracked -gt 0 ]] && echo -n " $num_untracked\u2026"

			local num_added=$(echo $porcelain | grep -c "^A")
			[[ num_added -gt 0 ]] && echo -n " $num_added✚"

			local modified num_modified=$(echo $porcelain | grep -c "^.M") num_cached_modified=$(echo $porcelain | grep -c "^M") num_cached_renamed=$(echo $porcelain | grep -c "^R")
			[[ num_modified -gt 0 ]] && modified=" $num_modified\u2022" # • ●
			[[ num_cached_modified -gt 0 || num_cached_renamed -gt 0 ]] && modified="${modified:= •}$((num_cached_modified+num_cached_renamed))±"
			echo -n ${modified}

			local deleted num_deleted=$(echo $porcelain | grep -c "^.D") num_cached_deleted=$(echo $porcelain | grep -c "^D")
			[[ num_deleted -gt 0 ]] && deleted=" $num_deleted‒"
			[[ num_cached_deleted -gt 0 ]] && deleted="${deleted:= -}$num_cached_deleted±"
			echo -n ${deleted}
			
			[[ num_added -gt 0 || num_cached_modified -gt 0 || num_cached_deleted -gt 0 ]] && echo -n ' ⚑'
		}
		
		if [[ AGNOR_GIT_SHOW_SEGMENT_REMOTE != false && -n ${remote} ]]; then
			if [[ $behind -ne 0 ]]; then
				prompt_segment magenta white # merge/rebase is needed
			else
				prompt_segment cyan black
			fi
			echo -n "\uE0A0 ${remote}" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		fi
		
	elif [[ $(git rev-parse --is-inside-git-dir 2>/dev/null) == true ]]; then
		if [[ $(git rev-parse --is-bare-repository) == true ]]; then
			prompt_segment cyan black "bare repo"
		else
			prompt_segment cyan black "GIT_DIR!"
		fi
	fi
} #  master ☗ tag ↑12 ✔ <B>  |>  12… 3•1± 3‒1± 12✚ ⚑  |>  origin ↓2

prompt_git_remotes() {
	eval "remotes=(`git remote | sed 's/\n/ /'`)"
	for remote in $remotes; do
		prompt_git_remote $remote
	done
}
prompt_git_remote() {
	local remote_status
	local remote=${1:-"origin"}
	local fg=black
	local current_branch=${$(git rev-parse --abbrev-ref HEAD)}
	local remote_path=${$(git rev-parse --verify remotes\/${remote}\/${current_branch} --symbolic-full-name 2> /dev/null)}

	if [[ -n ${remote_path} ]] ; then
		local ahead=$(git rev-list ${remote_path}..HEAD 2> /dev/null | wc -l | tr -d ' ')
		local behind=$(git rev-list HEAD..${remote_path} 2> /dev/null | wc -l | tr -d ' ')

		if [[ ahead -eq 0 && behind -eq 0 ]] ; then
			remote_status="○ "
		else
			if [[ behind -gt 0 ]] ; then
				fg=red
			elif [[ ahead -gt 0 ]] ; then
				fg=yellow
			fi
			remote_status="+${ahead} -${behind}"
		fi
	else
		remote_status="--"
	fi

	prompt_segment cyan $fg "⏏ $remote $remote_status"
}

# Git statuses:
# - Branch () or detached head (➦)
# - Dirty working directory state (orange (dirty) / green (✔))
# - Current branch / SHA1 in detached head state
# - Remote branch name (if you're tracking a remote branch)
# - Number of commit ahead HEAD and behind remote tracking branch (remote tracking segment will be magenta if merge/rebase is needed)
# - Stashes count
# - <B> - Bisect state on the current branch
# - >M< - Merge state on the current branch
# - >R> - Rebase state on the current branch

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
				prompt_segment green black
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
				prompt_segment green black
			fi
			echo -n "☿ $rev@$branch $status"
		fi
	fi
}


prompt_newline() {
	prompt_end
	echo
}
prompt_shell_chars() { # ($ / #) ❯
	echo -n " %(!.#.$) ❯"
}


build_prompt() {
	RETVAL=$?
	
	prompt_retval_status_lite
	prompt_root_status
	prompt_context
	prompt_dir_lite
	prompt_git
	prompt_end
	
	prompt_shell_chars
}
PROMPT='%{%f%b%k%}$(build_prompt) '




(( $+parameters[AGNOR_DISABLE_EXTRA_SETUP] )) || AGNOR_DISABLE_EXTRA_SETUP=false
[[ AGNOR_DISABLE_EXTRA_SETUP != true ]] && (){ # Extra setup
	autoload -Uz add-zsh-hook
	
	local start_time=$SECONDS
	function agnor_hook_preexec() {
		start_time=$SECONDS
	}
	function agnor_hook_precmd() {
		if [[ start_time -ne 0 ]]; then
			local elapsed_time=$(( SECONDS - start_time ))
			if [[ elapsed_time -ge 3600 ]]; then
				local timer_hours=$(( elapsed_time / 3600 ))
				local remainder=$(( elapsed_time % 3600 ))
				local timer_minutes=$(( remainder / 60 ))
				local timer_seconds=$(( remainder % 60 ))
				print -P "%B%F{red}>>> elapsed time ${timer_hours}h ${timer_minutes}m ${timer_seconds}s%b"
			elif [[ elapsed_time -ge 60 ]]; then
				local timer_minutes=$(( elapsed_time / 60 ))
				local timer_seconds=$(( elapsed_time % 60 ))
				print -P "%B%F{yellow}>>> elapsed time ${timer_minutes}m ${timer_seconds}s%b"
			elif [[ elapsed_time -gt 10 ]]; then
				print -P "%B%F{green}>>> elapsed time ${elapsed_time}s%b"
			fi
			start_time=0
		fi
	}
	add-zsh-hook preexec agnor_hook_preexec
	add-zsh-hook precmd agnor_hook_precmd
	
	TRAPWINCH() { # Ensure that the prompt is redrawn when the terminal size changes.
		zle && { zle reset-prompt; zle -R }
	}
}


() { # Async setup
	agnor_hook_precmd_2() {
		# kill child if necessary
		if [[ AGNOR_ASYNC_PROC -ne 0 ]]; then
			kill -s HUP $AGNOR_ASYNC_PROC >/dev/null 2>&1 || :
		fi
		# start background computation
		prompt_agnor_async_prompt &!
		AGNOR_ASYNC_PROC=$!
	}
	agnor_hook_zshexit() {
		rm -f "$(agnor_get_async_filename)" 2> /dev/null
	}
	
	prompt_agnor_async_prompt() {
		prompt_git > "$(agnor_get_async_filename)" 2>&1
		kill -s USR1 $$ # signal parent
	}
	
	add-zsh-hook precmd agnor_hook_precmd_2
	add-zsh-hook zshexit agnor_hook_zshexit
	
	TRAPUSR1() {
		AGNOR_ASYNC_READY=1
		AGNOR_ASYNC_PROC=0 # reset proc number
		zle && zle reset-prompt # reload
		AGNOR_ASYNC_READY=0
	}
}




_agkozak_branch_status() {
	if [[ -n $branch ]]; then
		local symbols i=1 k
		local git_status="$(git status 2>&1)"
		typeset -A messages=(
			'+' 'new file: '
			'x' 'deleted: '
			'!' 'modified: '
			'>' 'renamed: '
			'?' 'Untracked files:'
		)
		for k in '+' 'x' '!' '>' '?'; do
			case $git_status in
				*${messages[$k]}*) symbols+="${AGKOZAK_CUSTOM_SYMBOLS[$i]:-$k}" ;;
			esac
			(( i++ ))
		done
		[[ -n $symbols ]] && symbols=" ${symbols}"
	fi
}

