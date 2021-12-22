#!/bin/bash

set -eo pipefail

DOTGITREPO=https://github.com/smun/dotfiles.git
DOTDIR=.dotfiles
TDNOW=$(date +%s)

# add files here:
dotfiles=(
    ".zshrc" \
    ".p10k.zsh" \
    ".config/nvim/init.vim"
)

function help() {
    echo "$0 help"
}

function update() {
    cd ${HOME}/${DOTDIR}
    git pull
}

function install() {
    [ ! -d ${HOME}/${DOTDIR} ] && mkdir ${HOME}/${DOTDIR}
    git clone ${DOTGITREPO} ${HOME}/${DOTDIR}
    
    cd ${HOME}
    for dfile in ${dotfiles[@]}; do
        if [ -f ${HOME}/${dfile} ]; then
            mv ${HOME}/${dfile} ${HOME}/${dfile}.save-${TDNOW}
        else
            ln -sf ${DOTDIR}/${dfile} 
        fi
    done
}

progname=$0
subcommand=$1

case ${subcommand} in
    "" | "-h" | "--help")
        help
        ;;
    *)
        shift
        ${subcommand} $@
        if [ $? = 127 ]; then
            echo "unknown command"
            exit 1
        fi
esac
