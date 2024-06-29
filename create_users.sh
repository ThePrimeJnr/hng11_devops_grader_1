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

# exec >$LOG_FILE 2>&1

# Create necessary directories if they do not exist
touch $PASSWORD_FILE

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

    if id "$username" &>/dev/null; then
        echo "User $username already exists."
        continue
    fi

    # Create the user
    password=$(generate_password)
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    echo "User $username created successfully."
    echo "$username,$password" >>$PASSWORD_FILE
    cat $PASSWORD_FILE

    # Add user to the specified groups
    IFS=',' read -ra group_array <<<"$groups"

    $group_array | xargs -n 1 groupadd -r
    echo "Groups $group_array created"

    usermod -aG $group_array $username
    echo "User $username added to $group_array"

done <"$USERLIST_FILE"

echo "User creation script completed."
