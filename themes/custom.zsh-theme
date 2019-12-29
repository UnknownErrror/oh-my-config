source $ZSH/themes/base.zsh-theme

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
	prompt_dir_rw_status
	prompt_git
	# prompt_bzr
	# prompt_hg
	prompt_end
	
	prompt_end_chars
}
