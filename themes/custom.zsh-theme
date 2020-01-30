FONT_MODE=nf
source ${0%/*}/agnor-base.zsh-theme

function all_lines() {
	echo "$1" | grep -v "^$" | wc -l
}
function count_lines() {
	echo "$1" | egrep -c "^$2"
}
git_details() {
	gitstatus=`git diff --name-status 2>&1`
	staged_files=`git diff --staged --name-status`
	
	num_changed=$(( $( all_lines "$gitstatus" ) - $( count_lines "$gitstatus" U ) ))
	num_conflicts=$( count_lines "$staged_files" U )
	num_staged=$(( $( all_lines "$staged_files" ) - num_conflicts ))
	num_untracked=$( git ls-files --others --exclude-standard $(git rev-parse --show-cdup) | wc -l )
	
	
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


# if [[ -d ./node_modules ]]; then
	# SYMBOLS+="%{%F{green}%}`node -v 2> /dev/null` "
# fi


parseGitStatus() {
	local line gitstatus=$(git status --porcelain --untracked-files="${AGNOR_GIT_SHOW_UNTRACKED_FILES:-normal}")
	while read -r line; do
		case "${line:0:2}" in
			\#\#) ;; # branch
			\!\!) ;; # ignored
			\?\?) (( num_untracked++ )) ;;
			
			MM) ;; # 2(( num_staged++ )) # 2(( num_changed++ )) # (( num_modified++ )) # (( num_added++ ))
			AM) ;; # 2(( num_staged++ )) # 2(( num_changed++ )) # (( num_modified++ ))
			RM) ;; # 2(( num_staged++ )) # 2(( num_changed++ ))
			CM) ;; # 2(( num_staged++ )) # 2(( num_changed++ ))
			\ M) (( num_modified++ )); (( num_dirty++ )) ;; # 2(( num_changed++ ))
			# \ T) (( num_modified++ )); # ???
			
			MD) ;; # 2(( num_staged++ )) # (( num_changed++ ))
			AD) ;; # 2(( num_staged++ )) # (( num_changed++ )) # (( num_deleted++ ))
			RD) ;; # 2(( num_staged++ )) # (( num_changed++ ))
			CD) ;; # 2(( num_staged++ )) # (( num_changed++ ))
			\ D) (( num_deleted++ )); (( num_dirty++ )) ;; # (( num_changed++ ))
			
			# changes in the index
			M\ ) (( num_modified++ )) ;; # 2(( num_staged++ )) # (( num_added++ ))
			A\ ) (( num_added++ )) ;;    # 2(( num_staged++ ))
			D\ ) (( num_deleted++ )) ;;  # 2(( num_staged++ ))
			R\ ) (( num_renamed++ )) ;;  # 2(( num_staged++ ))
			C\ ) (( num_copied++ )) ;;   # 2(( num_staged++ ))
			
			DD) (( num_conflicts++ )) ;; # (( num_changed++ )) # (( num_staged++ ))
			AU) (( num_conflicts++ )) ;; # 2(( num_staged++ ))
			UD) (( num_conflicts++ )) ;; # (( num_changed++ ))
			UA) (( num_conflicts++ )) ;;
			DU) (( num_conflicts++ )) ;; # 2(( num_staged++ ))
			AA) (( num_conflicts++ )) ;; # (( num_staged++ ))
			UU) (( num_conflicts++ )) ;; # (( num_unmerged++ ))
			
			# U?) (( num_conflicts++ )) ;;
			# ?U) (( num_conflicts++ )) ;;
		esac
	done <<< "${gitstatus}"
}

function build_prompt000() {
	local number_of_logs="$(git log --pretty=oneline -n1 2>/dev/null | wc -l)"
	if [[ number_of_logs -ne 0 ]]; then
		local porcelain="$(git status --porcelain 2>/dev/null)"
		[[ porcelain =~ ($'\n'|^).M ]] && local has_modifications=true
		[[ porcelain =~ ($'\n'|^)M ]]  && local has_modifications_cached=true
		[[ porcelain =~ ($'\n'|^)A ]]  && local has_adds=true
		[[ porcelain =~ ($'\n'|^).D ]] && local has_deletions=true
		[[ porcelain =~ ($'\n'|^)D ]]  && local has_deletions_cached=true
		[[ porcelain =~ ($'\n'|^)[MAD] && ! porcelain =~ ($'\n'|^).[MAD\?] ]] && local ready_to_commit=true
		
		local current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
		local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)
	fi
}

# ' ' - unmodified
# M - modified
# A - added
# D - deleted
# R - renamed
# C - copied
# U - updated, but unmerged
# ? - untracked
# ! - ignored

#         | [AMD] - not updated
# M       | [ MD] - updated in index
# A       | [ MD] - added to index
# D       |       - deleted from index
# R       | [ MD] - renamed in index
# C       | [ MD] - copied in index
# [MARK]  |       - index and worktree matches
# [ MARK] | M     - worktree changed since index
# [ MARK] | D     - deleted in worktree
# [ D]    | R     - renamed in worktree
# [ D]    | C     - copied in worktree
# -----------------------------------------------
# D       | D     - unmerged, both deleted
# A       | U     - unmerged, added by us
# U       | D     - unmerged, deleted by them
# U       | A     - unmerged, added by them
# D       | U     - unmerged, deleted by us
# A       | A     - unmerged, both added
# U       | U     - unmerged, both modified
# -----------------------------------------------
# ?       | ?     - untracked
# !       | !     - ignored

# '+' 'new file: '
# 'x' 'deleted: '
# '!' 'modified: '
# '>' 'renamed: '
# '?' 'Untracked files:'
