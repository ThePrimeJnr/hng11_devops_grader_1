#!/bin/bash

# Check if the userlist file is provided as an argument
if [ -z "$1" ]; then
    echo "Error: User list file is required"
    exit 1
fi

USERLIST_FILE=$1

# Check if the userlist file exists
if [ ! -f "$USERLIST_FILE" ]; then
    echo "Error: User list file not found"
    exit 1
fi

# Log file and password file locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create necessary directories if they do not exist
mkdir -p /var/secure
touch $PASSWORD_FILE
touch $LOG_FILE

# Function to generate a random password
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Read the userlist file and process each line
while IFS= read -r line; do
    IFS=';' read -r username groups <<<"$line"

    # Trim spaces
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    if [ -z "$username" ]; then
        continue
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists." | tee -a $LOG_FILE
    else
        # Create the user
        password=$(generate_password)
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        echo "User $username created successfully." | tee -a $LOG_FILE
        echo "$username,$password" >>$PASSWORD_FILE
    fi

    # Create a personal group for the user if it doesn't exist
    personal_group="${username}_personal"
    if ! getent group $personal_group &>/dev/null; then
        groupadd $personal_group
        echo "Personal group $personal_group created successfully." | tee -a $LOG_FILE
    fi
    usermod -aG $personal_group $username
    echo "User $username added to personal group $personal_group." | tee -a $LOG_FILE

    # Add user to the specified groups
    IFS=',' read -ra group_array <<<"$groups"
    for group in "${group_array[@]}"; do
        if ! getent group $group &>/dev/null; then
            groupadd $group
            echo "Group $group created successfully." | tee -a $LOG_FILE
        fi
        usermod -aG $group $username
        echo "User $username added to group $group." | tee -a $LOG_FILE
    done

done <"$USERLIST_FILE"

echo "User creation script completed." | tee -a $LOG_FILE
