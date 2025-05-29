#!/bin/bash

echo "[Setup] Starting environment setup..."

# Check for python3
if ! command -v python3 &> /dev/null
then
    echo "[Error] python3 not found. Please install Python 3.8+ and try again."
    exit 1
fi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

echo "[Setup] Done! Activate with: source venv/bin/activate"
