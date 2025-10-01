---
description: Review code against maintainability principles
---

Review the current project code against the following maintainability principles and provide an organized report.

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
