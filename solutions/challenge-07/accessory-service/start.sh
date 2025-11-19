#!/bin/bash

# Accessory Service Startup Script
# This script helps set up and run the Accessory Service API

set -e  # Exit on any error

echo "🏃 Accessory Service Setup and Startup Script"
echo "=============================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Python installation
if ! command_exists python3; then
    echo "❌ Error: Python 3 is not installed"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is available
if ! command_exists pip3; then
    echo "❌ Error: pip3 is not installed"
    exit 1
fi

echo "✅ pip3 found: $(pip3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Check if .env file exists
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "⚙️  Creating .env file from .env.example..."
        cp .env.example .env
        echo "📝 Please review and update .env file with your configuration"
    else
        echo "⚠️  Warning: No .env or .env.example file found"
        echo "   Using environment variables or defaults"
    fi
else
    echo "✅ .env file found"
fi

# Check CosmosDB Emulator
echo ""
echo "🔍 Checking CosmosDB Emulator..."
COSMOS_ENDPOINT=$(grep -E "^COSMOS_ENDPOINT=" .env 2>/dev/null | cut -d'=' -f2 || echo "")

if [[ "$COSMOS_ENDPOINT" == *"localhost"* ]] || [[ "$COSMOS_ENDPOINT" == *"127.0.0.1"* ]]; then
    echo "📌 Using local CosmosDB Emulator"
    
    # Check if emulator is running
    if command_exists docker; then
        EMULATOR_RUNNING=$(docker ps | grep cosmos-emulator || true)
        if [ -z "$EMULATOR_RUNNING" ]; then
            echo "⚠️  Warning: CosmosDB Emulator might not be running"
            echo "   Start it with: docker start cosmos-emulator"
            echo "   Or run: docker run --name cosmos-emulator -d -p 8081:8081 mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview"
        else
            echo "✅ CosmosDB Emulator is running"
        fi
    fi
else
    echo "☁️  Using Azure CosmosDB"
fi

echo ""
echo "🚀 Starting Accessory Service..."
echo "📡 API will be available at: http://localhost:8030"
echo "📚 API Documentation at: http://localhost:8030/docs"
echo "🔍 Health check at: http://localhost:8030/health"
echo ""
echo "Press Ctrl+C to stop the service"
echo "=============================================="
echo ""

# Start the service
python3 main.py
