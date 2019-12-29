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
}
