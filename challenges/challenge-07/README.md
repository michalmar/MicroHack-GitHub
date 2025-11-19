# Challenge 07: Implementation and Local Testing

## Overview
In this challange we will implement and test our application - let's start with our two existing services and than code new one.

---
## 0. Run the Existing PetPal Stack (Preparation)
Before designing a new service, spin up the current system so you understand integration points.

### 0.1 Cosmos DB Emulator (Docker)
```sh
docker pull mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview

docker run \
   --name cosmos-emulator \
   --detach \
   --publish 8081:8081 \
   --publish 1234:1234 \
   mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-preview
```

> **⚠️ Important Note about SSL/TLS**: The Linux Cosmos DB emulator works more reliably with HTTP connections. The backend services are pre-configured to use `http://localhost:8081/` in their `.env` files. If you encounter SSL certificate errors, verify that `COSMOS_ENDPOINT=http://localhost:8081/` (not https) in the `.env` files for each service. See `/backend/COSMOS_EMULATOR_FIX.md` for details.

**Verify the emulator is running:**
If using GitHub Codespaces, access the forwarded port 1234 in your browser:
```
https://<your-codespace-name>-1234.app.github.dev/
```
Replace `<your-codespace-name>` with your actual Codespace name (e.g., `ideal-space-eureka-w5vxp9xrwphp9vw`). You should see the Cosmos DB Emulator explorer interface confirming the emulator is ready.

You should see the Cosmos DB Emulator explorer interface confirming the emulator is ready (no collections no data yet):
![Cosmos DB Emulator Explorer](../../solutions/challenge-06/docs/cosmosdb-emulator.png)


### 0.2 Start Backend Microservices
From repository root, ideally run in separate Terminals (icon of terminal with `+` in VS Code) icon looks like this:


Start the Pet Service backend:
```sh
cd backend/pet-service && ./start.sh
```


Start the Activity service backend:
```sh
cd backend/activity-service && ./start.sh
```

**Make the ports public**

You have started two backend services that will be used by the frontend UI:
* pet-service: 8010
* activity-service: 8020


Now check and make the auto-forwarded ports Public:

Option 1 - through GitHub Codespaces UI
- In GitHub Codespaces, go to the Ports tab (bottom panel), find the ports 8010 and 8020, and set their visibility to "Public" by righ-clicking on the port:
![make ports public](../../solutions/challenge-06/docs/codespaces-port-change-visibility.png)

Option 2 - thtough script
```sh
./challenges/challenge-06/scripts/setup_ports.sh
```

In the end you should see the ports in Ports tab as Public:
 ![public ports](../../solutions/challenge-06/docs/codespaces-ports-public.png)


### 0.3 Run UI Frontend
Once the backend services are running, you can start the frontend (already prepared as docker image).

> Note: The URLs for the backend services will be automatically generated using the CODESPACE_NAME environment variable.


```sh
docker pull ghcr.io/michalmar/petpal-ui:latest

docker run -d \
   -p 3000:80 \
   -e VITE_API_PETS_URL=https://${CODESPACE_NAME}-8010.app.github.dev \
   -e VITE_API_ACTIVITIES_URL=https://${CODESPACE_NAME}-8020.app.github.dev \
   -e VITE_API_ACCESSORIES_URL=https://${CODESPACE_NAME}-8030.app.github.dev \
   -e VITE_API_GITHUB_TOKEN=$GITHUB_TOKEN \
   --name petpal-ui \
   ghcr.io/michalmar/petpal-ui:latest

```

Open the forwarded port (3000) - Go to Codespaces' Ports tab and click on the Globe icon. An you should see something similar to:

> Note: for the first time it also creates and do initial load of data to the Cosmos DB, so it might take few seconds to load.

![app UI](../../solutions/challenge-06/docs/app-full.png)

Confirm existing pets and activities load. Accessories will show empty or error until your service is implemented.

### 0.4 Challenge check

The implemented frontend should show existing pets and activities. But accessories will be empty as the service is not implemented yet, in fact you can see Backend Error in the browser console:
![app UI error](../../solutions/challenge-06/docs/app-acc-err.png)

This is intentional as the accessory-service is not implemented yet. You are now ready to design and implement it in the next steps.


## 1. Challenge Focus

In this challenge, you will implement the **Accessory Service** - a microservice that manages pet accessories (toys, food, collars, bedding, grooming supplies, etc.). The service exposes REST API endpoints for CRUD operations with advanced filtering and search capabilities, persists data in Azure Cosmos DB (using the emulator), and integrates with the existing PetPal ecosystem.

**What You'll Build:**
- RESTful API with FastAPI following the existing service patterns
- Pydantic models for data validation (matching the provided schema)
- Cosmos DB integration with lazy initialization
- Search and filtering capabilities (by type, stock level, name)
- Pagination support for list operations
- Proper error handling and logging

**Key Learning Objectives:**
* Use GitHub Copilot to implement a complete microservice following established patterns
* Design and implement Pydantic models from specifications
* Work with Azure Cosmos DB (document database) using Python SDK
* Create RESTful endpoints with proper HTTP semantics
* Implement search and filtering logic
* Test API endpoints using HTTP client files
* Follow consistent coding patterns across microservices

## 2. First implementation
We have technical specifications pretty detailed so we can ask Copilot agent to code our accessory service based on it. Then we will test and iterate.

Try this prompt and make sure all our context is available to Copilot (drag our specs files into chat context).

```markdown
Your task is to code new microservice accessory-service based on specification.

1. Closely follow all technical specifications in `specs/services/accessory-service`, make sure to read all files there before continuing.
2. Review code, .env, start script and other parts our existing services `backend/activity-service` and `backend/pet-service` to make sure we follow the same style and structure.
3. If you need overall architecture overview read documents in `specs/platform` and for business requirements you can check `PRD.md`
4. After you gather all mention documents think about solution and plan for execution
5. Once you have plan what to do, start implementing this
6. Read types of tests in `backend/accessory-service/accessory-service.http` and write simple testing script that will do something similar. In one terminal run service, in other run test script and iterate until everything is OK.
```

Open `backend/accessory-service/accessory-service.http` which contains few API tests. Run throw them all, must be OK with no errors and make sense (eg. search returns correct items). If there are errors or unexpected behavior, work with Copilot to fix it.

### Example issues
For example if tests show you can write, but **getting accessories return empty array**, most likely there is error in how code builds WHERE filters in SQL query. Point this out to Copilot, for example:

```markdown
Accessory services correctly write items, but search and filter do not work, empty array is returned. Review the way how filters are build, write simple test Python script that uses the same .env and iterate over it until you find correct implementation and than fix our accessory service code.
```

Creating accessory fails with validation error such as

```json
HTTP/1.1 400 Bad Request
date: Wed, 19 Nov 2025 11:11:57 GMT
server: uvicorn
content-length: 793
content-type: application/json
connection: close

{
  "detail": "5 validation errors for Accessory\nname\n  Field required [type=missing, input_value={}, input_type=dict]\n    For further information visit https://errors.pydantic.dev/2.5/v/missing\ntype\n  Field required [type=missing, input_value={}, input_type=dict]\n    For further information visit https://errors.pydantic.dev/2.5/v/missing\nprice\n  Field required [type=missing, input_value={}, input_type=dict]\n    For further information visit https://errors.pydantic.dev/2.5/v/missing\nstock\n  Field required [type=missing, input_value={}, input_type=dict]\n    For further information visit https://errors.pydantic.dev/2.5/v/missing\nsize\n  Field required [type=missing, input_value={}, input_type=dict]\n    For further information visit https://errors.pydantic.dev/2.5/v/missing"
}
```

Copy this error to Copilot and let it find solution.

## 3. Seed data for accessories
Let's generate some seed data, ask Copilot to simply create Python script to do that.

```markdown
See API structure in `specs/services/accessory-service/API_REFERENCE.md` and create two scripts:
- delete_accessories: This script will delete all accessories
- seed_accessories: This script will create 3 example accessories (two toys, one food item with low stock)
```


















-----------




















---
## 2. Implementation Approach

The challenge follows a structured approach that mirrors professional microservice development:

1. **Setup & Preparation** - Run existing services and understand integration patterns
2. **Requirements Analysis** - Understand the business need and API contract
3. **Data Modeling** - Design Pydantic models based on the schema specification
4. **Database Layer** - Implement Cosmos DB persistence with proper error handling
5. **API Implementation** - Build REST endpoints following FastAPI best practices
6. **Testing & Validation** - Verify endpoints using HTTP test files and manual testing
7. **Integration** - Connect with the PetPal UI and verify end-to-end flow

Throughout each phase, you'll use GitHub Copilot to accelerate development while maintaining code quality and consistency.

---

## Learning Objectives

- Learn to use AI for architectural and design decisions
- Practice creating comprehensive technical specifications
- Understand microservices design patterns and best practices
- Experience collaborative design validation and iteration

## Prerequisites

- Understanding of microservices architecture
- Familiarity with the existing pet management system
- Completed previous Copilot challenges
- Basic knowledge of API design and data modeling

## Tasks

### Task 1: Requirements Analysis & Setup

**Goal:** Understand the existing architecture and set up your development environment.

1. **Run the Existing PetPal Stack:**
   - Follow the instructions in section 0 above to start Cosmos DB emulator
   - Start the pet-service and activity-service
   - Launch the PetPal UI and verify existing functionality
   - Note the port convention: pet-service (8010), activity-service (8020), accessory-service (8030)

2. **Study Existing Services:**
   - Examine `backend/pet-service/main.py` and `backend/activity-service/main.py`
   - Identify common patterns:
     - FastAPI app structure with lifespan management
     - CORS middleware configuration
     - Dependency injection for database service
     - Exception handler patterns
     - Logging approach
   - Note the consistency in endpoint structure (`/health`, `/`, `/api/{resource}`)

3. **Understand the Accessory Requirements:**
   - **Core functionality**: Manage pet accessories with CRUD operations
   - **Search & Filter**: Support filtering by type, low stock detection, text search
   - **Pagination**: Handle large datasets with offset/limit pagination
   - **Data types**: Support 6 accessory types (toy, food, collar, bedding, grooming, other)
   - **Size categories**: S, M, L, XL
   - **Stock management**: Track quantity and identify low stock items (< 10)

4. **Review Test Cases** (in `accessory-service.http`):
   - Examine the provided HTTP test file to understand expected API behavior
   - Note the test scenarios: basic CRUD, filtering, pagination, error cases
   - Use this as your acceptance criteria

**Deliverable:** Understanding of existing patterns and clear requirements for the accessory service

---

### Task 2: API Design & Project Structure

**Goal:** Set up the project structure and define the API contract.

1. **Create Project Structure:**
   ```
   backend/accessory-service/
   ├── main.py                 # FastAPI app and routes
   ├── models.py               # Pydantic models
   ├── database.py             # Cosmos DB service
   ├── config.py               # Configuration & environment variables
   ├── requirements.txt        # Dependencies
   ├── .env                    # Environment variables (copy from .env.example)
   ├── .env.example           # Template for environment variables
   └── accessory-service.http # HTTP test file (already provided)
   ```

2. **Define API Endpoints** (to be implemented):
   - `GET /` - Root endpoint with service info
   - `GET /health` - Health check with database connectivity
   - `GET /api/accessories` - List accessories with filtering and pagination
   - `POST /api/accessories` - Create new accessory
   - `GET /api/accessories/{id}` - Get specific accessory
   - `PATCH /api/accessories/{id}` - Update accessory (partial)
   - `DELETE /api/accessories/{id}` - Delete accessory

3. **Query Parameters for List Endpoint:**
   - `search` (Optional[str]) - Search in name or description
   - `type` (Optional[str]) - Filter by accessory type
   - `lowStockOnly` (Optional[bool]) - Show only items with stock < 10
   - `limit` (int, default=100) - Max results to return
   - `offset` (int, default=0) - Pagination offset

**Copilot Prompts to Try:**
```
"Create a FastAPI project structure for a microservice following the pattern in pet-service..."
"Generate requirements.txt for a FastAPI service with Azure Cosmos DB support..."
```

**Deliverable:** Project structure created with placeholder files

---

### Task 3: Data Schema & Models

**Goal:** Implement Pydantic models for data validation based on the provided schema.

**Schema Specification:**

The accessory data model should include:

```python
# Base fields (required for all accessories):
- name: str (1-200 chars)
- type: Literal["toy", "food", "collar", "bedding", "grooming", "other"]
- price: float (>= 0)
- stock: int (>= 0)
- size: Literal["S", "M", "L", "XL"]

# Optional fields:
- imageUrl: Optional[str]
- description: Optional[str] (max 2000 chars)

# System fields (auto-generated):
- id: str (UUID, auto-generated)
- createdAt: datetime (auto-set on creation)
- updatedAt: datetime (auto-set on creation/update)
```

**Models to Implement:**

1. **AccessoryBase** - Base model with common fields
2. **AccessoryCreate** - For POST requests (no id, timestamps)
3. **AccessoryUpdate** - For PATCH requests (all fields optional)
4. **Accessory** - Complete model with id and timestamps
5. **AccessorySearchFilters** - Query parameters for search/filter

**Implementation Steps:**

1. Create `models.py` file
2. Import required dependencies:
   ```python
   import uuid
   from typing import Optional, Literal
   from pydantic import BaseModel, Field
   from datetime import datetime
   ```

3. Implement each model class using Pydantic
4. Use `Field(...)` for validation constraints (min_length, ge, etc.)
5. Add proper descriptions to all fields

**Copilot Prompts to Try:**
```
"Create a Pydantic model for an accessory with validation for name, type, price, stock, and size"
"Add a SearchFilters model with optional search, type, lowStockOnly, limit, and offset parameters"
"Generate an update model where all fields from the base model are optional"
```

**Validation Points:**
- Price must be non-negative
- Stock must be non-negative
- Type must be one of the 6 valid types
- Size must be S, M, L, or XL
- Name length between 1-200 characters

**Deliverable:** Complete `models.py` with all 5 model classes and proper validation

---

### Task 4: Configuration Management

**Goal:** Set up configuration and environment variables following the pattern from other services.

1. **Check and update (if needed) `config.py`:**
   - Import required modules (os, dotenv, functools)
   - Create Settings class with:
     - Cosmos DB configuration (endpoint, key, database name, container name)
     - Application configuration (app name, version, debug mode)
     - Validation for required settings
   - Implement `get_settings()` function with `@lru_cache()` decorator

2. **Check and update (if needed)  `.env.example`:**
   ```
   # Azure CosmosDB Configuration
   COSMOS_ENDPOINT=http://localhost:8081/
   COSMOS_KEY=<emulator-key>
   COSMOS_DATABASE_NAME=accessoryservice
   COSMOS_CONTAINER_NAME=accessories
   
   # Application Configuration
   DEBUG=false
   ```

3. **Create `.env`:**
   - Copy from `.env.example`
   - Check and update (if needed) the actual Cosmos DB emulator key and other variables
   - Ensure `COSMOS_ENDPOINT=http://localhost:8081/` (HTTP for emulator)

**Deliverable:** `config.py`, `.env.example`, and `.env` files configured correctly

---

### Task 5: Database Layer Implementation **[OPTIONAL -> TODO]**

**Goal:** Implement the Cosmos DB service class for CRUD operations and search.

**Key Components:**

1. **AccessoryCosmosService Class** with methods:
   - `__init__()` - Initialize with connection parameters
   - `_ensure_initialized()` - Lazy connection (connect on first use)
   - `health_check()` - Verify database connectivity, auto-create if needed
   - `create_accessory()` - Insert new accessory
   - `get_accessory()` - Retrieve by ID
   - `update_accessory()` - Update existing accessory
   - `delete_accessory()` - Delete accessory
   - `search_accessories()` - Search with filters and pagination
   - `_create_database_and_seed()` - Create database/container with sample data

2. **Factory Function:**
   - `get_cosmos_service()` - Return configured service instance

**Implementation Guidance:**

1. **Lazy Initialization Pattern:**
   - Don't connect to Cosmos DB during `__init__()`
   - Connect only when first operation is attempted
   - Use `_ensure_initialized()` before each database operation

2. **Health Check with Auto-Setup:**
   - Try to query the container
   - If database/container doesn't exist, create it automatically
   - Seed with 2 sample accessories (one toy, one food item with low stock)

3. **Search Implementation:**
   - Build dynamic SQL query based on filters
   - Support text search in name and description (`CONTAINS`)
   - Support type filtering
   - Support low stock filtering (stock < 10)
   - Add pagination with `OFFSET` and `LIMIT`
   - Order results by `createdAt DESC`

4. **Error Handling:**
   - Catch `CosmosResourceNotFoundError` for 404 cases
   - Catch `CosmosResourceExistsError` for duplicate IDs
   - Log all operations and errors
   - Re-raise exceptions for FastAPI to handle

**Copilot Prompts to Try:**
```
"Create a Cosmos DB service class with CRUD methods for accessories"
"Implement a search method that supports filtering by type and text search with pagination"
"Add lazy initialization to Cosmos DB client following the pattern from activity-service"
"Generate SQL query for Cosmos DB that filters by type and searches in name/description"
```

**Deliverable:** Complete `database.py` with AccessoryCosmosService class

---

### Task 6: FastAPI Application & Routes

**Goal:** Implement the main FastAPI application with all REST endpoints.

**Implementation Steps:**

1. **App Setup (in `main.py`):**
   - Create FastAPI app with title, version, description
   - Add lifespan context manager (startup/shutdown logging)
   - Add CORS middleware
   - Create dependency injection for database service
   - Add exception handlers for ValueError and general exceptions

2. **Implement Endpoints:**

   **Health & Info:**
   - `GET /` - Return service info (name, version, status)
   - `GET /health` - Call `db.health_check()` and return result

   **CRUD Operations:**
   - `GET /api/accessories` - Call `db.search_accessories()` with filters
   - `POST /api/accessories` - Call `db.create_accessory()`, return 201
   - `GET /api/accessories/{id}` - Call `db.get_accessory()`, return 404 if not found
   - `PATCH /api/accessories/{id}` - Call `db.update_accessory()`, return 404 if not found
   - `DELETE /api/accessories/{id}` - Call `db.delete_accessory()`, return 204

3. **Request/Response Models:**
   - Use appropriate Pydantic models for type safety
   - `POST` uses `AccessoryCreate` input, `Accessory` response
   - `PATCH` uses `AccessoryUpdate` input, `Accessory` response
   - `GET /api/accessories` uses `Query` parameters and `List[Accessory]` response

4. **Error Handling:**
   - Return proper HTTP status codes (200, 201, 204, 400, 404, 500, 503)
   - Use `HTTPException` for error responses
   - Log all errors appropriately

5. **Add uvicorn runner** at the bottom:
   ```python
   if __name__ == "__main__":
       import uvicorn
       uvicorn.run("main:app", host="0.0.0.0", port=8030, reload=settings.debug)
   ```

**Copilot Prompts to Try:**
```
"Create a FastAPI endpoint that lists accessories with query parameters for filtering"
"Implement a POST endpoint that creates an accessory and returns 201 status"
"Add a PATCH endpoint that updates an accessory by ID with partial update support"
"Create exception handlers for ValueError and general exceptions in FastAPI"
```

**Pattern Consistency:**
- Follow the same structure as pet-service and activity-service
- Use the same logging format
- Use the same CORS configuration
- Use the same dependency injection pattern

**Deliverable:** Complete `main.py` with all endpoints implemented and tested

---

### Task 7: Testing & Validation

**Goal:** Verify the implementation using the provided HTTP test file and manual testing.

1. **Start the Accessory Service:**
   ```sh
   cd backend/accessory-service
   python main.py
   # Or: uvicorn main:app --host 0.0.0.0 --port 8030 --reload
   ```

2. **Run HTTP Tests:**
   - Open `accessory-service.http` in VS Code
   - Install REST Client extension if not already installed
   - Execute tests in this order:
     a. Health check (should auto-create database)
     b. Create accessories (toy, food, collar, bedding)
     c. Get all accessories
     d. Get by ID
     e. Filter by type
     f. Search by name
     g. Filter low stock only
     h. Test pagination
     i. Update accessory
     j. Delete accessory
     k. Test error cases (404, validation errors)

3. **Verify in Cosmos DB Emulator:**
   - Open Cosmos DB emulator UI (port 1234 if using Codespaces)
   - Verify `accessoryservice` database exists
   - Verify `accessories` container exists
   - Check that documents are created correctly

4. **Integration with UI:**
   - Update the UI environment variable:
     ```sh
     docker rm -f petpal-ui
     docker run -d \
        -p 3000:80 \
        -e VITE_API_PETS_URL=<pets service URL> \
        -e VITE_API_ACTIVITIES_URL=<activities service URL> \
        -e VITE_API_ACCESSORIES_URL=<accessory service URL> \
        -e VITE_API_GITHUB_TOKEN=$GITHUB_TOKEN \
        --name petpal-ui \
        ghcr.io/michalmar/petpal-ui:latest
     ```
   - Open the UI and verify accessories are visible
   - Create a new accessory via UI
   - Verify it appears in the list

**Test Checklist:**
- [ ] Health check returns healthy status
- [ ] Database and container auto-created on first health check
- [ ] Sample data seeded correctly
- [ ] Create accessory returns 201 with correct data
- [ ] Get all accessories returns list
- [ ] Get by ID works for existing accessory
- [ ] Get by ID returns 404 for non-existent accessory
- [ ] Filter by type works (try "toy", "food")
- [ ] Search by name works (partial match)
- [ ] Low stock filter works (stock < 10)
- [ ] Pagination works (offset/limit)
- [ ] Update accessory works (partial update)
- [ ] Delete accessory returns 204
- [ ] Validation errors return 400 (negative price, invalid type, etc.)
- [ ] OpenAPI docs available at `/docs`
- [ ] UI integration works

**Deliverable:** All tests passing, service fully functional

---

## Using GitHub Copilot Effectively

### General Prompting Strategies

**Context Setting:**
```
"I'm implementing a FastAPI microservice for pet accessories following the pattern from pet-service and activity-service"
```

**References to existing implementation:**
```
"Implement in alignment with #folder [or #file]..."
```

**Model Generation:**
```
"Create Pydantic models for an accessory with name, type (enum), price, stock, size (enum), optional imageUrl and description, plus auto-generated id and timestamps"
```

**Database Operations:**
```
"Implement a Cosmos DB search method that supports filtering by type, text search in name/description, low stock detection (< 10), and pagination"
```

**Endpoint Implementation:**
```
"Create a FastAPI GET endpoint that lists accessories with query parameters for search, type filter, lowStockOnly, limit, and offset"
```

**Error Handling:**
```
"Add exception handlers to FastAPI that return 400 for ValueError and 500 for general exceptions with proper logging"
```

### Copilot Chat Prompts for Different Tasks

**Understanding Patterns:**
```
"@workspace How do the existing microservices handle database initialization?"
"Show me how pet-service implements the health check endpoint"
```

**Code Generation:**
```
"Generate a function that builds a dynamic Cosmos DB SQL query with optional filters"
"/doc Add docstrings to all methods in this class"
```

**Debugging:**
```
"Why might this Cosmos DB query return empty results?"
"Review this code for potential issues with lazy initialization"
```

**Testing:**
```
"Suggest test cases for the accessory search endpoint"
"What edge cases should I test for the create accessory endpoint?"
```

### Tips for Best Results

1. **Be Specific:** Instead of "create a service", say "create an AccessoryCosmosService class with CRUD methods following the pattern from pet-service"

2. **Provide Context:** Reference existing files or patterns: "@workspace #file:pet-service/main.py create a similar structure for accessory-service"

3. **Iterate:** Start with basic functionality, then enhance: "Add pagination support to this search method"

4. **Review & Refine:** Always review generated code - Copilot is a tool, not a replacement for understanding

5. **Use Comments:** Write comments describing what you want, then let Copilot generate the code

6. **Learn Patterns:** Study how Copilot solves problems, then apply those patterns yourself

---

## Implementation Guidance & Tips

### Common Challenges & Solutions

**Challenge 1: Cosmos DB Connection Issues**
- Ensure emulator is running: `docker ps | grep cosmos`
- Verify endpoint uses HTTP (not HTTPS): `http://localhost:8081/`
- Check emulator key is correctly set in .env

**Challenge 2: Import Errors**
- Run from the service directory: `cd backend/accessory-service`
- Install dependencies: `pip install -r requirements.txt`
- Check Python path if modules not found

**Challenge 3: Pydantic Validation Errors**
- Review model definitions carefully
- Ensure Field constraints match (ge=0 for non-negative)
- Use Literal types for enums (not string)
- Make sure optional fields use Optional[type]

**Challenge 4: Search Not Working**
- Verify Cosmos DB SQL syntax (use CONTAINS for text search)
- Check parameter binding (@search, @type)
- Enable cross-partition queries
- Test queries in Cosmos DB emulator UI

**Challenge 5: UI Integration**
- Verify service URL is correct in docker run command
- Check CORS is enabled in FastAPI
- Ensure service is accessible from the UI container
- Use public forwarded URLs in Codespaces

### Development Workflow

1. **Start Small:** Implement one endpoint at a time
2. **Test Immediately:** Use accessory-service.http after each endpoint
3. **Check Logs:** Monitor console output for errors
4. **Verify Data:** Check Cosmos DB emulator UI to see documents
5. **Iterate:** Get basic functionality working, then add enhancements

### Code Quality Checklist

- [ ] Consistent naming conventions (snake_case for functions, PascalCase for classes)
- [ ] Proper type hints on all functions
- [ ] Docstrings on classes and complex functions
- [ ] Appropriate logging (INFO for operations, ERROR for failures)
- [ ] No hardcoded values (use config or constants)
- [ ] Proper error handling (try/except with specific exceptions)
- [ ] DRY principle (don't repeat yourself)
- [ ] Follows patterns from pet-service and activity-service

---

## What Parts to Remove for Student Implementation

To create an appropriate learning challenge, the following should be removed from the current implementation:

### Core Implementation (Remove Completely):
1. **`main.py` content** - Keep only:
   - Import statements (partially)
   - App initialization structure (without routes)
   - Leave TODO comments for students to implement

2. **`database.py` content** - Keep only:
   - Class definition with `__init__`
   - Method signatures (no implementations)
   - TODO comments for each method

3. **`models.py` content** - Keep only:
   - Import statements
   - AccessoryBase class structure (students complete fields)
   - Empty classes for other models with docstrings

### Keep as Reference/Guidance:
1. **`config.py`** - Keep complete (students can copy pattern from other services)
2. **`requirements.txt`** - Keep complete (dependency management is not the focus)
3. **`.env.example`** - Keep complete (configuration template needed)
4. **`accessory-service.http`** - Keep complete (this is the test specification)

### Recommended Removal Strategy:

**models.py:**
- Remove field definitions, keep class structures
- Students implement based on schema specification in Task 3

**database.py:**
- Keep method signatures and docstrings
- Remove all implementation code inside methods
- Students implement using Copilot and pattern from other services

**main.py:**
- Keep app setup (FastAPI initialization, middleware, lifespan)
- Remove all endpoint implementations
- Keep exception handler structure (students can complete)
- Students implement routes following the specification

### Learning Progression:

This gives students practice with:
1. **Task 3**: Implementing Pydantic models from specifications
2. **Task 5**: Implementing database operations with Cosmos DB
3. **Task 6**: Creating REST API endpoints with FastAPI
4. **Task 7**: Testing and debugging their implementation

The difficulty level is balanced:
- Not starting from completely blank files (overwhelming)
- Not having everything done (no learning)
- Having clear structure and patterns to follow
- Using Copilot to accelerate but not bypass learning

### Alternative Approach (More Challenging):

For advanced students, remove even more:
- All models (just import statements)
- All database code (just the class name)
- All main.py (just the file name)

This forces students to:
- Design the complete architecture
- Make more decisions
- Use Copilot more extensively
- Learn from scratch with patterns as reference

Choose based on:
- Student experience level
- Time available
- Learning objectives
- Prior Copilot experience

---

---

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Azure Cosmos DB Python SDK](https://docs.microsoft.com/en-us/azure/cosmos-db/sql/sql-api-sdk-python)
- [REST API Best Practices](https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design)
- [Microservices Patterns](https://microservices.io/patterns/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)

## Summary

By completing this challenge, you will have:
- Built a complete microservice from specifications using GitHub Copilot
- Gained hands-on experience with FastAPI and Azure Cosmos DB
- Learned to follow established patterns and maintain code consistency
- Practiced data modeling with Pydantic validation
- Implemented search, filtering, and pagination features
- Integrated your service into an existing microservices ecosystem
- Tested your implementation thoroughly using HTTP test files

The skills learned here are directly applicable to real-world microservice development and will help you leverage AI-assisted coding tools effectively while maintaining code quality and architectural consistency.

---

## Solution

When you're ready to compare your implementation, review: [Solution Steps](/solutions/challenge-06/README.md)

> **Important:** Try to complete the challenge on your own first. The solution is there to help you if you get stuck or to compare approaches after you've finished. The learning value comes from implementing it yourself with GitHub Copilot's assistance.

---



## Overview

Progressive development of a new component using Copilot and integration with the existing application. Emphasis on working with both local environment and cloud services.

## Learning Objectives

- Implement a microservice using AI-assisted development
- Practice test-driven development with Copilot
- Learn local development and testing strategies
- Understand integration patterns with existing services
- Experience debugging and troubleshooting with AI assistance

## Prerequisites

- Completed Challenge 06 (Design phase)
- Local development environment set up
- Docker and containerization knowledge
- Understanding of the existing pet management system
- Access to development/testing cloud resources

## Tasks

### Task 1: Environment Setup
1. **Local Development Environment**:
   - Set up development environment for your chosen technology stack
   - Configure local database (PostgreSQL, MongoDB, etc.)
   - Set up local message broker (Redis, RabbitMQ) if needed
   - Configure environment variables and secrets

2. **Integration with Existing Services**:
   - Clone and run existing pet management services locally
   - Configure service discovery or direct service communication
   - Set up local API gateway or load balancer
   - Test connectivity between services

### Task 2: Test-Driven Development Setup
1. **Testing Framework**:
   - Use Copilot to set up appropriate testing frameworks
   - Configure unit test, integration test, and end-to-end test structure
   - Set up test data management and cleanup
   - Configure test coverage reporting

2. **Test Planning**:
   - Generate test cases with Copilot based on your design specifications
   - Create test data fixtures and mock objects
   - Plan testing strategy for external service dependencies
   - Set up continuous testing in development workflow

### Task 3: Core Service Implementation
1. **Data Layer Implementation**:
   - Implement data models and repository patterns
   - Use Copilot to generate database access code
   - Implement data validation and error handling
   - Add database migrations and schema management

2. **Business Logic Layer**:
   - Implement core business logic with AI assistance
   - Add input validation and business rule enforcement
   - Implement error handling and logging
   - Add performance optimizations

3. **API Layer Implementation**:
   - Implement REST endpoints based on your OpenAPI specification
   - Use Copilot to generate route handlers and middleware
   - Add request/response validation
   - Implement proper HTTP status code handling

### Task 4: Integration Implementation
1. **Service-to-Service Communication**:
   - Implement synchronous API calls to existing services
   - Add retry logic and circuit breaker patterns
   - Implement asynchronous messaging if applicable
   - Add correlation ID tracking for distributed tracing

2. **Event Publishing and Consumption**:
   - Implement event publishing for significant business events
   - Add event consumers for relevant external events
   - Ensure idempotent event processing
   - Add event schema validation

### Task 5: Local Testing and Validation
1. **Unit Testing**:
   - Write comprehensive unit tests with Copilot assistance
   - Test business logic in isolation
   - Mock external dependencies appropriately
   - Achieve high test coverage

2. **Integration Testing**:
   - Test database interactions and data persistence
   - Test API endpoints with various input scenarios
   - Test error conditions and edge cases
   - Validate integration with existing services

3. **End-to-End Testing**:
   - Test complete user workflows
   - Validate business processes across service boundaries
   - Test performance under load
   - Validate error propagation and handling

### Task 6: Cloud Integration Testing
1. **Cloud Service Configuration**:
   - Configure cloud database connections
   - Set up cloud messaging services
   - Configure monitoring and logging services
   - Test cloud-specific features and limitations

2. **Deployment Testing**:
   - Create containerized version of your service
   - Test deployment to development environment
   - Validate configuration management
   - Test service discovery and health checks

### Task 7: Performance and Monitoring
1. **Performance Testing**:
   - Use Copilot to generate load testing scripts
   - Test service performance under various loads
   - Identify and optimize bottlenecks
   - Validate scalability characteristics

2. **Observability Implementation**:
   - Add structured logging throughout the service
   - Implement metrics collection and export
   - Add distributed tracing integration
   - Set up health check endpoints

## Success Criteria

- [ ] Successfully implemented new microservice with core functionality
- [ ] Achieved high test coverage with comprehensive test suite
- [ ] Successfully integrated with existing services locally
- [ ] Deployed and tested service in cloud environment
- [ ] Implemented proper error handling and resilience patterns
- [ ] Added observability and monitoring capabilities
- [ ] Validated performance meets design requirements

## Development Workflow with Copilot

### 1. Feature Implementation Cycle
```
1. Write failing test with Copilot assistance
2. Use Copilot to generate initial implementation
3. Refine and optimize the generated code
4. Run tests and fix any issues
5. Refactor with Copilot suggestions
6. Commit and push changes
```

### 2. Effective Copilot Prompts for Implementation
```
"Implement a repository pattern for managing pet health records with CRUD operations"

"Create a REST endpoint for scheduling veterinary appointments with proper validation"

"Generate unit tests for the appointment scheduling business logic"

"Add error handling and retry logic for external service calls"
```

### 3. Integration Testing Strategies
- Use Docker Compose for local multi-service testing
- Implement test containers for database testing
- Use service mocks for external dependencies
- Create integration test scenarios covering happy path and error conditions

## Debugging and Troubleshooting with AI

### Common Issues and AI Assistance
- Use Copilot Chat to analyze error messages and stack traces
- Get suggestions for debugging complex integration issues
- Generate test cases to reproduce and isolate problems
- Get recommendations for performance optimization

### Code Review with AI
- Use Copilot to review code for potential issues
- Get suggestions for code improvements and best practices
- Validate security considerations and vulnerabilities
- Check for compliance with coding standards

## Additional Resources

- [Test-driven development best practices](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Microservices testing strategies](https://martinfowler.com/articles/microservice-testing/)
- [Docker Compose for development](https://docs.docker.com/compose/)
- [API testing with Postman](https://learning.postman.com/docs/writing-scripts/test-scripts/)
- [Performance testing tools](https://k6.io/docs/)

## Solution

[Solution Steps](/solutions/challenge-07/README.md)