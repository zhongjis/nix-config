# Flowchart Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Node Shapes](#node-shapes)
- [Direction Options](#direction-options)
- [Subgraphs](#subgraphs)
- [Multi-line Labels](#multi-line-labels)
- [Bidirectional Arrows](#bidirectional-arrows)
- [Example](#example)
- [Accessibility](#accessibility)
- [Validation Checklist](#validation-checklist)

## Overview
Flowchart diagrams visualize processes and decision paths, aiding understanding of workflows.

## Syntax Overview
Syntax:
```mermaid
flowchart TD
    Start([Start]) --> Input[/User Input/]
    Input --> Validate{Valid?}
    Validate -->|Yes| Process[Process Data]
    Validate -->|No| Error[Show Error]
    Error --> Input
    Process --> Save[(Save to DB)]
    Save --> Success[/Success Response/]
    Success --> End([End])
```

## Node Shapes
- `[Rectangle]` - Process step
- `([Rounded])` - Start/End
- `{Diamond}` - Decision
- `[/Parallelogram/]` - Input/Output
- `[(Database)]` - Data storage
- `((Circle))` - Connector

## Direction Options
- `TD` - Top to Down
- `LR` - Left to Right
- `BT` - Bottom to Top
- `RL` - Right to Left

## Subgraphs
Group related nodes using subgraphs. Useful for representing systems, services, or logical boundaries.

```mermaid
flowchart TD
    subgraph "External Services"
        API[API Server]
        DB[(Database)]
    end
    subgraph "Client"
        UI[User Interface]
    end
    UI --> API
    API --> DB
```

## Multi-line Labels
Use `<br/>` to split labels across multiple lines for readability.

```mermaid
flowchart TD
    A[Service<br/>Port: 8080] --> B[Database<br/>PostgreSQL]
```

## Bidirectional Arrows
Use `<-->` for connections that can flow in both directions.

```mermaid
flowchart TD
    Client[Client] <--> Server[Server]
    Server <--> Cache[(Cache)]
```

## Example
```mermaid
flowchart TD
    Start([User Initiates Booking]) --> CheckDates[Check Date Availability]
    CheckDates --> Available{Dates Available?}
    Available -->|No| ShowError[/Show Unavailable Message/]
    ShowError --> End([End])
    Available -->|Yes| CreateBooking[Create Pending Booking]
    CreateBooking --> Payment[Process Payment]
    Payment --> PaymentSuccess{Payment Success?}
    PaymentSuccess -->|No| CancelBooking[Cancel Booking]
    CancelBooking --> ShowError
    PaymentSuccess -->|Yes| ConfirmBooking[Confirm Booking]
    ConfirmBooking --> SendEmail[/Send Confirmation Email/]
    SendEmail --> SaveDB[(Save to Database)]
     SaveDB --> Success[/Show Success/]
     Success --> End
```

## Accessibility
Add accessibility attributes to ensure diagrams are understandable to screen readers and automated tools.

```mermaid
flowchart TD
    accTitle: User Booking Flow
    accDescr: A flowchart showing the user booking process with payment validation
    Start([Start]) --> Input[User Input]
    Input --> Validate{Valid?}
```

See [accessibility.md](accessibility.md) for comprehensive accessibility guidelines.

## Validation Checklist
- [ ] All paths covered
- [ ] Decision points clear
- [ ] Start and end defined
- [ ] Flow direction logical
- [ ] Accessibility attributes present
- [ ] Subgraphs named descriptively
