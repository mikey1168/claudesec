---
description: Security Headers validation methodology. Covers CSP, HSTS, X-Frame-Options, CORS headers, and how missing configurations compound the severity of other web vulnerabilities.
tags: Security Headers, Web, CSP, HSTS, CORS, Clickjacking
---

# Security Headers Validation

Security headers are HTTP response headers that define the security policies of a web application. Proper configuration protects applications from client-side attacks like XSS, Clickjacking, and MIME sniffing.

## Methodology

1. Make a request to the target application and inspect the HTTP response headers.
2. Identify missing security headers.
3. Analyze the configuration of present headers for misconfigurations (e.g., overly permissive policies).
4. Evaluate how these missing or misconfigured headers can be combined with other vulnerabilities to increase impact.

## Key Security Headers

### 1. Content-Security-Policy (CSP)
CSP is a defense-in-depth mechanism that helps detect and mitigate Cross-Site Scripting (XSS) and data injection attacks.

- **Look for**: Missing CSP, or the presence of `unsafe-inline` or `unsafe-eval` in the `script-src` directive.
- **Exploitation Impact**: If CSP is missing, an attacker who finds an HTML injection flaw can easily escalate it to full XSS. If `unsafe-inline` is allowed, basic XSS payloads like `<script>alert(1)</script>` will execute. If `script-src` relies on a whitelist of domains (e.g., `*.google.com`), look for JSONP endpoints on those domains to bypass the CSP.

### 2. Strict-Transport-Security (HSTS)
HSTS forces browsers to communicate with the server exclusively over HTTPS.

- **Look for**: Missing header, or a `max-age` set to 0 or a very low value. Also check if the `includeSubDomains` and `preload` directives are present.
- **Exploitation Impact**: Allows Man-in-the-Middle (MitM) attackers to perform SSL stripping attacks, downgrading users to HTTP and intercepting sensitive traffic (like session cookies).

### 3. X-Frame-Options (XFO)
Protects against Clickjacking attacks by determining whether the site can be framed.

- **Look for**: Missing header, or `ALLOW-FROM` pointing to an attacker-controlled domain.
- **Exploitation Impact**: If missing, an attacker can embed the vulnerable page in an `<iframe>` on their own site, overlaying invisible elements to trick authenticated users into performing actions (e.g., deleting an account, transferring funds).
- *Note*: CSP's `frame-ancestors` directive obsoletes `X-Frame-Options` in modern browsers.

### 4. X-Content-Type-Options
Prevents browsers from MIME-sniffing the response away from the declared `Content-Type`.

- **Look for**: Missing header or any value other than `nosniff`.
- **Exploitation Impact**: If a site allows users to upload a text file (e.g., `payload.txt`) containing HTML/JavaScript, but serves it with `Content-Type: text/plain`, a missing `nosniff` directive might cause the browser to guess the content is HTML and execute the script, leading to XSS.

### 5. CORS Headers
Controls cross-origin resource sharing.
- **Look for**: `Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true` (which is technically invalid in modern browsers, but points to bad logic), or dynamic reflection of the `Origin` header.
- **Exploitation Impact**: Can allow malicious sites to read sensitive data from the authenticated user's session. (See the specific CORS skill for deep exploitation).

### 6. Cross-Origin Opener / Embedder Policies (COOP & COEP)
Prevents cross-origin documents from sharing a browsing context group and protects against side-channel attacks like Spectre.
- **Look for**: `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

## Advanced Bypass Techniques & Payloads

- **CSP Bypass via JSONP**: If a trusted domain in the CSP (e.g., `script-src trusted.com`) hosts a vulnerable JSONP endpoint, you can inject a script via `<script src="https://trusted.com/api?callback=alert(1)"></script>`.
- **CSP Bypass via Open Redirects**: If a trusted domain has an open redirect, some older browsers will follow the redirect and load the script from the attacker's domain, bypassing the CSP.
- **Clickjacking Frame Busting Bypass**: If the application uses JavaScript frame-busting (`if (top != self) top.location = self.location;`) instead of `X-Frame-Options`, attackers can bypass it using the `sandbox` attribute on the iframe: `<iframe sandbox="allow-forms" src="..."></iframe>` (blocking the JavaScript redirect).

## Automation

- Tools like **SecurityHeaders.com**, **shcheck**, or built-in Burp Suite passive scanning can quickly identify missing security headers across a web application.

- **Author**: **Vivek Chanchal**
