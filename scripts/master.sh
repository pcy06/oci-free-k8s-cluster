#!/bin/bash

CALICO_DEFAULT_CIDR="192.168.0.0/16"
POD_NETWORK_CIDR="172.16.0.0/16"
SERVICE_CIDR="192.168.0.0/16"
DEFAULT_USER="ubuntu"

# sudo iptables-save > ~/iptables-rules

# grep -v "DROP" iptables-rules > tmpfile && mv tmpfile iptables-rules-mod
# grep -v "REJECT" iptables-rules-mod > tmpfile && mv tmpfile iptables-rules-mod

# sudo iptables-restore < ~/iptables-rules-mod

# sudo netfilter-persistent save
# sudo systemctl restart iptables

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt update

sudo apt install -y containerd.io

sudo systemctl enable containerd
sudo systemctl start containerd

sudo modprobe br_netfilter
sudo modprobe overlay

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab

sudo rm -rf /etc/containerd/config.toml
sudo systemctl restart containerd

while true; do
    sudo kubeadm init --pod-network-cidr $POD_NETWORK_CIDR --service-cidr $SERVICE_CIDR

    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "Master Node Initalization done successfully."
        break
    else
        echo "Master Node Initalization failed with exit code $exit_code. Retrying..."
        sleep 3
    fi
done

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/$DEFAULT_USER/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/$DEFAULT_USER/.kube/config
sudo chown $DEFAULT_USER /home/$DEFAULT_USER/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml

sed -i "s|$CALICO_DEFAULT_CIDR|$POD_NETWORK_CIDR|g" "custom-resources.yaml"

kubectl create -f custom-resources.yaml

content=$(kubeadm token create --print-join-command)

output_file="/tmp/master.env"

MASTER_HOST=$(echo "$content" | grep -oP 'join \K[^\s]+')
MASTER_TOKEN=$(echo "$content" | grep -oP -- '--token \K[^\s]+')
MASTER_CA_CERT_HASH=$(echo "$content" | grep -oP -- '--discovery-token-ca-cert-hash \K[^\s]+')

echo "MASTER_HOST=\"$MASTER_HOST\"" > "$output_file"
echo "MASTER_TOKEN=\"$MASTER_TOKEN\"" >> "$output_file"
echo "MASTER_CA_CERT_HASH=\"$MASTER_CA_CERT_HASH\"" >> "$output_file"

echo "Master Node Initalization done successfully."