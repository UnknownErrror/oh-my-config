() {
	grep-flag-available() {
		echo | grep $1 "" >/dev/null 2>&1
	}
	local GREP_OPTIONS
	grep-flag-available --color=auto && GREP_OPTIONS=' --color=auto'
	
	local VCS_FOLDERS="{.bzr,CVS,.git,.hg,.svn}" # ignore VCS folders (if the necessary grep flags are available)
	if grep-flag-available --exclude-dir=.cvs; then
		GREP_OPTIONS+=" --exclude-dir=$VCS_FOLDERS"
	elif grep-flag-available --exclude=.cvs; then
		GREP_OPTIONS+=" --exclude=$VCS_FOLDERS"
	fi
	
	alias grep="grep $GREP_OPTIONS"
	
	unfunction grep-flag-available
}