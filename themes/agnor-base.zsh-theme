source $ZSH/themes/agnor-icons.zsh


typeset -grA __p9k_colors=(
            black 000               red 001             green 002            yellow 003
             blue 004           magenta 005              cyan 006             white 007
             grey 008            maroon 009              lime 010             olive 011
             navy 012           fuchsia 013              aqua 014              teal 014
           silver 015             grey0 016          navyblue 017          darkblue 018
            blue3 020             blue1 021         darkgreen 022      deepskyblue4 025
      dodgerblue3 026       dodgerblue2 027            green4 028      springgreen4 029
       turquoise4 030      deepskyblue3 032       dodgerblue1 033          darkcyan 036
    lightseagreen 037      deepskyblue2 038      deepskyblue1 039            green3 040
     springgreen3 041             cyan3 043     darkturquoise 044        turquoise2 045
           green1 046      springgreen2 047      springgreen1 048 mediumspringgreen 049
            cyan2 050             cyan1 051           purple4 055           purple3 056
       blueviolet 057            grey37 059     mediumpurple4 060        slateblue3 062
       royalblue1 063       chartreuse4 064    paleturquoise4 066         steelblue 067
       steelblue3 068    cornflowerblue 069     darkseagreen4 071         cadetblue 073
         skyblue3 074       chartreuse3 076         seagreen3 078       aquamarine3 079
  mediumturquoise 080        steelblue1 081         seagreen2 083         seagreen1 085
   darkslategray2 087           darkred 088       darkmagenta 091           orange4 094
       lightpink4 095             plum4 096     mediumpurple3 098        slateblue1 099
           wheat4 101            grey53 102    lightslategrey 103      mediumpurple 104
   lightslateblue 105           yellow4 106      darkseagreen 108     lightskyblue3 110
         skyblue2 111       chartreuse2 112        palegreen3 114    darkslategray3 116
         skyblue1 117       chartreuse1 118        lightgreen 120       aquamarine1 122
   darkslategray1 123         deeppink4 125   mediumvioletred 126        darkviolet 128
           purple 129     mediumorchid3 133      mediumorchid 134     darkgoldenrod 136
        rosybrown 138            grey63 139     mediumpurple2 140     mediumpurple1 141
        darkkhaki 143      navajowhite3 144            grey69 145   lightsteelblue3 146
   lightsteelblue 147   darkolivegreen3 149     darkseagreen3 150        lightcyan3 152
    lightskyblue1 153       greenyellow 154   darkolivegreen2 155        palegreen1 156
    darkseagreen2 157    paleturquoise1 159              red3 160         deeppink3 162
         magenta3 164       darkorange3 166         indianred 167          hotpink3 168
         hotpink2 169            orchid 170           orange3 172      lightsalmon3 173
       lightpink3 174             pink3 175             plum3 176            violet 177
            gold3 178   lightgoldenrod3 179               tan 180        mistyrose3 181
         thistle3 182             plum2 183           yellow3 184            khaki3 185
     lightyellow3 187            grey84 188   lightsteelblue1 189           yellow2 190
  darkolivegreen1 192     darkseagreen1 193         honeydew2 194        lightcyan1 195
             red1 196         deeppink2 197         deeppink1 199          magenta2 200
         magenta1 201        orangered1 202        indianred1 204           hotpink 206
    mediumorchid1 207        darkorange 208           salmon1 209        lightcoral 210
   palevioletred1 211           orchid2 212           orchid1 213           orange1 214
       sandybrown 215      lightsalmon1 216        lightpink1 217             pink1 218
            plum1 219             gold1 220   lightgoldenrod2 222      navajowhite1 223
       mistyrose1 224          thistle1 225           yellow1 226   lightgoldenrod1 227
           khaki1 228            wheat1 229         cornsilk1 230           grey100 231
            grey3 232             grey7 233            grey11 234            grey15 235
           grey19 236            grey23 237            grey27 238            grey30 239
           grey35 240            grey39 241            grey42 242            grey46 243
           grey50 244            grey54 245            grey58 246            grey62 247
           grey66 248            grey70 249            grey74 250            grey78 251
           grey82 252            grey85 253            grey89 254            grey93 255)
function getColorCode() {
  emulate -L zsh
  setopt no_hist_expand extended_glob no_prompt_bang prompt_{percent,subst} no_aliases
  if (( ARGC == 1 )); then
    case $1 in
      foreground)
        local k
        for k in "${(k@)__p9k_colors}"; do
          local v=${__p9k_colors[$k]}
          print -rP -- "%F{$v}$v - $k%f"
        done
        return 0
        ;;
      background)
        local k
        for k in "${(k@)__p9k_colors}"; do
          local v=${__p9k_colors[$k]}
          print -rP -- "%K{$v}$v - $k%k"
        done
        return 0
        ;;
    esac
  fi
  echo "Usage: getColorCode background|foreground" >&2
  return 1
}
_p9k_translate_color() {
  if [[ $1 == <-> ]]; then                  # decimal color code: 255
    _p9k_ret=${(l.3..0.)1}
  elif [[ $1 == '#'[[:xdigit:]]## ]]; then  # hexademical color code: #ffffff
    _p9k_ret=${(L)1}
  else                                      # named color: red
    # Strip prifixes if there are any.
    _p9k_ret=$__p9k_colors[${${${1#bg-}#fg-}#br}]
  fi
}


# _p9k_color prompt_foo_BAR BACKGROUND red
_p9k_color() {
  local key="_p9k_color ${(pj:\0:)*}"
  _p9k_ret=$_p9k_cache[$key]
  if [[ -n $_p9k_ret ]]; then
    _p9k_ret[-1,-1]=''
  else
    _p9k_param "$@"
    _p9k_translate_color $_p9k_ret
    _p9k_cache[$key]=${_p9k_ret}.
  fi
}


### Segment drawing # A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
CURRENT_RIGHT_BG='NONE'
case ${SOLARIZED_THEME:-dark} in
	light) CURRENT_FG='white' ;;
	*)     CURRENT_FG='black' ;;
esac

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


### Prompt components # Each component will draw itself, and hide itself if no information needs to be shown

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
	
	    0|127 ->   0|127
	  0|0|127 -> 0|0|127
	0|0|0|127 -> ..0|127
	
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

prompt_root_status() { # Status of root: (⚡)
	# if [[ $UID -eq 0 ]]; then
		# prompt_segment black yellow "$(print_icon ROOT_ICON)"
	# fi
	if [[ $(print -P "%#") == '#' ]]; then
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
	if [[ $(print -P "%#") == '#' ]]; then
		prompt_segment black yellow "$USER@%m"
	elif [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
		if [[ -n "$SUDO_COMMAND" ]]; then
			prompt_segment black yellow "(ssh) $USER@%m" # "$(print_icon SSH_ICON)"
		else
			prompt_segment black yellow "(ssh) %(!..%{%F{default}%})$USER@%m" # "$(print_icon SSH_ICON)"
		fi
	elif [[ -n "$SUDO_COMMAND" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
	fi
	
	
	# if [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		# prompt_segment black yellow "(ssh) %(!..%{%F{default}%})$USER@%m" # "$(print_icon SSH_ICON)"
	# elif [[ "$USER" != "$DEFAULT_USER" ]]; then
		# prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
	# fi
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


function agnor_parse_git_dirty() { # Checks if working tree is dirty
	local -a FLAGS=('--porcelain')
	[[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]] && FLAGS+='--untracked-files=no'
	[[ "$GIT_STATUS_IGNORE_SUBMODULES" != "git" ]] && FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
	local STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
	[[ -n $STATUS ]] && echo '*'
}
prompt_git_def() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local repo_path=$(git rev-parse --git-dir 2>/dev/null)
		local dirty=$(agnor_parse_git_dirty)
		local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
		fi
		local mode
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
	local modified untracked added deleted tagged stashed
	local ready_commit git_status bgclr fgclr

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local clean
		if [[ -n $dirty ]]; then
			clean=''
			bgclr='yellow'
			fgclr='white'
		else
			clean=" $(print_icon OK_ICON)" # ✔
			bgclr='green'
			fgclr='white'
		fi

		local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

		local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
		# if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
		if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

		local number_added=$(\grep -c "^A" <<< "${git_status}")
		[[ $number_added -gt 0 ]] && added=" $number_added✚"

		local number_modified=$(\grep -c "^.M" <<< "${git_status}")
		if [[ $number_modified -gt 0 ]]; then
			modified=" $number_modified●"
			bgclr='red'
			fgclr='white'
		fi

		local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
		local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
		if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
			modified="$modified$((number_added_modified+number_added_renamed))±"
		elif [[ $number_added_modified -gt 0 ]]; then
			modified=" ●$((number_added_modified+number_added_renamed))±"
		fi

		local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
		if [[ $number_deleted -gt 0 ]]; then
			deleted=" $number_deleted‒"
			bgclr='red'
			fgclr='white'
		fi

		local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
		if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
			deleted="$deleted$number_added_deleted±"
		elif [[ $number_added_deleted -gt 0 ]]; then
			deleted=" ‒$number_added_deleted±"
		fi

		local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
		if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

		local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
		if [[ $number_of_stashes -gt 0 ]]; then
			stashed=" ${number_of_stashes##*(  )}$(print_icon ETC_ICON)" # ⚙
			bgclr='magenta'
			fgclr='white'
		fi

		[[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]] && ready_commit=' ⚑'
		
		local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
		local commits_ahead commits_behind
		if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then
			local commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
			commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
			commits_behind=$(\grep -c "^>" <<< "$commits_diff")
		fi
		
		prompt_segment $bgclr $fgclr
		
		# ➦        head
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀  ●1±
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1±  ‒1±
		
		#  origin ^ master <B> ·↑12 ·↓2 ✔ ☗tag 2⚙ 12☀ 3●1± 3‒1± 12✚ ⚑
		#           master              ✔ ☗tag 2⚙ 12☀ 3●1± 3‒1± 12✚ ⚑
		
		
		# |> +1
		# ➦ head
		#  master ·↑12 ● ✚ <B>      ||> origin ·↓2
		
		print -n "%{$fg_bold[$fgclr]%}"
		print -n "${ref/refs\/heads\//$PL_BRANCH_CHAR}$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit"
		print -n "%{$fg_no_bold[$fgclr]%}"
	fi
}




prompt_git() { # Git: branch/detached head, dirty status
	(( $+commands[git] )) || return
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		local dirty=$(agnor_parse_git_dirty)
		
		# if [[ $SHOW_STASH_SEGMENT -eq 1 ]]; then
			local stash_size=$(git stash list | wc -l | tr -d ' ')
			if [[ stash_size -ne 0 ]]; then
				prompt_segment white black
				echo -n "+${stash_size}"
			fi
		# fi
		
		local ref_symbol ref=$(git symbolic-ref HEAD 2> /dev/null)
		if [[ -z $ref ]]; then
			ref=$(git rev-parse --short HEAD 2> /dev/null) || return 0
			# ref=$(git show-ref --head -s --abbrev |head -n1 2> /dev/null) || return 0
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
		
		local remote="${$(git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/}"
		local ahead behind
		if [[ -n ${remote} ]]; then
			remote="${remote/\/$ref/}"
			ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
			behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | tr -d ' ')
		fi

		if [[ $behind -ne 0 ]] && [[ $ahead -ne 0 ]]; then
			prompt_segment red white # diverged state
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
		[[ $ahead -ne "0" ]] && echo -n " ·\u2191${ahead}" # ↑ # VCS_OUTGOING_CHANGES_ICON
		echo -n "${vcs_info_msg_0_%% }${mode}"
		
		if [[ -n ${remote} ]]; then
			if [[ $behind -ne 0 ]]; then
				prompt_segment magenta white
			else
				prompt_segment cyan black
			fi
			echo -n "\uE0A0 $remote" #  # VCS_BRANCH_ICON
			[[ $behind -ne 0 ]] && echo -n " ·\u2193${behind}" # ↓ # VCS_INCOMING_CHANGES_ICON
		fi
	fi
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
				prompt_segment green $CURRENT_FG
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
				prompt_segment green $CURRENT_FG
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


