# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
function ohmyzsh_inst() {
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
}

if [ ! -d ~/.oh-my-zsh ]; then
    echo "[INFO] setting up Oh My Zsh"
    ohmyzsh_inst
fi

ZSH_THEME="robbyrussell"

export UPDATE_ZSH_DAYS=14
ENABLE_CORRECTION="true"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# rust
function rust_inst() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}
[ -f ~/.zshenv ] && . ~/.zshenv
    
# kubernetes
BASH_VERSION=" "

function minikube_inst() {
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
}

function kubectl_inst() {
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
}

function kctx() {
    local namesp=${1:-"default"}
    kubectl config set-context --current --namespace=${namesp}
}

if [ -x /usr/local/bin/kubectl ]; then
    source <(kubectl completion zsh)
    alias k=kubectl
    complete -F __start_kubectl k
fi

if [ -f /usr/local/bin/minikube ]; then
    . <(minikube completion zsh)
    complete -F __start_minikube mk
    alias mk=minikube
fi 

# linkerd2
function linkerd2_inst() {
    curl -fsL https://run.linkerd.io/install | sh
    echo "Press any key to continue"
    read
    linkerd check --pre
    read
    linkerd install | kubectl apply -f -
    read
    linkerd check
}

if [ -x ~/.linkerd/bin/linkerd ]; then
    export PATH=$PATH:/home/smun/.linkerd2/bin
    source <(linkerd completion zsh)
fi

# powerlevel10k
function powerl10k_inst() {
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME}/.oh-my-zsh/
}

if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    	powerl10k_inst
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme

autoload -Uz compinit
compinit

# neovim 
function neovim_inst() {
    # add Ubuntu/Debian repo 
    sudo add-apt-repository ppa:neovim-ppa/stable && \
    sudo apt-get update && \
    sudo apt-get install -y neovim python-dev python-pip python3-dev python3-pip
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
    sudo update-alternatives --config vi
    sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
    sudo update-alternatives --config vim
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    sudo update-alternatives --config editor

    # install plugin
    curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim | sh 
    if [ -f ~/.config/nvim/init.vim ]; then
        nvim +PlugInstall +qall --headless
    fi

}


export  BROWSER=/usr/bin/google-chrome-stable
export  PATH=$PATH:~/bin

alias   ls='ls --color'
alias   vim='nvim'
export  ARCHFLAGS="-arch x86_64"

set -o vi
bindkey "^R" history-incremental-search-backward

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
