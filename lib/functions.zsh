<<<<<<< HEAD
# [Functions]:

function async_run() {
	{
		eval "$@"
	}&
}

function is_bool_true() {
	[[ $1 == true || $1 == 1 || $1 =~ ^[Yy].* ]] && return 0 || return 1
}
function is_bool_false() {
	[[ $1 == false || $1 == 0 || $1 =~ ^[Nn].* ]] && return 0 || return 1
}
function is_bool_indeterminate() {
	! is_true $1 && ! is_false $1 && return 0 || return 1
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
	local mmpath='/sbin/.magisk/busybox'
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
	CON=$5
	[ -z $CON ] && CON=u:object_r:system_file:s0
	chcon -v $CON $1 || return 1
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
=======
function alias_value() {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
function try_alias_value() {
	alias_value "$1" || echo "$1"
}
function default() { # cmd <name> <default_value>
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
function env_default() { # cmd <env_var> <default_value`>
	(( ${${(@f):-$(typeset +xg)}[(I)$1]} )) && return 0
	export "$1=$2" && return 3
}

zmodload zsh/langinfo # Required for $langinfo
function omz_urlencode() {
	emulate -L zsh
	zparseopts -D -E -a opts r m P

	local in_str=$1
	local url_str=""
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]; then spaces_as_plus=1; fi
	local str="$in_str"

	# URLs must use UTF-8 encoding; convert str to UTF-8 if required
	local encoding=$langinfo[CODESET]
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII)
	if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8)
		if [[ $? != 0 ]]; then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi

	# Use LC_CTYPE=C to process text byte-by-byte
	local i byte ord LC_ALL=C
	export LC_ALL
	local reserved=';/?:@&=+$,'
	local mark='_.!~*''()-'
	local dont_escape="[A-Za-z0-9"
	if [[ -z $opts[(r)-r] ]]; then
		dont_escape+=$reserved
	fi
	# $mark must be last because of the "-"
	if [[ -z $opts[(r)-m] ]]; then
		dont_escape+=$mark
	fi
	dont_escape+="]"

	# Implemented to use a single printf call and avoid subshells in the loop,
	# for performance (primarily on Windows).
	local url_str=""
	for (( i = 1; i <= ${#str}; ++i )); do
		byte="$str[i]"
		if [[ "$byte" =~ "$dont_escape" ]]; then
			url_str+="$byte"
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]; then
				url_str+="+"
			else
				ord=$(( [##16] #byte ))
				url_str+="%$ord"
			fi
		fi
	done
	echo -E "$url_str"
}
function omz_urldecode {
	emulate -L zsh
	local encoded_url=$1

	# Work bytewise, since URLs escape UTF-8 octets
	local caller_encoding=$langinfo[CODESET]
	local LC_ALL=C
	export LC_ALL

	# Change + back to ' '
	local tmp=${encoded_url:gs/+/ /}
	# Protect other escapes to pass through the printf unchanged
	tmp=${tmp:gs/\\/\\\\/}
	# Handle %-escapes by turning them into `\xXX` printf escapes
	tmp=${tmp:gs/%/\\x/}
	local decoded
	eval "decoded=\$'$tmp'"

	# Now we have a UTF-8 encoded string in the variable. We need to re-encode
	# it if caller is in a non-UTF-8 locale.
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII)
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]; then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding)
		if [[ $? != 0 ]]; then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi

	echo -E "$decoded"
>>>>>>> Stuff
}
