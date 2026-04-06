# Sequence Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Participant Types](#participant-types)
- [Arrow Types](#arrow-types)
- [Example](#example)
- [Multi-line Participant Names](#multi-line-participant-names)
- [Accessibility](#accessibility)
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

## Multi-line Participant Names
Use `<br/>` tags to display participant names across multiple lines. This improves readability for long names or when adding metadata like port numbers or service types.

Example with multi-line participant names:
```mermaid
sequenceDiagram
    participant API as API Server<br/>(Port 8080)
    participant DB as Database<br/>(PostgreSQL)
    participant Cache as Cache<br/>(Redis)
    
    API->>Cache: Check cached data
    Cache-->>API: Cache miss
    API->>DB: Query records
    DB-->>API: Return data
    API->>Cache: Store in cache
```

**Best practices**:
- Use descriptive aliases (e.g., `API as API Server<br/>(Port 8080)`)
- Include relevant context like port numbers, database type, or service version
- Keep lines concise to avoid excessive wrapping

## Accessibility
Sequence diagrams should include accessibility attributes to ensure diagrams are usable by assistive technologies. See [accessibility.md](accessibility.md) for comprehensive accessibility guidance.

Example with accessibility attributes:
```mermaid
sequenceDiagram
    accTitle: Authentication Flow
    accDescr: Shows login sequence between user and authentication service
    
    actor User
    participant Auth
    participant DB
    
    User->>Auth: Login request
    Auth->>DB: Verify credentials
    DB-->>Auth: User found
    alt Credentials match
        Auth-->>User: JWT token
    else Credentials invalid
        Auth-->>User: Error 401
    end
```

**Accessibility requirements**:
- Use `accTitle:` for a brief diagram title
- Use `accDescr:` for a detailed description of the diagram flow
- Ensure `actor` and `participant` labels are descriptive
- Test diagrams with screen readers to verify clarity

## Validation Checklist
- [ ] All participants identified
- [ ] Message flow logical
- [ ] Return messages shown
- [ ] Alt/loop blocks used correctly
- [ ] Accessibility attributes present (accTitle, accDescr)
- [ ] Participant aliases descriptive

