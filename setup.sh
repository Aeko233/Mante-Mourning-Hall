#!/bin/bash

mcsmanager_install_path="/opt/mcsmanager"
mcsmanager_download_addr="https://59-47-237-130.pd1.123pan.cn:30443/download-cdn.123pan.cn/123-896/ffb588bd/1815896253-0/ffb588bde6ab9ed392df8c9535dae780/c-m39?v=5&t=1719306864&s=171930686458fda6ec0bd0f344b7b8c4b2cd039d3b&r=LF9KV9&bzc=2&bzs=313632373138363a36393039353330373a33323135373337373a30&filename=mcsmanager_linux_release.tar.gz&x-mf-biz-cid=32cd54dc-3ca9-423a-87fa-89c1351e7a69-a0d664&auto_redirect=0&ndcp=1&cache_type=1&xmfcid=9018c6dd-98c1-4723-808f-ed4f879a6c65-1-50111d3b1"
package_name="mcsmanager_linux_release.tar.gz"
node="v20.12.2"
arch=$(uname -m)

if [ "$(id -u)" -ne 0]; then
    echo "This script must be run as root. Please use \"sudo bash\" instead."
    exit 1
fi

printf "\033c"

echo_cyan() {
    printf '\033[1;36m%b\033[0m\n' "$@"
}
echo_red() {
    printf '\033[1;31m%b\033[0m\n' "$@"
}
echo_green() {
    printf '\033[1;32m%b\033[0m\n' "$@"
}

echo_cyan_n() {
    printf '\033[1;36m%b\033[0m' "$@"
}

echo_yellow() {
    printf '\033[1;33m%b\033[0m\n' "$@"
}

# script info
echo_cyan "+----------------------------------------------------------------------
| MCSManager Installer
+----------------------------------------------------------------------
"

Red_Error() {
    echo '================================================='
    printf '\033[1;31;40m%b\033[0m\n' "$@"
    echo '================================================='
    exit 1
}

Install_MCSManager() {
    echo_cyan "[+] Install MCSManager..."

    # stop service
    systemctl disable --now mcsm-{web,daemon}

    # delete service
    rm -rf /etc/systemd/system/mcsm-{daemon,web}.service
    systemctl daemon-reload

    mkdir -p "${mcsmanager_install_path}" || Red_Error "[x] Failed to create ${mcsmanager_install_path}"

    # cd /opt/mcsmanager
    cd "${mcsmanager_install_path}" || Red_Error "[x] Failed to enter ${mcsmanager_install_path}"

    # download MCSManager release
    wget "${mcsmanager_download_addr}" || Red_Error "[x] Failed to download MCSManager"
    tar -zxf ${package_name} -o || Red_Error "[x] Failed to untar ${package_name}"
    rm -rf "${mcsmanager_install_path}/${package_name}"

    # echo "[→] cd daemon"
    cd "${mcsmanager_install_path}/daemon" || Red_Error "[x] Failed to enter ${mcsmanager_install_path}/daemon"

    echo_cyan "[+] Install MCSManager-Daemon dependencies..."
    env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --production --no-fund --no-audit &>/dev/null || Red_Error "[x] Failed to npm install in ${mcsmanager_install_path}/daemon"

    # echo "[←] cd .."
    cd "${mcsmanager_install_path}/web" || Red_Error "[x] Failed to enter ${mcsmanager_install_path}/web"

    echo_cyan "[+] Install MCSManager-Web dependencies..."
    env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --production --no-fund --no-audit &>/dev/null || Red_Error "[x] Failed to npm install in ${mcsmanager_install_path}/web"

    echo
    echo_yellow "=============== MCSManager ==============="
    echo_green "Daemon: ${mcsmanager_install_path}/daemon"
    echo_green "Web: ${mcsmanager_install_path}/web"
    echo_yellow "=============== MCSManager ==============="
    echo
    echo_green "[+] MCSManager installation success!"

    chmod -R 755 "$mcsmanager_install_path"

    sleep 3
}

Create_Service() {
    echo_cyan "[+] Create MCSManager service..."

    echo "[Unit]
Description=MCSManager-Daemon

[Service]
WorkingDirectory=${mcsmanager_install_path}/daemon
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/mcsm-daemon.service

    echo "[Unit]
Description=MCSManager-Web

[Service]
WorkingDirectory=${mcsmanager_install_path}/web
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/mcsm-web.service

    systemctl daemon-reload
    systemctl enable --now mcsm-{daemon,web}.service
    echo_green "Registered!"

    sleep 2

    printf "\n\n\n\n"

    echo_yellow "=================================================================="
    echo_green "Installation is complete! Welcome to the MCSManager!!!"
    echo_yellow " "
    echo_cyan_n "HTTP Web Service:        "
    echo_yellow "http://<Your IP>:23333  (Browser)"
    echo_cyan_n "Daemon Address:          "
    echo_yellow "ws://<Your IP>:24444    (Cluster)"
    echo_red "You must expose ports "
	echo_yellow "23333"
	echo_red " and " 
	echo_yellow "24444"
	echo_red " to use the service properly on the Internet."
    echo_yellow " "
    echo_cyan "Usage:"
    echo_cyan "systemctl start mcsm-{daemon,web}.service"
    echo_cyan "systemctl stop mcsm-{daemon,web}.service"
    echo_cyan "systemctl restart mcsm-{daemon,web}.service"
    echo_yellow " "
    echo_green "Official Document: https://docs.mcsmanager.com/"
    echo_yellow "=================================================================="
}

# Environmental inspection
if [[ "$arch" == x86_64 ]]; then
    arch=x64
    #echo "[-] x64 architecture detected"
elif [[ $arch == aarch64 ]]; then
    arch=arm64
    #echo "[-] 64-bit ARM architecture detected"
elif [[ $arch == arm ]]; then
    arch=armv7l
    #echo "[-] 32-bit ARM architecture detected"
elif [[ $arch == ppc64le ]]; then
    arch=ppc64le
    #echo "[-] IBM POWER architecture detected"
elif [[ $arch == s390x ]]; then
    arch=s390x
    #echo "[-] IBM LinuxONE architecture detected"
else
    Red_Error "[x] Sorry, this architecture is not supported yet!\n[x]Please try to install manually: https://github.com/MCSManager/MCSManager#linux"
fi

# Define the variable Node installation directory
node_install_path="/opt/node-$node-linux-$arch"

# Check network connection
echo_cyan "[-] Architecture: $arch"

# Install related software
echo_cyan_n "[+] Installing dependent software (git, tar, wget)... "
if [[ -x "$(command -v yum)" ]]; then
    yum install -y git tar wget
elif [[ -x "$(command -v apt-get)" ]]; then
    apt-get install -y git tar wget
elif [[ -x "$(command -v pacman)" ]]; then
    pacman -S --noconfirm git tar wget
elif [[ -x "$(command -v zypper)" ]]; then
    zypper --non-interactive install git tar wget
else
    echo_red "[!] Cannot find your package manager! You may need to install git, tar and wget manually!"
fi

# Determine whether the relevant software is installed successfully
if [[ -x "$(command -v git)" && -x "$(command -v tar)" && -x "$(command -v wget)" ]]; then
    echo_green "Success"
else
    Red_Error "[x] Failed to find git, tar and wget, please install them manually!"
fi

# Install the Node environment
Install_Node

# Install MCSManager
Install_MCSManager

# Create MCSManager background service
Create_Service
