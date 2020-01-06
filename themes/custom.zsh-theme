FONT_MODE=nf
source $ZSH/themes/agnor-base.zsh-theme

function all_lines() {
	echo "$1" | grep -v "^$" | wc -l
}
function count_lines() {
	echo "$1" | egrep -c "^$2"
}
git_details() {
	num_changed=$(( $( all_lines "$gitstatus" ) - $( count_lines "$gitstatus" U ) ))
	num_conflicts=$( count_lines "$staged_files" U )
	num_staged=$(( $( all_lines "$staged_files" ) - num_conflicts ))
	num_untracked=$( git ls-files --others --exclude-standard $(git rev-parse --show-cdup) | wc -l )




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
	
	gitstatus=$( LC_ALL=C git status ${_ignore_submodules} --untracked-files="${__GIT_PROMPT_SHOW_UNTRACKED_FILES:-normal}" --porcelain --branch )
	
	num_staged=0
	num_changed=0
	num_conflicts=0
	num_untracked=0
	while IFS='' read -r line || [[ -n "${line}" ]]; do
		status="${line:0:2}"
		while [[ -n ${status} ]]; do
			case "${status}" in
				#two fixed character matches, loop finished
				\#\#) branch_line="${line/\.\.\./^}"; break ;;
				\?\?) ((num_untracked++)); break ;;
				U?) ((num_conflicts++)); break ;;
				?U) ((num_conflicts++)); break ;;
				DD) ((num_conflicts++)); break ;;
				AA) ((num_conflicts++)); break ;;
				# two character matches, first loop
				?M) ((num_changed++)) ;;
				?D) ((num_changed++)) ;;
				?\ ) ;;
				# single character matches, second loop
				U) ((num_conflicts++)) ;;
				\ ) ;;
				*) ((num_staged++)) ;;
			esac
			status="${status:0:(${#status}-1)}"
		done
	done <<< "${gitstatus}"
}

: "
const statusRegex = /^([AMRDC]|\?\?)\s+([\w\d\/\.\-_]+)/;
export default (output) => {
  if (typeof output !== 'string') return;

  let statuses = {
    modified: [],
    added: [],
    deleted: [],
    renamed: [],
    copied: [],
    untracked: []
  };

  const keys = {
    'M': 'modified',
    'A': 'added',
    'D': 'deleted',
    'R': 'renamed',
    'C': 'copied',
    '??': 'untracked'
  };

  forEach(output.split('\n'), (status) => {
    const statusParts = statusRegex.exec(status.trim());
    statuses[keys[statusParts[1]]].push(statusParts[2]);
  });

  return statuses;
};
"
: '
func parseLine(line string) {
	switch line[:2] {

	// match branch and origin
	case "##":
		parseBranchinfo(line)

	// untracked files
	case "??":
		Git.untracked++

	case "MM":
		fallthrough
	case "AM":
		fallthrough
	case "RM":
		fallthrough
	case "CM":
		fallthrough
	case " M":
		Git.modified++
		Git.dirty++

	case "MD":
		fallthrough
	case "AD":
		fallthrough
	case "RD":
		fallthrough
	case "CD":
		fallthrough
	case " D":
		Git.deleted++
		Git.dirty++

	// changes in the index
	case "M ":
		Git.modified++
	case "A ":
		Git.added++
	case "D ":
		Git.deleted++
	case "R ":
		Git.renamed++
	case "C ":
		Git.copied++

	case "DD":
		fallthrough
	case "AU":
		fallthrough
	case "UD":
		fallthrough
	case "UA":
		fallthrough
	case "DU":
		fallthrough
	case "AA":
		fallthrough
	case "UU":
		Git.unmerged++
	}
}
'

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
function build_prompt000() {
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

			local will_rebase=$(git config --get branch.${current_branch}.rebase 2> /dev/null)
		fi
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
