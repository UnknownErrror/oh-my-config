source ${0%/*}/agnor-icons.zsh

######################################
### Utilities ###

# Configurable: AGNOR_DISABLE_UNTRACKED_FILES_DIRTY, AGNOR_GIT_STATUS_IGNORE_SUBMODULES
function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ AGNOR_DISABLE_UNTRACKED_FILES_DIRTY == true ]] && FLAGS+='--untracked-files=no'
	[[ AGNOR_GIT_STATUS_IGNORE_SUBMODULES != "git" ]] && FLAGS+="--ignore-submodules=${AGNOR_GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	[[ -n $(git status ${FLAGS} 2>/dev/null) ]] && echo '*'
}
function agnor_format_exit_status() {
	local RETVAL=$1
	if (( RETVAL <= 128 )); then
		echo "${RETVAL}"
	else
		local sig=$(( RETVAL - 128 ))
		local idx=$(( sig + 1 ))
		echo "SIG${signals[$idx]}(${sig})"
	fi
}
function agnor_get_user_context() { # Context: ((ssh/screen/tmux) <user>@<hostname>)
	local icon string
	if [[ ${(%):-%#} == '#' ]]; then
		icon="%{%F{yellow}%}$(print_icon ROOT_ICON)"
	elif [[ -n $SUDO_COMMAND ]]; then
		icon="%{%F{yellow}%}$(print_icon SUDO_ICON)"
	fi
	if [[ $SHORT_HOST != $DEFAULT_HOST ]]; then
		string="%{%(!.%F{yellow}.%F{default})%}${USERNAME}@${SHORT_HOST}"
	elif [[ $USERNAME != $DEFAULT_USER ]]; then
		string="%{%(!.%F{yellow}.%F{default})%}${USERNAME}"
	fi
	
	if [[ -n "$string" ]] && [[ -n "$icon" ]]; then
		icon="${icon} "
	fi
	echo "${icon}${string}"
}

######################################
### Segment drawing ###

function agnor_prompt_full() {
	if [[ "$1" == "right" ]]; then
		echo -n " %{%F{$2}%}\uE0B3 $3"
	else
		echo -n "%{%F{$2}%} $3 \uE0B1"
	fi
}
function agnor_prompt_start() {
	if [[ "$1" == "right" ]]; then
		echo -n " %{%F{$2}%}\uE0B3 $3"
	else
		echo -n "%{%F{$2}%} $3"
	fi
}
function agnor_prompt_end() {
	if [[ "$1" == "left" ]]; then
		echo -n " \uE0B1"
	fi
}

######################################
### Prompt components ###

prompt_retval_status() { # Return Value: (✘ <retvals> / ✘ <retval> / ✔)
	local code_sum code
	if (( $#RETVALS > 1 )); then
		code_sum="${RETVALS[1]}"
	else
		code_sum="${RETVAL}"
	fi
	local result=$(agnor_format_exit_status "${code_sum}")
	for code in "${(@)RETVALS[2,-1]}"; do
		result="${result}|$(agnor_format_exit_status "$code")"
		code_sum=$(( code_sum + code ))
	done
	
	local pre_result=$(echo $result | sed -r 's/^0\|0\|(0\|)+/..0|/')
	if [[ pre_result == result ]]; then
		pre_result=$(echo $result | sed -r 's/(\|0)+\|0\|0$/|0../')
	fi
	result="${pre_result}"

	if (( code_sum > 0 )); then
		agnor_prompt_full $1 009 "$(print_icon FAIL_ICON) ${result}"
	else
		agnor_prompt_full $1 green "$(print_icon OK_ICON)"
	fi
}
prompt_retval_status_simple() { # Return Value (Simple): (✘ <retval> / ✔)
	if (( RETVAL > 0 )); then
		agnor_prompt_full $1 009 "$(print_icon FAIL_ICON) $(agnor_format_exit_status "${RETVAL}")"
	else
		agnor_prompt_full $1 green "$(print_icon OK_ICON)"
	fi
}

prompt_jobs_status() { # Status of jobs: [ ⚙ <count> / ⚙ ]
	local jobs_count="${$(jobs -l | wc -l)// /}"
	local wrong_lines="$(jobs -l | awk '/pwd now/{ count++ } END {print count}')"
	if (( wrong_lines > 0 )); then
		jobs_count=$(( jobs_count - wrong_lines ))
	fi
	if (( jobs_count > 0 )); then
		agnor_prompt_start $1 cyan "$(print_icon BACKGROUND_JOBS_ICON)"
		if (( jobs_count > 1 )); then
			echo -n " ${jobs_count}"
		fi
		agnor_prompt_end $1
	fi
}

prompt_context() { # Context: [ (ssh/screen/tmux) ⚡ /  <user>@<hostname> ]
	local string="$(agnor_get_user_context)"
	if [[ -n $SSH_CONNECTION ]] || [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		[[ -n "$string" ]] && string=" ${string}"
		agnor_prompt_full $1 yellow "(ssh)${string}"
	elif [[ -n $STY ]]; then
		[[ -n "$string" ]] && string=" ${string}"
		agnor_prompt_full $1 default "(screen)${string}"
	elif [[ -n $TMUX ]]; then
		[[ -n "$string" ]] && string=" ${string}"
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			agnor_prompt_full $1 013 "(tmux@${session_name})${string}"
		else
			agnor_prompt_full $1 013 "(tmux)${string}"
		fi
	elif [[ -n "$string" ]]; then
		agnor_prompt_full $1 default "${string}"
	fi
}
prompt_context_simple() { # Context (Simple): [ (ssh) ⚡ /  <user>@<hostname> ]
	local string="$(agnor_get_user_context)"
	if [[ -n $SSH_CONNECTION ]] || [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		[[ -n "$string" ]] && string=" ${string}"
		agnor_prompt_full $1 yellow "(ssh)${string}"
	elif [[ -n "$string" ]]; then
		agnor_prompt_full $1 default "${string}"
	fi
}

prompt_dir() { # Dir: [  / WO <pwd> ]
	local icon
	if [[ -r "$PWD" ]]; then
		if [[ ! -w "$PWD" ]]; then
			icon="%{%F{yellow}%}$(print_icon LOCK_ICON)%{%f%} "
		fi
	elif [[ -w "$PWD" ]]; then
		icon="%{%F{yellow}%}WO%{%f%} "
	else
		icon="$(print_icon LOCK_ICON) "
	fi
	agnor_prompt_full $1 blue "${icon}${PWD/#$HOME/~}"
}
prompt_dir_simple() { # Dir (Simple): [  <pwd> ]
	local icon
	[[ ! -w "$PWD" ]] && icon="$(print_icon LOCK_ICON) "
	agnor_prompt_full $1 blue "${icon}${PWD/#$HOME/~}"
}
prompt_dir_simpler() { # Dir (Simpler): [ <pwd> ]
	agnor_prompt_full $1 blue "${PWD/#$HOME/~}"
}

prompt_time() { # System time: [ HH:MM:SS ]
	agnor_prompt_full $1 white "$(print_icon TIME_ICON) %D{%H:%M:%S}"
}
prompt_date() { # System date: [ dd.mm.yy ]
	agnor_prompt_full $1 white "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}

prompt_tty() { # $TTY: [ <tty> ]
	agnor_prompt_full $1 white "%y"
}


prompt_async() { # Prompt all async data
	if [[ -n $AGNOR_ASYNC_DATA ]]; then
		echo -n $AGNOR_ASYNC_DATA
	fi
}

prompt_async_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]; then
		local dirty=$(agnor_parse_git_dirty)
		
		local stashes=$(git stash list -n1 | wc -l)
		if [[ stashes -ne 0 ]]; then
			agnor_prompt_full $1 white "+${stashes}$(print_icon ETC_ICON)" # ⚙
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
		
		if [[ behind -ne 0 ]] && [[ ahead -ne 0 ]]; then
			agnor_prompt_start $1 red # diverged state
		elif [[ -n $dirty ]]; then
			agnor_prompt_start $1 yellow
		else
			agnor_prompt_start $1 green # black
		fi
		
		echo -n "${ref_symbol} ${ref}"
		
		local tag=$(git describe --exact-match --tags 2> /dev/null)
		[[ -n $tag ]] && echo -n " ☗ ${tag}"
		
		[[ ahead -ne 0 ]] && echo -n " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		
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
				echo -n " <A/R>"
			fi
		elif [[ -e "${git_dir}/CHERRY_PICK_HEAD" ]]; then
			echo -n " <C<"
		elif [[ -e "${git_dir}/REVERT_HEAD" ]]; then
			echo -n " <R<"
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
			[[ num_cached_modified -gt 0 || num_cached_renamed -gt 0 ]] && modified="${modified:= •}$((num_cached_modified + num_cached_renamed))±"
			echo -n ${modified}

			local deleted num_deleted=$(echo $porcelain | grep -c "^.D") num_cached_deleted=$(echo $porcelain | grep -c "^D")
			[[ num_deleted -gt 0 ]] && deleted=" $num_deleted‒"
			[[ num_cached_deleted -gt 0 ]] && deleted="${deleted:= -}$num_cached_deleted±"
			echo -n ${deleted}
			
			[[ num_added -gt 0 || num_cached_modified -gt 0 || num_cached_renamed -gt 0 || num_cached_deleted -gt 0 ]] && echo -n ' ⚑'
		}
		agnor_prompt_end $1
		
		if [[ "f" == "t" && -n ${remote} ]]; then
			if [[ behind -ne 0 ]]; then
				agnor_prompt_start $1 magenta # merge/rebase is needed
			else
				agnor_prompt_start $1 cyan
			fi
			echo -n "\uE0A0 ${remote}" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
			agnor_prompt_end $1
		fi
		prompt_async_git_remotes $1
		
	elif [[ $(git rev-parse --is-inside-git-dir 2>/dev/null) == true ]]; then
		if [[ $(git rev-parse --is-bare-repository) == true ]]; then
			agnor_prompt_full $1 cyan "bare repo"
		else
			agnor_prompt_full $1 cyan "GIT_DIR!"
		fi
	fi
}
prompt_async_git_remotes() {
	eval "remotes=(`git remote | sed 's/\n/ /'`)"
	for remote in $remotes; do
		prompt_async_git_remote $1 $remote
	done
}
prompt_async_git_remote() {
	local remote=${2:-"origin"}
	local current_branch=$(git rev-parse --abbrev-ref HEAD)
	local remote_path=$(git rev-parse --verify remotes\/${remote}\/${current_branch} --symbolic-full-name 2> /dev/null)

	if [[ -n ${remote_path} ]]; then
		local ahead=$(git rev-list ${remote_path}..HEAD 2>/dev/null | wc -l)
		local behind=$(git rev-list HEAD..${remote_path} 2>/dev/null | wc -l)
		if [[ behind -ne 0 ]] && [[ ahead -ne 0 ]]; then
			agnor_prompt_start $1 red # diverged state
		elif [[ behind -ne 0 ]]; then
			agnor_prompt_start $1 magenta # merge/rebase is needed
		else
			agnor_prompt_start $1 cyan
		fi
		echo -n "⏏ ${remote}" # ⏏ | \uE0A0 # VCS_BRANCH_ICON
		[[ ahead -ne 0 ]] && echo -n " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		agnor_prompt_end $1
	fi
}

prompt_async_bzr() { # Bzr: (bzr@<revision> ✚)
	(( $+commands[bzr] )) || return
	if ( bzr status -q >/dev/null 2>&1 ); then
		# local revision=$(bzr log | head -n2 | tail -n1 | sed 's/^revno: //')
		#[[ -z $revision ]] && revision='0'
		local revision=$(bzr revno)
		local bzr_status=$(bzr status | head -n1)
		if (( $(echo $bzr_status | grep "modified" | wc -m) > 0 )); then
			agnor_prompt_full $1 yellow "bzr@${revision} ✚"
		elif (( $(echo $bzr_status | wc -m) > 0 )); then
			agnor_prompt_full $1 yellow "bzr@${revision}"
		else
			agnor_prompt_full $1 green "bzr@${revision}"
		fi
	fi
}
prompt_async_hg() { # Mercurial: (☿ <revision>@<branch> ±)
	(( $+commands[hg] )) || return
	# if ( hg id >/dev/null 2>&1 ); then
	if ( hg root >/dev/null 2>&1 ); then
		local dirty
		if ( hg prompt >/dev/null 2>&1 ); then
			if [[ $(hg prompt "{status|unknown}") == "?" ]]; then # files are not added
				agnor_prompt_start $1 red
				dirty='±'
			elif [[ -n $(hg prompt "{status|modified}") ]]; then # any modification
				agnor_prompt_start $1 yellow
				dirty='±'
			else # working copy is clean
				agnor_prompt_start $1 green
			fi
			# $'\u263F' # ☿ # VCS_BOOKMARK_ICON
			echo -n $(hg prompt "☿ {rev}@{branch}") $dirty
			agnor_prompt_end $1
		else
			local rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
			local branch=$(hg id -b 2>/dev/null)
			if $(hg st | grep -q "^\?"); then # files are not added
				agnor_prompt_start $1 red
				dirty='±'
			elif $(hg st | grep -q "^[MA]"); then # any modification
				agnor_prompt_start $1 yellow
				dirty='±'
			else
				agnor_prompt_start $1 green
			fi
			echo -n "☿ ${rev}@${branch} ${dirty}"
			agnor_prompt_end $1
		fi
	fi
}
# cdv !cvs darcs fossil mtn p4 svk !svn tla


prompt_newline() {
	echo -n "%{%f%K{008}%}%E\n%{%k%}"
}
prompt_shell_chars() { # ($ / #) ❯
	echo -n ' %(!.#.$) ❯'
}


function build_prompt() {
	RETVAL=$?
	RETVALS=( "$pipestatus[@]" )
	AGNOR_SEGMENTS=()
	
	echo -n "%{%K{008}%}"
	prompt_retval_status left
	prompt_jobs_status left
	prompt_context left
	prompt_dir left
	
	prompt_async # Git Hg Bzr
	
	prompt_newline left
	prompt_shell_chars left
}
function build_rprompt() {
	echo -n "%{%K{008}%}"
	prompt_tty right
}

function agnor_async_response() {
	AGNOR_ASYNC_DATA="$(<&$1)"
	if [[ -n $AGNOR_ASYNC_DATA ]]; then
		zle && zle reset-prompt
	fi
	zle -F $1
	exec {1}<&-
}
function agnor_setup(){ # Setup
	autoload -Uz add-zsh-hook
	AGNOR_ASYNC_NEEDED=${AGNOR_ASYNC_NEEDED:-true}
	AGNOR_GIT_SHOW_SEGMENT_REMOTE=${AGNOR_GIT_SHOW_SEGMENT_REMOTE:-true}
	AGNOR_GIT_SHOW_SEGMENT_STASH=${AGNOR_GIT_SHOW_SEGMENT_STASH:-true}
	
	local start_time=$SECONDS
	function agnor_hook_preexec() {
		start_time=$SECONDS
	}
	function agnor_hook_precmd() {
		# Async
		AGNOR_ASYNC_DATA=''
		if [[ $AGNOR_ASYNC_NEEDED == true ]]; then
			[[ -n $AGNOR_ASYNC_FD ]] && zle -F $AGNOR_ASYNC_FD 2>/dev/null
			exec {AGNOR_ASYNC_FD}< <(
				prompt_async_git left
				# prompt_async_bzr left
				# prompt_async_hg left
			)
			zle -F $AGNOR_ASYNC_FD agnor_async_response
		fi
		
		# Elapsed time
		if [[ start_time -ne 0 ]]; then
			local elapsed_time=$(( SECONDS - start_time ))
			if [[ elapsed_time -ge 3600 ]]; then
				local timer_hours=$(( elapsed_time / 3600 ))
				local remainder=$(( elapsed_time % 3600 ))
				local timer_minutes=$(( remainder / 60 ))
				local timer_seconds=$(( remainder % 60 ))
				print -P "%{%B%F{red}%}>>> elapsed time ${timer_hours}h ${timer_minutes}m ${timer_seconds}s%{%b%f%}"
			elif [[ elapsed_time -ge 60 ]]; then
				local timer_minutes=$(( elapsed_time / 60 ))
				local timer_seconds=$(( elapsed_time % 60 ))
				print -P "%{%B%F{yellow}%}>>> elapsed time ${timer_minutes}m ${timer_seconds}s%{%b%f%}"
			elif [[ elapsed_time -gt 10 ]]; then
				print -P "%{%B%F{green}%}>>> elapsed time ${elapsed_time}s%{%b%f%}"
			fi
			start_time=0
		fi
	}
	add-zsh-hook preexec agnor_hook_preexec
	add-zsh-hook precmd agnor_hook_precmd
	
	# TRAPWINCH() { # Ensure that the prompt is redrawn when the terminal size changes.
		# zle && { zle reset-prompt; zle -R }
	# }
	
	PROMPT='%{%f%b%k%}$(build_prompt) '
	PROMPT2='%(1_.%_.-)> '
	PROMPT3='#?> '
	
	# PROMPT4='+ %N:%i> '
	typeset -g agnor_prompt4_fix_symbol='%e'
	PROMPT4='%{%F{yellow}%}${(l:${(S%)agnor_prompt4_fix_symbol}::+:)} %{%F{blue}%}%N%{%F{242}%}:%i:%I> %{%f%}'
	
	TIMEFMT=$'user: %U system: %S total: %E cpu: %P  %J'
	# TIMEFMT=$'%J:\n    user:\t%U\n    system:\t%S\n    total:\t%E\n    cpu:\t%P'
	REPORTTIME=1
	
	SPROMPT="%{%F{yellow}%B%}[ZSH]: Correct '%{%F{red}%}%R%{%F{yellow}%}' to '%{%F{green}%b%}%r%{%F{yellow}%B%}' [nyae]? %{%f%}"
	WATCHFMT="[%U%D %T%u]  %{%B%}%n%{%b%} has %a %{%B%}%l%{%b%} from %{%B%{%M%{%b%}."
	
	(){
		local LC_ALL="" LC_CTYPE="en_US.UTF-8" # Set the right locale to protect special characters
		RPROMPT_PREFIX=$'%{\e[1A%}' # one line up
		RPROMPT_SUFFIX=$'%{\e[1B%}' # one line down
	}
	RPROMPT='%y'
	RPROMPT="$RPROMPT_PREFIX"'%{%f%b%k%}$(build_rprompt)%{%E%}'"$RPROMPT_SUFFIX"
	# RPROMPT='%{%f%b%k%}$(build_rprompt)%{%E%}'
}
agnor_setup "$@"

function set-prompt() {
	local top_left='%~'
	local top_right="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
	local bottom_left='%# '
	local bottom_right='%T'

	PROMPT="$(fill-line "$top_left" "$top_right")"$'\n'$bottom_left
	RPROMPT=$bottom_right
}
function fill-line() {
	local left_len=$(prompt-length $1)
	local right_len=$(prompt-length $2)
	local pad_len=$((COLUMNS - left_len - right_len - 1))
	local pad=${(pl.$pad_len.. .)} # pad_len spaces
	echo ${1}${pad}${2}
}
function prompt-length() {
	emulate -L zsh
	local -i x y=$#1 m
	if (( y )); then
		while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
			x=y
			(( y *= 2 ));
		done
		local xy
		while (( y > x + 1 )); do
			m=$(( x + (y - x) / 2 ))
			typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
		done
	fi
	echo $x
}
