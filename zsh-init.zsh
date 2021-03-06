
[[ -z "$ZSH_CACHE_DIR" ]] && ZSH_CACHE_DIR="$ZSH/cache"
[[ -z "$ZSH_CUSTOM" ]] && ZSH_CUSTOM="$ZSH/custom"

fpath=($ZSH/functions $ZSH/completions $fpath) # function path
autoload -U compaudit compinit # Load all stock functions (from $fpath files).


is_plugin() { # is_plugin <base_dir> <plugin_name>
	local plugin_dir=$1/plugins/$2
	test -f $plugin_dir/$2.plugin.zsh || test -f $plugin_dir/_$2
}
for plugin ($plugins); do # Add all defined plugins to fpath. This must be done before running compinit.
	if is_plugin $ZSH_CUSTOM $plugin; then
		fpath=($ZSH_CUSTOM/plugins/$plugin $fpath)
	elif is_plugin $ZSH $plugin; then
		fpath=($ZSH/plugins/$plugin $fpath)
	else
		echo "[zsh-init] plugin '$plugin' not found"
	fi
done

# Figure out the SHORT hostname. MacOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
[[ OSTYPE = darwin* ]] && SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}

[[ -z "$ZSH_COMPDUMP" ]] && ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
compinit -u -C -d "${ZSH_COMPDUMP}"

[[ -f $ZSH/lib/functions.zsh ]] && source $ZSH/lib/functions.zsh
for config_file ($ZSH/lib/*.zsh); do # Load all of the config files in ~/oh-my-zsh that end in .zsh
	[[ $config_file != 'functions' && $config_file != 'completion' ]] && source $config_file
done
[[ -f $ZSH/lib/completion.zsh ]] && source $ZSH/lib/completion.zsh

for plugin ($plugins); do # Load all of the plugins that were defined in ~/.zshrc
	if [[ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]]; then
		source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
	elif [[ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]]; then
		source $ZSH/plugins/$plugin/$plugin.plugin.zsh
	fi
done
for config_file ($ZSH_CUSTOM/*.zsh(N)); do # Load all of your custom configurations from custom/
	source $config_file
done

if [[ -n "$ZSH_THEME" ]]; then # Load the theme
	if [[ -f $ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme ]]; then
		source $ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme
	else
		source $ZSH/themes/$ZSH_THEME.zsh-theme
	fi
fi
unset plugin config_file # clear