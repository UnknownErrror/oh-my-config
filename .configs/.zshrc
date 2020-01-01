export USER="$(id -un)"
export DEFAULT_USER="u0_a78"

export TERM="xterm-256color"

export EDITOR=micro
export ZSH="$HOME/.oh-my-config" # [REQ]
export SD="/sdcard"
export TMUX_PATH="/data/data/com.termux"


CASE_SENSITIVE=false # Use case-sensitive completion
HYPHEN_INSENSITIVE=false # Use hyphen-insensitive completion; Case-sensitive completion must be off. _ and - will be interchangeable.
# DISABLE_MAGIC_FUNCTIONS=true # Uncomment if pasting URLs and other text is messed up.
ENABLE_CORRECTION=true # Enable command auto-correction
COMPLETION_WAITING_DOTS=true # Display red dots whilst waiting for completion
# DISABLE_UNTRACKED_FILES_DIRTY=true # Disable marking untracked files under VCS as dirty. This makes repository status check for large repositories muuuch faster
# ZSH_AUTOSUGGEST_STRATEGY=( completion history ) # [HARD]
DISABLE_AUTO_TITLE=false
DISABLE_LS_COLORS=false
ZSH_THEME="custom"

plugins=(
	# git
	# zsh-syntax-highlighting
	fast-syntax-highlighting
	zsh-autosuggestions
	zsh-completions
	extract
	last-working-dir

	adb
	pip
	gem
	node
	colored-man-pages
	jump
	gitfast
	themes
	timer
)
source $ZSH/zsh-init.zsh # [REQ]

# [CUSTOM]

# 0 - синий, синий
# 1 - чёрный, синий
# 2 - чёрный, тёмно-ярко-блеклый
# 4 - синеватая - неплохо
# 8 - дефолт?
# 9 - серый, блеклый
# 10- темно-синий, блеклый
# 27- дефолт? - темнее, блеклее
# 30- блеклыйдефолт?
# 33- ДЕФОЛТ
# 36- синяя блеклая

HISTFILE=~/.zhistory
SAVEHIST=50000
HISTSIZE=100000
DIRSTACKSIZE=20


# setopt CORRECT_ALL # correction.zsh

### Changing dirs:
# setopt AUTO_CD # theme-and-appereance.zsh
# setopt AUTO_PUSHD # directories.zsh
setopt CHASE_DOTS
unsetopt CHASE_LINKS
# setopt PUSHD_IGNORE_DUPS # directories.zsh
# setopt PUSHD_MINUS # directories.zsh
unsetopt PUSHD_SILENT
setopt PUSHD_TO_HOME

### Completion:
# setopt ALWAYS_LAST_PROMPT # If unset, key functions that list completions try to return to the last prompt if given a numeric argument. If set these functions try to return to the last prompt if given no numeric argument.
# setopt ALWAYS_TO_END # completion.zsh
setopt AUTO_LIST
# setopt AUTO_MENU # completion.zsh
setopt AUTO_PARAM_KEYS
setopt AUTO_PARAM_SLASH
setopt AUTO_REMOVE_SLASH
setopt COMPLETE_ALIASES
# setopt COMPLETE_IN_WORD # completion.zsh
setopt GLOB_COMPLETE
setopt LIST_PACKED
unsetopt LIST_ROWS_FIRST
setopt LIST_TYPES
# unsetopt MENU_COMPLETE # completion.zsh
unsetopt REC_EXACT
# Expansion and Globbing:
setopt BAD_PATTERN
setopt GLOB
unsetopt GLOB_ASSIGN
setopt GLOB_DOTS
setopt GLOB_STAR_SHORT
# setopt KSH_GLOB # In pattern matching, the interpretation of parentheses is affected by a preceding `@', `*', `+', `?' or `!'.  See thesection `Filename Generation'.
setopt MARK_DIRS
setopt NOMATCH
unsetopt NULL_GLOB
setopt REMATCH_PCRE

### History:
setopt APPEND_HISTORY
unsetopt BANG_HIST
# setopt EXTENDED_HISTORY # history.zsh
# setopt HIST_EXPIRE_DUPS_FIRST # history.zsh
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
# setopt HIST_IGNORE_DUPS # history.zsh
# setopt HIST_IGNORE_SPACE # history.zsh
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
# setopt HIST_VERIFY # history.zsh
# setopt INC_APPEND_HISTORY # history.zsh
# setopt SHARE_HISTORY # history.zsh

### Input/Output:
setopt CLOBBER
setopt CORRECT
# unsetopt FLOW_CONTROL # completion.zsh
unsetopt IGNORE_EOF
# setopt INTERACTIVE_COMMENTS # misc.zsh
unsetopt RM_STAR_SILENT
unsetopt RM_STAR_WAIT
setopt SHORT_LOOPS

### Job Control:
setopt CHECK_JOBS
setopt CHECK_RUNNING_JOBS
# setopt HUP
# setopt LONG_LIST_JOBS # misc.zsh
setopt MONITOR
setopt NOTIFY
### Prompting:
# setopt PROMPT_SUBST # theme-and-appereance.zsh
# Scripts and Functions:
setopt C_BASES
# setopt C_PRECEDENCES
# setopt FUNCTION_ARGZERO
setopt LOCAL_LOOPS
# setopt MULTIOS # theme-and-appereance.zsh
# setopt OCTAL_ZEROES

### Zle:
setopt BEEP


# [INIT]

# chcur 1
chpath bb

# run-help command
unalias run-help
autoload run-help

# Recent dirs # cdr command
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':completion:*:*:cdr:*:*' menu selection

