---
description: Cross-Site Request Forgery (CSRF) methodology. Covers token bypasses, SameSite cookie attributes, and JSON CSRF.
tags: CSRF, Web, SameSite, Authorization
---

# Cross-Site Request Forgery (CSRF)

CSRF occurs when a malicious website causes a user's web browser to perform an unwanted action on a trusted site where the user is currently authenticated.

## Requirements for CSRF

1. **Relevant Action**: The action must be state-changing (e.g., updating a password, transferring funds).
2. **Cookie-based Session Handling**: The application relies on session cookies automatically sent by the browser.
3. **No Unpredictable Request Parameters**: The request must not contain unpredictable tokens (e.g., anti-CSRF tokens).

## Bypassing CSRF Defenses

### 1. Bypassing Anti-CSRF Tokens

- **Remove the Token**: Send the request without the token parameter entirely. Sometimes validation is skipped if the token is missing.
- **Change Request Method**: If the token is only validated on POST requests, try changing the method to GET. (e.g., `<img src="https://target.com/action?param=value">`)
- **Use Another User's Token**: If tokens are not tied to the user session, use a token generated from your attacker account.
- **Provide a Blank Token**: Try sending an empty string as the token.
- **Extract Token via XSS**: If XSS is present on the site, use it to read the CSRF token and forge the request.
- **Bypass Referer/Origin Checks**: If the site relies on HTTP `Referer` or `Origin` headers instead of tokens, try omitting them (using `<meta name="referrer" content="no-referrer">`), or spoofing them if the regex is weak (e.g., `attacker-target.com`).

### 2. SameSite Cookie Bypasses

The `SameSite` cookie attribute restricts when cookies are sent in cross-site requests.

- **SameSite=None**: No restrictions. Vulnerable to standard CSRF.
- **SameSite=Lax (Default in modern browsers)**: Cookies are only sent on top-level navigations (e.g., clicking a link) using safe HTTP methods (GET).
  - *Bypass*: If a state-changing action can be performed via GET (e.g., `GET /updateEmail?email=attacker@site.com`), it can be exploited.
  - *Bypass*: Method override. Some frameworks allow overriding POST with GET by appending `?_method=POST`.
- **SameSite=Strict**: Cookies are never sent in cross-site requests.

### 3. JSON CSRF

Traditional CSRF payloads use HTML forms (`application/x-www-form-urlencoded`). If the endpoint expects JSON (`application/json`), standard forms won't work.

- **Bypass**: Some endpoints accept `text/plain` but parse it as JSON. You can use a standard HTML form with `enctype="text/plain"` to send JSON-like payloads.
- **Bypass**: Flash or CORS misconfigurations can sometimes be leveraged to send JSON cross-origin.

## Proof of Concept Generation

Create an HTML file to demonstrate the attack:

```html
<html>
  <body>
    <form action="https://target.com/update_profile" method="POST">
      <input type="hidden" name="email" value="attacker@evil.com" />
      <input type="submit" value="Submit request" />
    </form>
    <script>
      document.forms[0].submit();
    </script>
  </body>
</html>
```

## Instructions for usage:
1.  Identify a state-changing action that does not require re-authentication (like entering a password).
2.  Use a proxy tool like Burp Suite or OWASP ZAP to intercept the request and right-click to "Generate CSRF PoC".
3.  Test the generated HTML file in a browser where you are logged in.
4.  If it fails, apply the bypass techniques listed above (method change, removing tokens, overriding JSON content types).

## Advanced Bypass Techniques & Payloads

- **Obfuscation**: Use encoding, chunking, and case variation to bypass signature-based detection.
- **Rate Limit Bypasses**: Rotate IPs via proxies, modify `X-Forwarded-For` headers, or append random parameters to the query string.

- **Author**: **Vivek Chanchal**
