# Service Data Models

Capture schemas owned by this service.

## Schema Inventory
| Name | Type | Owner | Storage |
| --- | --- | --- | --- |
| Accessory | Entity | Accessory Service | Cosmos DB (`accessories` container) |

## Detailed Schemas

### Accessory
Represents a pet accessory item.

**Storage Location**: Cosmos DB container `accessories`.

**Fields:**

| Field | Type | Required | Description | Validation |
| --- | --- | --- | --- | --- |
| `id` | str (UUID) | Yes | Unique identifier | Auto-generated |
| `name` | str | Yes | Name of the accessory | 1-200 chars |
| `type` | str | Yes | Category of the accessory | One of: "toy", "food", "collar", "bedding", "grooming", "other" |
| `price` | float | Yes | Price of the item | >= 0 |
| `stock` | int | Yes | Quantity in stock | >= 0 |
| `size` | str | Yes | Size category | One of: "S", "M", "L", "XL" |
| `imageUrl` | str | No | URL to image | |
| `description` | str | No | Detailed description | Max 2000 chars |
| `createdAt` | datetime | Yes | Creation timestamp | Auto-set on creation |
| `updatedAt` | datetime | Yes | Last update timestamp | Auto-set on creation/update |

### Models to Implement

#### AccessoryBase
Base model with common fields.
- `name`
- `type`
- `price`
- `stock`
- `size`
- `imageUrl`
- `description`

#### AccessoryCreate
For POST requests. Inherits from `AccessoryBase`.
- No `id`, `createdAt`, `updatedAt`.

#### AccessoryUpdate
For PATCH requests.
- All fields from `AccessoryBase` are optional.

#### Accessory
Complete model. Inherits from `AccessoryBase`.
- Includes `id`, `createdAt`, `updatedAt`.

#### AccessorySearchFilters
Query parameters for search/filter.
- `search`: Optional[str]
- `type`: Optional[str]
- `lowStockOnly`: Optional[bool]
- `limit`: int
- `offset`: int

### Validation Rules
- **Price**: Must be non-negative.
- **Stock**: Must be non-negative.
- **Type**: Must be one of the 6 valid types.
- **Size**: Must be S, M, L, or XL.
- **Name**: Length between 1-200 characters.
