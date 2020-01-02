#!/system/bin/sh

# Install main
pkg install -y root-repo
# root-repo - Termux repository for root
apt update && apt full-upgrade -y && apt autoremove -y
termux-setup-storage
apt install -y tsu curl wget git micro ncurses-utils man
# curl wget git man
# tsu           - `su` wrapper for termux
# micro         - Text editor
# ncurses-utils - Tool for working with terminals

# apt install -y termux-api



# Install 'zsh'
apt install -y zsh # Shell

cd $HOME

ZSH=$HOME/.oh-my-config

git clone https://github.com/UnknownErrror/oh-my-config.git $ZSH --depth 1
cp -vR $ZSH/.termux $HOME
cp -vR $ZSH/.configs/.zshrc $HOME/
cp -vR $ZSH/.configs/.zlogin $HOME/
cp -vR $ZSH/.configs/.zlogout $HOME/

git clone https://github.com/zdharma/fast-syntax-highlighting.git  $ZSH/custom/plugins/fast-syntax-highlighting --depth 1
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/custom/plugins/zsh-syntax-highlighting --depth 1
git clone https://github.com/zsh-users/zsh-autosuggestions.git     $ZSH/custom/plugins/zsh-autosuggestions --depth 1
git clone https://github.com/zsh-users/zsh-completions.git         $ZSH/custom/plugins/zsh-completions --depth 1
chsh -s zsh



# Install goodies
apt install -y nodejs python ruby
# nodejs python ruby - Programming languages

# apt install -y clang python-dev # Python development
python -m pip install --upgrade pip

apt install -y tree htop mc unrar zip jq nnn exa
# tree      - Recursive directory lister
# htop      - Process viewer
# mc        - Midnight Commander - file manager
# unrar     - Tool for extraction files from .rar
# zip       - Tools for working with .zip
# [-] termimage - Image viewer in terminal
# [-] fd        - Alternative to `find`
# jq        - JSON processor
# [-] ncdu      - Disk usage analizer
# nnn       - File browser

apt install -y figlet cowsay
# [-] toilet  - FIGlet-compatible display of large colorful characters in text mode
# figlet  - Program for making large letters out of ordinary text
# cowsay  - Program which generates ASCII pictures of a cow with a message

gem install lolcat

# hash -r # ??? 



echo "oh-my-config install complete!"
echo ''
echo ''
echo "Choose your color scheme now~ (Default the best)"
echo ''
chmod +x $HOME/.termux/colors.sh $HOME/.termux/fonts.sh
$HOME/.termux/colors.sh
echo ''
echo "Choose your font now~ (Meslo the best)"
$HOME/.termux/fonts.sh

echo ''
echo ''
echo "Please restart Termux app..."
