setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

function ..() { # .. [count=1]
	count=${1:-1}
	for ((i=$count; i > 0; i = i - 1)); do
		cd ..
	done
}
alias -g ...='../..'
alias -- -='cd -'
