# [Aliases]:
alias chcolor='/data/data/com.termux/files/home/.termux/colors.sh'
alias chfont='/data/data/com.termux/files/home/.termux/fonts.sh'


alias mem='free -ht'
alias cpu='lscpu -ae;echo '';lscpu'
alias cpu0='less /proc/cpuinfo'

alias history0='fc -il 1'
alias df0='df -h'

# alias du0="ncdu"
alias nnn0='nnn -dEHor'
alias files='mc'
alias tree0='tree -aF'
alias tree1='tree -apughF'
alias ll='ls -lAFh' # long-list (l), almost-all (A), show type (F), human-readable sizes (h)
alias lsa='ls -AF' # almost-all (A), show type (F)

alias ll0='exa -alFhg --color=auto --color-scale --git'

# alias img='termimage'
# alias json='jq'
alias edit='${=EDITOR}'
alias zshrc='${=EDITOR} ~/.zshrc' # Quick access to the ~/.zshrc file
alias pass=':'


alias rld='exec $SHELL -l'
alias install='pkg install'
alias finstall='apt install'
alias uninstall='pkg uninstall'
alias showpkg='apt show'

alias clr='clear'
alias q='exit'
alias bb='busybox'

alias subb='/system/xbin/busybox'
alias shbb='/data/data/com.termux/files/usr/bin/busybox'


alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

alias wget='wget -c' # continue after fail (c)
alias mkdir='mkdir -pv' # recursive (p), verbose (v)
alias nano='nano -l' # line-numbers (l)


alias sudo='su -c "$@"'
alias sysro='mount -o remount,ro /system'
alias sysrw='mount -o remount,rw /system'
alias mountrw='mount -o remount,rw'
alias mountro='mount -o remount,ro'

# Command line head / tail shortcuts
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"


alias b64e='base64'
alias b64e='base64 --decode'
alias path='print -l $path'
