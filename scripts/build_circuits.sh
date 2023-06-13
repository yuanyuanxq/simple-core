#!/bin/bash

# This file should be store in ./scripts of the project folder
# This script will build following files in the ./build/circuits
#
# circuit.r1cs
# circuit.sym
# circuit.wasm
# powersOfTau28_hez_final_11.ptau
# circuit_0000.zkey
# circuit_final.zkey
# verification_key.json

# constants
TARGET_CIRCUIT=../../circuits/withdraw.circom
PTAU_FILE=powersOfTau28_hez_final_15.ptau
ENTROPY_FOR_ZKEY=mnbvc

cd "$(dirname "$0")"

# to project root
cd ..

# load .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# build directory ../build/circuits
mkdir -p ./build/circuits

cd ./build/circuits

# generate circuit.r1cs & circuit.sym & circuit.wasm

echo 'Generating circuit.r1cs & circuit.sym & circuit.wasm'
circom $TARGET_CIRCUIT --r1cs --wasm --sym || { exit 1; }

# download $PTAU_FILE
if [ -f ./$PTAU_FILE ]; then
    echo skip: "$PTAU_FILE already exists"
else
    echo "Downloading $PTAU_FILE"
    wget https://hermez.s3-eu-west-1.amazonaws.com/$PTAU_FILE --no-check-certificate
fi

# generate circuit_0000.zkey
echo "Generating circuit_0000.zkey"
snarkjs zkey new withdraw.r1cs $PTAU_FILE circuit_0000.zkey || { exit 1; }

# generate circuit_final.zkey
echo "Generating circuit_final.zkey"
echo $ENTROPY_FOR_ZKEY | snarkjs zkey contribute circuit_0000.zkey circuit_final.zkey || { exit 1; }

# generate verification_key.json
echo "Generating verification_key.json"
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json || { exit 1; }
