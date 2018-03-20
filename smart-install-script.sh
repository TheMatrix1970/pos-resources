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

purgeOldInstallation() {
    echo "Searching and removing old masternode files and configurations"

    #kill wallet daemon
    sudo killall nihilod > /dev/null 2>&1

    #remove old ufw port allow
    sudo ufw delete allow 13535/tcp > /dev/null 2>&1

    #remove old files
    sudo rm -rf ~/.nihilocore > /dev/null 2>&1

    #remove log file
    sudo rm -rf ~/sentinel.log > /dev/null 2>&1
    sudo rm -rf ~/reindex.log > /dev/null 2>&1

    #remove all sh files in ~ folder
    sudo find ~/ -type f -iname \*.sh -delete > /dev/null 2>&1

    #remove binaries and nihilo utilities
    cd /usr/bin && sudo rm -rf nihilo-cli nihilo-tx nihilod nihilo > /dev/null 2>&1 && cd
    sudo rm -rf nihilo-cli nihilo-tx nihilod nihilo > /dev/null 2>&1

    #remove leftover folder and files that contain nihilo in their name just to be sure
    sudo find ~/ -name '*nihilo*' -delete > /dev/null 2>&1
    sudo find ~/ -name '*Nihilo*' -delete > /dev/null 2>&1

    #clear crontab
    cd && touch mycron && crontab mycron && sudo rm -rf mycron > /dev/null 2>&1

    echo -e "${GREEN}* Done${NONE}";
}

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

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcport=5454\nrpcallowip=127.0.0.1\ndaemon=1\nserver=1\nlisten=1\ntxindex=1\nlistenonion=0\nmasternode=1\nmasternodeaddr=${mnip}:${COINPORT}\nmasternodeprivkey=${mnkey}\naddnode=ns1.nihilo.space\naddnode=ns2.nihilo.space\naddnode=ns3.nihilo.space\naddnode=ns4.nihilo.space\naddnode=ns5.nihilo.space\naddnode=ns6.nihilo.space\naddnode=ns7.nihilo.space\naddnode=ns8.nihilo.space\naddnode=ns9.nihilo.space\naddnode=ns10.nihilo.space\naddnode=159.89.230.236:5353\naddnode=104.238.151.107:5353\naddnode=104.156.249.56:5353\naddnode=144.202.6.195:5353\naddnode=45.77.190.226:5353\naddnode=45.76.17.23:5353\naddnode=207.148.64.219:5353\naddnode=207.148.65.66:5353\naddnode=45.77.139.153:5353\naddnode=139.59.63.194:5353\naddnode=172.104.243.224:5353\naddnode=46.38.236.102:5353\naddnode=46.38.232.78:5353\naddnode=144.202.115.152:5353\naddnode=207.246.110.242:5353\naddnode=104.238.140.250:5353\naddnode=46.38.237.7:5353\naddnode=45.77.111.134:5353\naddnode=18.222.60.114:5353\naddnode=5.45.100.98:5353\naddnode=144.202.103.41:5353\naddnode=107.175.95.234:5454\naddnode=172.245.124.130:5454\naddnode=107.172.168.218:5454\naddnode=172.245.110.111:5454\naddnode=23.94.69.164:5454\naddnode=194.67.207.15:5353\naddnode=18.222.46.20:5353\naddnode=159.89.16.22:5353\naddnode=45.63.66.226:5353\naddnode=45.76.7.57:5353\naddnode=172.104.150.79:5353\naddnode=45.77.230.108:5353\naddnode=45.77.248.188:5353\naddnode=13.125.222.240:5353\naddnode=52.78.115.206:5353\naddnode=159.65.53.106:5353\naddnode=159.89.106.70:5353\naddnode=45.76.137.130:5353\naddnode=45.76.138.220:5353\naddnode=45.76.52.147:5353\naddnode=90.156.157.28:5353\naddnode=45.77.121.183:5353\naddnode=45.77.247.215:5353\naddnode=18.219.190.135:5353\naddnode=159.65.129.20:5353\naddnode=139.162.156.72:5353\naddnode=128.199.236.140:5353\naddnode=45.63.4.88:5353\naddnode=199.247.16.205:5353\naddnode=45.76.135.64:5353\naddnode=165.227.23.125:5353\naddnode=199.247.1.138:5353\naddnode=45.76.63.242:5353\naddnode=144.202.64.102:5353\naddnode=45.32.192.222:5353\naddnode=207.148.2.227:5353\naddnode=108.61.182.122:5353\naddnode=45.32.101.234:13535\naddnode=144.202.51.54:5353\naddnode=45.76.243.154:5353\naddnode=185.28.103.35:5353\naddnode=108.61.219.62:5353\naddnode=198.13.35.32:5353\naddnode=178.239.54.228:5353\naddnode=45.32.127.179:5353\naddnode=199.247.28.195:5353\naddnode=107.175.144.13:5353\naddnode=37.148.210.11:5353\naddnode=45.77.136.194:5353\naddnode=199.247.16.157:5353\naddnode=199.247.18.246:5353\naddnode=45.76.91.232:5353\naddnode=104.207.130.154:5353\naddnode=198.13.35.234:5353\naddnode=45.63.74.6:5353\naddnode=104.238.176.62:5353\naddnode=45.76.132.102:5353\naddnode=45.77.89.33:5353\naddnode=46.38.233.91:5353\naddnode=104.238.145.134:5353\naddnode=45.63.51.217:5353\naddnode=45.77.121.151:5353\naddnode=173.199.119.78:5353\naddnode=45.77.215.6:5353\naddnode=82.208.35.189:13535\naddnode=45.76.62.91:5353\naddnode=45.77.58.63:5353\naddnode=45.32.123.0:5353\naddnode=45.76.143.60:5353\naddnode=83.169.34.206:5353\naddnode=195.201.10.32:5353\naddnode=159.89.231.153:5353\naddnode=159.65.233.11:5353\naddnode=138.68.190.136:5353\naddnode=45.32.199.144:5353\naddnode=209.250.243.219:5353\naddnode=46.188.45.34:5353\naddnode=62.77.155.120:5353\naddnode=62.77.156.179:5353\naddnode=80.209.224.248:5353\naddnode=165.227.38.96:5353\naddnode=159.65.159.56:5353\naddnode=83.169.38.133:5353\naddnode=185.183.182.176:5353\naddnode=199.247.28.68:5353\naddnode=199.247.18.137:5353\naddnode=165.227.107.73:5353\naddnode=45.63.34.212:5353\naddnode=45.77.145.188:5353\naddnode=37.148.211.246:5353\naddnode=5.175.4.62:13536\naddnode=82.208.35.185:5353\naddnode=82.208.35.181:5353\naddnode=45.32.186.13:5353\naddnode=199.247.30.114:5353\naddnode=45.63.91.1:5353\naddnode=199.247.31.137:5353\naddnode=199.247.24.139:5353\naddnode=193.33.201.48:5353\naddnode=199.247.25.105:5353\naddnode=45.77.140.182:5353\naddnode=45.77.3.196:5353\naddnode=45.63.84.48:5353\naddnode=199.247.25.94:5353\naddnode=108.61.103.39:5353\naddnode=209.250.246.204:5353\naddnode=45.76.81.116:5353\naddnode=194.169.239.231:5353\naddnode=194.169.239.232:5353\naddnode=194.169.239.233:5353\naddnode=144.202.68.95:5353\naddnode=199.247.16.249:5353\naddnode=82.208.35.183:5353\naddnode=82.208.35.174:13535\naddnode=98.100.196.174:5353\naddnode=159.89.82.141:5353\naddnode=198.199.121.92:5353\naddnode=45.35.73.195:5353\naddnode=104.223.25.3:5353\naddnode=45.76.169.241:5353\naddnode=45.76.246.181:5353\naddnode=45.77.135.193:5353\naddnode=104.238.152.234:5353\naddnode=70.167.245.140:5353\naddnode=45.32.33.247:5353\naddnode=110.232.113.53:5353\naddnode=110.232.112.81:5353\naddnode=110.232.114.6:5353\naddnode=199.247.25.107:5353\naddnode=45.76.214.241:5353\naddnode=45.76.233.170:5353\naddnode=34.245.65.93:5353\naddnode=45.32.141.10:5353\naddnode=192.227.174.12:5353\naddnode=45.76.205.55:5353\naddnode=68.233.236.105:5353\naddnode=195.201.92.122:5353\naddnode=198.13.42.92:5353\naddnode=45.32.172.140:5353\naddnode=144.202.89.58:5353\naddnode=45.32.162.143:5353\naddnode=45.32.157.231:5353\naddnode=92.222.65.177:5353\naddnode=94.156.35.190:5353\naddnode=146.199.185.170:5353\naddnode=138.68.59.86:5353\naddnode=45.32.252.226:5353\naddnode=199.247.16.18:5353\naddnode=45.63.49.219:5353\naddnode=172.106.3.203:5353\naddnode=172.106.3.204:5353\naddnode=199.247.5.188:5353\naddnode=45.32.174.194:13535\naddnode=199.247.5.78:5353\naddnode=199.247.30.249:5353\naddnode=207.148.78.70:5353\naddnode=85.121.196.181:5353\naddnode=108.61.207.229:5353\naddnode=172.245.36.171:13535\naddnode=209.250.253.136:5353\naddnode=103.75.190.201:5353\naddnode=45.76.135.199:5353\naddnode=209.250.226.106:5353\naddnode=107.173.250.24:5353\naddnode=128.199.79.85:5353\naddnode=199.247.29.180:5353\naddnode=45.35.2.203:5353\naddnode=173.199.70.251:5353\naddnode=45.76.239.71:5353\naddnode=45.79.207.203:5353\naddnode=144.202.21.14:5353\naddnode=107.173.250.70:5353\naddnode=207.201.218.197:5353\naddnode=68.233.236.104:5353\naddnode=68.233.236.111:5353\naddnode=68.233.236.116:5353\naddnode=68.233.236.118:5353\naddnode=82.16.238.35:5353\naddnode=167.99.160.136:5353\naddnode=199.247.28.178:5353\naddnode=209.250.254.106:5353\naddnode=199.247.26.86:5353\naddnode=82.223.26.113:5353\naddnode=45.77.47.127:5353\naddnode=45.32.104.225:5353\naddnode=80.211.211.231:5353\naddnode=144.202.18.161:5353\naddnode=185.224.249.64:5353\naddnode=104.238.147.84:5353\naddnode=207.246.116.221:5353\naddnode=45.77.180.230:5353\naddnode=68.233.236.103:5353\naddnode=68.233.236.106:5353\naddnode=68.233.236.107:5353\naddnode=68.233.236.108:5353\naddnode=68.233.236.109:5353\naddnode=199.247.17.22:5353\naddnode=68.233.236.117:5353\naddnode=43.254.133.122:5353\naddnode=68.233.236.110:5353" > ~/$COINCORE/$COINCONFIG

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
    purgeOldInstallation
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
