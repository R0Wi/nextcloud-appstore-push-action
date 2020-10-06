#!/usr/bin/env bats

@test "Test sign function" {
    source ../functions.sh
    expected="MU8K5DbVAJgCnt/LjUnNKiPCPp9CrWgGyCFn/UOwfveDBuV6hjEOylbSwbuEAG9iERdooaykVh/3MHUAdv3xFR03BEIkCW3XEle/w9Su1+r0FGDQYZjS6dm0fUjYTK3f5/+V1zBYhG+g9pWkCqpf7/4d4BiN0HTRjlL8f8fjh62PycPiCJH5czr2s5n9g5WK3t2roamGonQWGeqBILwkVK4plPIbSit5fMN7KHlc0J18izjT8IkkEIZ1Dm0ejiDGydLF699FCkwCFGX3aHpwQGD604JLBP6Y5ZwqX0gaSo5JpNxyhiGolvKn6zai7tpe8ObpaxmZ/KlCQCtdX9Or+ZJXdWhgYrwRxOE3twwNjY5HI2FLHBTUgmCrvXmJgeGr2q/neMAZcOITqzSHe/sJvpBBz0Qx4EVeP7wetgzCDWcmZsgpiA/AUJtDosVPswI4T4s/IBFpsH93EfbA71+G+58gKjAVHml0ayda15DzFb3UlDOwIwujsHrQ5iVcsG4iNn5JBzk/r81RR6LJRSAIpCSJOSJlxOTQCfFpwWRQrI+3E0CVW0y0Hf5WQibE7fO3al3gVq93W/S0oMH90u8OHilPLI3ZAHjSaqVmoQSm9cPoxW738P17N1o79nQBx4fUXjhXRzy1qD78QYU0JyqO4z804akRUiIe/XVylHGIF5w="
    run createsign test_appkey.key test_app_artifact.tar.gz
    [ "$status" = 0 ]
    [ "$output" = $expected ]
}

@test "Test app upload with token non nightly" {
    export DOWNLOAD_URL="http://localhost:7000/github/test_app_artifact.tar.gz"
    export APP_NAME="test_app"
    export APP_PRIVATE_KEY_FILE="test_appkey.key"
    export NIGHTLY="false"
    export APPSTORE_TOKEN="MY_TOKEN"
    export APPSTORE_URL="http://localhost:7000/api/v1/apps/releases/ok"

    run ../push_appstore.sh

    response_file="server_output.txt"
    webserver_response=$(cat $response_file)

    [[ "$webserver_response" =~ .*"\"authorization\":\"Token $APPSTORE_TOKEN\"".* ]]
    [[ "$webserver_response" =~ .*"\"content-type\":\"application/json\"".* ]]
    [[ "$webserver_response" =~ .*"\"download\": \"$DOWNLOAD_URL\"".* ]]
    [[ "$webserver_response" =~ .*"\"signature\": \"MU".* ]]
    [[ "$webserver_response" =~ .*"\"nightly\": false".* ]]
}

@test "Test app upload with username pw nightly" {
    export DOWNLOAD_URL="http://localhost:7000/github/test_app_artifact.tar.gz"
    export APP_NAME="test_app"
    export APP_PRIVATE_KEY_FILE="test_appkey.key"
    export NIGHTLY="true"
    export APPSTORE_USERNAME="MyAppstoreUser"
    export APPSTORE_PASSWORD="MySuperSecret"
    export APPSTORE_URL="http://localhost:7000/api/v1/apps/releases/ok"

    run ../push_appstore.sh

    response_file="server_output.txt"
    webserver_response=$(cat $response_file)
    base64user=$(echo -n "$APPSTORE_USERNAME:$APPSTORE_PASSWORD" | base64)

    [[ "$webserver_response" =~ .*"\"authorization\":\"Basic $base64user\"".* ]]
    [[ "$webserver_response" =~ .*"\"content-type\":\"application/json\"".* ]]
    [[ "$webserver_response" =~ .*"\"download\": \"$DOWNLOAD_URL\"".* ]]
    [[ "$webserver_response" =~ .*"\"signature\": \"MU".* ]]
    [[ "$webserver_response" =~ .*"\"nightly\": true".* ]]
}

@test "Test script returns 1 if no auth-method is provided" {
    export DOWNLOAD_URL="http://localhost:7000/github/test_app_artifact.tar.gz"
    export APP_NAME="test_app"
    export APP_PRIVATE_KEY_FILE="test_appkey.key"
    export NIGHTLY="false"
    export APPSTORE_URL="http://localhost:7000/api/v1/apps/releases/ok"

    run ../push_appstore.sh

    [ "$status" = 1 ]
    [[ "$output" =~ .*"Please provide 'appstore_token' or 'appstore_username' and 'appstore_password' ".* ]]
}

@test "Test script fails if api returned non 200 (token auth)" {
    export DOWNLOAD_URL="http://localhost:7000/github/test_app_artifact.tar.gz"
    export APP_NAME="test_app"
    export APP_PRIVATE_KEY_FILE="test_appkey.key"
    export NIGHTLY="false"
    export APPSTORE_TOKEN="MY_TOKEN"
    export APPSTORE_URL="http://localhost:7000/api/v1/apps/releases/badrequest"

    run ../push_appstore.sh

    [ "$status" != 0 ]
}

@test "Test script fails if api returned non 200 (username pw auth)" {
    export DOWNLOAD_URL="http://localhost:7000/github/test_app_artifact.tar.gz"
    export APP_NAME="test_app"
    export APP_PRIVATE_KEY_FILE="test_appkey.key"
    export NIGHTLY="false"
    export APPSTORE_USERNAME="MyAppstoreUser"
    export APPSTORE_PASSWORD="MySuperSecret"
    export APPSTORE_URL="http://localhost:7000/api/v1/apps/releases/badrequest"

    run ../push_appstore.sh

    [ "$status" != 0 ]
}