#!/bin/bash

LOG_FILE="install-srsranE2.log"

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

install_dependencies() {
  print_progress "Installing dependencies..."
  log_command sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev libtool autoconf libzmq3-dev libuhd-dev libuhd4.5.0 uhd-host
  log_command sudo add-apt-repository ppa:ettusresearch/uhd
  log_command sudo apt-get update
  print_progress "Dependencies installed successfully."
}

clone_and_setup_asn1c() {
  print_progress "Cloning and setting up asn1c..."
  log_command git clone https://gitlab.eurecom.fr/oai/asn1c.git
  log_command cd asn1c
  log_command git checkout velichkov_s1ap_plus_option_group
  log_command autoreconf -iv
  log_command ./configure
  log_command make -j`nproc`
  log_command sudo make install
  log_command sudo ldconfig
  log_command cd ..
  print_progress "asn1c setup successfully."
}

setup_srsRAN_e2() {
  print_progress "Setting up srsRAN-e2..."
  log_command cd srsRAN-e2
  log_command mkdir build
  log_command export SRS=`realpath .`
  log_command cd build
  log_command cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo \
              -DRIC_GENERATED_E2AP_BINDING_DIR=${SRS}/e2_bindings/E2AP-v01.01 \
              -DRIC_GENERATED_E2SM_KPM_BINDING_DIR=${SRS}/e2_bindings/E2SM-KPM \
              -DRIC_GENERATED_E2SM_GNB_NRT_BINDING_DIR=${SRS}/e2_bindings/E2SM-GNB-NRT
  log_command make -j5
  log_command sudo make install
  log_command sudo ldconfig
  log_command sudo srsran_install_configs.sh service
  print_progress "srsRAN-e2 setup successfully."
}

# Welcome message
echo -e "\e[1;34m"
cat << "EOF"
  _____     _     
 / _ \ \   / /    
| | | \ \ / /_ _  
| |_| |\ V / _` | 
 \___(_)_\_\__,_| 
                  
EOF
echo -e "\e[0m"
echo -e "Welcome to \e[1;32msrsRAN-e2 Setup\e[0m!"
echo -e "Let's get started...\n"

install_dependencies
clone_and_setup_asn1c
setup_srsRAN_e2

print_progress "srsRAN-e2 setup completed successfully!"
