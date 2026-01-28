---
name: mermaid-diagram-specialist
description: |
  Mermaid diagram specialist for creating flowcharts, sequence diagrams, ERDs, state machines, and architecture visualizations. Use when:
  (1) Creating technical documentation with diagrams
  (2) Visualizing workflows and processes
  (3) Documenting data models with ERDs
  (4) Explaining sequence flows and API interactions
  (5) Creating state machines and lifecycles
  (6) Designing system architecture (C4 diagrams)
  (7) Adding visual diagrams to markdown documents
  CRITICAL: Always use Mermaid format for ALL supported diagram types. Do not use other diagramming formats.
---

# Mermaid Diagram Specialist

Expert in creating Mermaid diagrams for technical documentation, architecture visualization, and process mapping.

**Core Principle**: Use Mermaid format for ALL diagram types. Never substitute with other diagramming tools.

## Supported Diagram Types

- Flowcharts: Decision flows, algorithms, processes
- Sequence Diagrams: API interactions, message flows
- ERDs: Database schemas, entity relationships
- State Diagrams: State machines, lifecycles
- C4 Diagrams: System architecture (context, container, component levels)
- Gantt Charts: Project timelines
- Pie/Bar Charts: Data visualization
- Git Graphs: Version control flows
- User Journeys: User experience flows

## Workflow

### Step 1: Diagram Type Selection

Choose appropriate diagram type based on requirements:

- Process with decisions → **Flowchart** (see [flowcharts.md](references/flowcharts.md))
- API/system interactions → **Sequence Diagram** (see [sequence-diagrams.md](references/sequence-diagrams.md))
- Database structure → **ERD** (see [erds.md](references/erds.md))
- System architecture → **C4 Diagram** (see [c4-diagrams.md](references/c4-diagrams.md))
- State transitions → **State Diagram** (see [state-diagrams.md](references/state-diagrams.md))
- Visual styling → (see [styling.md](references/styling.md))

**Validation**: Diagram type matches content and purpose.

### Step 2: Create Diagram

1. Select appropriate syntax for chosen diagram type (see reference docs)
2. Use Mermaid code only - NEVER substitute with other formats
3. Follow best practices from reference documentation
4. Apply styling from [styling.md](references/styling.md) if needed

### Step 3: Validate Diagram

**CRITICAL**: Always validate Mermaid syntax before finalizing.

Use validation script:
```bash
scripts/validate_mermaid.py --string "<mermaid_code>"
```

Validation checks:
- Correct diagram type declaration
- Proper syntax for chosen diagram type
- Balanced connectors and parentheses
- Valid arrow notation (for sequence diagrams)
- Correct relationship syntax (for ERDs)

If validation fails, fix errors and re-validate.

### Step 4: Integrate into Documentation

Add to markdown with proper code fencing and follow [common patterns](references/common-patterns.md).

## Enforcement

This skill **MUST NOT** generate diagrams in non-Mermaid formats:
- ❌ PlantUML, Graphviz DOT, or other diagramming languages
- ❌ ASCII art or text-based diagrams
- ❌ Screenshot placeholders

Always use Mermaid with syntax validation.

## Resources

See [references/](references/) directory for detailed examples and patterns:
- [flowcharts.md](references/flowcharts.md) - Flowchart syntax and examples
- [sequence-diagrams.md](references/sequence-diagrams.md) - Sequence diagram patterns
- [erds.md](references/erds.md) - ERD relationship syntax
- [c4-diagrams.md](references/c4-diagrams.md) - C4 architecture levels
- [state-diagrams.md](references/state-diagrams.md) - State machine patterns
- [styling.md](references/styling.md) - Theming and customization
- [common-patterns.md](references/common-patterns.md) - Reusable workflow patterns

## Validation Script

Use [scripts/validate_mermaid.py](scripts/validate_mermaid.py) to verify syntax correctness.

## Best Practices

1. Simplicity: Keep diagrams focused and uncluttered
2. Labels: Clear, descriptive labels for all elements
3. Direction: Consistent flow direction (usually top-down or left-right)
4. Grouping: Use subgraphs to group related elements
5. Colors: Use color to highlight important elements
6. Testing: Verify diagrams render in target platform
7. Validation: Always validate syntax before finalizing