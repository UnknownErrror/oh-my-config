[[ -o login ]] && export IS_LOGIN=true || export IS_LOGIN=''
[[ -o interactive ]] && export IS_INTERACTIVE=true || export IS_INTERACTIVE=''
[[ -d "/data/data/com.termux" ]] && export IS_TERMUX=true || export IS_TERMUX=''

[[ -n $IS_TERMUX ]] && export EDITOR=micro || export EDITOR=nano

[[ -z $IS_INTERACTIVE ]] && source $HOME/.oh-my-config/lib/functions.zsh