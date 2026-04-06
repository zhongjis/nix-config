# Entity Relationship Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Relationship Types](#relationship-types)
- [Cardinality Symbols](#cardinality-symbols)
- [Example](#example)
- [Accessibility](#accessibility)
- [Validation Checklist](#validation-checklist)

## Overview
ER diagrams model data structures and relationships between entities.

## Syntax Overview
Syntax:
```mermaid
erDiagram
    USER ||--o{ BOOKING : creates
    ACCOMMODATION ||--o{ BOOKING : "booked for"
    USER {
        uuid id PK
        string email UK
        string name
        timestamp created_at
    }
    BOOKING {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        date check_in
        date check_out
        enum status
    }
    ACCOMMODATION {
        uuid id PK
        string name
        text description
        decimal price_per_night
    }
```

## Relationship Types
- `||--||` - One to one
- `||--o{` - One to many
- `}o--o{` - Many to many
- `||--o|` - One to zero or one

## Cardinality Symbols
- `||` - Exactly one
- `o|` - Zero or one
- `}o` - Zero or more
- `}|` - One or more

## Example - Full Hospeda ERD:
```mermaid
erDiagram
    USER ||--o{ BOOKING : creates
    USER ||--o{ REVIEW : writes
    USER ||--o{ ACCOMMODATION : owns
    ACCOMMODATION ||--o{ BOOKING : "has bookings"
    ACCOMMODATION ||--o{ REVIEW : "has reviews"
    ACCOMMODATION }o--o{ AMENITY : includes
    BOOKING ||--|| PAYMENT : "has payment"

    USER {
        uuid id PK
        string clerk_id UK
        string email UK
        string name
        enum role
        timestamp created_at
    }

    ACCOMMODATION {
        uuid id PK
        uuid owner_id FK
        string name
        text description
        decimal price_per_night
        int max_guests
        enum status
    }

    BOOKING {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        date check_in
        date check_out
        int guests
        enum status
        decimal total_price
    }

    REVIEW {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        int rating
        text comment
        timestamp created_at
    }

    PAYMENT {
        uuid id PK
        uuid booking_id FK
        string mercadopago_id UK
        decimal amount
        enum status
        timestamp processed_at
    }

    AMENITY {
        uuid id PK
        string name
        string icon
    }
```

## Accessibility

For full accessibility patterns, see [accessibility.md](accessibility.md).

Example:
```mermaid
erDiagram
    accTitle: User Database Schema
    accDescr: Shows relationships between User, Order, and Product entities
    USER ||--o{ ORDER : places
```

## Validation Checklist
- [ ] All entities defined
- [ ] Relationships accurate
- [ ] Cardinality correct
- [ ] Primary/Foreign keys marked
- [ ] Accessibility attributes present
