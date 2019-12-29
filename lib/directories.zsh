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

alias md='mkdir -p'
alias rd=rmdir

function d() {
	if [[ -n $1 ]]; then
		dirs "$@"
	else
		dirs -v | head -10
	fi
}
compdef _dirs d
