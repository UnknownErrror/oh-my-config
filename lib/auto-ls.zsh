auto-ls() {
	# Possible invocation sources:
	#	1. Called from `chpwd_functions` – show file list
	#	2. Called by another ZLE plugin (like `dirhistory`) through `zle accept-line` – show file list
	#	3. Called by ZLE itself – only should file list if prompt was empty
	if ! zle || { [[ ${WIDGET} != accept-line ]] && [[ ${LASTWIDGET} != .accept-line ]] } || { [[ ${WIDGET} == accept-line ]] && [[ $#BUFFER -eq 0 ]] }; then
		zle && echo
		ls -AF
		echo ''
	fi
	if zle; then # Forward this event down the ZLE stack
		if [[ ${WIDGET} == accept-line ]] && [[ $#BUFFER -eq 0 ]]; then
			# Shortcut to reduce the number of empty lines appearing when pressing Enter
			echo && zle redisplay
		elif [[ ${WIDGET} != accept-line ]] && [[ ${LASTWIDGET} == .accept-line ]]; then
			# Hack to make only 2 lines appear after `dirlist` navigation
			# (Uses a VT100 escape sequence to move curser up one line…)
			tput cuu 1
		else
			zle .accept-line
		fi
	fi
}

zle -N auto-ls
zle -N accept-line auto-ls

if [[ ${chpwd_functions[(I)auto-ls]} -eq 0 ]]; then
	chpwd_functions+=(auto-ls)
fi
