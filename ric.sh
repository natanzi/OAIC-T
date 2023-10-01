#!/bin/bash

LOG_FILE="install.log"

# Function to display a formatted message with a counter
print_progress() {
  local message="$1"
  printf "\n\e[1;34m%s\e[0m\n" "${message}" | tee -a $LOG_FILE
}

# Function to log the output of a command
log_command() {
  local cmd="$@"
  echo "$cmd" >> $LOG_FILE
  $cmd 2>&1 | tee -a $LOG_FILE
}

# Function to prompt user to continue or exit on error
prompt_continue_or_exit() {
  echo -e "\n\nError occurred during installation." | tee -a $LOG_FILE
  read -p "Do you want to continue? (Y/N): " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    return 0
  else
    echo "Exiting the script." | tee -a $LOG_FILE
    exit 1
  fi
}

update_packages() {
  print_progress "Updating package list..."
  log_command sudo apt update || prompt_continue_or_exit
  print_progress "Package list updated successfully."
}

clone_and_setup_git() {
  print_progress "Cloning the git repository..."
  log_command git clone https://github.com/openaicellular/oaic.git
  log_command cd oaic
  log_command git submodule update --init --recursive --remote
  log_command cd RIC-Deployment/tools/k8s/bin
  log_command ./gen-cloud-init.sh
  log_command sudo ./k8s-1node-cloud-init-k_1_16-h_2_17-d_cur.sh
  log_command sudo kubectl get ns ricinfra
  log_command sudo kubectl create ns ricinfra
  log_command sudo helm install stable/nfs-server-provisioner --namespace ricinfra --name nfs-release-1
  log_command sudo kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  log_command sudo apt-get install nfs-common
  log_command sudo docker run -d -p 5001:5000 --restart=always --name ric registry:2
  print_progress "Git repository cloned and setup successfully."
}

install_packages_with_docker() {
  print_progress "Installing packages using Docker..."
  log_command cd ../../../..
  log_command cd ric-plt-e2
  log_command cd RIC-E2-TERMINATION
  log_command sudo docker build -f Dockerfile -t localhost:5001/ric-plt-e2:5.5.0 .
  log_command sudo docker push localhost:5001/ric-plt-e2:5.5.0
  log_command cd ../../
  log_command cd RIC-Deployment/bin
  log_command sudo ./deploy-ric-platform -f ../RECIPE_EXAMPLE/PLATFORM/example_recipe_oran_e_release_modified_e2.yaml
  print_progress "Packages installed using Docker successfully."
}

# Welcome message
print_progress "Welcome to the OAIC-Project Installation!"

# Start the installation steps
update_packages
clone_and_setup_git
install_packages_with_docker

# Done message
print_progress "OAIC-Project setup completed successfully!"
