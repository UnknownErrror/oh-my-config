FONT_MODE=nf
source $ZSH/themes/agnor-base.zsh-theme

function all_lines() {
  echo "$1" | grep -v "^$" | wc -l ;
}
function count_lines() {
  echo "$1" | egrep -c "^$2" ;
}
git_details() {
  gitstatus=`git diff --name-status 2>&1`
  staged_files=`git diff --staged --name-status`
  
  staged=$(( `all_lines "$staged_files"` - num_conflicts ))
  if [[ $staged -ne "0" ]]; then
      prompt_segment blue white
      echo -n "\u25CF ${staged}" # ● # VCS_STAGED_ICON
  fi
  untracked=`git status -s -uall | grep -c "^??"`
  if [[ $untracked -ne "0" ]]; then
      prompt_segment green white
      echo -n "\u271A ${untracked}" # ✚ # VCS_UNSTAGED_ICON
  fi
  deleted=$(( `all_lines "$gitstatus"` - `count_lines "$gitstatus" U` - `count_lines "$gitstatus" M` ))
  if [[ $deleted -ne "0" ]]; then
      prompt_segment red white
      echo -n "- ${deleted}"
  fi
  changed=$(( `all_lines "$gitstatus"` - `count_lines "$gitstatus" U` - `count_lines "$gitstatus" D`))
  if [[ $changed -ne "0" ]]; then
      prompt_segment magenta white
      echo -n " ${changed}"
  fi
  stashed=`git stash list | wc -l`
  if [[ $stashed -ne "0" ]]; then
      prompt_segment cyan white
      echo -n "⚑ ${stashed}"
  fi
  conflict=`count_lines "$staged_files" U`
  if [[ $conflict -ne "0" ]]; then
      prompt_segment red white
      echo -n "✖ ${conflict}"
  fi
}

git_branch_diff() {
  local merge_name remote_ref
  local branch=`git symbolic-ref HEAD | sed -e 's/refs\/heads\///g'`
  local remote_name=`git config branch.${branch}.remote`
  if [[ -n "$remote_name" ]]; then
    merge_name=`git config branch.${branch}.merge`
  else
    remote_name='origin'
    merge_name="refs/heads/${branch}"
  fi
  if [[ "$remote_name" == '.' ]]; then
    remote_ref="$merge_name"
  else
    remote_ref="refs/remotes/$remote_name/${branch}"
  fi
  if [[ `git remote 2>/dev/null | wc -l` -ne "0" ]]; then
    local revgit=`git rev-list --left-right ${remote_ref}...HEAD`
    local revs=`all_lines "$revgit"`
    local ahead=`count_lines "$revgit" "^>"`
    local behind=$(( revs - ahead ))
    if [[ $ahead -ne "0" ]]; then
        echo -n "·\u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
    fi
    if [[ $behind -ne "0" ]]; then
        echo -n "·\u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
    fi
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
	local ref dirty
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		ZSH_THEME_GIT_PROMPT_DIRTY='±'
		local dirty=$(parse_git_dirty)
		local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
		fi
		local BRANCH_CHAR=$'\uE0A0' #  # VCS_BRANCH_ICON
		echo -n "${ref/refs\/heads\//$BRANCH_CHAR }"
		git_branch_diff
		git_details
		
		local mode
		if [[ -e "${repo_path}/BISECT_LOG" ]]; then
			mode=" <B>"
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			mode=" >M<"
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
			mode=" >R>"
		fi
		echo -n "${mode}"
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
	# prompt_dir_rw_status
	prompt_git
	# prompt_bzr
	# prompt_hg
	prompt_end
	
	prompt_end_chars
}
