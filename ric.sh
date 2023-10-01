echo -e "\e[1;34m"
cat << "EOF"
  ____                   _    _    _     _   
 / ___|  ___   ___  _ __| |_ / |_ | |__ (_)_ 
 \___ \ / _ \ / _ \| '__| __| | __|| '_ \| \ \
  ___) |  __/|  __/| |  | |_| | |_ | | | | |\ \
 |____/ \___| \___||_|   \__|_|\__||_| |_|_| \_\
                                                
EOF
echo -e "\e[0m"
echo -e "Welcome to \e[1;32mOAIC Setup\e[0m!"
echo -e "Let's get started...\n"
#!/bin/bash

LOG_FILE="install.log"

print_progress() {
  local message="$1"
  printf "\n\e[1;34m%s\e[0m\n" "${message}" | tee -a $LOG_FILE
}

log_command() {
  local cmd="$@"
  echo "$cmd" >> $LOG_FILE
  $cmd 2>&1 | tee -a $LOG_FILE
}

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

setup_git() {
  print_progress "Setting up Git repository..."
  log_command git clone https://github.com/openaicellular/oaic.git oaic
  log_command git -C oaic submodule update --init --recursive --remote
  print_progress "Git repository setup successfully."
}

configure_k8s() {
  print_progress "Configuring Kubernetes..."
  log_command sudo ./oaic/RIC-Deployment/tools/k8s/bin/gen-cloud-init.sh
  log_command sudo ./oaic/RIC-Deployment/tools/k8s/bin/k8s-1node-cloud-init-k_1_16-h_2_17-d_cur.sh
  log_command sudo apt-get install nfs-common
  log_command sudo docker run -d -p 5001:5000 --restart=always --name ric registry:2
  print_progress "Kubernetes configured successfully."
}

deploy_docker() {
  print_progress "Deploying Docker containers..."
  log_command sudo docker build -f ./oaic/ric-plt-e2/RIC-E2-TERMINATION/Dockerfile -t localhost:5001/ric-plt-e2:5.5.0 .
  log_command sudo docker push localhost:5001/ric-plt-e2:5.5.0
  log_command sudo ./oaic/RIC-Deployment/bin/deploy-ric-platform -f ./oaic/RIC-Deployment/RECIPE_EXAMPLE/PLATFORM/example_recipe_oran_e_release_modified_e2.yaml
  print_progress "Docker containers deployed successfully."
}

# Welcome message
echo -e "\e[1;34m"
cat << "EOF"
  ____                   _    _    _     _   
 / ___|  ___   ___  _ __| |_ / |_ | |__ (_)_ 
 \___ \ / _ \ / _ \| '__| __| | __|| '_ \| \ \
  ___) |  __/|  __/| |  | |_| | |_ | | | | |\ \
 |____/ \___| \___||_|   \__|_|\__||_| |_|_| \_\
                                                
EOF
echo -e "\e[0m"
echo -e "Welcome to \e[1;32mOAIC Setup\e[0m!"
echo -e "Let's get started...\n"

update_packages
setup_git
configure_k8s
deploy_docker

print_progress "OAIC RIC setup completed successfully!"
