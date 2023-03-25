#!/bin/bash
set -eu

# Get insite and outside informations
read -p "Please enter your email address to manage SSL(mail@test.com): " email
read -p "Please enter your Server IP(X.X.X.X): " SERVER_IP
read -p "Please enter your SSH Password: " SERVER_PASSWORD
read -p "Please enter your basedomain(example.com): " domain
read -p "Please enter your subdomain(test): " subdomain
read -p "Please enter CloudFlate ApiToken: " api_token
# read -p "Would you like to your CloudFlare A Record Proxied or not(y/n): " proxied
read -p "Enter your web gui v2ray admin username: " config_account
read -p "Enter your web gui v2ray admin password: " config_password
read -p "Enter your web gui v2ray admin panel port: " config_port

# Install Requirements
sudo apt update -y
sudo apt install -y ansible sshpass git

# Create playbook inventory
cp inventory.example inventory
sed -i "s/SERVER_IP/$SERVER_IP/g" inventory
sed -i "s/SERVER_PASSWORD/$SERVER_PASSWORD/g" inventory

# Create function executer
func_exec_script() {
    ansible-playbook -i inventory playbook.yaml --extra-vars="api_token='${api_token}' domain='${domain}' subdomain='${subdomain}' ip_address='${SERVER_IP}' config_account='${config_account}' config_password='${config_password}' config_port='${config_port}' email='${email}'"
}

func_exec_script "$api_token $domain $subdomain $SERVER_IP $config_account $config_password $config_port $email"