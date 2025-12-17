# Frontend Service - Kubernetes Deployment

## Overview

The frontend service is a React application deployed to Kubernetes using Helm charts. It serves static assets via Nginx and follows production-grade best practices for security and scalability.

## Architecture

**Architecture**: Single-container deployment with Nginx serving static React build. Since the application uses Client-Side Rendering (CSR) rather than Server-Side Rendering (SSR), all rendering occurs in the browser, allowing Nginx to serve pre-built static assets without requiring a Node.js runtime or server-side processing.

## Key Features

- Non-root execution (UID 101 - nginx user)
- Resource limits for predictable performance
- Health probes for automatic recovery

## Resource Allocation

| Component        | CPU Request | CPU Limit | Memory Request | Memory Limit |
| ---------------- | ----------- | --------- | -------------- | ------------ |
| Frontend (Nginx) | 100m        | 500m      | 128Mi          | 256Mi        |

**QoS Class**: Burstable (requests ≠ limits) - provides flexibility with resource protection, allowing pods to burst beyond requests when capacity is available.

## Helm-Based Deployment

**Decision**: Everything is packaged and deployed using Helm charts

**Rationale**:

- **Unified Deployment**: All Kubernetes resources (Deployments, Services, ConfigMaps, Secrets, NetworkPolicies, HPA, PDB) are defined and managed through Helm charts, ensuring consistency across environments
- **Dependency Management**: External dependencies are managed as Helm chart dependencies, providing version control and automated installation
- **Environment-Specific Configuration**: Helm values files enable easy customization for different environments (dev, staging, production) without code duplication
- **Versioning & Rollback**: Helm tracks release versions, enabling easy rollback to previous configurations
- **Template Reusability**: Helm templates reduce duplication and ensure consistent resource definitions across components
- **CI/CD Integration**: Helm charts integrate seamlessly with CI/CD pipelines, enabling automated deployments
- **Infrastructure as Code**: All infrastructure configuration is version-controlled and declarative, following GitOps principles

## Deployment Strategy

**Strategy**: Rolling Update with `maxSurge: 1` and `maxUnavailable: 0`

**Benefits**:

- Zero-downtime deployments
- New pods are created before old ones are terminated
- One pod at a time ensures service stability
- Automatic rollback on failure

## Horizontal Pod Autoscaling

**Configuration**: HPA based on CPU (70%) and memory (80%) utilization

**Scaling Range**: 2-10 replicas

**Scaling Behavior**:

- **Scale Up**: Aggressive (2 pods per 60s) to handle traffic spikes
- **Scale Down**: Conservative (25% reduction per 60s) to prevent thrashing

**Trade-off**: Slower scale-down prevents premature pod termination but may result in over-provisioning during traffic drops.

## Health Checks

**Implementation**: Both liveness and readiness probes

- **Liveness Probe**: Detects deadlocked containers and triggers restart
- **Readiness Probe**: Ensures traffic only routes to healthy pods
- **Different Timings**: Readiness checks more frequently to respond quickly to health changes

## PodDisruptionBudget

**Configuration**: `minAvailable: 1` for stateless services

**Benefits**:

- Protects against node maintenance, cluster upgrades
- Ensures at least one pod remains available
- Maintains service continuity during voluntary disruptions

## Network Security

**Model**: Zero-trust networking with NetworkPolicies

**Frontend Policy**: Allows ingress from ingress controller, egress for DNS

**Benefits**:

- Limits lateral movement in case of compromise
- Reduces attack surface
- Enforces least-privilege network access

## Security Architecture

### Container Security Context

**Per-container hardening**:

- `runAsNonRoot: true` - Prevents privilege escalation
- `runAsUser: 101` - Runs as nginx user (non-root)
- `allowPrivilegeEscalation: false` - Blocks privilege escalation
- `capabilities.drop: ALL` - Removes all Linux capabilities
- `readOnlyRootFilesystem: true` - Prevents filesystem modifications (where applicable)

## Monitoring & Observability

**Stack**:

- **Metrics**: Prometheus + Grafana
- **Logging**: ELK Stack or Loki
- **Tracing**: Jaeger (via OpenTelemetry)

**Key Metrics to Monitor**:

- Pod CPU/Memory utilization
- Request latency (p50, p95, p99)
- Error rates
- HPA scaling events

## Logging Strategy

**Implementation**: Structured logging to stdout/stderr

## Deployment Commands

### Standard Rolling Deployment

1. Update image tag in Helm values
2. Deploy using Helm: `helm upgrade --install frontend ./helm -f values-prod.yaml`
3. Monitor rollout: `kubectl rollout status deployment/frontend`
4. Verify health: Check pod logs and metrics
5. Rollback if needed: `kubectl rollout undo deployment/frontend`

## Configuration Management

### ConfigMaps

Externalize all non-sensitive configuration in ConfigMaps:

- Environment-specific configuration without image rebuilds
- Version control of configuration
- Easy rollback of configuration changes

### Secrets

Store sensitive data like passwords separately in secrets. Kubernetes Secrets with base64 encoding used in CI/CD.

**Future Enhancement**: Integrate with AWS Secrets Manager or HashiCorp Vault

## Development

### Local Setup

Install dependencies:

```bash
npm install
```

Run the development server:

```bash
npm run dev
```

The app will be available at http://localhost:3000

### Build

Build for production:

```bash
npm run build
```

The built files will be in the `dist` directory.
