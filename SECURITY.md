# Security

Report vulnerabilities privately through GitHub's private vulnerability reporting when enabled. Do not post credentials or private session data in public issues.

## Initial release limitations

- The app is ad-hoc signed, not Developer ID signed or Apple-notarized.
- Session titles and project paths are stored in local status files. Treat them as private data.
- The GUI navigation integration uses an experimental OpenCode Desktop event/API and supports the local sidecar only.
- On 2026-11-05, `npm audit --omit=dev` reported 24 moderate dependency findings in the `@opencode/plugin` dependency tree, including `glob` and `minimatch` denial-of-service advisories. No high or critical findings were reported. Some upstream findings have no compatible automatic fix. The status plugin does not itself use globbing or install packages; this is not a claim that the dependency findings are harmless. Review the current audit before deploying in sensitive environments.
