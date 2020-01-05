FONT_MODE=nf
source $ZSH/themes/agnor-base.zsh-theme

function all_lines() {
	echo "$1" | grep -v "^$" | wc -l
}
function count_lines() {
	echo "$1" | egrep -c "^$2"
}
git_details() {
	gitstatus=`git diff --name-status 2>&1`
	staged_files=`git diff --staged --name-status`
	
	staged=$(( `all_lines "$staged_files"` - num_conflicts ))
	if [[ $staged -ne "0" ]]; then
		prompt_segment blue white "\u25CF ${staged}" # ● # VCS_STAGED_ICON
	fi
	untracked=`git status -s -uall | grep -c "^??"`
	if [[ $untracked -ne "0" ]]; then
		prompt_segment green white "\u271A ${untracked}" # ✚ # VCS_UNSTAGED_ICON
	fi
	deleted=$(( `all_lines "$gitstatus"` - `count_lines "$gitstatus" U` - `count_lines "$gitstatus" M` ))
	if [[ $deleted -ne "0" ]]; then
		prompt_segment red white "- ${deleted}"
	fi
	changed=$(( `all_lines "$gitstatus"` - `count_lines "$gitstatus" U` - `count_lines "$gitstatus" D`))
	if [[ $changed -ne "0" ]]; then
		prompt_segment magenta white "~ ${changed}"
	fi
	conflict=`count_lines "$staged_files" U`
	if [[ $conflict -ne "0" ]]; then
		prompt_segment red white "✖ ${conflict}"
	fi
}

build_prompt() {
	RETVAL=$?
	RETVALS=( "$pipestatus[@]" )
	
	prompt_retval_status
	prompt_root_status
	prompt_jobs_status
	# prompt_virtualenv
	# prompt_aws
	# prompt_tmux_context
	prompt_context
	
	prompt_dir
	prompt_git
	# prompt_bzr
	# prompt_hg
	prompt_newline
	
	prompt_end_chars
}
