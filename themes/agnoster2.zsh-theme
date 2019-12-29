### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

case ${SOLARIZED_THEME:-dark} in
	light) CURRENT_FG='white' ;;
	*)     CURRENT_FG='black' ;;
esac

# Special Powerline characters
() {
	local LC_ALL="" LC_CTYPE="en_US.UTF-8"
	SEGMENT_SEPARATOR=$'\ue0b0' # Do not change this!
}

# Begin a segment
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

# End the prompt, closing any open segments
prompt_end() {
	if [[ -n $CURRENT_BG ]]; then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# [FREEZE] Virtualenv: (CW VIRTUAL_ENV)
prompt_virtualenv() {
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		prompt_segment blue black "(`basename $virtualenv_path`)"
	fi
}
# [FREEZE] AWS Profile: (Current AWS_PROFILE, yellow on red if production, black on green otherwise) (☁️ $AWS_PROFILE)
prompt_aws() {
	[[ -z "$AWS_PROFILE" ]] && return
	case "$AWS_PROFILE" in
		*-prod|*production*) prompt_segment red   yellow "☁️ $AWS_PROFILE" ;; # - profile contains 'production' or ends in '-prod' # [MOD]
		*)                   prompt_segment green black  "☁️ $AWS_PROFILE" ;; # [MOD]
	esac
}

# Status: (Error) (✘ YYY, ✔)
prompt_status_retval() {
	if [[ $RETVAL > 0 ]]; then
		if (( $RETVAL <= 128 )); then
			prompt_segment red white "✘ $RETVAL"
		else
			local sig=$(( $RETVAL - 128 ))
			local idx=$(( sig + 1 ))
			prompt_segment red white "✘ SIG${signals[$idx]}(${sig})"
		fi
	else
		prompt_segment green white "✔"
	fi
}
# Status: (Root) (⚡)
prompt_status_root() {
	if [[ $UID -eq 0 ]]; then #
		prompt_segment black default "%{%F{yellow}%}⚡"
	fi
}
# Status: (Jobs) (YYY ⚙)
prompt_status_jobs() {
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
# Context: (who am I and where am I) (user@hostname)
prompt_tmux_context() {
	if [[ -n $TMUX ]]; then
		local session_name="$(tmux display-message -p '#S')"
		if [[ -n $session_name ]]; then
			prompt_segment black default "%{%F{magenta}%}tmux@$session_name"
		else
			prompt_segment black default "%{%F{magenta}%}tmux"
		fi
	fi
}
prompt_context() {
	if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m (ssh)"
	elif [[ "$USER" != "$DEFAULT_USER" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m" # [MOD]
	fi
}
# Dir: (CWD) (~, /, ~/a/b/c/, ...)
prompt_dir() {
	prompt_segment blue $CURRENT_FG '%~'
}
# Dir: (CWD.isWritable)
prompt_dir_writable() {
	if [[ ! -w "$PWD" ]]; then
		prompt_segment red yellow1 $'\UE0A2'
	fi
}

# Git: branch/detached head, dirty status
prompt_git() {
	(( $+commands[git] )) || return
	if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
		return
	fi
	local PL_BRANCH_CHAR
	() {
		local LC_ALL="" LC_CTYPE="en_US.UTF-8"
		PL_BRANCH_CHAR=$'\ue0a0' # 
	}
	local ref dirty mode repo_path

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		repo_path=$(git rev-parse --git-dir 2>/dev/null)
		dirty=$(parse_git_dirty)
		ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green $CURRENT_FG
		fi

		if [[ -e "${repo_path}/BISECT_LOG" ]]; then
			mode=" <B>"
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			mode=" >M<"
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
			mode=" >R>"
		fi

		setopt promptsubst
		autoload -Uz vcs_info

		zstyle ':vcs_info:*' enable git
		zstyle ':vcs_info:*' get-revision true
		zstyle ':vcs_info:*' check-for-changes true
		zstyle ':vcs_info:*' stagedstr '✚'
		zstyle ':vcs_info:*' unstagedstr '●'
		zstyle ':vcs_info:*' formats ' %u%c'
		zstyle ':vcs_info:*' actionformats ' %u%c'
		vcs_info
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
	fi
}
# Bzr
prompt_bzr() {
	(( $+commands[bzr] )) || return
	if (bzr status >/dev/null 2>&1); then
		status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
		status_all=`bzr status | head -n1 | wc -m`
		revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
		if [[ $status_mod -gt 0 ]] ; then
			prompt_segment yellow black
			echo -n "bzr@"$revision "✚ "
		else
			if [[ $status_all -gt 0 ]] ; then
				prompt_segment yellow black
				echo -n "bzr@"$revision
			else
				prompt_segment green black
				echo -n "bzr@"$revision
			fi
		fi
	fi
}
# Mercurial
prompt_hg() {
	(( $+commands[hg] )) || return
	local rev st branch
	if $(hg id >/dev/null 2>&1); then
		if $(hg prompt >/dev/null 2>&1); then
			if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
				# if files are not added
				prompt_segment red white
				st='±'
			elif [[ -n $(hg prompt "{status|modified}") ]]; then
				# if any modification
				prompt_segment yellow black
				st='±'
			else
				# if working copy is clean
				prompt_segment green $CURRENT_FG
			fi
			echo -n $(hg prompt "☿ {rev}@{branch}") $st
		else
			st=""
			rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
			branch=$(hg id -b 2>/dev/null)
			if `hg st | grep -q "^\?"`; then
				prompt_segment red black
				st='±'
			elif `hg st | grep -q "^[MA]"`; then
				prompt_segment yellow black
				st='±'
			else
				prompt_segment green $CURRENT_FG
			fi
			echo -n "☿ $rev@$branch" $st
		fi
	fi
}

# Prompt ending characters ($, #)
prompt_end_chars() { # λ
	echo ''
	if [[ $UID -eq 0 ]]; then
		echo -n ' #'
	else
		echo -n ' $'
	fi
}



## Main prompt
build_prompt() {
	RETVAL=$?
	prompt_status_retval
	prompt_status_root
	prompt_status_jobs
	# prompt_virtualenv
	# prompt_aws
	# prompt_tmux_context
	prompt_context
	prompt_dir
	prompt_dir_writable
	prompt_git
	prompt_bzr
	prompt_hg
	prompt_end
	
	prompt_end_chars
}

PROMPT='%{%f%b%k%}$(build_prompt) '