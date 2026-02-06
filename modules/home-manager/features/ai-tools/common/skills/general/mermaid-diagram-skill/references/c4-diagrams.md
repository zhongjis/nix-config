# C4 Architecture Diagrams Reference

## Table of Contents
- [Overview](#overview)
- [Context Level](#context-level)
- [Container Level](#container-level)
- [Component Level](#component-level)
- [Accessibility](#accessibility)
- [Validation Checklist](#validation-checklist)

## Overview
C4 diagrams describe a system's architecture at multiple levels of abstraction.

## Context Level
```mermaid
C4Context
    title System Context - Hospeda Platform

    Person(guest, "Guest", "Tourist looking for accommodation")
    Person(owner, "Owner", "Accommodation owner")
    System(hospeda, "Hospeda Platform", "Tourism booking platform")

    System_Ext(clerk, "Clerk", "Authentication provider")
    System_Ext(mercadopago, "Mercado Pago", "Payment processor")
    System_Ext(email, "Email Service", "Transactional emails")

    Rel(guest, hospeda, "Searches and books", "HTTPS")
    Rel(owner, hospeda, "Manages listings", "HTTPS")
    Rel(hospeda, clerk, "Authenticates users", "API")
    Rel(hospeda, mercadopago, "Processes payments", "API")
    Rel(hospeda, email, "Sends notifications", "SMTP")
```

## Container Level
```mermaid
C4Container
    title Container - Hospeda Platform

    Person(user, "User")

    Container(web, "Web App", "Astro + React", "Public-facing website")
    Container(admin, "Admin Panel", "TanStack Start", "Management interface")
    Container(api, "API", "Hono", "Backend services")
    ContainerDb(db, "Database", "PostgreSQL", "Stores all data")

    Rel(user, web, "Uses", "HTTPS")
    Rel(user, admin, "Manages", "HTTPS")
    Rel(web, api, "Calls", "JSON/HTTPS")
    Rel(admin, api, "Calls", "JSON/HTTPS")
    Rel(api, db, "Reads/Writes", "SQL")
```

## Component Level
```mermaid
C4Component
    title Components - API Application

    Container(api, "API", "Hono")

    Component(routes, "Routes", "Hono Router", "HTTP endpoints")
    Component(services, "Services", "Business Logic", "Domain operations")
    Component(models, "Models", "Data Access", "DB operations")
    Component(middleware, "Middleware", "Cross-cutting", "Auth, logging, errors")

    Rel(routes, middleware, "Uses")
    Rel(routes, services, "Calls")
    Rel(services, models, "Uses")
     Rel(models, db, "Queries")
```

## Accessibility

For full accessibility patterns, see [accessibility.md](accessibility.md).

Example:
```mermaid
C4Context
    accTitle: System Architecture Overview
    accDescr: High-level view of users interacting with the platform and external services
    Person(user, "User")
```

## Validation Checklist
- [ ] Appropriate level selected
- [ ] All systems/containers shown
- [ ] Relationships clear
- [ ] External systems identified
- [ ] Accessibility attributes present
