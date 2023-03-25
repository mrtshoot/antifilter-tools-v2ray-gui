#!/bin/bash

# Cloudflare API token
read -p "Please enter your api_token: " api_token

# Domain name
read -p "Please enter Your domain: " domain

# Subdomain name
read -p "Please enter Your subdomain: " subdomain

# IP address
read -p "Please enter Your IP Address: " ip_address

#func

CF_ADD_RCRD() {
    # Create A record
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$subdomain'.'$domain'","content":"'$ip_address'","ttl":1,"proxied":true}'

    # Enable HTTPS redirect
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/always_use_https" \
    -H "Authorization: Bearer ${api_token}" \
    -H "Content-Type: application/json" \
    --data '{"value":"on"}'
}

# Zone ID
zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
-H "Authorization: Bearer $api_token" \
-H "Content-Type: application/json" | jq -r '.result[0].id')

CF_ADD_RCRD

echo "--------------------------------------------------------------------------------------------"

echo "A record created succesfully with DNS proxy enabled and HTTPS redirect enabled for ${domain}."