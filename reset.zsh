ZSH=$HOME/.oh-my-config

rm -rfdv $ZSH/

git clone https://github.com/UnknownErrror/oh-my-config.git $ZSH --depth 1
cp -vR $ZSH/.configs/.zshrc $HOME/
cp -vR $ZSH/.configs/.zshenv $HOME/
cp -vR $ZSH/.configs/.zlogin $HOME/
cp -vR $ZSH/.configs/.zlogout $HOME/

git clone https://github.com/zdharma/fast-syntax-highlighting.git $ZSH/custom/plugins/fast-syntax-highlighting --depth 1
git clone https://github.com/zsh-users/zsh-autosuggestions.git    $ZSH/custom/plugins/zsh-autosuggestions --depth 1
git clone https://github.com/zsh-users/zsh-completions.git        $ZSH/custom/plugins/zsh-completions --depth 1

echo 'Reset completed!'
