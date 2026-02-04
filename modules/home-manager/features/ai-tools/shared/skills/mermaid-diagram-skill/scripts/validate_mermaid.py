#!/usr/bin/env python3
"""
Mermaid Syntax Validator

Validates Mermaid diagram code for syntax correctness and common patterns.
Usage: python scripts/validate_mermaid.py [--string|--file] <input>
"""

import sys
import re
from pathlib import Path


# Validation rules per diagram type
DIAGRAM_PATTERNS = {
    "flowchart": r"^flowchart\s+(TD|LR|BT|RL)\s*$",
    "sequence": r"^sequenceDiagram\s*$",
    "erDiagram": r"^erDiagram\s*$",
    "stateDiagram": r"^stateDiagram-v2\s*$",
    "C4Context": r"^C4Context\s*$",
    "C4Container": r"^C4Container\s*$",
    "C4Component": r"^C4Component\s*$",
}


def validate_mermaid_code(mermaid_code, diagram_type=None):
    """
    Validate Mermaid diagram code.

    Args:
        mermaid_code: The Mermaid code to validate
        diagram_type: Optional, expected diagram type

    Returns:
        (is_valid, errors, warnings) tuple
    """
    errors = []
    warnings = []

    # Check code not empty
    if not mermaid_code.strip():
        return False, ["Mermaid code is empty"], []

    # Extract first line to detect diagram type
    lines = mermaid_code.strip().split("\n")
    first_line = lines[0].strip() if lines else ""

    # Detect diagram type if not provided
    if not diagram_type:
        for dtype, pattern in DIAGRAM_PATTERNS.items():
            if re.match(pattern, first_line, re.IGNORECASE):
                diagram_type = dtype
                break

    if not diagram_type:
        errors.append("Unable to detect valid diagram type from first line")

    # Basic syntax validation
    mermaid_code_lower = mermaid_code.lower()

    # Check for common syntax errors
    if "```mermaid" not in mermaid_code_lower:
        warnings.append("Missing ```mermaid code fence marker")

    # Check for common pitfalls based on diagram type
    if diagram_type:
        if "flowchart" in diagram_type.lower():
            check_flowchart_syntax(mermaid_code, errors, warnings)
        elif "sequence" in diagram_type.lower():
            check_sequence_syntax(mermaid_code, errors, warnings)
        elif "er" in diagram_type.lower():
            check_erd_syntax(mermaid_code, errors, warnings)
        elif "state" in diagram_type.lower():
            check_state_syntax(mermaid_code, errors, warnings)

    return len(errors) == 0, errors, warnings


def check_flowchart_syntax(code, errors, warnings):
    """Validate flowchart-specific syntax"""
    # Check for balanced brackets
    open_square = code.count("[") - code.count("[/")  # Exclude [/
    close_square = code.count("]") - code.count("/]")  # Exclude /]

    open_paren = code.count("(") - code.count("(/")  # Exclude (/
    close_paren = code.count(")") - code.count("/)")  # Exclude /)

    if open_square != close_square:
        errors.append(
            f"Unbalanced square brackets: {open_square} open, {close_square} close"
        )

    if open_paren != close_paren:
        errors.append(
            f"Unbalanced parentheses: {open_paren} open, {close_paren} close"
        )


def check_sequence_syntax(code, errors, warnings):
    """Validate sequence diagram-specific syntax"""
    # Check for arrow syntax patterns
    invalid_arrows = re.findall(r"(->>-|<-<|->-\|--<|-><|>-|->", code)

    for arrow in invalid_arrows:
        errors.append(f"Invalid arrow syntax: {arrow}")


def check_erd_syntax(code, errors, warnings):
    """Validate ERD-specific syntax"""
    # Check for valid relationship patterns
    # Common relationship patterns: ||--||, ||--o{, }o--o{, etc.
    lines = code.split("\n")

    for line in lines:
        line = line.strip()
        if "--{" in line or "}--" in line:
            # Check for cardinality symbols in relationships
            relationship_part = line.split("{")[0].split("}")[0]
            if "{" in relationship_part or "}" in relationship_part:
                # Check for dangling braces
                warnings.append(
                    "Check relationship syntax: braces should enclose cardinality"
                )


def check_state_syntax(code, errors, warnings):
    """Validate state diagram-specific syntax"""
    # Check for state transition syntax
    lines = code.split("\n")

    for line in lines:
        line = line.strip()
        if "-->" in line and line.count("-->") > 1:
            warnings.append("Multiple transitions on one line, consider splitting")


def main():
    if len(sys.argv) < 3:
        print("Usage: python validate_mermaid.py [--string|--file] <input>")
        sys.exit(1)

    mode = sys.argv[1]
    input_ = sys.argv[2] if len(sys.argv) > 2 else None

    if not input_:
        print("Error: No input provided")
        sys.exit(1)

    mermaid_code = ""
    if mode == "--file":
        try:
            mermaid_code = Path(input_).read_text()
        except FileNotFoundError:
            print(f"Error: File not found: {input_}")
            sys.exit(1)
    elif mode == "--string":
        mermaid_code = input_
    else:
        print(f"Error: Invalid mode {mode}")
        print("Expected: --string or --file")
        sys.exit(1)

    is_valid, errors, warnings = validate_mermaid_code(mermaid_code)

    if errors:
        print("❌ VALIDATION FAILED")
        for error in errors:
            print(f"  ERROR: {error}")

    if warnings:
        print("⚠️  WARNINGS:")
        for warning in warnings:
            print(f"  WARNING: {warning}")

    if is_valid:
        print("✅ VALIDATION PASSED")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
