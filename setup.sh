MANAGER="docker-manager"
WORKER1="docker-worker1"
WORKER2="docker-worker2"

# Create a lxc container from ubuntu template and install docker in it
function create_container()
{
    lxc-info $1 &> /dev/null
    if [[ "$?" == "1" ]]; then
        echo "[*] Creating $1 container:" 
        (lxc-create -n $1 -t download -- -d ubuntu -r jammy -a amd64) &> /dev/null

        # make this container privileged
        echo "# For docker" >> /var/lib/lxc/$1/config
        echo "lxc.apparmor.profile = unconfined" >> /var/lib/lxc/$1/config
        echo "lxc.cgroup.devices.allow = a" >> /var/lib/lxc/$1/config
        echo "lxc.cap.drop =" >> /var/lib/lxc/$1/config

        echo -en "[*]   Starting $1: "
        (lxc-start $1) &> /dev/null
        (lxc-wait -s RUNNING $1) &> /dev/null
        echo "Done" 
        echo -en "[*]   Installing docker inside $1 (may take some time): "

        cmds="
        apt-get update;
        apt-get install -y apt-transport-https ca-certificates curl gnupg;
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -;
        apt-key fingerprint 0FDEDC98;
        echo \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" \
           >> /etc/apt/sources.list;
        apt-get update;
        apt install -y docker-ce;
        " 

        (echo $cmds | lxc-attach $MANAGER -- /bin/bash) &> /dev/null

        echo "Done" 
    else
        echo "[*] Skipping creation of $1: already exists"  
    fi
}

# Destroy an lxc container
function destroy_container()
{
    (lxc-stop $1) &> /dev/null
    (lxc-destroy $1) &> /dev/null
}

function install()
{
    echo "[*] Enabling br_netfilter"
    modprobe br_netfilter
    sysctl net.bridge.bridge-nf-call-iptables=1

    echo "[*] Setting up containers..."
    create_container $MANAGER
    (lxc-stop $MANAGER) &> /dev/null
 
    for name in $WORKER1 $WORKER2; do
        lxc-info $name &> /dev/null
        if [[ "$?" == "1" ]]; then
            echo -en "[*] Cloning $name container: " 
            (lxc-copy -n $MANAGER -N $name) &> /dev/null
            echo "Done" 
        else
            echo "[*] Skipping creation of $name: already exists"  
        fi
    done
        
     for name in $MANAGER $WORKER1 $WORKER2; do
        (lxc-start $name) &> /dev/null    
    done
}

function clean()
{
    echo "[*] Disabling br_netfilter"
    modprobe -r br_netfilter
    echo "[*] Cleaning containers ..."
    for name in $MANAGER $WORKER1 $WORKER2; do
        destroy_container $name
    done
}

user=$(id -u)
if [[ "$user" == "0" ]]; then
    if [[ "$1" == "install" ]]; then
        install
    elif [[ "$1" == "clean" ]]; then
        clean
    else
        echo "usage: $0 <[install|clean]>"
    fi
else
    echo "You need to execute this script as root"
fi

