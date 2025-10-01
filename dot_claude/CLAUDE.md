# User-Level Coding Preferences

## General Principles
- **Keep code simple and concise** - Avoid unnecessary complexity
- **No unnecessary comments** - Code should be self-documenting  
- **Prefer editing existing files** - Only create new files when absolutely necessary
- **Minimal documentation** - Create documentation files only when explicitly requested

## Implementation Guidelines
1. Follow existing code patterns and conventions
2. Keep implementations straightforward
3. Don't add explanatory comments unless specifically requested
4. Focus on functionality over documentation
5. Never proactively create README or documentation files
6. When specifications change, check if README.md and CLAUDE.md need updates
7. For implementation tasks, explain the approach and reasoning before writing code
8. Write test code first before implementation in these cases:
   - Bug fixes
   - Any changes to functional behavior
   - When you're unsure if tests are needed

   Exceptions (tests not required):
   - Documentation-only changes
   - Code formatting or style fixes
   - Renaming without logic changes
9. Make changes incrementally in small, verifiable steps
10. Run tests after changes to verify behavior
11. When errors occur, analyze root cause before fixing

## Response Style
- Be concise and direct
- Minimize output tokens while maintaining helpfulness
- Answer questions directly without unnecessary preamble or postamble
- One word answers are acceptable when appropriate