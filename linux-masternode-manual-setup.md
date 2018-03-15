# [:arrow_backward:](./README.md) Linux Masternode Manual Setup

## Table of contents
- **[Setup swap space](#setup-swap-space)**
- **[Update and upgrade](#update-and-upgrade)**
- **[Basic Intrusion Prevention with Fail2Ban](#basic-intrusion-prevention-with-fail2ban)**
- **[Set Up a Basic Firewall](#set-up-a-basic-firewall)**
- **[Install required dependencies](#install-required-dependencies)**
- **[Install the wallet](#install-the-wallet)**
- **[Configure the wallet](#configure-the-wallet)**
- **[Start the wallet](#start-the-wallet)**
- **[Getting masternode config for windows wallet](#getting-masternode-config-for-windows-wallet)**

## Setup swap space
This is our first step, i know **swap space** is slow, but for a **VPS** with only **1GB of ram** it's mandatory. Log into the **VPS** as root and start typing the following commands:

````bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
````

Now that the swap is created, let's make it work better

````bash
sudo nano /etc/sysctl.conf
````

Add to the bottom of the file

````
vm.swappiness=10
vm.vfs_cache_pressure=50	
````

Also let's make sure the swap if mounted again after a server restart

````bash
sudo nano /etc/fstab
````

Add to the bottom of the file

````
/swapfile   none    swap    sw    0   0
````

## Update and upgrade
Now let's run **update** and **upgrade** by typing the following commands:

````bash
sudo apt-get -y update
sudo apt-get -y upgrade
````

You will be asked to choose an option when upgrading, leave the default one that is selected and just hit **``Enter``**.

## Basic Intrusion Prevention with Fail2Ban
We will add a basic **dictionary attack** protection. This will ban an IP address for 10 minutes after 10 failed login attempts.

````bash
sudo apt-get -y install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
````

If you want to see what **Fail2Ban** is doing behing the scenes just type the following command. You can exit with **``CTRL+C``**.

````bash
sudo tail -f /var/log/fail2ban.log
````

## Set Up a Basic Firewall
**Ubuntu 16.04** can use the **UFW Firewall** to make sure only connections to certain services are allowed. We can set up a basic firewall very easily using this application.

````bash
sudo ufw allow OpenSSH
sudo ufw allow 5353/tcp
sudo ufw enable
````

You will be asked if you want to enable it, type **``Y``**. If you want to see the status of the **firewall** type the following command:

````bash
sudo ufw status
````

## Install required dependencies
In order to build the wallet, we need to install the following dependencies:

````bash
sudo apt-get -y install git nano rpl wget python-virtualenv build-essential libtool automake autoconf autotools-dev autoconf pkg-config libssl-dev libgmp3-dev libevent-dev bsdmainutils libboost-all-dev software-properties-common python-software-properties virtualenv
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev libminiupnpc-dev libzmq5
````	

## Install the wallet
Now we need to clone the **coin source** from **github** and build the wallet. Type the following commands to do so:

````bash
cd
wget https://github.com/nihilocoin/pos-resources/releases/download/2.0.0/Nihilo-Linux-CLI-V2
mv Nihilo-Linux-CLI-V2 nihilod
chmod 755 nihilod
````

After the compilation is done, let's make the wallet so we can access it from any location.

````bash
strip nihilod
sudo mv nihilod /usr/bin
````

## Configure the wallet
Let's configure the wallet now, we'll start by **starting the wallet daemon for 10 seconds and then closing it again**. We are doing this so the wallet can dump it's core.

````bash
nihilod
#press enter and daemon will stop
````

Now lets configure the **``nihilo.conf``** configuration files. The file is located in **``~/.nihilo``** but we will use the following commands to add the required config.

````bash
mnip=$(curl --silent ipinfo.io/ip)

rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowedip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1" > ~/.nihilo/.nihilo.conf
nihilod

mnkey=$(nihilod masternode genkey)

nihilod

sleep 2

nihilod stop

echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcport=5454\nrpcallowip=127.0.0.1\ndaemon=1\nserver=1\nlisten=1\ntxindex=1\nlistenonion=0\nmasternode=1\nmasternodeaddr=${mnip}:${COINPORT}\nmasternodeprivkey=${mnkey}\naddnode=ns1.nihilo.space\naddnode=ns2.nihilo.space\naddnode=ns3.nihilo.space\naddnode=ns4.nihilo.space\naddnode=ns5.nihilo.space\naddnode=ns6.nihilo.space\naddnode=ns7.nihilo.space\naddnode=ns8.nihilo.space\naddnode=ns9.nihilo.space\naddnode=ns10.nihilo.space" > ~/.nihilo/.nihilo.conf
````

## Start the wallet

````bash
nihilod
````

## Getting masternode config for windows wallet
:white_check_mark: **Great**, now everything is ready on our **Linux VPS**, type the following command to receive the line that you will need in order to finish the **Windows** part.

````bash
echo "Masternode IP: ${mnip}:5353" && echo && echo "Masternode Private Key: ${mnkey}"
````

**Save** the **masternode ip** and **masternode private key** somewhere on your pc and continue with the cold wallet part.
