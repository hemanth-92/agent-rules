---
name: linux-sysadmin
description: Diagnose and operate Linux systems (Ubuntu, Debian, Fedora, Arch, and similar), including SSH, permissions, firewalls, packages, processes, logs, and systemd services. Use when asked to troubleshoot hosts, prepare commands, write runbooks, fix service failures, or reason about Linux administration.
---

# linux-sysadmin

## Workflow

1. Gather host, service, resource, network, and security diagnostics.
2. Determine impact and recent changes.
3. Create rollback for files, packages, service units, and firewall changes.
4. Implement the smallest fix.
5. Validate runtime behavior and boot persistence.

## Diagnostics

```bash
cat /etc/os-release
uname -a
uptime
free -h
df -h
lsblk
systemctl status <unit>
journalctl -xeu <unit>
ss -tulpn
# Optional security stacks when present:
command -v getenforce >/dev/null && getenforce
command -v firewall-cmd >/dev/null && firewall-cmd --list-all
command -v ufw >/dev/null && ufw status verbose
```

## Safety Rules

- Never disable SELinux/AppArmor as a default fix.
- Never rotate SSH keys or change `sshd_config` without rollback.
- Never modify firewall rules without confirming the active firewall stack.
- Prefer systemd drop-ins over editing packaged unit files.
- Preserve ownership, permissions, ACLs, mount options, and labels.

## Validation

- Service starts now and after reboot when applicable.
- Logs show no new errors.
- Expected ports listen and unexpected ports do not.
- SSH access still works when SSH was in scope.
- Firewall and mandatory-access-control state match the intended policy.
