#!/bin/bash

# Function to display a formatted message with a counter
print_progress() {
  local message="$1"
  local counter="$2"
  printf "\r\e[2K[\e[1;32m%s\e[0m] %s" "${counter}" "${message}"
}

# Function to prompt user to continue or exit on error
prompt_continue_or_exit() {
  echo -e "\n\nError occurred during installation."
  read -p "Do you want to continue? (Y/N): " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    return 0
  else
    echo "Exiting the script."
    exit 1
  fi
}

# Welcome message
echo -e "\e[1;34mWelcome to the OAIC-Project Setup Script!\e[0m"
echo -e "This script will guide you through the installation and setup process.\n"

# Counter for tracking progress
counter=0

# Part 1: Installing prerequisites
echo -e "\e[1;33mPart 1: Installing prerequisites...\e[0m"
((counter++))
print_progress "Updating package list" $counter
sudo apt update || prompt_continue_or_exit

((counter++))
print_progress "Installing git" $counter
sudo apt install -y git || prompt_continue_or_exit

((counter++))
print_progress "Installing python3" $counter
sudo apt install -y python3 || prompt_continue_or_exit

((counter++))
print_progress "Installing vim" $counter
sudo apt install -y vim || prompt_continue_or_exit

# Part 2: Cloning and setting up the git repository
echo -e "\n\e[1;33mPart 2: Cloning and setting up the git repository...\e[0m"
((counter++))
print_progress "Cloning OAIC repository" $counter
git clone https://github.com/openaicellular/oaic.git || prompt_continue_or_exit

((counter++))
print_progress "Updating git submodules" $counter
cd oaic
git submodule update --init --recursive --remote || prompt_continue_or_exit

((counter++))
print_progress "Running cloud init scripts" $counter
cd RIC-Deployment/tools/k8s/bin
./gen-cloud-init.sh || prompt_continue_or_exit
sudo ./k8s-1node-cloud-init-k_1_16-h_2_17-d_cur.sh || prompt_continue_or_exit

((counter++))
print_progress "Setting up Kubernetes namespace" $counter
sudo kubectl get ns ricinfra || prompt_continue_or_exit
sudo kubectl create ns ricinfra || prompt_continue_or_exit

((counter++))
print_progress "Installing NFS server provisioner" $counter
sudo helm install stable/nfs-server-provisioner --namespace ricinfra --name nfs-release-1 || prompt_continue_or_exit

((counter++))
print_progress "Patching storage class" $counter
sudo kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || prompt_continue_or_exit

((counter++))
print_progress "Installing NFS common" $counter
sudo apt-get install nfs-common || prompt_continue_or_exit

((counter++))
print_progress "Running Docker container" $counter
sudo docker run -d -p 5001:5000 --restart=always --name ric registry:2 || prompt_continue_or_exit

cd ../../../..
cd ric-plt-e2

cd RIC-E2-TERMINATION
((counter++))
print_progress "Building Docker image" $counter
sudo docker build -f Dockerfile -t localhost:5001/ric-plt-e2:5.5.0 . || prompt_continue_or_exit

((counter++))
print_progress "Pushing Docker image" $counter
sudo docker push localhost:5001/ric-plt-e2:5.5.0 || prompt_continue_or_exit
cd ../../

# Part 3: Installing packages using Docker and other steps
echo -e "\n\e[1;33mPart 3: Installing packages using Docker and other steps...\e[0m"
cd RIC-Deployment/bin

((counter++))
print_progress "Deploying RIC platform" $counter
sudo ./deploy-ric-platform -f ../RECIPE_EXAMPLE/PLATFORM/example_recipe_oran_e_release_modified_e2.yaml || prompt_continue_or_exit

# Completion message
echo -e "\n\e[1;32mOAIC-RIC setup completed successfully!\e[0m\n"
