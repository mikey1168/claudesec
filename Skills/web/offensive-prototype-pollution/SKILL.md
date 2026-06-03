---
description: JavaScript Prototype Pollution methodology. Covers client-side and server-side pollution, Gadget discovery, and escalation to RCE/XSS.
tags: Prototype Pollution, JavaScript, Web, XSS, RCE, Node.js
---

# Prototype Pollution

Prototype pollution is a vulnerability in JavaScript applications where an attacker can inject properties into the global `Object.prototype`. This can manipulate the logic of the application, leading to XSS, bypasses, or RCE (especially in Node.js).

## Mechanism

JavaScript objects inherit properties from their prototype. If an application incorrectly merges or parses objects (e.g., via `__proto__`, `constructor.prototype`), an attacker can pollute the global prototype.

```json
{
  "__proto__": {
    "pollutedProperty": "evilValue"
  }
}
```
Alternatively, bypasses for WAFs/Filters that block `__proto__`:
```json
{
  "constructor": {
    "prototype": {
      "pollutedProperty": "evilValue"
    }
  }
}
```
If successful, all objects in the application will now have `pollutedProperty = "evilValue"` unless explicitly overridden.

## Identifying Prototype Pollution

### 1. Client-Side (Browser)

1. Inject prototype pollution vectors into URL parameters, JSON payloads, or fragment identifiers.
   - `?__proto__[testProp]=testValue`
   - `?constructor[prototype][testProp]=testValue`
2. Open the browser console and check if the property exists globally:
   - `console.log(Object.prototype.testProp)`
3. If it returns `"testValue"`, the application is vulnerable.

### 2. Server-Side (Node.js)

1. Inject vectors into JSON payloads sent to the API.
2. Observe application behavior. Server-side pollution often leads to Denial of Service (DoS) if critical properties are overwritten, or it might alter response logic.
3. Look for changes in JSON responses that suggest global properties have been altered.

## Exploitation (Gadgets)

A "gadget" is a piece of code that behaves insecurely when a specific property is polluted.

### Client-Side (Escalating to DOM XSS)

Look for code that accesses an undefined property and uses it in a sink (e.g., `innerHTML`, `eval`, `setTimeout`).
If a script does:
`element.innerHTML = config.customHtml || defaultHtml;`
You can pollute `customHtml` with an XSS payload:
`?__proto__[customHtml]=<img src=x onerror=alert(1)>`

### Server-Side (Escalating to RCE)

In Node.js environments, polluting properties used in `child_process.spawn()`, `exec()`, or template engines (e.g., Pug, Handlebars) can lead to RCE.
Common targets for RCE:
- `env` or `shell` options in `child_process.spawn()`
- `NODE_OPTIONS` environment variable (e.g., `--require /proc/self/environ`)

## Common Vulnerable Functions

- `merge()`
- `clone()`
- `extend()`
- JSON parsing with custom revivers
- URL query string parsers

## Tools

- **Server-Side Prototype Pollution Scanner (Burp Extension)**
- **DOM Invader (Burp Suite)**

## Instructions for usage:
1. Always test for prototype pollution safely first (e.g., by polluting a harmless property like `x-test-pollute=1`) and checking if it exists globally. Do not pollute common properties like `toString` or `valueOf` on production servers as it can cause a permanent Denial of Service (DoS) requiring a server restart.
2. If client-side, look for sinks using the browser's developer tools. Search the DOM for elements that evaluate code or inject HTML dynamically based on object properties.
3. If server-side (Node.js), try to identify the templating engine being used (e.g., Pug, Handlebars) and search for known gadget chains for that specific engine.

## Advanced Bypass Techniques & Payloads

- **Obfuscation**: Use encoding, chunking, and case variation to bypass signature-based detection.
- **Rate Limit Bypasses**: Rotate IPs via proxies, modify `X-Forwarded-For` headers, or append random parameters to the query string.

- **Author**: **Vivek Chanchal**
