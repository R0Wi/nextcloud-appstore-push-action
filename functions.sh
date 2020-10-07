#!/bin/bash

# $1 = private key file
# $2 = app tar file
function createsign {
    echo "`openssl dgst -sha512 -sign $1 $2 | openssl base64 -A`"
}