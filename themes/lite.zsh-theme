source $ZSH/themes/base.zsh-theme

build_prompt() {
	RETVAL=$?
	
	prompt_retval_status_lite
	prompt_root_status
	prompt_jobs_status
	prompt_context
	prompt_dir
	prompt_dir_rw_status_lite
	prompt_git
	prompt_end
	
	prompt_end_chars
}
