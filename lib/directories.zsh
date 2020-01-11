setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

function ..() { # .. [<count>=1]
	local i
	for (( i = ${1:-1}; i > 0; i-- )); do
		cd ..
	done
}
alias -g ...='../..'
alias -- -='cd -'
