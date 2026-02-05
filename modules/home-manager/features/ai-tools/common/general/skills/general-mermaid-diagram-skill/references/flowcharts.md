# Flowchart Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Node Shapes](#node-shapes)
- [Direction Options](#direction-options)
- [Example](#example)
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

## Validation Checklist
- [ ] All paths covered
- [ ] Decision points clear
- [ ] Start and end defined
- [ ] Flow direction logical
