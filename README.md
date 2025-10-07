# MicroHack-GitHub Backend Services

A microservices architecture for pet management using FastAPI and Azure CosmosDB.

## Services Overview

This project implements three backend services:

### 🐾 Pet Service (Port 8000)
**Base URL:** `/api/pets`

Pet management service with full CRUD operations:
- **GET** `/api/pets` - List all pets with filtering (species, search)
- **GET** `/api/pets/{pet_id}` - Get pet by ID
- **POST** `/api/pets` - Create new pet
- **PATCH** `/api/pets/{pet_id}` - Update pet
- **DELETE** `/api/pets/{pet_id}` - Delete pet

**Pet Model:**
- `id`: Unique identifier
- `name`: Pet name
- `species`: Type of pet (dog, cat, bird, fish, rabbit, hamster, other)
- `breed`: Pet breed
- `age`: Age in months
- `weight`: Weight in kg
- `color`: Pet color
- `imageUrl`: Optional photo URL

### 📊 Activity Service (Port 8001)
**Base URL:** `/api/activities`

Pet activity tracking service:
- **GET** `/api/activities` - List activities with date filtering and pet association
- **GET** `/api/activities/{activity_id}` - Get activity by ID
- **POST** `/api/activities` - Create new activity
- **PATCH** `/api/activities/{activity_id}` - Update activity
- **DELETE** `/api/activities/{activity_id}` - Delete activity

**Activity Model:**
- `id`: Unique identifier
- `petId`: Associated pet ID
- `type`: Activity type (exercise, feeding, grooming, medical, play, training, other)
- `description`: Activity details
- `timestamp`: When activity occurred
- `duration`: Duration in minutes (optional)
- `notes`: Additional notes (optional)

### 🛍️ Accessory Service (Port 8002)
**Base URL:** `/api/accessories`

Pet accessory inventory management service:
- **GET** `/api/accessories` - List accessories with filtering (type, search, low stock)
- **GET** `/api/accessories/{accessory_id}` - Get accessory by ID
- **POST** `/api/accessories` - Create new accessory
- **PATCH** `/api/accessories/{accessory_id}` - Update accessory
- **DELETE** `/api/accessories/{accessory_id}` - Delete accessory

**Accessory Model:**
- `id`: Unique identifier
- `name`: Accessory name
- `type`: Type (toy, food, collar, bedding, grooming, other)
- `price`: Price in currency
- `stock`: Current stock quantity
- `size`: Size (XS, S, M, L, XL)
- `imageUrl`: Optional product image URL
- `description`: Product description

## 🚀 Quick Start

### Prerequisites

1. **Python 3.8+** installed
2. **Azure CosmosDB Emulator** running locally:
   - Download: [Azure CosmosDB Emulator](https://aka.ms/cosmosdb-emulator)
   - Default endpoint: `https://localhost:8081`
   - Or use Azure CosmosDB in the cloud with connection credentials

### Start All Services

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd MicroHack-GitHub
   ```

2. **Run the startup script:**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

   This will:
   - Create virtual environments for each service
   - Install dependencies
   - Create `.env` files from examples
   - Start all three services simultaneously
   - Monitor service health

### Manual Service Setup

If you prefer to start services individually:

```bash
# Pet Service
cd backend/pet-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --host 0.0.0.0 --port 8000

# Activity Service  
cd ../activity-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --host 0.0.0.0 --port 8001

# Accessory Service
cd ../accessory-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --host 0.0.0.0 --port 8002
```

## 📡 API Documentation

Once services are running, access interactive API documentation:

- **Pet Service:** http://localhost:8000/docs
- **Activity Service:** http://localhost:8001/docs
- **Accessory Service:** http://localhost:8002/docs

## 🧪 Testing with REST Client

Each service includes a `.http` file for testing with the [REST Client extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) in VS Code:

- `backend/pet-service/pet-service.http`
- `backend/activity-service/activity-service.http`
- `backend/accessory-service/accessory-service.http`

## 🏥 Health Checks

Each service provides health endpoints:

- **Pet Service:** http://localhost:8000/health
- **Activity Service:** http://localhost:8001/health
- **Accessory Service:** http://localhost:8002/health

Health checks verify database connectivity and automatically create databases/containers if they don't exist, along with sample data.

## 🗄️ Database Configuration

### Using CosmosDB Emulator (Default)

Services are configured to use the local CosmosDB emulator by default:
- Endpoint: `https://localhost:8081`
- Uses emulator's default authentication key
- Databases are created automatically

### Using Azure CosmosDB

Update the `.env` files in each service directory:

```bash
# Pet Service
COSMOS_ENDPOINT=https://your-account.documents.azure.com:443/
COSMOS_KEY=your-primary-key

# Activity Service  
COSMOS_ENDPOINT=https://your-account.documents.azure.com:443/
COSMOS_KEY=your-primary-key

# Accessory Service
COSMOS_ENDPOINT=https://your-account.documents.azure.com:443/
COSMOS_KEY=your-primary-key
```

## 🏗️ Architecture

```
MicroHack-GitHub/
├── backend/
│   ├── pet-service/          # Pet management (port 8000)
│   ├── activity-service/     # Activity tracking (port 8001)
│   └── accessory-service/    # Inventory management (port 8002)
├── start.sh                  # Multi-service startup script
└── readme.md                 # This file
```

Each service follows the same architectural pattern:
- **models.py**: Pydantic data models with validation
- **database.py**: CosmosDB service layer with CRUD operations
- **config.py**: Configuration management with environment variables
- **main.py**: FastAPI application with routes and middleware
- **requirements.txt**: Python dependencies
- **.env.example**: Environment variable template

## 🔧 Development

### Adding New Features

1. Follow the established patterns in existing services
2. Update the corresponding `.http` file with test cases
3. Ensure proper error handling and validation
4. Test with both emulator and Azure CosmosDB

### Service Communication

Services are designed to be independent but can communicate via HTTP APIs when needed. Each service maintains its own database for data isolation.

## 📝 Sample Data

Each service creates sample data automatically when the health check runs:

**Pet Service:**
- 2 sample pets (Golden Retriever and Siamese Cat)

**Activity Service:**
- 2 sample activities (feeding and exercise)

**Accessory Service:**
- 2 sample accessories (chew toy and salmon treats)

## 🛑 Stopping Services

Press `Ctrl+C` in the terminal running `./start.sh` to gracefully stop all services.

## 📋 Logs

Service logs are available in each service directory:
- `backend/pet-service/pet-service.log`
- `backend/activity-service/activity-service.log`
- `backend/accessory-service/accessory-service.log`

---

Happy coding! 🚀
