#/bin/bash
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
MAX=10

COINDOWNLOADLINK=https://github.com/nihilocoin/pos-resources/releases/download/2.0.0/Nihilo-Linux-CLI-V2
COINDOWNLOADFILE=Nihilo-Linux-CLI-V2
COINPORT=5353
COINDAEMON=nihilod
COINCORE=.nihilo
COINCONFIG=nihilo.conf

checkForUbuntuVersion() {
   echo
   echo "[1/${MAX}] Checking Ubuntu version..."
    if [[ `cat /etc/issue.net`  == *16.04* ]]; then
        echo -e "${GREEN}* You are running `cat /etc/issue.net` . Setup will continue.${NONE}";
    else
        echo -e "${RED}* You are not running Ubuntu 16.04.X. You are running `cat /etc/issue.net` ${NONE}";
        echo && echo "Installation cancelled" && echo;
        exit;
    fi
}

updateAndUpgrade() {
    echo
    echo "[2/${MAX}] Runing update and upgrade. Please wait..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}";
}

setupSwap() {
    swapspace=$(free -h | grep Swap | cut -c 16-18);
    if [ $(echo "$swapspace < 1.0" | bc) -ne 0 ]; then

    echo a; else echo b; fi

    echo -e "${BOLD}"
    read -e -p "Add swap space? (Recommended for VPS that have 1GB of RAM) [Y/n] :" add_swap
    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        swap_size="4G"
    else
        echo -e "${NONE}[3/${MAX}] Swap space not created."
    fi

    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        echo && echo -e "${NONE}[3/${MAX}] Adding swap space...${YELLOW}"
        sudo fallocate -l $swap_size /swapfile
        sleep 2
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo -e "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Done${NONE}";
    fi
}

installFail2Ban() {
    echo
    echo -e "[4/${MAX}] Installing fail2ban. Please wait..."
    sudo apt-get -y install fail2ban > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installFirewall() {
    echo
    echo -e "[5/${MAX}] Installing UFW. Please wait..."
    sudo apt-get -y install ufw > /dev/null 2>&1
    sudo ufw allow OpenSSH > /dev/null 2>&1
    sudo ufw allow $COINPORT/tcp > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installDependencies() {
    echo
    echo -e "[6/${MAX}] Installing dependecies. Please wait..."
    sudo apt-get install bc git nano rpl wget python-virtualenv -qq -y > /dev/null 2>&1
    sudo apt-get install build-essential libtool automake autoconf -qq -y > /dev/null 2>&1
    sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -qq -y > /dev/null 2>&1
    sudo apt-get install software-properties-common python-software-properties -qq -y > /dev/null 2>&1
    sudo add-apt-repository ppa:bitcoin/bitcoin -y > /dev/null 2>&1
    sudo apt-get update -qq -y > /dev/null 2>&1
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libminiupnpc-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libzmq5 -qq -y > /dev/null 2>&1
    sudo apt-get install virtualenv -qq -y > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

downloadWallet() {
    echo
    echo -e "[7/${MAX}] Compiling wallet. Please wait, this might take a while to complete..."

    cd && mkdir new && cd new

    wget $COINDOWNLOADLINK > /dev/null 2>&1
    mv $COINDOWNLOADFILE $COINDAEMON > /dev/null 2>&1
    chmod 755 $COINDAEMON > /dev/null 2>&1

    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installWallet() {
    echo
    echo -e "[8/${MAX}] Installing wallet. Please wait..."
    strip $COINDAEMON  > /dev/null 2>&1
    sudo mv $COINDAEMON /usr/bin  > /dev/null 2>&1
    cd && sudo rm -rf new > /dev/null 2>&1
    cd
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

configureWallet() {
    echo
    echo -e "[9/${MAX}] Configuring wallet. Please wait..."
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 2
    $COINDAEMON stop > /dev/null 2>&1
    sleep 2

    mnip=$(curl --silent ipinfo.io/ip)
    rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowedip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1" > ~/$COINCORE/$COINCONFIG

    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 2

    mnkey=$($COINDAEMON masternode genkey)

    $COINDAEMON stop > /dev/null 2>&1
    sleep 2

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcport=5454\nrpcallowip=127.0.0.1\ndaemon=1\nserver=1\nlisten=1\ntxindex=1\nlistenonion=0\nmasternode=1\nmasternodeaddr=${mnip}:${COINPORT}\nmasternodeprivkey=${mnkey}\naddnode=ns1.nihilo.space\naddnode=ns2.nihilo.space\naddnode=ns3.nihilo.space\naddnode=ns4.nihilo.space\naddnode=ns5.nihilo.space\naddnode=ns6.nihilo.space\naddnode=ns7.nihilo.space\naddnode=ns8.nihilo.space\naddnode=ns9.nihilo.space\naddnode=ns10.nihilo.space" > ~/$COINCORE/$COINCONFIG

    echo -e "${NONE}${GREEN}* Done${NONE}";
}

startWallet() {
    echo
    echo -e "[10/${MAX}] Starting wallet daemon..."
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 2
    echo -e "${GREEN}* Done${NONE}";
}

clear
cd

echo
echo -e "-----------------------------------------------------------------------------------"
echo -e "|                                                                                 |"
echo -e "|                 ${CYAN}(((((((((((((((((((((((((((((((((((((((((((((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((((((((((((((((((((((((((((((((((((((((((((${NONE}                 |"
echo -e "|                 ${CYAN}((((((             ,(((((((((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((((              ((((((((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}((((( ((              (((((((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((  ((.             ((((((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((   ((*             *((((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((     ((              (((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((      ((              ((((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((       ((              (((           (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((        ((*             /(*          (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((         /(/             .((         (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           ((              ((        (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           (((              ((       (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           ((((.             ((.     (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           (((((/             ,((    (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           (((((((              ((   (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           ((((((((              ((  (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           (((((((((              (( (((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           ((((((((((,             (((((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((           (((((((((((/             /(((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((((((((((((((((((((((((((((((((((((((((((((${NONE}                 |"
echo -e "|                 ${CYAN}(((((((((((((((((((((((((((((((((((((((((((((((${NONE}                 |"
echo -e "|                                                                                 |"
echo -e "|                 ${BOLD}------ Nihilo Coin Masternode installer ------${NONE}                  |"
echo -e "|                                                                                 |"
echo -e "-----------------------------------------------------------------------------------"

echo -e "${BOLD}"
read -p "This script will setup your Nihilo Pos Masternode. Do you wish to continue? (y/n)?" response
echo -e "${NONE}"

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    checkForUbuntuVersion
    updateAndUpgrade
    setupSwap
    installFail2Ban
    installFirewall
    installDependencies
    downloadWallet
    installWallet
    configureWallet
    startWallet

    echo && echo -e "${BOLD}The VPS side of your masternode has been installed. Save the masternode ip and private key so you can use them to complete your local wallet part of the setup${NONE}".
    echo && echo -e "${BOLD}Masternode IP:${NONE} ${mnip}:${COINPORT}"
    echo && echo -e "${BOLD}Masternode Private Key:${NONE} ${mnkey}"
    echo && echo -e "${BOLD}Continue with the cold wallet part of the setup${NONE}" && echo
else
    echo && echo "Installation cancelled" && echo
fi
