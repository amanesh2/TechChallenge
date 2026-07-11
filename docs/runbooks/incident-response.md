# Incident Response Runbook

## Scope

Operational triage for Quote of the Day platform incidents.

## Ownership

Single-operator demo environment. Primary responder and escalator: repository owner.

## Severity Model

1. Sev 1: Full outage or persistent `GET /health` failure.
2. Sev 2: Elevated 5xx or SQL connectivity instability.
3. Sev 3: Degraded latency, transient spikes, non-critical control degradation.

## Initial Triage Checklist

1. Confirm current deployment status in GitHub Actions.
2. Check Front Door origin health.
3. Check App Service `GET /health` and `GET /health/ready`.
4. Review Azure Monitor alerts in last 30 minutes.
5. Determine whether rollback (slot swap back) is the fastest mitigation.

## KQL Queries

### 1. App 5xx spike

```kusto
requests
| where timestamp > ago(30m)
| summarize count() by resultCode, bin(timestamp, 5m)
| where resultCode startswith "5"
| order by timestamp desc
```

### 2. SQL dependency failures

```kusto
dependencies
| where timestamp > ago(30m)
| where type == "SQL"
| summarize failures = countif(success == false), total = count() by bin(timestamp, 5m)
| order by timestamp desc
```

### 3. WAF block flood

```kusto
AzureDiagnostics
| where TimeGenerated > ago(30m)
| where Category == "FrontDoorWebApplicationFirewallLog"
| summarize blocks = count() by clientIP_s, bin(TimeGenerated, 5m)
| top 20 by blocks desc
```

### 4. Readiness failures

```kusto
requests
| where timestamp > ago(30m)
| where url endswith "/health/ready"
| summarize failures = countif(success == false), total = count() by bin(timestamp, 5m)
| order by timestamp desc
```

### 5. Unauthorized Key Vault access events

```kusto
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where Category == "AuditEvent"
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where ResultType != "Success"
| project TimeGenerated, OperationName, ResultType, CallerIPAddress, identity_claim_appid_g
| order by TimeGenerated desc
```

## Containment Actions

1. Swap App Service staging and production slots if latest deploy caused regression.
2. Temporarily disable traffic to unhealthy origin from Front Door route if needed.
3. If SQL is unavailable, run failover drill script and verify retry behavior.

## Resolution and Follow-up

1. Record root cause summary.
2. Capture telemetry screenshots and query output.
3. Create a backlog item for preventive remediation.
4. Update architecture docs if trade-off assumptions changed.
