# Dockerfile Best Practices Check

Check the Dockerfile against the following best practices.

## References

1. [Best practices | Docker Docs](https://docs.docker.com/build/building/best-practices/)
2. [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
3. [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
4. [Top 20 Dockerfile best practices | Sysdig](https://www.sysdig.com/learn-cloud-native/dockerfile-best-practices)

## Checklist

### Base Image

- Use lightweight images (slim/alpine/distroless/Chainguard) [1]
- Pin versions (avoid :latest) [1]
- Use trusted registries [2,3]

### Build Optimization

- Use multi-stage builds [1,4]
- Minimize layers (chain commands with &&) [1,4]
- Order instructions from least to most frequently changing (cache optimization) [1]
- Configure .dockerignore [1]
- Use COPY instead of ADD [1,2]
- Use set -o pipefail for piped commands [1]

### Package Management

- Exclude unnecessary packages [2,4]
- Run apt-get update && install in the same RUN [1,2]
- Use --no-install-recommends [1]
- Remove apt cache (/var/lib/apt/lists/*) [1]

### Security

- Run as non-root user [2,3]
- Create dedicated user (groupadd/useradd) [1,4]
- Do not embed secrets in Dockerfiles [2]
- Consider removing setuid/setgid binaries [2]

### Configuration

- Set WORKDIR (avoid cd) [1]
- Declare EXPOSE if applicable [1]
- Use exec form for CMD (e.g., CMD ["executable"]) [1]
- Add LABEL for metadata (OCI standard: org.opencontainers.image.*) [4]

## Output Format

Output results in a table format and suggest improvements if issues are found.
Do not include reference numbers in the output.
