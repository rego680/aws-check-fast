#!/bin/bash

# Function to show the banner
show_banner() {
    echo -e "\033[1;34m"
    echo "###############################################"
    echo "#                                             #"
    echo "#             █████╗ ██╗    ██╗███████╗       #"
    echo "#            ██╔══██╗██║    ██║██╔════╝       #"
    echo "#            ███████║██║ █╗ ██║█████╗         #"
    echo "#            ██╔══██║██║███╗██║██╔══╝         #"
    echo "#            ██║  ██║╚███╔███╔╝███████╗       #"
    echo "#            ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝       #"
    echo "#                                             #"
    echo "#            AWS-Enum                         #"
    echo "#           By Lucas Zuluaga                  #"
    echo "#                                             #"
    echo "###############################################"
    echo -e "\033[0m"
}

# Function to display available AWS profiles
show_aws_profiles() {
    echo -e "\033[1;32mAvailable AWS Profiles:\033[0m"
    grep '^\[.*\]' /root/.aws/credentials | sed 's/^\[\(.*\)\]/\1/' | while read -r profile; do
        echo " - $profile"
    done
    echo ""
}

# Function to handle interruptions gracefully
handle_interrupt() {
    echo -e "\n\033[1;31mProcess interrupted. Exiting gracefully.\033[0m"
    exit 1
}

# Trap CTRL+C and CTRL+Z signals to handle interruptions properly
trap handle_interrupt SIGINT SIGTERM

# Function to check if the profile exists in /root/.aws/config and show the configuration line
check_aws_profile() {
    local profile=$1
    local config_file="/root/.aws/config"
    local profile_entry="[profile $profile]"

    # Check if the profile exists in the config file
    if grep -q "$profile_entry" "$config_file"; then
        echo -e "\033[1;32m[+] Profile '$profile' found in $config_file [+]\033[0m"
        local next_line=$(awk -v profile="$profile_entry" '
            $0 == profile {getline; print $0; exit}
        ' "$config_file")
        if [[ -n $next_line ]]; then
            echo -e "\033[1;33m[+] $next_line [+]\033[0m"
            sleep 3  # Wait for 3 seconds before proceeding
        else
            echo -e "\033[1;31m[!] No configuration line found under profile '$profile'.\033[0m"
        fi
    else
        echo -e "\033[1;31m[!] Profile '$profile' not found in $config_file.\033[0m"
        exit 1
    fi
}

# Function to execute AWS commands with retries, pauses, and save results
execute_aws_commands() {
    local profile=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="${profile}_${timestamp}.txt"

    # AWS Commands
    declare -a aws_commands=(
        "aws sts get-caller-identity --profile $profile"
        "aws iam list-users --profile $profile"
        "aws iam list-groups --profile $profile"
        "aws iam list-roles --profile $profile"
        "aws iam list-policies --profile $profile"
        "aws iam list-account-aliases --profile $profile"
        "aws organizations describe-organization --profile $profile"
        "aws s3api list-buckets --profile $profile"
        "aws cloudformation list-stacks --profile $profile"
        "aws ecs list-clusters --profile $profile"
        "aws eks list-clusters --profile $profile"
        "aws rds describe-db-clusters --profile $profile"
        "aws rds describe-db-instances --profile $profile"
        "aws rds describe-db-snapshots --profile $profile"
        "aws rds describe-db-subnet-groups --profile $profile"
        "aws secretsmanager list-secrets --profile $profile"
        "aws kms list-keys --profile $profile"
        "aws route53 list-hosted-zones --profile $profile"
        "aws elasticloadbalancing describe-load-balancers --profile $profile"
        "aws autoscaling describe-auto-scaling-groups --profile $profile"
        "aws ec2 describe-instances --profile $profile"
        "aws ec2 describe-security-groups --profile $profile"
        "aws ec2 describe-key-pairs --profile $profile"
        "aws ec2 describe-volumes --profile $profile"
        "aws ec2 describe-vpcs --profile $profile"
        "aws cloudtrail describe-trails --profile $profile"
        "aws cloudwatch describe-alarms --profile $profile"
        "aws apigateway get-rest-apis --profile $profile"
        "aws ecr describe-repositories --profile $profile"
        "aws sqs list-queues --profile $profile"
        "aws sns list-topics --profile $profile"
        "aws lambda list-functions --profile $profile"
    )

    echo -e "\033[1;36mWaiting 5 seconds before executing commands...\033[0m"
    sleep 5

    echo -e "\033[1;36mSaving results to $output_file\033[0m"

    # Execute AWS commands
    for cmd in "${aws_commands[@]}"; do
        echo -e "\n\033[1;33m[+] Executing: $cmd [+]\033[0m\n" | tee -a "$output_file"
        result=$(eval $cmd 2>&1 | tee -a "$output_file")
        echo "$result"
        if [[ "$result" == *"Could not connect to the endpoint URL: \"https://iam.amazonaws.com/\""* ]]; then
            echo -e "\033[1;31m[!] Could not connect. Retrying in 2 seconds... [!]\033[0m" | tee -a "$output_file"
            sleep 2
            echo -e "\033[1;33m[!] Retry Execution [!]\033[0m" | tee -a "$output_file"
            result=$(eval $cmd 2>&1 | tee -a "$output_file")
            echo "$result"
        fi
        echo "--------------------------------------------------" | tee -a "$output_file"
        sleep 3
    done

    echo -e "\033[1;32mAll results saved in $output_file\033[0m"
}

# 1. Show the banner
show_banner

# 2. Show available AWS profiles
show_aws_profiles

# 3. Prompt the user for the AWS profile name
read -p "Enter the AWS profile name: " profile_name

# 4. Check if the selected profile exists in /root/.aws/config and show the next line
check_aws_profile "$profile_name"

# 5. Execute AWS commands using the provided profile
execute_aws_commands "$profile_name"
