# Service Security Notes

Detail the threat model and controls unique to this service. Align with global requirements from `../../platform/SECURITY.md`.

## Threat Model Snapshot
| Asset | Threat | Mitigation |
| --- | --- | --- |
| **Accessory Data** | Unauthorized access | Managed Identity for DB access (in Azure), Key-based in local emulator. |
| **API** | DDoS / Abuse | Container Apps scaling, API Gateway (future). |

## Controls Checklist
- **Authentication**: Public access for workshop/demo purposes.
- **Secrets Handling**: Environment variables for configuration. Managed Identity preferred for Azure resources.
- **Transport**: HTTPS enforced.

## Testing & Monitoring
- **Scans**: GitHub Advanced Security (dependency scanning).
- **Logs**: Structured logs with `traceparent` propagation.
