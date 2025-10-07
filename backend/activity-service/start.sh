#!/bin/bash

# Activity Service Startup Script
# This script sets up the environment and starts the Activity Service

echo "🚀 Starting Activity Service..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/update requirements
echo "📥 Installing requirements..."
pip install -r requirements.txt

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file from .env.example..."
    cp .env.example .env
    echo "✏️ Please update .env with your configuration before running the service"
    exit 1
fi

# Start the server
echo "🌟 Starting Activity Service on http://localhost:8001"
echo "📚 API Documentation: http://localhost:8001/docs"
echo "🏥 Health Check: http://localhost:8001/health"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8001 --reload