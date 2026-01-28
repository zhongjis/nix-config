# State Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Syntax Overview](#syntax-overview)
- [Example](#example)
- [Validation Checklist](#validation-checklist)

## Overview
State diagrams describe the lifecycle and state transitions of an entity.

## Syntax Overview
```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Confirmed : Payment Success
    Pending --> Cancelled : Payment Failed
    Pending --> Cancelled : User Cancels
    Confirmed --> CheckedIn : Check-in Date
    Confirmed --> Cancelled : Cancellation Request
    CheckedIn --> CheckedOut : Check-out Date
    CheckedOut --> Reviewed : User Submits Review
    CheckedOut --> [*] : 30 Days Elapsed
    Reviewed --> [*]
    Cancelled --> [*]
```

## Example
```mermaid
stateDiagram-v2
    [*] --> Draft : Create Booking

    state "Pending Payment" as Pending
    state "Payment Processing" as Processing

    Draft --> Pending : Submit Booking
    Pending --> Processing : Initiate Payment

    Processing --> Confirmed : Payment Approved
    Processing --> PaymentFailed : Payment Declined

    PaymentFailed --> Pending : Retry Payment
    PaymentFailed --> Cancelled : Max Retries

    Confirmed --> Active : Check-in Date Reached
    Active --> Completed : Check-out Date Reached

    Confirmed --> CancelRequested : Cancellation Request
    CancelRequested --> RefundProcessing : Approve Cancellation
    RefundProcessing --> Cancelled : Refund Complete

    Completed --> [*]
    Cancelled --> [*]

    note right of Confirmed
        Owner notified
        Calendar blocked
    end note

    note right of Completed
        Review requested
        Payment released
    end note
```

## Validation Checklist
- [ ] All states defined
- [ ] Transitions logical
- [ ] Start/end states marked
- [ ] Notes explain key states
