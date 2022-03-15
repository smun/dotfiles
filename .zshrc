# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

LOCAL="/usr/local/"
LOCALBIN="${LOCAL}/bin"

# Path to your oh-my-zsh installation.
function ohmyzsh_user_inst() {
    curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | \
	    sh -s -- --unattended --keep-zshrc
}

if [ ! -d ${HOME}/.oh-my-zsh ]; then
    echo "[INFO] setting up Oh My Zsh"
    ohmyzsh_user_inst
fi

ZSH_THEME="robbyrussell"
HISTSIZE=400
UPDATE_ZSH_DAYS=14
ENABLE_CORRECTION="true"

plugins=(aliases git kubectl docker minikube rust terraform ubuntu vagrant)

ZSH=${HOME}/.oh-my-zsh

[ -f ${ZSH}/oh-my-zsh.sh ] && source ${ZSH}/oh-my-zsh.sh

# rust (system-wide install)
function rust_server_inst() {
    export RUSTUP_HOME=/opt/rust
    export CARGO_HOME=/opt/rust
    curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    if [[ ! -d "${RUSTUP_HOME}" || ! -d "${CARGO_HOME}" ]]; then
	   echo "root required to create a system-wide Rust install directory"
	   sudo mkdir /opt/rust
	   sudo chown $(whoami) /opt/rust
    fi
    curl -sSf https://sh.rustup.rs | sh -s -- -y
    echo ". ${RUSTUP_HOME}/env" >> ~/.zshenv
}

function rust_user_inst() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # TODO: a work-around for 'unstable' rust-analyzer; check for 'stable' release
    bfile=rust-analyzer
    curl -sSL https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > $HOME/bin/${bfile}
    chmod a+x ${HOME}/bin/${bfile}
    
}
[ -f ${HOME}/.zshenv ] && . ${HOME}/.zshenv
    
# kubernetes
function minikube_download() {
    mfile=${1:-"minikube-linux-amd64"}
    curl -sSLO https://storage.googleapis.com/minikube/releases/latest/${mfile}
}

function minikube_server_inst() {
    bfile="minikube_latest_amd64.deb"
    minikube_download ${bfile}
    sudo dpkg -i minikube_latest_amd64.deb && rm ${bfile}
}

function minikube_user_inst() {
    bfile="minikube-linux-amd64"
    minikube_download ${bfile}
    sudo install ${bfile} /usr/local/bin/minikube && rm ${bfile}
}

function kubectl_download() {
    kctlver=$(curl -sSL https://dl.k8s.io/release/stable.txt)
    kctlsum=$(curl -sSL https://dl.k8s.io/${kctlver}/bin/linux/amd64/kubectl.sha256)
    curl -sSLO "https://dl.k8s.io/release/${kctlver}/bin/linux/amd64/kubectl"
    sha256sum -c <(echo "${kctlsum} kubectl")
}

function kubectl_server_inst() {
    kubectl_download
    sudo install -o root -g root -m 0755 kubectl ${LOCALBIN}/
}

function kubectl_user_inst() {
    kubectl_download
    [ ! -d ${HOME}/bin ] && mkdir ${HOME}/bin
    mv kubectl ${HOME}/bin
}

function kctx() {
    local namesp=${1:-"default"}
    kubectl config set-context --current --namespace=${namesp}
}

function dotfiles_update() {
    ${HOME}/.dotfiles/setup.sh update
}

function linkerd2_inst() {
    curl -fsSL https://run.linkerd.io/install | sh
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
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME}/themes/powerlevel10k
}

if [ ! -d ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k ]; then
    echo "setting up Powerlevel10K"     
    powerl10k_inst
fi

[ -f ${ZSH}/custom/themes/powerlevel10k/powerlevel10k.zsh-theme ] && \
    source ${ZSH}/custom/themes/powerlevel10k/powerlevel10k.zsh-theme

autoload -Uz compinit
compinit

# node (required by neovim)    
function node_server_install() {    
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -    
    sudo apt-get install -y nodejs    
}    


# neovim 
function neovim_server_inst() {
    # add Ubuntu/Debian repo 
    sudo add-apt-repository ppa:neovim-ppa/stable 
    sudo apt-get update 
    sudo apt-get install -y neovim python3-dev python3-pip
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 80
    sudo update-alternatives --auto vi
    sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 80
    sudo update-alternatives --auto vim

    node_server_install
}

function neovim_user_inst() {
    # install plugin
    curl -sSfLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim | sh 
    if [ -f ${HOME}/.config/nvim/init.vim ]; then
        echo -n "@ 1st Run (ignore): " 
        nvim +'PlugInstall --sync' +qall --headless > /dev/null 2>&1 && echo " success" || echo " failed"
        echo -n "@ 2nd Run: " 
        nvim +'PlugInstall --sync' +qall --headless > /dev/null 2>&1 && echo " success" || echo " failed"
    fi
}

# main
PATH=${LOCALBIN}:${PATH}:~/bin
export  BROWSER=/usr/bin/google-chrome-stable

alias   mk='minikube'
alias   ls='ls --color'
alias	vpn='pritunl-client-electron'
export  ARCHFLAGS="-arch x86_64"

set -o vi
bindkey "^R" history-incremental-search-backward



# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[ ! -f ~/.p10k.zsh ] || source ~/.p10k.zsh
export SIGNALFX_CREDENTIALS=/var/secrets/signalfx/key.json
