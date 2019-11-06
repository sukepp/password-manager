#!/bin/bash

ROOT_DIR=./passManager

if [ ! -d "$ROOT_DIR" ]; then
    mkdir $ROOT_DIR
fi

if [[ $# -ne 1 && $# -ne 2 ]]; then
    echo "Error: parameters problem"
    exit 1
fi

USER_DIR=$1

if [ ! -d "$ROOT_DIR/$USER_DIR" ]; then
    echo "Error: user does not exist"
    exit 2
fi

if [ $# -eq 1 ]; then
    echo " ."
    tree $ROOT_DIR/$USER_DIR | head -n -2 | tail -n +2
    exit 0
else
    SERVICE_DIR=$2
    if [ ! -d "$ROOT_DIR/$USER_DIR/$SERVICE_DIR" ]; then
        echo "Error: folder does not exist"
        exit 3
    fi
    echo "$SERVICE_DIR"
    tree $ROOT_DIR/$USER_DIR/$SERVICE_DIR | head -n -2 | tail -n +2
    exit 0
fi