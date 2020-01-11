# [Functions]:

function async_run() {
	{ eval "$@" }&
}

function check_bool() {
	[[ $1 == true || $1 == 1 || $1 =~ ^[Yy].* || $1 =~ ^[Oo][Nn]$ ]] && return 0 || return 1
}

function color256() {
	local red=$1; shift
	local green=$2; shift
	local blue=$3; shift
	echo -n $[$red * 36 + $green * 6 + $blue + 16]
}
function fg256() {
	echo -n $'\e[38;5;'$(color256 "$@")"m"
}
function bg256() {
	echo -n $'\e[48;5;'$(color256 "$@")"m"
}

function hex2dec() {
	awk 'BEGIN { printf "%d\n",0x$1}'
}
function dec2hex() {
	awk 'BEGIN { printf "%x\n",$1}'
}


function repeat0() { # repeat <count> <command>
	local i max
	max=$1; shift;
	for ((i=1; i <= max ; i++)); do # --> C-like syntax
		eval "$@";
	done
}

function lcd cdl() { # cd + ls
	cd "$@" && ls -AF
}
function mkcd() { # mkdir + cd
	# mkdir -vp "$@" && eval cd "\"\$$#\""
	mkdir -vp "$@" && cd ${@:$#}
}

function maketar() { # Creates an archive (*.tar.gz) from given directory.
	tar cvzf "${1%%/}.tar.gz" "${1%%/}/"
}
function makezip() { # Create a ZIP archive of a file or folder.
	zip -r "${1%%/}.zip" "$1"
}

function ask() { # ask <text> [Y|N] # https://djm.me/ask
	local prompt default reply
	if [ "${2:-}" = "Y" ]; then
		prompt="Y/n"
		default=Y
	elif [ "${2:-}" = "N" ]; then
		prompt="y/N"
		default=N
	else
		prompt="y/n"
		default=
	fi
	while true; do
		echo -n "$1 [$prompt] " # Ask the question (not using "read -p" as it uses stderr not stdout)
		read reply </dev/tty # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
		if [ -z "$reply" ]; then # Default?
			reply=$default
		fi
		case "$reply" in # Check if the reply is valid
			Y*|y*) return 0 ;;
			N*|n*) return 1 ;;
		esac
	done
}
function is-stdin-open() {
	[ -t 0 ] && return 1 || return 0
}

function chcur() { # chcur [curmode:1|2]
	case $1 in
		1|\|) echo -ne '\e[5 q' ;; # |
		2|_) echo -ne '\e[3 q' ;; # _
		*) echo -ne '\e[1 q' ;; # Default
	esac
}
function chpath(){
	if [[ -z $IS_TERMUX ]]; then
		echo "Command 'chpath' can be run only in Termux app"
		exit 1
	fi
	# local mmpath='/sbin/.magisk/busybox'
	local supath='/sbin:/sbin/su:/su/bin:/su/xbin:/system/bin:/system/xbin:/vendor/bin'
	local bbpath='/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets'
	if [[ $1 == 'su' ]]; then
		export PATH="$supath:$bbpath"
	elif [[ $1 == 'suo' ]]; then
		export PATH="$supath"
	elif [[ $1 == 'bb' ]]; then
		export PATH="$bbpath:$supath"
	elif [[ $1 == 'bbo'^ ]]; then
		export PATH="$bbpath"
	fi
}

function set_perm() { # <target> <owner> <group> <permission> [context]
	chown -v $2:$3 $1 || return 1
	chmod -v $4 $1 || return 1
	local CON=$5
	if [[ -n $CON ]]; then # u:object_r:system_file:s0
		chcon -v $CON $1 || return 1
	fi 
}
function set_perm_recursive() { # <directory> <owner> <group> <dirpermission> <filepermission> [context]
	find $1 -type d 2>/dev/null | while read dir; do
		set_perm $dir $2 $3 $4 $6
	done
	find $1 -type f -o -type l 2>/dev/null | while read file; do
		set_perm $file $2 $3 $5 $6
	done
}

function default() { # cmd <name> <default_value>
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
function env_default() { # cmd <env_var> <default_value`>
	(( ${${(@f):-$(typeset +xg)}[(I)$1]} )) && return 0
	export "$1=$2" && return 3
}
