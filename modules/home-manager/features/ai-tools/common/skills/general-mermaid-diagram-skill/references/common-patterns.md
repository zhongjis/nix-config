# Common Mermaid Patterns Reference

## Table of Contents
- [API Request Flow](#api-request-flow)
- [Error Handling Flow](#error-handling-flow)
- [Accessibility](#accessibility)

## API Request Flow
```mermaid
sequenceDiagram
    Client->>+API: GET /resource
    API->>+Service: fetchResource()
    Service->>+Model: findById()
    Model->>+DB: SELECT query
    DB-->>-Model: Row data
    Model-->>-Service: Entity
    Service-->>-API: DTO
    API-->>-Client: JSON response
```

## Error Handling Flow
```mermaid
flowchart TD
    Request[Incoming Request] --> Validate{Valid?}
    Validate -->|No| ValidationError[Validation Error]
    ValidationError --> ErrorHandler[Error Handler]
    Validate -->|Yes| Process[Process Request]
    Process --> DB{DB Success?}
    DB -->|No| DBError[Database Error]
    DBError --> ErrorHandler
    DB -->|Yes| Success[Success Response]
    ErrorHandler --> LogError[Log Error]
     LogError --> ErrorResponse[Error Response]
```

## Accessibility

For full accessibility patterns, see [accessibility.md](accessibility.md).

Example:
```mermaid
flowchart TD
    accTitle: Request Processing Flow
    accDescr: Illustrates how requests are validated and processed with error handling
    Request[Incoming Request] --> Validate{Valid?}
```

