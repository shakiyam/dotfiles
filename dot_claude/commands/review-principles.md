---
description: Review code against maintainability principles
---

Review the current project code against the following maintainability principles and provide an organized report.

## Output Format

CRITICAL: You MUST follow this exact format for scores. Do NOT output "Score: 9/10" - you MUST output "Score: 9/10 (Good)".

For each principle, provide:
- **Score: X/10 (Rating Label)**
  - Use one of these exact formats:
    - Score: 10/10 (Excellent)
    - Score: 9/10 (Good) or Score: 8/10 (Good)
    - Score: 7/10 (Acceptable) or Score: 6/10 (Acceptable)
    - Score: 5/10 (Needs Improvement) or Score: 4/10 (Needs Improvement)
    - Score: 3/10 (Poor) or Score: 2/10 (Poor) or Score: 1/10 (Poor)
- **Strengths:** List specific examples from the codebase
- **Areas for improvement:** List specific issues with file:line references when applicable

At the end, provide:
- **Overall Score: X/10 (Rating Label)** - Calculate average and use appropriate label from above
- **Summary:** 2-3 sentences highlighting main findings
- **Recommended improvements:** Prioritized list of actionable items

Example of correct format:
```
## 1. Express Intent
**Score: 9/10 (Good)**

**Strengths:**
- Clear function names
...
```

Source: https://be.shos.info/

1. Express Intent
- Intent is expressed
- Intent is easy to understand
- There is little description other than intent
- What (what to do) is described, not How (how to do it)
- If possible, Why (why to do it) is also described

2. Single Responsibility Principle
- Program units describe a single job
- That job is completely described within that program unit

3. Accurate Naming
- Names express their (only) job (in one phrase, necessary and sufficient)
- Same things have the same name, different things have different names
- Don't use known names with different meanings
- Don't use problem domain words with changed meanings

4. Once And Only Once
- Things with the same intent are not written repeatedly
- You can distinguish between what it is and what it isn't

5. Appropriately Described Methods
- Method contents consist of descriptions at the same level of abstraction
- Method contents are described at natural granularity (like spoken language)
- Appropriate amount (not too much description)

6. Rule Unification
- The whole follows the same rules

7. Testable
- It should be clear that the description is correct
