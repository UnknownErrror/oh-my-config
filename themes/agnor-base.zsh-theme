source ${0%/*}/agnor-icons.zsh

######################################
### Variables ###

AGNOR_SEGMENTS=()
AGNOR_COMMAND_START=$'\x00'
AGNOR_COMMAND_RAW=$'\x01'
AGNOR_COMMAND_NL=$'\x03'

AGNOR_ASYNC_SEGMENTS=()

######################################
### Utilities ###

# Configurable: AGNOR_DISABLE_UNTRACKED_FILES_DIRTY, AGNOR_GIT_STATUS_IGNORE_SUBMODULES
function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ AGNOR_DISABLE_UNTRACKED_FILES_DIRTY == true ]] && FLAGS+='--untracked-files=no'
	[[ AGNOR_GIT_STATUS_IGNORE_SUBMODULES != "git" ]] && FLAGS+="--ignore-submodules=${AGNOR_GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	[[ -n $(git status ${FLAGS} 2>/dev/null) ]] && echo '*'
}

function agnor_prompt_add_segment() {
	AGNOR_SEGMENTS+=($AGNOR_COMMAND_START $@)
}
function agnor_prompt_start_segment() {
	AGNOR_SEGMENTS+=($AGNOR_COMMAND_START)
}
function agnor_prompt_raw_segment() {
	AGNOR_SEGMENTS+=($@)
}

function agnor_async_prompt_add_segment() {
	emulate -L zsh
	echo "$AGNOR_COMMAND_START"
	for (( i = 1; i <= $#; i++ )); do
		echo $@[$i]
	done
}
function agnor_async_prompt_start_segment() {
	echo "$AGNOR_COMMAND_START"
}
function agnor_async_prompt_raw_segment() {
	emulate -L zsh
	for (( i = 1; i <= $#; i++ )); do
		echo $@[$i]
	done
}

######################################
### Segment drawing ###

(){ # Special Powerline characters # Do not change this!
	local LC_ALL='' LC_CTYPE='en_US.UTF-8' # Set the right locale to protect special characters
	SEGMENT_SEPARATOR=$'\ue0b0'
}

function agnor_prompt_segments() {
	emulate -L zsh
	local BG FG STATE COMMAND CURRENT_BG='NONE'
	
	for (( i = 1; i <= $#AGNOR_SEGMENTS; i++ )); do
		COMMAND=$AGNOR_SEGMENTS[$i]
		
		if [[ $COMMAND == $AGNOR_COMMAND_START ]]; then
			STATE='start'
		elif [[ $COMMAND == $AGNOR_COMMAND_RAW ]]; then
			STATE='content'
		elif [[ $COMMAND == $AGNOR_COMMAND_NL ]]; then
			if [[ $CURRENT_BG != 'NONE' ]]; then
				echo -n " %{%K{008}%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
			else
				echo -n "%{%K{008}%}"
			fi
			echo -n "%E%{%f%}\n%{%k%}"
			CURRENT_BG='NONE'
		elif [[ $STATE == 'content' ]]; then
			echo -n ${COMMAND}
			
		elif [[ $STATE == 'start' ]]; then
			BG=${COMMAND}
			STATE='bg'
		elif [[ $STATE == 'bg' ]]; then
			FG=${COMMAND}
			STATE='fg'
		elif [[ $STATE == 'fg' ]]; then
			if [[ $CURRENT_BG != 'NONE' && $CURRENT_BG != $BG ]]; then
				echo -n " %{%K{$BG}%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{%F{$FG}%} "
			else
				echo -n "%{%K{$BG}%F{$FG}%} "
			fi
			echo -n ${COMMAND}
			CURRENT_BG=$BG
			STATE='content'
		fi
	done
	
	if [[ $CURRENT_BG != 'NONE' ]]; then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
}

######################################
### Prompt components ###

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
		agnor_prompt_add_segment red white "$(print_icon FAIL_ICON) ${result}"
	else
		agnor_prompt_add_segment green white "$(print_icon OK_ICON)"
	fi
}
prompt_retval_status_lite() { # Return Value (Lite): (✘ <code> / ✘ SIG<sig>(<code>) / ✔)
	if (( RETVAL > 0 )); then
		agnor_prompt_add_segment red white "$(print_icon FAIL_ICON) $(normalize_exit_status "${RETVAL}")"
	else
		agnor_prompt_add_segment green white "$(print_icon OK_ICON)"
	fi
}


prompt_root_status() { # Status of root: (⚡ / )
	if [[ ${(%):-%#} == '#' ]]; then
		agnor_prompt_add_segment black yellow "$(print_icon ROOT_ICON)"
	elif [[ -n $SUDO_COMMAND ]]; then
		agnor_prompt_add_segment black yellow "$(print_icon SUDO_ICON)"
	fi
}
prompt_jobs_status() { # Status of jobs: (⚙ <count> / ⚙)
	local jobs_count="${$(jobs -l | wc -l)// /}"
	local wrong_lines="$(jobs -l | awk '/pwd now/{ count++ } END {print count}')"
	if (( wrong_lines > 0 )); then
		jobs_count=$(( jobs_count - wrong_lines ))
	fi
	if (( jobs_count > 0 )); then
		agnor_prompt_add_segment cyan white "$(print_icon BACKGROUND_JOBS_ICON)"
		if (( jobs_count > 1 )); then
			agnor_prompt_raw_segment " ${jobs_count}"
		fi
	fi
}

prompt_context() { # Context: ((ssh) <user>@<hostname> / (screen) <user>@<hostname> / (tmux) <user>@<hostname> / <user>@<hostname>)
	local shell_deep=${(%):-%L}
	[[ shell_deep -gt 1 ]] && agnor_prompt_add_segment black default "${shell_deep}"
	
	if [[ -n $SSH_CONNECTION ]] || [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		agnor_prompt_add_segment black yellow "(ssh) %(!..%{%F{default}%})${USERNAME}@%m"
	elif [[ -n $STY ]]; then
		agnor_prompt_add_segment black white "(screen) %(!.%{%F{yellow}%}.)${USERNAME}@%m"
	elif [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			agnor_prompt_add_segment black magenta "(tmux@${session_name}) %(!.%{%F{yellow}%}.%{%F{default}%})${USERNAME}@%m"
		else
			agnor_prompt_add_segment black magenta "(tmux) %(!.%{%F{yellow}%}.%{%F{default}%})${USERNAME}@%m"
		fi
	elif [[ $USERNAME != $DEFAULT_USER ]]; then
		agnor_prompt_add_segment black white "%(!.%{%F{yellow}%}.)${USERNAME}@%m"
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
	agnor_prompt_add_segment blue white "${icon}${PWD/#$HOME/~}"
}
prompt_dir_lite() { # Dir (Lite): () + (PWD)
	local icon
	[[ ! -w "$PWD" ]] && icon="$(print_icon LOCK_ICON) "
	agnor_prompt_add_segment blue white "${icon}${PWD/#$HOME/~}"
}
prompt_dir_simple() { # Dir (Simple): (PWD)
	agnor_prompt_add_segment blue white "${PWD/#$HOME/~}"
}

prompt_time() { # System time
	agnor_prompt_add_segment black default "$(primt_icon TIME_ICON) %D{%H:%M:%S}"
}
prompt_date() { # System date
	agnor_prompt_add_segment white black "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}

# hg root >/dev/null 2>/dev/null && echo '☿' && return


prompt_async() { # Prompt all async data
	if (( $#AGNOR_ASYNC_SEGMENTS > 0 )); then
		agnor_prompt_raw_segment $AGNOR_ASYNC_SEGMENTS
	fi
}

prompt_newline() {
	agnor_prompt_raw_segment $AGNOR_COMMAND_NL
}
prompt_shell_chars() { # ($ / #) ❯
	agnor_prompt_raw_segment $AGNOR_COMMAND_RAW
	agnor_prompt_raw_segment ' %(!.#.$) ❯'
}


# Git statuses: #  master ☗ tag ↑12 ✔ <B>  |>  12… 3•1± 3‒1± 12✚ ⚑  |>  origin ↓2
	# - Branch () or detached head (➦)
	# - Dirty working directory state (orange (dirty) / green (✔))
	# - Current branch / SHA1 in detached head state
	# - Remote branch name (if you're tracking a remote branch)
	# - Number of commit ahead HEAD and behind remote tracking branch (remote tracking segment will be magenta if merge/rebase is needed)
	# - Stashes count
	# - <B> - Bisect state on the current branch
	# - >M< - Merge state on the current branch
	# - >R> - Rebase state on the current branch
prompt_async_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]; then
		local dirty=$(agnor_parse_git_dirty)
		
		if [[ AGNOR_GIT_SHOW_SEGMENT_STASH != false ]]; then
			local stashes=$(git stash list -n1 | wc -l)
			if [[ stashes -ne 0 ]]; then
				agnor_async_prompt_add_segment white black "+$stashes$(print_icon ETC_ICON)" # ⚙
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
			agnor_async_prompt_add_segment red white # diverged state
		elif [[ AGNOR_GIT_SHOW_SEGMENT_REMOTE == false && behind -ne 0 ]]; then
			agnor_async_prompt_add_segment magenta white # merge/rebase is needed
		elif [[ -n $dirty ]]; then
			agnor_async_prompt_add_segment yellow black
		else
			agnor_async_prompt_add_segment green white # black
		fi
		
		agnor_async_prompt_raw_segment "${ref_symbol} ${ref}"
		
		local tag=$(git describe --exact-match --tags 2> /dev/null)
		[[ -n $tag ]] && agnor_async_prompt_raw_segment " ☗ ${tag}"
		
		[[ ahead -ne 0 ]] && agnor_async_prompt_raw_segment " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ AGNOR_GIT_SHOW_SEGMENT_REMOTE == false && behind -ne 0 ]] && agnor_async_prompt_raw_segment " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		
		[[ ! -n $dirty ]] && agnor_async_prompt_raw_segment " $(print_icon OK_ICON)" # ✔
		
		local git_dir=$(git rev-parse --git-dir 2>/dev/null)
		if [[ -e "${git_dir}/BISECT_LOG" ]]; then # Modes
			agnor_async_prompt_raw_segment " <B>"
		elif [[ -e "${git_dir}/MERGE_HEAD" ]]; then
			agnor_async_prompt_raw_segment " >M<"
		elif [[ -e "${git_dir}/rebase" || -e "${git_dir}/../.dotest" ]]; then
			agnor_async_prompt_raw_segment " >R>"
		elif [[ -e "${git_dir}/rebase-merge" ]]; then
			if [[ -e "${git_dir}/rebase-merge/interactive" ]]; then
				agnor_async_prompt_raw_segment " >R[i]>"
			else
				agnor_async_prompt_raw_segment " >R[m]>"
			fi
		elif [[ -e "${git_dir}/rebase-apply" ]]; then
			if [[ -e "${git_dir}/rebase-apply/rebasing" ]]; then
				agnor_async_prompt_raw_segment " >R>"
			elif [[ -e "${git_dir}/rebase-apply/applying" ]]; then
				agnor_async_prompt_raw_segment " <A<"
			else
				agnor_async_prompt_raw_segment " <A</>R>"
			fi
		elif [[ -e "${git_dir}/CHERRY_PICK_HEAD" ]]; then
			agnor_async_prompt_raw_segment " <C<"
		elif [[ -e "${git_dir}/REVERT_HEAD" ]]; then
			agnor_async_prompt_raw_segment " [Revert]"
		elif local result=$(local todo; if [[ -r "${git_dir}/sequencer/todo" ]] && read todo < "${git_dir}/sequencer/todo"; then
				case "$todo" in (p[\ \	]|pick[\ \	]*) echo -n "<C<" ;; (revert[\ \	]*) echo -n "[Revert]" ;; esac
			fi) && [[ -n ${result} ]]; then
			# see if a cherry-pick or revert is in progress, if the user has committed a
			# conflict resolution with 'git commit' in the middle of a sequence of picks or
			# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read the todo file.
			agnor_async_prompt_raw_segment " ${result}"
		fi
		
		(){
			local porcelain=$(git status --porcelain 2> /dev/null)
			
			local num_untracked=$(echo $porcelain | grep -c "^??")
			[[ num_untracked -gt 0 ]] && agnor_async_prompt_raw_segment " $num_untracked\u2026"

			local num_added=$(echo $porcelain | grep -c "^A")
			[[ num_added -gt 0 ]] && agnor_async_prompt_raw_segment " $num_added✚"

			local modified num_modified=$(echo $porcelain | grep -c "^.M") num_cached_modified=$(echo $porcelain | grep -c "^M") num_cached_renamed=$(echo $porcelain | grep -c "^R")
			[[ num_modified -gt 0 ]] && modified=" $num_modified\u2022" # • ●
			[[ num_cached_modified -gt 0 || num_cached_renamed -gt 0 ]] && modified="${modified:= •}$((num_cached_modified+num_cached_renamed))±"
			agnor_async_prompt_raw_segment ${modified}

			local deleted num_deleted=$(echo $porcelain | grep -c "^.D") num_cached_deleted=$(echo $porcelain | grep -c "^D")
			[[ num_deleted -gt 0 ]] && deleted=" $num_deleted‒"
			[[ num_cached_deleted -gt 0 ]] && deleted="${deleted:= -}$num_cached_deleted±"
			agnor_async_prompt_raw_segment ${deleted}
			
			[[ num_added -gt 0 || num_cached_modified -gt 0 || num_cached_deleted -gt 0 ]] && agnor_async_prompt_raw_segment ' ⚑'
		}
		
		if [[ AGNOR_GIT_SHOW_SEGMENT_REMOTE != false && -n ${remote} ]]; then
			if [[ $behind -ne 0 ]]; then
				agnor_async_prompt_add_segment magenta white # merge/rebase is needed
			else
				agnor_async_prompt_add_segment cyan black
			fi
			agnor_async_prompt_raw_segment "\uE0A0 ${remote}" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && agnor_async_prompt_raw_segment " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		fi
		
	elif [[ $(git rev-parse --is-inside-git-dir 2>/dev/null) == true ]]; then
		if [[ $(git rev-parse --is-bare-repository) == true ]]; then
			agnor_prompt_add_segment cyan black "bare repo"
		else
			agnor_prompt_add_segment cyan black "GIT_DIR!"
		fi
	fi
}
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

	agnor_prompt_add_segment cyan $fg "⏏ $remote $remote_status"
}
prompt_async_bzr() { # Bzr: (bzr@<revision> ✚)
	(( $+commands[bzr] )) || return
	if ( bzr status -q >/dev/null 2>&1 ); then
		# local revision=$(bzr log | head -n2 | tail -n1 | sed 's/^revno: //')
		#[[ -z $revision ]] && revision='0'
		local revision=$(bzr revno)
		local bzr_status=$(bzr status | head -n1)
		if (( $(echo $bzr_status | grep "modified" | wc -m) > 0 )); then
			agnor_async_prompt_add_segment yellow black "bzr@${revision} ✚"
		elif (( $(echo $bzr_status | wc -m) > 0 )); then
			agnor_async_prompt_add_segment yellow black "bzr@${revision}"
		else
			agnor_async_prompt_add_segment green white "bzr@${revision}"
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
				agnor_async_prompt_add_segment red white
				dirty='±'
			elif [[ -n $(hg prompt "{status|modified}") ]]; then # any modification
				agnor_async_prompt_add_segment yellow black
				dirty='±'
			else # working copy is clean
				agnor_async_prompt_add_segment green white
			fi
			# $'\u263F' # ☿ # VCS_BOOKMARK_ICON
			agnor_async_prompt_raw_segment $(hg prompt "☿ {rev}@{branch}") $dirty
		else
			local rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
			local branch=$(hg id -b 2>/dev/null)
			if $(hg st | grep -q "^\?"); then # files are not added
				agnor_async_prompt_add_segment red white
				dirty='±'
			elif $(hg st | grep -q "^[MA]"); then # any modification
				agnor_async_prompt_add_segment yellow black
				dirty='±'
			else
				agnor_async_prompt_add_segment green white
			fi
			agnor_async_prompt_raw_segment "☿ ${rev}@${branch} ${dirty}"
		fi
	fi
}
# CVS,.svn

function build_prompt() {
	RETVAL=$?
	RETVALS=( "$pipestatus[@]" )
	AGNOR_SEGMENTS=()
	
	prompt_retval_status
	prompt_root_status
	prompt_jobs_status
	# prompt_virtualenv
	# prompt_aws
	prompt_context
	
	prompt_dir
	prompt_async # GIT
	
	prompt_newline
	prompt_shell_chars
	
	agnor_prompt_segments
}

function agnor_setup(){ # Setup
	autoload -Uz add-zsh-hook
	AGNOR_ASYNC_NEEDED=${AGNOR_ASYNC_NEEDED:-true}
	AGNOR_GIT_SHOW_SEGMENT_REMOTE=${AGNOR_GIT_SHOW_SEGMENT_REMOTE:-true}
	AGNOR_GIT_SHOW_SEGMENT_STASH=${AGNOR_GIT_SHOW_SEGMENT_STASH:-true}
	
	function agnor_async_response() {
		local ASYNC_DATA="$(<&$1)"
		if [[ -n $ASYNC_DATA ]]; then
			AGNOR_ASYNC_SEGMENTS=("${(f)ASYNC_DATA}")
			zle && zle reset-prompt
		fi
		zle -F $1
		exec {1}<&-
	}
	
	local start_time=$SECONDS
	function agnor_hook_preexec() {
		start_time=$SECONDS
	}
	function agnor_hook_precmd() {
		# Async
		AGNOR_ASYNC_SEGMENTS=()
		if [[ $AGNOR_ASYNC_NEEDED == true ]]; then
			[[ -n $AGNOR_ASYNC_FD ]] && zle -F $AGNOR_ASYNC_FD 2>/dev/null
			exec {AGNOR_ASYNC_FD}< <(
				prompt_async_git
				# prompt_async_bzr
				# prompt_async_hg
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
				print -P "%B%F{red}>>> elapsed time ${timer_hours}h ${timer_minutes}m ${timer_seconds}s%b%f"
			elif [[ elapsed_time -ge 60 ]]; then
				local timer_minutes=$(( elapsed_time / 60 ))
				local timer_seconds=$(( elapsed_time % 60 ))
				print -P "%B%F{yellow}>>> elapsed time ${timer_minutes}m ${timer_seconds}s%b%f"
			elif [[ elapsed_time -gt 10 ]]; then
				print -P "%B%F{green}>>> elapsed time ${elapsed_time}s%b%f"
			fi
			start_time=0
		fi
	}
	add-zsh-hook preexec agnor_hook_preexec
	add-zsh-hook precmd agnor_hook_precmd
	
	TRAPWINCH() { # Ensure that the prompt is redrawn when the terminal size changes.
		zle && { zle reset-prompt; zle -R }
	}
	
	RPROMPT='%y'
	
	PROMPT='%{%f%b%k%}$(build_prompt) '
	PROMPT2='%(1_.%_.-)> '
	PROMPT3='#?> '
	#PROMPT4='+ %N:%i>'
	typeset -g agnor_prompt4_fix_symbol='%e'
	PROMPT4='%F{yellow}${(l:${(S%)agnor_prompt4_fix_symbol}::+:)} %F{blue}%N%F{242}:%i:%I>%f '
	
	#TIMEFMT=$'%J:\n%U user %S system %P cpu %E total'
	TIMEFMT=$'%J:\n    user:\t%U\n    system:\t%S\n    total:\t%E\n    cpu:\t%P'
	# SPROMPT="Correct '%R' to '%r' [nyae]?"
	SPROMPT="%{%F{yellow}%B%}[ZSH]: Correct '%{%F{red}%B%}%R%{%f%b%}%{%F{yellow}%B%}' to '%{%F{green}%b%}%r%{%f%}%{%F{yellow}%B%}' [nyae]? %f"
	
	# POSTEDIT=`echotc se`

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
