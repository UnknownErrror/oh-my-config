if [[ ENABLE_CORRECTION == true ]]; then
	if [[ -f $ZSH/.configs/.zsh_nocorrect ]]; then
		while read -r COMMAND; do
			alias $COMMAND="nocorrect $COMMAND"
		done < $ZSH/.configs/.zsh_nocorrect
	fi
	
	setopt CORRECT
	setopt CORRECT_ALL
	#CORRECT_IGNORE='_*'
	#CORRECT_IGNORE_FILE='_*'
fi
