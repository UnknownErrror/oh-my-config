if [[ "$ENABLE_CORRECTION" == "true" ]]; then
	alias cp='nocorrect cp'
	alias ebuild='nocorrect ebuild'
	alias gist='nocorrect gist'
	alias heroku='nocorrect heroku'
	alias hpodder='nocorrect hpodder'
	alias man='nocorrect man'
	alias mkdir='nocorrect mkdir'
	alias mv='nocorrect mv'
	alias mysql='nocorrect mysql'
	alias sudo='nocorrect sudo'
	
	setopt CORRECT
	setopt CORRECT_ALL
	CORRECT_IGNORE='_*'
	CORRECT_IGNORE_FILE='_*'
fi
