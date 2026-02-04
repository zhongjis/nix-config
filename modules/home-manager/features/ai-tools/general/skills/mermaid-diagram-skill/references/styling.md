# Mermaid Styling Reference

## Table of Contents
- [Overview](#overview)
- [Theme Application](#theme-application)
- [Class Styling](#class-styling)
- [Validation Checklist](#validation-checklist)

## Overview
This section covers applying consistent styling to diagrams for branding and readability.

## Theme Application
```mermaid
%%{init: {'theme':'base', 'themeVariables': {
   'primaryColor':'#3B82F6',
   'primaryTextColor':'#fff',
   'primaryBorderColor':'#2563EB',
   'lineColor':'#6B7280',
   'secondaryColor':'#10B981',
   'tertiaryColor':'#F59E0B'
}}}%%
flowchart TD
    A[Start] --> B[Process]
    B --> C[End]
```

## Class Styling
```mermaid
flowchart TD
    A[Normal] --> B[Success]
    B --> C[Error]

    classDef successClass fill:#10B981,stroke:#059669,color:#fff
    classDef errorClass fill:#EF4444,stroke:#DC2626,color:#fff

    class B successClass
    class C errorClass
```

## Validation Checklist
- [ ] Colors match brand
- [ ] Contrast sufficient
- [ ] Styling consistent
- [ ] Readable in both themes
