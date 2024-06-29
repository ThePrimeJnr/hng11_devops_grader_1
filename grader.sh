#!/bin/bash

set -e

echo "" > output.log
exec > output.log 2>&1

if [ -z "$1" ]; then
    echo "Error: GitHub repository URL is required"
    exit 1
fi

REPO_URL=$1
USERNAME=$(echo $REPO_URL | awk -F'/' '{print $4}')
CLONE_DIR="/tmp/${USERNAME}_repo"
RESULT_FILE="/tmp/${USERNAME}_result.json"

echo -n "" >$RESULT_FILE

cleanup() {
    rm -rf $CLONE_DIR
    rm -f userlist.txt
    rm -f /var/secure/user_passwords.csv
    rm -f /var/log/user_management.log
    for user in zxenon idimma mayowa alice bob charlie testuser; do
        deluser --remove-home $user &>/dev/null || true
    done
    for group in sudo dev www-data admin testgroup; do
        delgroup $group &>/dev/null || true
    done
}

check_user_exists() {
    id "$1" &>/dev/null
}

check_group_exists() {
    getent group "$1" &>/dev/null
}

check_log_contains() {
    grep -q "$1" /var/log/user_management.log
}

check_password_file_contains() {
    grep -q "$1" /var/secure/user_passwords.csv
}

echo "[" >$RESULT_FILE

# Check if the repository exists and is public
if ! curl -s -o /dev/null -w "%{http_code}" "$REPO_URL" | grep -q "200"; then
    echo "GitHub repository does not exist or is not public" >$RESULT_FILE
    exit 1
fi

cleanup
git clone $REPO_URL $CLONE_DIR
cd $CLONE_DIR

tests=(
    "Test 1: Check if script exists; [ -f create_users.sh ]"
    "Test 2: Check if README.md exists; [ -f README.md ]"
    "Test 3: Check if users are created; echo \"zxenon; sudo,dev,www-data\nidimma; sudo\nmayowa; dev,www-data\" > userlist.txt && sudo bash create_users.sh userlist.txt && check_user_exists \"zxenon\" && check_user_exists \"idimma\" && check_user_exists \"mayowa\""
    "Test 4: Check if groups are created and users are added to them; check_group_exists \"sudo\" && check_group_exists \"dev\" && check_group_exists \"www-data\""
    "Test 5: Check if passwords are set and stored securely; check_password_file_contains \"zxenon\" && check_password_file_contains \"idimma\" && check_password_file_contains \"mayowa\""
    "Test 6: Check if logs are created and contain the right entries; check_log_contains \"User zxenon created successfully.\" && check_log_contains \"User idimma created successfully.\" && check_log_contains \"User mayowa created successfully.\""
    "Test 7: Edge case - user already exists; sudo useradd -m -s /bin/bash testuser && echo \"testuser; testgroup\" > userlist.txt && sudo bash create_users.sh userlist.txt && check_log_contains \"User testuser already exists.\""
    "Test 8: Check if groups are created and user is added even if user exists; check_group_exists \"testgroup\""
    "Test 9: Empty userlist file; touch userlist.txt && sudo bash create_users.sh userlist.txt && check_log_contains \"User creation script completed.\""
    "Test 10: Check if a user is added to multiple groups; echo \"alice; sudo,dev,www-data\" > userlist.txt && sudo bash create_users.sh userlist.txt && check_user_exists \"alice\" && id -nG alice | grep -q \"sudo\" && id -nG alice | grep -q \"dev\" && id -nG alice | grep -q \"www-data\""
)

for i in "${!tests[@]}"; do
    test="${tests[i]}"
    description="${test%%;*}"
    command="${test#*; }"
    echo "Running $description"
    eval "$command" && {
        echo "{\"title\": \"$description\", \"status\": \"pass\"}" >>$RESULT_FILE
    } || {
        echo "{\"title\": \"$description\", \"status\": \"fail\"}" >>$RESULT_FILE
    }
    [ $i -lt $((${#tests[@]} - 1)) ] && echo "," >>$RESULT_FILE
    cleanup
done

echo "]" >>$RESULT_FILE
