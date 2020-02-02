# My own current termux installation & configs

Created by me for myself

Installs:
* My (backward-incompatible) alternative to [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) terminal environment
* [fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting) plugin
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) plugin
* My theme: agnoster2 (temporary name)
* My .zshrc config
* My .zlogin, .logout files
* My functions and aliases
* And other

Packages:
* root-repo - Termux repository for root
* curl, wget, git, man
* tsu           - `su` wrapper for termux
* micro         - Text editor
* ncurses-utils - Tool for working with terminals
* nodejs, python, ruby - Programming languages
* tree      - Recursive directory lister
* htop      - Process viewer
* mc        - Midnight Commander - file manager
* unrar     - Tool for extraction files from .rar
* zip       - Tools for working with .zip
* jq        - JSON processor
* nnn       - File browser
* figlet    - Program for making large letters out of ordinary text
* cowsay    - Program which generates ASCII pictures of a cow with a message


## Package required:
-curl

## Install:
```shell
sh -c "$ (curl -fsSL https://github.com/UnknownErrror/termux-oh-my-zsh/raw/master/install.sh)"
``

## Set color style:
Run `chcolor` to change the color style, or run:
```shell
~/.termux/colors.sh
```

## Set font
Run `chfont` to change the font, or run:
```shell
~/.termux/fonts.sh
```

