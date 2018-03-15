# [:arrow_backward:](../README.md) Masternode Guide for Windows Cold Wallet and Linux VPS
This guide will help you setup your **Nihilo Masternode** in the most convenient way. You keep a hot wallet on a **Linux VPS** so the **Masternode** can be always on and keep you collateral safe in your **Windows wallet** that isn't always connected to the internet.

Even is this guide is designed for **Windows Cold Wallet** it should also work for **Mac** and **Linux** QT wallets.

**This guide can be also used to upgrade masternodes to new Nihilo Pos masternodes**

## Table of contents
- **[Requirements](#requirements)**
- **[Installation](#linux-vps-setup)**
  - **[Setting up the collateral address](#setting-up-the-collateral-address)**
  - **[Setting up the VPS](#setting-up-the-vps)** 	
  - **[Configure and start Masternode](#configure-and-start-masternode)**
- **[FAQ](#faq)**

## Requirements
- 10,000 **NIHL** coins
- **VPS Server** with **root** access runing **Ubuntu 16.04 x64** operation with the following **minimum** specs:
	- **1GHZ** CPU Core
	- **1GB** of ram
- **Windows** computer with a **ssh client** installed ( **[www.putty.org](http://www.putty.org)** is recommended )

### Setting up the collateral address
We are going to start with the **collateral address** setup so we can get all the confirmations needed to start the masternode, till we finish the rest of the setup.

**Step 1 - Create new receiving address** 
Go to the **``Receive``** tab on the left and click on **``New Address``** button. In here give it a name, we will call it ``masternode1`` and click the **``Ok``** button.

**Step 2 - Send 10,000 Nihilo Coins** 
Go to the **``Send``** tab on the left and copy paste the address created earlier in the **``Pay to``** input ( the label will be automatically set to the name you gave it in **Step 1**), type in the **``Amount``** input exactly ``10000.00000000``. 
Now double check all the inputs and click on the **``Send``** button in order to send the **10,000** coins to your masternodes collateral address.

**The process of setting up the collateral address can be viewed in the gif bellow.**

![](./images/setting-collateral-address.gif)

### Setting up the VPS
Log intro your **VPS** using **[www.putty.org](http://www.putty.org)** or any other **ssh client** you have as **root** and type the following commands:

**If you upgrade from old Nihilo Masternode and don't have any other masternode coins**
````
cd
wget "https://raw.githubusercontent.com/nihilocoin/pos-resources/master/smart-install-script.sh"
chmod 755 smart-install-script.sh
sudo bash smart-install-script.sh
````

**If you have other masternode coins on you vps, use this**

````
cd
wget "https://raw.githubusercontent.com/nihilocoin/pos-resources/master/smart-install-script-without-upgrade.sh"
chmod 755 smart-install-script.sh
sudo bash smart-install-script.sh
````

Now grab a coffee :coffee: or whatever beverage you preffer and wait for the **smart install script** to do it's **magic**. 

After the script finished it will output the **Masternode Ip** and **Masternode Private Key** that you will need to **save** in order to finish the setup. 

The output will look like this:

````
Masternode Ip: 123.123.123.123:5353
Masternode Private Key: 75PvpMAfpweLLpyvZ5QidffsFAWYRMeiFgVs4NUYkna6hV4Vq
````

### Configure and start Masternode
Let's first check if our transaction has at least 10 confirmations. You can do this by going to the **``Transactions Tab``** and just hover over the left icon of the transaction. If it has 10 confirmations you can continue, if not just wait a little longer for it to have at least 10.

**Step 1 - Get the tx and index**
In the wallets top menu, go to **``Help``** and select **``Debug window``**. Type in there ``masternode outputs`` and you will receive something in the following format:
````
{
  "75PvpMAfpweLLpyvZ5QidffsFAWYRMeiFgVs4NUYkna6hV4Vq" : "1"
}
````

This output translates to the following:

````
{
  "tx" : "index"
}
````

Now grab your **tx** and **index** and save it near the **Masternode Ip** and **Masternode Private Key** you got from the **smart install script** on the **VPS**.

**Step 2 - Create and start masternode**
Now that we have everything we need, go to the **``Masternode``** tab on the left and select **``My Masternode Nodes``**. 
Click on the **``Create...``** button and fill the fields:
- **Alias** - Whatever name you want, this is only for you to identify each masternode locally
- **Address** - Your **``Masternode Ip``** that you saved from the **smart install script** on the **VPS**
- **PrivKey** - Your **``Masternode Private Key``** that you saved from the **smart install script** on the **VPS**
- **TxHash** - The **``tx``** value you got earlier from **Debug console** by running **``masternode outputs``** command. Do not include the quotes, just the value. 
- **Output Index** - The **``index``** value you got earlier from **Debug console** by running **``masternode outputs``** command. Do not include the quotes, just the numeric value. 
- **Reward Address** - leave empty
- **Reward %** - leave empty

Now click the **``Ok``** button. If the masternode does not appear in the list after clicking the **``Ok``** button, just click on the **``Update button``** and it will appear.

We now have the masternode in the list, make sure your wallet is unlocked ( not just for staking ), select it and click on the **``Start``** button.

**The process from Step 2 can be viewed in the following gif**

![](./images/configure-and-start-masternode.gif)

### Faq

**I started my wallet today and i don't see any of my masternodes in the list**
Just click the **``Update``** button and they will appear.

**I'm getting and error when I click the ``Start`` button on a masternode**
First check if you fully unlocked your wallet, while unlocking you wallet you has an option to unckeck ``For staking only`` so unckeck it.
If this still doesn't fix your problem, check the guide again making sure you followed all the steps correctly.



s
