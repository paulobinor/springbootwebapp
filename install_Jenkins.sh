#!/bin/bash
sudo yum update –y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y

#install aws cli
echo "Installing AWS CLI.."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
sudo apt install unzip
sudo unzip awscliv2.zip  
sudo ./aws/install -y
echo "AWS CLI installation Complete!"

#install helm
echo "Installing Helm.."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh
echo "Helm installation Complete!"

#install kubectl
echo "Installing Kubectl.."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y 
echo "Kubectl installation Complete!"

#install eksctl
echo "Installing eksctl..!"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
echo "eksctl installation Complete!"

#install and prep jenkins
sudo amazon-linux-extras install java-openjdk11 -y
sudo apt install maven -y
sudo sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo sudo systemctl start jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword