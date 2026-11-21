# Security

This repository is a local/portfolio stack, not a production deployment.

## Reporting

Report suspected vulnerabilities privately via a GitHub security advisory in
the affected repository instead of a public issue.

## Sensitive data

- The stack uses generated local secrets; never commit `.env`, `.secrets/` or
  generated gateway keys.
- Demo logs and screenshots must use synthetic data only.
- Do not record API keys, bearer tokens or private hostnames in demo videos.

## Local exposure

By default, host ports are bound to `127.0.0.1`. Do not expose the admin API,
lmlog token or console tokens to an untrusted network. Use a reverse proxy with
TLS for any shared deployment.

## Supported versions

Only the latest `0.1.x` line is supported for security fixes.
