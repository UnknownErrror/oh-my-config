<<<<<<< HEAD
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
=======
# Changing/making/removing directory
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
>>>>>>> Stuff

alias md='mkdir -p'
alias rd=rmdir

<<<<<<< HEAD
function d() {
	if [[ -n $1 ]]; then
		dirs "$@"
	else
		dirs -v | head -10
	fi
}
compdef _dirs d
=======
function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -10
  fi
}
compdef _dirs d

# List directory contents
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
>>>>>>> Stuff
