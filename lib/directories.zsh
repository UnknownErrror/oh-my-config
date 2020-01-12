setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

alias .='source'
function ..() { # .. [<count>=1]
	local i
	for (( i = ${1:-1}; i > 0; i-- )); do
		cd ..
	done
}

function cd() {
	if [[ -f $1 ]]; then
		builtin cd $1:h
	else
		builtin cd $1
	fi
}

function lcd cdl() { # cd + ls
	cd "$@" && ls -AF
}
function llcd cdll() { # cd + ls -l
	cd "$@" && ls -lAFh
}
function mkcd() { # mkdir + cd
	mkdir -vp "$@" && cd ${@:$#}
}

alias -g ...='../..'
alias -- -='cd -'
