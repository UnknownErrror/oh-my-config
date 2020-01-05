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
	[[ -n $(git status ${FLAGS} 2>/dev/null | tail -n1) ]] && echo '*'
}
prompt_git_def() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local dirty=$(agnor_parse_git_dirty)
		local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
		fi
		local mode repo_path=$(git rev-parse --git-dir 2>/dev/null)
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




prompt_git() { # «»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
	local modified untracked added deleted stashed

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local git_status=$(git status --porcelain 2> /dev/null)
		
		local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

		local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}") # new untracked files preceeded by their number
		# [[ $number_of_untracked_files -gt 0 ]] && untracked=" $number_of_untracked_files◆"
		[[ $number_of_untracked_files -gt 0 ]] && untracked=" $number_of_untracked_files☀"

		local number_added=$(\grep -c "^A" <<< "${git_status}") # added files from the new untracked ones preceeded by their number
		[[ $number_added -gt 0 ]] && added=" $number_added✚"

		local number_modified=$(\grep -c "^.M" <<< "${git_status}") # modified files preceeded by their number
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

		local number_deleted=$(\grep -c "^.D" <<< "${git_status}") # deleted files preceeded by their number
		if [[ $number_deleted -gt 0 ]]; then
			deleted=" $number_deleted‒"
		fi
		local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
		if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
			deleted="$deleted$number_added_deleted±"
		elif [[ $number_added_deleted -gt 0 ]]; then
			deleted=" ‒$number_added_deleted±"
		fi
		## ±	added files from the modifies or delete ones preceeded by their number
		
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀  ●1±
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1±  ‒1±
		
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1± 3‒1± 12✚ ⚑
		#           master                           12☀ 3●1± 3‒1± 12✚
		
		
		# |> +2
		#  master ·↑12 ● ✚ <B>             ||>  origin ·↓2
		
		#  master ☗ tag ↑12 ✔ <B>    ||>  ● ✚      ||>  origin ·↓2
		
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
			# local stashes=$(git rev-list --walk-reflogs --count refs/stash 2>/dev/hull)
			# local stashes=$(git rev-parse --verify --quiet refs/stash 2>/dev/hull)
			# local stashes=$(git stash list -n 1 | wc -l)
			if [[ stashes -ne 0 ]]; then
				prompt_segment white black "+$stashes$(print_icon ETC_ICON)" # ⚙
			fi
		fi
		
		local ref_symbol ref=$(git symbolic-ref HEAD 2>/dev/null)
		if [[ -z $ref ]]; then
			ref=$(git rev-parse --short HEAD 2>/dev/null) || return 1
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
		
		# local remote="${$(git rev-parse --symbolic-full-name --verify @{upstream} 2>/dev/null)/refs\/remotes\/}"
		# local remote="$(git rev-parse --abbrev-ref --verify @{upstream} 2>/dev/null)"
		local remote="$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)"
		local ahead behind
		if [[ -n ${remote} ]]; then
			remote="${remote/\/$ref/}"
			# ahead=$(git rev-list @{upstream}..HEAD 2>/dev/null | wc -l)
			ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
			behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
		fi
		
		if [[ $behind -ne 0 ]] && [[ $ahead -ne 0 ]]; then
			prompt_segment red white # diverged state
		elif [[ ${SHOW_GIT_SEGMENT_REMOTE} == false && $behind -ne 0 ]]; then
			prompt_segment magenta white # merge/rebase is needed
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
		
		local tag=$(git describe --exact-match --tags 2> /dev/null)
		[[ -n $tag ]] && echo -n " ☗ $tag"
		
		[[ $ahead -ne "0" ]] && echo -n " \u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		[[ ${SHOW_GIT_SEGMENT_REMOTE} == false && $behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		
		[[ ! -n $dirty ]] && echo -n " $(print_icon OK_ICON)" # ✔
		
		echo -n "${mode}"
		
		prompt_segment yellow black "${vcs_info_msg_0_%% }"
		
		if [[ ${SHOW_GIT_SEGMENT_REMOTE} != false && -n ${remote} ]]; then
			if [[ $behind -ne 0 ]]; then
				prompt_segment magenta white # merge/rebase is needed
			else
				prompt_segment cyan black
			fi
			echo -n "\uE0A0 $remote" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && echo -n " \u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		fi
		
		prompt_segment green default
		# see if a cherry-pick or revert is in progress, if the user has committed a
		# conflict resolution with 'git commit' in the middle of a sequence of picks or
		# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read the todo file.
		__git_sequencer_status() {
			local todo
			if [[ -e "${repo_path}/CHERRY_PICK_HEAD" ]]; then
				echo -n ">ChP<"
			elif [[ -e "${repo_path}/REVERT_HEAD" ]]; then
				echo -n "<R<"
			elif [[ -r "${repo_path}/sequencer/todo" ]] && read todo < "${repo_path}/sequencer/todo"; then
				case "$todo" in
					p[\ \	]|pick[\ \	]*)
						echo -n ">ChP<" ;;
					revert[\ \	]*)
						echo -n "<R<" ;;
				esac
			fi
		}
		if [[ -e "${repo_path}/rebase-merge" ]]; then
			if [[ -e "${repo_path}/rebase-merge/interactive" ]]; then
				echo -n ">R>|i"
			else
				echo -n ">R>|m"
			fi
		elif [[ -e "${repo_path}/rebase-apply" ]]; then
			if [[ -e "${repo_path}/rebase-apply/rebasing" ]]; then
				echo -n ">R>"
			elif [[ -e "${repo_path}/rebase-apply/applying" ]]; then
				echo -n ">R>|AM"
			else
				echo -n ">R>|AM/REBASE"
			fi
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			echo -n ">M<"
		elif local s=$(__git_sequencer_status) && [[ $s != "" ]]; then
			echo -n "$s"
		elif [[ -e "${repo_path}/BISECT_LOG" ]]; then
			echo -n "<B>"
		fi
		
	elif [[ $(git rev-parse --is-inside-git-dir 2>/dev/null) == true ]]; then
		# if [[ $(git rev-parse --is-shallow-repository) == true ]]; then
		if [[ $(git rev-parse --is-bare-repository) == true ]]; then
			prompt_segment cyan black "BARE REPO"
		else
			prompt_segment cyan black "GIT_DIR!"
		fi
	fi
	# ···
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


: '
isChanged :: MiniStatus -> Bool
isChanged (MkMiniStatus index work) =
		work == 'M' || (work == 'D' && index /= 'D')

isStaged :: MiniStatus -> Bool
isStaged (MkMiniStatus index work) =
		(index `elem` "MRC") || (index == 'D' && work /= 'D') || (index == 'A' && work /= 'A')

isConflict :: MiniStatus -> Bool
isConflict (MkMiniStatus index work) =
		index == 'U' || work == 'U' || (index == 'A' && work == 'A') || (index == 'D' && work == 'D')

isUntracked :: MiniStatus -> Bool
isUntracked (MkMiniStatus index _) =
		index == '?'

'


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
            local git_status="$(git status --porcelain 2> /dev/null)"
            
            if [[ $git_status =~ ($'\n'|^).M ]]; then local has_modifications=true; fi
            if [[ $git_status =~ ($'\n'|^)M ]]; then local has_modifications_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)A ]]; then local has_adds=true; fi
            if [[ $git_status =~ ($'\n'|^).D ]]; then local has_deletions=true; fi
            if [[ $git_status =~ ($'\n'|^)D ]]; then local has_deletions_cached=true; fi
            if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=true; fi

            local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
            if [[ $number_of_untracked_files -gt 0 ]]; then local has_untracked_files=true; fi

            if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then local should_push=true; fi
        
            local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)
        
            local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
            if [[ $number_of_stashes -gt 0 ]]; then local has_stashes=true; fi
        fi
    fi
    
    echo "$(custom_build_prompt ${enabled:-true} ${current_commit_hash:-""} ${is_a_git_repo:-false} ${current_branch:-""} ${detached:-false} ${just_init:-false} ${has_upstream:-false} ${has_modifications:-false} ${has_modifications_cached:-false} ${has_adds:-false} ${has_deletions:-false} ${has_deletions_cached:-false} ${has_untracked_files:-false} ${ready_to_commit:-false} ${tag_at_current_commit:-""} ${is_on_a_tag:-false} ${has_upstream:-false} ${commits_ahead:-false} ${commits_behind:-false} ${has_diverged:-false} ${should_push:-false} ${will_rebase:-false} ${has_stashes:-false} ${action})"
    
}