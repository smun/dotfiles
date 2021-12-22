#!/bin/bash

set -eo pipefail

DOTGITREPO=https://github.com/smun/dotfiles.git
DOTDIR=.dotfiles
TDNOW=$(date +%s)

# add files here:
dotfiles=(".zshrc" ".p10k.zsh" ".config/nvim/init.vim")
homedirs=("bin" "lib" ".ssh" ".config" ".local")

function help() {
    echo "$0 <install|update>"
}

function update() {
    cd ${HOME}/${DOTDIR}
    git pull
}

function populate_homedir() {
    cd ${HOME}
    for hdir in ${homedirs[@]}; do
        [ ! -d ${HOME}/${hdir} ] && mkdir -p ${HOME}/${hdir}
    done
}
    
function install() {
    [ ! -d ${HOME}/${DOTDIR} ] && mkdir ${HOME}/${DOTDIR}
    git clone ${DOTGITREPO} ${HOME}/${DOTDIR}
    
    cd ${HOME}

    populate_homedir

    for dfile in ${dotfiles[@]}; do
        if [ -f ${HOME}/${dfile} ]; then
            mv ${HOME}/${dfile} ${HOME}/${dfile}.save-${TDNOW}
        else
	    parent_dir=$(dirname ${dfile})
	    [ ${parent_dir} != "." ] && mkdir -p ${parent_dir}
            ln -sf ${HOME}/${DOTDIR}/${dfile} ${dfile}
        fi
    done
}

progname=$0
subcomm=$1

case ${subcomm} in
    "" | "-h" | "--help")
        help
        ;;
    *)
        shift
        ${subcomm} $@
        if [ $? = 127 ]; then
            echo "unknown command"
	    help
            exit 1
        fi
esac
