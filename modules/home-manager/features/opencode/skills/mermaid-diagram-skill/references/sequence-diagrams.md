# Sequence Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Participant Types](#participant-types)
- [Arrow Types](#arrow-types)
- [Example](#example)
- [Validation Checklist](#validation-checklist)

## Overview
Sequence diagrams describe interactions and message flows between actors and systems.

## Syntax Overview
Syntax:
```mermaid
sequenceDiagram
    actor User
    participant Frontend
    participant API
    participant DB
    participant Payment

    User->>Frontend: Click "Book"
    Frontend->>API: POST /api/bookings
    API->>DB: Check availability
    DB-->>API: Available
    API->>Payment: Process payment
    Payment-->>API: Payment successful
    API->>DB: Create booking
    DB-->>API: Booking created
    API-->>Frontend: 201 Created
    Frontend-->>User: Show confirmation
```

## Participant Types
- `actor` - Human user
- `participant` - System/Service
- `database` - Database

## Arrow Types
- `->` - Solid line (synchronous)
- `-->` - Dotted line (response)
- `->>` - Solid arrow (async message)
- `-->>` - Dotted arrow (async response)

## Example - Authentication Flow:
```mermaid
sequenceDiagram
    actor User
    participant Frontend
    participant API
    participant Clerk
    participant DB

    User->>Frontend: Enter credentials
    Frontend->>Clerk: Login request
    Clerk->>Clerk: Validate credentials
    alt Credentials valid
        Clerk-->>Frontend: JWT token
        Frontend->>API: Request with token
        API->>Clerk: Verify token
        Clerk-->>API: Token valid
        API->>DB: Fetch user data
        DB-->>API: User data
        API-->>Frontend: User session
        Frontend-->>User: Logged in
    else Credentials invalid
        Clerk-->>Frontend: Auth error
        Frontend-->>User: Show error
    end
```

## Validation Checklist
- [ ] All participants identified
- [ ] Message flow logical
- [ ] Return messages shown
- [ ] Alt/loop blocks used correctly
