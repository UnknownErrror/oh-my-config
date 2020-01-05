source $ZSH/themes/agnor-icons.zsh

######################################
### Segment drawing ###
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
CURRENT_RIGHT_BG='NONE'

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
	CURRENT_BG='NONE'
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
	CURRENT_RIGHT_BG='NONE'
}


######################################
### Prompt components ###
# Each component will draw itself, and hide itself if no information needs to be shown


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
	echo -n "%1(j.JOBS%j job%2(j.s.).)"
}

function color256() {
	local red=$1; shift
	local green=$2; shift
	local blue=$3; shift
	echo -n $[$red * 36 + $green * 6 + $blue + 16]
}
function fg256() {
	echo -n $'\e[38;5;'$(color256 "$@")"m"
}
function bg256() {
	echo -n $'\e[48;5;'$(color256 "$@")"m"
}

prompt_context() { # Context: ((ssh) <user>@<hostname> / <user>@<hostname>) # [EX]
	local shell_deep=${(%):-%L}
	if [[ shell_deep -gt 1 ]] && prompt_segment black default "$shell_deep"
	
	if [[ -n $SSH_CONNECTION ]] || [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		prompt_segment black yellow "(ssh) %(!..%{%F{default}%})$USER@%m" # "$(print_icon SSH_ICON)"
	elif [[ -n $STY ]]; then
		prompt_segment black default "(screen) %(!.%{%F{yellow}%}.)$USER@%m"
	elif [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			prompt_segment black magenta "(tmux@$session_name) %(!.%{%F{yellow}%}.%{%F{default}%})$USER@%m"
		else
			prompt_segment black magenta "(tmux) %(!.%{%F{yellow}%}.%{%F{default}%})$USER@%m"
		fi
	elif [[ $USER != $DEFAULT_USER ]]; then
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
	prompt_segment white black "$(print_icon DATE_ICON) %D{%d.%m.%y}"
}

# Configurable: DISABLE_UNTRACKED_FILES_DIRTY, GIT_STATUS_IGNORE_SUBMODULES
function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ ${DISABLE_UNTRACKED_FILES_DIRTY} == true ]] && FLAGS+='--untracked-files=no'
	[[ ${GIT_STATUS_IGNORE_SUBMODULES} != "git" ]] && FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	[[ -n $(git status ${FLAGS} 2>/dev/null | tail -n1) ]] && echo '*'
}

prompt_git() { # «»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
	local modified untracked added deleted

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local porcelain=$(git status --porcelain 2> /dev/null)
		
		local untracked num_untracked=$(echo $porcelain | grep -c "^??")
		[[ $num_untracked -gt 0 ]] && untracked=" $num_untracked\u2026"
		echo ${untracked}

		local added num_added=$(echo $porcelain | grep -c "^A")
		[[ $num_added -gt 0 ]] && added=" $num_added✚"
		echo ${added}

		local modified num_modified=$(echo $porcelain | grep -c "^.M") num_added_modified=$(echo $porcelain | grep -c "^M") num_added_renamed=$(echo $porcelain | grep -c "^R")
		# [[ $num_modified -gt 0 ]] && modified=" $num_modified●"
		[[ $num_modified -gt 0 ]] && modified=" $num_modified\u2022" # •
		[[ $num_added_modified -gt 0 || $num_added_renamed -gt 0 ]] && modified="${modified:= •}$((num_added_modified+num_added_renamed))±"
		echo ${modified}

		local deleted num_deleted=$(echo $porcelain | grep -c "^.D") num_added_deleted=$(echo $porcelain | grep -c "^D")
		[[ $num_deleted -gt 0 ]] && deleted=" $num_deleted‒"
		[[ $num_added_deleted -gt 0 ]] && deleted="${deleted:= -}$num_added_deleted±"
		echo ${deleted}
		
		if [[ $num_added -gt 0 || $num_added_modified -gt 0 || $num_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi
		
		## ±	added files from the modifies or delete ones preceeded by their number
		
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12… 3●1± 3‒1± 12✚ ⚑
		#           master                        12… 3●1± 3‒1± 12✚
		#           master                        12… 3•1± 3‒1± 12✚
		
		# |> +2
		#  master ☗ tag ↑12 ✔ <B>      |>      ● ✚      |>      origin ↓2
		
		print -n "${ref/refs\/heads\//$PL_BRANCH_CHAR}$untracked$modified$deleted$added"
	fi
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

(( $+parameters[SHOW_GIT_SEGMENT_REMOTE] )) || SHOW_GIT_SEGMENT_REMOTE=true # default value
(( $+parameters[SHOW_GIT_SEGMENT_STASH] ))  || SHOW_GIT_SEGMENT_STASH=true # default value
prompt_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]; then
		local dirty=$(agnor_parse_git_dirty)
		
		if [[ $SHOW_GIT_SEGMENT_STASH != false ]]; then
			local stashes=$(git stash list | wc -l)
			# local stashes=$(git stash list -n1 | wc -l)
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
		
		if [[ $behind -ne 0 ]] && [[ $ahead -ne 0 ]]; then # [EXPERIMENT]
			prompt_segment red white # diverged state
		elif [[ ${SHOW_GIT_SEGMENT_REMOTE} == false && $behind -ne 0 ]]; then
			prompt_segment magenta white # merge/rebase is needed
		elif [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green white # black
		fi
		
		echo -n "${ref_symbol} ${ref}"
		
		local tag=$(git describe --exact-match --tags 2> /dev/null)
		[[ -n $tag ]] && echo -n " ☗ ${tag}"
		
		[[ $ahead -ne "0" ]] && echo -n " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ ${SHOW_GIT_SEGMENT_REMOTE} == false && $behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		
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
				echo -n " >R[rebase]>"
			elif [[ -e "${git_dir}/rebase-apply/applying" ]]; then
				echo -n " >R[am]>"
			else
				echo -n " >R[am/rebase]>"
			fi
		elif [[ -e "${git_dir}/CHERRY_PICK_HEAD" ]]; then
			echo -n " [CherryPick]"
		elif [[ -e "${git_dir}/REVERT_HEAD" ]]; then
			echo -n " [Revert]"
		elif local result=$(local todo; if [[ -r "${git_dir}/sequencer/todo" ]] && read todo < "${git_dir}/sequencer/todo"; then
				case "$todo" in (p[\ \	]|pick[\ \	]*) echo -n "[CherryPick]" ;; (revert[\ \	]*) echo -n "[Revert]" ;; esac
			fi) && [[ -n ${result} ]]; then
			# see if a cherry-pick or revert is in progress, if the user has committed a
			# conflict resolution with 'git commit' in the middle of a sequence of picks or
			# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read the todo file.
			echo -n " ${result}"
		fi
		
		prompt_segment yellow black "${vcs_info_msg_0_%% }"
		
		if [[ ${SHOW_GIT_SEGMENT_REMOTE} != false && -n ${remote} ]]; then
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
}

prompt_git_remotes() {
	eval "remotes=(`git remote | sed 's/\n/ /'`)"
	for remote in $remotes; do
		prompt_git_remote $remote
	done
}
prompt_git_remote() {
	local fg
	local current_branch
	local remote
	local ahead behind
	local remote_status
	local remote=${1:-"origin"}

	fg=black

	current_branch=${$(git rev-parse --abbrev-ref HEAD)}
	remote_path=${$(git rev-parse --verify remotes\/${remote}\/${current_branch} --symbolic-full-name 2> /dev/null)}

	if [[ -n ${remote_path} ]] ; then
		ahead=$(git rev-list ${remote_path}..HEAD 2> /dev/null | wc -l | tr -d ' ')
		behind=$(git rev-list HEAD..${remote_path} 2> /dev/null | wc -l | tr -d ' ')

		if [[ $ahead -eq 0 && $behind -eq 0 ]] ; then
			remote_status="○ "
		else
			if [[ $ahead -gt 0 ]] ; then
				fg=yellow
			fi

			if [[ $behind -gt 0 ]] ; then
				fg=red
			fi

			remote_status="+${ahead} -${behind}"
		fi
	else
		remote_status="--"
	fi

	prompt_segment cyan $fg "⏏ $remote $remote_status"
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
prompt_end_chars() { # Prompt ending characters ($ / #) ❯
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
	
	# if [[ $(tput cols) -ge ${TRIGGER_WIDTH:-100} ]]; then
		# pass
	# fi
	
	prompt_end_chars
}

PROMPT='%{%f%b%k%}$(build_prompt) '

build_right_prompt() {
	prompt_date
	prompt_time
	prompt_right_end
}
# RPROMPT='%{$reset_color%}%{'$'\e[1A''%}%{%f%b%k%}$(build_right_prompt)%{$reset_color%}%{'$'\e[1B''%}'


# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
	zle && { zle reset-prompt; zle -R }
}



POWERLINE_A_COLOR="6" # normal cyan
POWERLINE_B_COLOR='12' # bright blue
POWERLINE_C_COLOR="4" # normal blue



LSCOLORS="cxFxgxhxbxeadaabagDdad" # BSD
LS_COLORS="di=32;40:ln=1;35;40:so=36;40:pi=37;40:ex=31;40:bd=34;40:cd=33;40:su=0;41:sg=0;46:tw=1;33;43:ow=0;43:" # Linux



(){ # Setup
	setopt PROMPT_SUBST
	autoload -Uz vcs_info
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' get-revision true
	zstyle ':vcs_info:*' check-for-changes true
	zstyle ':vcs_info:*' stagedstr $'\u271A' # ✚ # VCS_UNSTAGED_ICON
	zstyle ':vcs_info:*' unstagedstr $'\u25CF' # ● # VCS_STAGED_ICON
	zstyle ':vcs_info:*' formats ' %u%c'
	zstyle ':vcs_info:*' actionformats ' %u%c'
	
	
	
	autoload -Uz add-zsh-hook
	local start_time=$SECONDS
	prompt_agnor_preexec() {
		start_time=$SECONDS
	}
	prompt_agnor_precmd() {
		local timer_result=$(( SECONDS - start_time ))
		if [[ $timer_result -ge 3600 ]]; then
			local timer_hours remainder timer_minutes timer_seconds
			let "timer_hours = $timer_result / 3600"
			let "remainder = $timer_result % 3600"
			let "timer_minutes = $remainder / 60"
			let "timer_seconds = $remainder % 60"
			print -P "%B%F{red}>>> elapsed time ${timer_hours}h${timer_minutes}m${timer_seconds}s%b"
		elif [[ $timer_result -ge 60 ]]; then
			local timer_minutes timer_seconds
			let "timer_minutes = $timer_result / 60"
			let "timer_seconds = $timer_result % 60"
			print -P "%B%F{yellow}>>> elapsed time ${timer_minutes}m${timer_seconds}s%b"
		elif [[ $timer_result -gt 10 ]]; then
			print -P "%B%F{green}>>> elapsed time ${timer_result}s%b"
		fi
		start_time=$SECONDS
		vcs_info
	}
	
	add-zsh-hook preexec prompt_agnor_preexec
	add-zsh-hook precmd prompt_agnor_precmd
}


: "
isChanged :: MiniStatus -> Bool
isChanged (MkMiniStatus index work) =
		work == 'M' || (work == 'D' && index /= 'D')

isStaged :: MiniStatus -> Bool
isStaged (MkMiniStatus index work) =
		(index `elem` \"MRC\") || (index == 'D' && work /= 'D') || (index == 'A' && work /= 'A')

isConflict :: MiniStatus -> Bool
isConflict (MkMiniStatus index work) =
		index == 'U' || work == 'U' || (index == 'A' && work == 'A') || (index == 'D' && work == 'D')

isUntracked :: MiniStatus -> Bool
isUntracked (MkMiniStatus index _) =
		index == '?'
"


function build_prompt000 {
    local prompt=""
    
    # Git info
    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)
    if [[ -n $current_commit_hash ]]; then local is_a_git_repo=true; fi
    
    if [[ $is_a_git_repo == true ]]; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
        if [[ $current_branch == 'HEAD' ]]; then local detached=true; fi

        local number_of_logs="$(git log --pretty=oneline -n1 2> /dev/null | wc -l)"
        if [[ $number_of_logs -eq 0 ]]; then
            local just_init=true
        else
            local porcelain="$(git status --porcelain 2> /dev/null)"
            
            if [[ $porcelain =~ ($'\n'|^).M ]]; then local has_modifications=true; fi
            if [[ $porcelain =~ ($'\n'|^)M ]]; then local has_modifications_cached=true; fi
            if [[ $porcelain =~ ($'\n'|^)A ]]; then local has_adds=true; fi
            if [[ $porcelain =~ ($'\n'|^).D ]]; then local has_deletions=true; fi
            if [[ $porcelain =~ ($'\n'|^)D ]]; then local has_deletions_cached=true; fi
            if [[ $porcelain =~ ($'\n'|^)[MAD] && ! $porcelain =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=true; fi

            local number_of_untracked_files=$(echo $porcelain | grep -c "^??")
            if [[ $number_of_untracked_files -gt 0 ]]; then local has_untracked_files=true; fi

            if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then local should_push=true; fi
        
            local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)
        
            local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
            if [[ $number_of_stashes -gt 0 ]]; then local has_stashes=true; fi
        fi
    fi
    
    echo "$(custom_build_prompt ${enabled:-true} ${current_commit_hash:-""} ${is_a_git_repo:-false} ${current_branch:-""} ${detached:-false} ${just_init:-false} ${has_upstream:-false} ${has_modifications:-false} ${has_modifications_cached:-false} ${has_adds:-false} ${has_deletions:-false} ${has_deletions_cached:-false} ${has_untracked_files:-false} ${ready_to_commit:-false} ${tag_at_current_commit:-""} ${is_on_a_tag:-false} ${has_upstream:-false} ${commits_ahead:-false} ${commits_behind:-false} ${has_diverged:-false} ${should_push:-false} ${will_rebase:-false} ${has_stashes:-false} ${action})"
    
}