# Service API Reference

Describe the HTTP endpoints owned by this service.

## Quick Links
- Shared contracts: `../../platform/API_REFERENCE.md`

## Endpoint Catalog

| Endpoint | Method | Description | Auth |
| --- | --- | --- | --- |
| `/` | GET | Root endpoint with service info | Public |
| `/health` | GET | Health check with database connectivity | Public |
| `/api/accessories` | GET | List accessories with filtering and pagination | Public |
| `/api/accessories` | POST | Create new accessory | Public |
| `/api/accessories/{id}` | GET | Get specific accessory | Public |
| `/api/accessories/{id}` | PATCH | Update accessory (partial) | Public |
| `/api/accessories/{id}` | DELETE | Delete accessory | Public |

## Detailed Contracts

### GET /
Returns service information.
- **Response**: JSON with service name, version, and status.

### GET /health
Checks the health of the service and database connectivity.
- **Behavior**: Tries to query the container. If database/container doesn't exist, creates it automatically and seeds with sample data.
- **Response**: JSON with status and database check result.

### GET /api/accessories
List accessories with filtering and pagination.

**Query Parameters:**
- `search` (Optional[str]): Search in name or description (`CONTAINS`).
- `type` (Optional[str]): Filter by accessory type.
- `lowStockOnly` (Optional[bool]): Show only items with stock < 10.
- `limit` (int, default=100): Max results to return.
- `offset` (int, default=0): Pagination offset.

**Response:**
- `200 OK`: List of `Accessory` objects.

### POST /api/accessories
Create a new accessory.

**Request Body:** `AccessoryCreate`
```json
{
  "name": "Squeaky Toy",
  "type": "toy",
  "price": 15.99,
  "stock": 50,
  "size": "M",
  "imageUrl": "http://example.com/toy.jpg",
  "description": "A fun squeaky toy."
}
```

**Response:**
- `201 Created`: The created `Accessory` object.

### GET /api/accessories/{id}
Get a specific accessory by ID.

**Response:**
- `200 OK`: The `Accessory` object.
- `404 Not Found`: If the accessory does not exist.

### PATCH /api/accessories/{id}
Update an accessory (partial update).

**Request Body:** `AccessoryUpdate` (all fields optional)
```json
{
  "price": 12.99,
  "stock": 45
}
```

**Response:**
- `200 OK`: The updated `Accessory` object.
- `404 Not Found`: If the accessory does not exist.

### DELETE /api/accessories/{id}
Delete an accessory.

**Response:**
- `204 No Content`: On successful deletion.
- `404 Not Found`: If the accessory does not exist.
