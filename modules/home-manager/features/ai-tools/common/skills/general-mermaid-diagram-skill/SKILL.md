---
name: mermaid-diagram-specialist
description: |
Create Mermaid diagrams for technical documentation. Supports 18 diagram types including Flowchart, Sequence, ERD, State, C4, Class, Mindmap, Gantt, Git Graph, User Journey, and more.
---

# Mermaid Diagram Specialist

Expert in creating Mermaid diagrams for technical documentation, architecture visualization, and process mapping.

**Core Principle**: Use Mermaid format for ALL diagram types. Never substitute with other diagramming tools.

## Supported Diagram Types

### Stable Types

- Flowcharts: Decision flows, algorithms, processes (see [flowcharts.md](references/flowcharts.md))
- Sequence Diagrams: API interactions, message flows (see [sequence-diagrams.md](references/sequence-diagrams.md))
- ERDs: Database schemas, entity relationships (see [erds.md](references/erds.md))
- State Diagrams: State machines, lifecycles (see [state-diagrams.md](references/state-diagrams.md))
- C4 Diagrams: System architecture (context, container, component levels) (see [c4-diagrams.md](references/c4-diagrams.md))
- Gantt Charts: Project timelines
- Pie/Bar Charts: Data visualization
- Git Graphs: Version control flows
- User Journeys: User experience flows
- Class Diagrams: Object-oriented structures (see [stable-new-diagrams.md](references/stable-new-diagrams.md))
- Mindmaps: Hierarchical brainstorming (see [stable-new-diagrams.md](references/stable-new-diagrams.md))
- Quadrant Charts: 2x2 matrix visualizations (see [stable-new-diagrams.md](references/stable-new-diagrams.md))

### Experimental Types 🔥

_Use with caution; syntax may be unstable or rendering support may vary._

- Timeline: Chronological event mapping
- Sankey: Flow distribution visualization
- XY Chart: Generic coordinate plotting
- Block: High-level architectural blocks
- Kanban: Workflow board visualization
- Architecture: Cloud/system component visualization

See [experimental-diagrams.md](references/experimental-diagrams.md) for details on experimental syntax.

## Workflow

### Step 1: Diagram Type Selection

Choose appropriate diagram type based on requirements:

- Process with decisions → **Flowchart**
- API/system interactions → **Sequence Diagram**
- Database structure → **ERD**
- System architecture → **C4 Diagram** or **Architecture** 🔥
- State transitions → **State Diagram**

**Validation**: Ensure chosen diagram type matches the structural nature of the information.

### Step 2: Create Diagram

1. Select appropriate syntax for chosen diagram type (see reference docs)
2. Use Mermaid code only - NEVER substitute with other formats
3. Follow best practices from reference documentation
4. Apply styling from [styling.md](references/styling.md) if needed

### Step 2.5: Add Accessibility

**MANDATORY**: Include accessibility metadata for screen readers.

1. Use `accTitle: <Short Title>` to define the diagram's title
2. Use `accDescr: <Detailed Description>` to describe the diagram's content/flow
   (See [accessibility.md](references/accessibility.md) for details)

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
- Valid relationship syntax
- Inclusion of accessibility metadata

If validation fails, fix errors and re-validate.

### Step 4: Integrate into Documentation

Add to markdown with proper code fencing and follow [common patterns](references/common-patterns.md).

## Experimental Features

The following diagram types are under active development in Mermaid:

- **Timeline**: Use for project histories or roadmaps.
- **Sankey**: Use for resource allocation or energy flows.
- **XY Chart**: Use for line, bar, or scatter plots.
- **Block**: Use for grouping high-level system components.
- **Kanban**: Use for visualizing work status.
- **Architecture**: Use for cloud infrastructure visualization.

**Warning**: These features may have limited rendering support in some Markdown viewers. Always verify the output. See [experimental-diagrams.md](references/experimental-diagrams.md).

## Enforcement

This skill **MUST NOT** generate diagrams in non-Mermaid formats:

- ❌ PlantUML, Graphviz DOT, or other diagramming languages
- ❌ ASCII art or text-based diagrams
- ❌ Screenshot placeholders

## Resources

See [references/](references/) directory for detailed examples and patterns:

- [flowcharts.md](references/flowcharts.md) - Flowchart syntax and examples
- [sequence-diagrams.md](references/sequence-diagrams.md) - Sequence diagram patterns
- [erds.md](references/erds.md) - ERD relationship syntax
- [c4-diagrams.md](references/c4-diagrams.md) - C4 architecture levels
- [state-diagrams.md](references/state-diagrams.md) - State machine patterns
- [styling.md](references/styling.md) - Theming and customization
- [common-patterns.md](references/common-patterns.md) - Reusable workflow patterns
- [accessibility.md](references/accessibility.md) - Accessibility best practices
- [experimental-diagrams.md](references/experimental-diagrams.md) - Experimental syntax guides
- [stable-new-diagrams.md](references/stable-new-diagrams.md) - Class, Mindmap, Quadrant guides

## Best Practices

1. **Accessibility**: Always include `accTitle` and `accDescr`.
2. **Init Directives**: Use `%%{init: { 'theme': 'base' } }%%` for granular theme control.
3. **Multi-line Labels**: Use string quotes `"Label Text"` for labels with special characters or line breaks.
4. **Subgraphs**: Use subgraphs to group related elements logically.
5. **Simplicity**: Keep diagrams focused and uncluttered.
6. **Direction**: Consistent flow direction (usually top-down `TD` or left-right `LR`).
7. **Validation**: Always validate syntax before finalizing.
