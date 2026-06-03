---
description: Information Disclosure and Sensitive File Access methodology. Covers exposure of backups, configs, source code, and PII.
tags: Info Disclosure, Data Leakage, Git, Env, Web
---

# Information Disclosure & Sensitive Files

Information disclosure occurs when an application fails to properly protect sensitive data, leaking it to unauthorized users. This can range from verbose error messages to full source code exposure.

## Common Sensitive Files

1. **Version Control**:
   - `/.git/` or `/.git/config`
   - `/.svn/entries`
2. **Configuration & Environment**:
   - `/.env`, `.env.bak`, `.env.dev`
   - `/web.config`, `/Web.config`
   - `/appsettings.json`
3. **Backups & Archives**:
   - `index.php.bak`, `config.php.save`, `backup.zip`, `archive.tar.gz`
4. **Logs & Diagnostics**:
   - `/phpinfo.php`, `/info.php`
   - `/server-status` (Apache)
   - `/logs/`, `/debug/`

## Directory Listing

- Navigate to common directories (`/images/`, `/css/`, `/uploads/`, `/api/`, `/js/`) to check if directory indexing is enabled.
- If enabled, look for sensitive files that might have been accidentally left behind.
- **Bypass WAF blocks on directories**: Try appending variations like `/images/.`, `/images//`, or `/images%20/`.

## Verbose Error Messages

- Intentionally trigger errors (e.g., malformed input, invalid types, exceedingly long strings, unexpected HTTP methods).
- Look for:
  - Stack traces (reveals internal paths and library versions)
  - Database queries (reveals schema structure)
  - Framework versions (useful for finding CVEs)

## PII Leakage & API Enumeration

- Check API responses (`/api/v1/users/1`) for over-privileged data returns (e.g., password hashes, SSNs, internal IDs).
- Analyze GraphQL introspection queries or REST API endpoints for hidden fields not displayed in the UI.
- **Bypass API Rate Limits/Filters**: 
  - Inject unexpected headers: `X-Forwarded-For: 127.0.0.1` or `X-Original-URL: /admin`
  - Exploit IDOR patterns: If `/user/1` is blocked, try `/user/01`, `/user/1.json`, or `/user/%201`.

## Exploitation using Git Tools

If `/.git/` is exposed, use tools like `git-dumper` to reconstruct the repository.
```bash
git-dumper http://target.com/.git/ output_dir
```
Analyze the reconstructed repo for hardcoded credentials, API keys, and sensitive logic.

## Instructions for usage:
- When scanning for sensitive files, rely on targeted fuzzing using tools like `ffuf` or `gobuster` rather than manual probing.
- Ensure your wordlists contain technology-specific extensions (e.g., `.php.bak`, `.swp`, `.zip`).
- Always check the `robots.txt` and `sitemap.xml` before starting aggressive enumeration, as they often explicitly list sensitive endpoints you shouldn't access.

## Advanced Bypass Techniques & Payloads

- **Obfuscation**: Use encoding, chunking, and case variation to bypass signature-based detection.
- **Rate Limit Bypasses**: Rotate IPs via proxies, modify `X-Forwarded-For` headers, or append random parameters to the query string.

- **Author**: **Vivek Chanchal**
