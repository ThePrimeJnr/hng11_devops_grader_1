#!/bin/bash

set -e

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
    for user in zxenon idimma mayowa alice bob charlie testuser; do
        sudo deluser --remove-home $user &>/dev/null || true
    done
    for group in hng testgroup; do
        sudo delgroup $group &>/dev/null || true
    done
    rm -f userlist.txt
    sudo rm -f /var/secure/user_passwords.txt
    sudo rm -f /var/secure/user_passwords.csv
    sudo rm -f /var/log/user_management.log
    rm -rf $CLONE_DIR
}

check_user_exists() {
    id "$1" &>/dev/null
}

check_group_exists() {
    getent group "$1" &>/dev/null
}

check_user_in_group() {
    id -nG "$1" | grep -qw "$2"
}

check_log_contains() {
    grep -q "$1" /var/log/user_management.log
}

check_password_file_contains() {
    grep -q "$1" /var/secure/user_passwords.txt || grep -q "$1" /var/secure/user_passwords.csv
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
    "Test 1: Check if script exists;\
    [ -f create_users.sh ]"

    "Test 2: Check if README.md exists;\
    [ -f README.md ]"

    "Test 3: Check if users are created;\
    echo -e \"zxenon; sudo,hng,www-data\nidimma; sudo\nmayowa; hng,www-data\" > userlist.txt &&\
    sudo bash create_users.sh userlist.txt &&\
    check_user_exists \"zxenon\" &&\
    check_user_exists \"idimma\" &&\
    check_user_exists \"mayowa\""

    "Test 4: Check if groups are created;\
    check_group_exists \"hng\""

    "Test 5: Check if personal group is created for each user;\
    check_group_exists \"zxenon\" &&\
    check_group_exists \"mayowa\""

    "Test 6: Check if users belong to all specified groups;\
    check_user_in_group \"zxenon\" \"sudo\" &&\
    check_user_in_group \"mayowa\" \"hng\" &&\
    check_user_in_group \"zxenon\" \"www-data\""

    "Test 7: Check if users belong to their personal group;\
    check_user_in_group \"zxenon\" \"zxenon\" &&\
    check_user_in_group \"mayowa\" \"mayowa\""

    "Test 8: Check if passwords are stored securely;\
    check_password_file_contains \"zxenon\" &&\
    check_password_file_contains \"mayowa\""

    "Test 9: Check if logs are stored securely;\
    check_log_contains \"zxenon\""

    "Test 10: Check if groups are created and user is added even if user already exists;\
    sudo useradd -m -s /bin/bash testuser &&\
    echo \"testuser; testgroup\" > userlist.txt &&\
    sudo bash create_users.sh userlist.txt &&\
    check_group_exists \"testgroup\" &&\
    check_user_in_group \"testuser\" \"testgroup\""
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
done
cleanup

echo "]" >>$RESULT_FILE
