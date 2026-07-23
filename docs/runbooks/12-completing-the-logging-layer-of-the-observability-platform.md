Introduction

Following the successful deployment of the Kubernetes monitoring stack consisting of Prometheus, Grafana, Alertmanager, and Promtail, the next phase of the project focused on completing the centralized logging solution.

Although the monitoring stack was already capable of collecting and visualizing metrics, it lacked centralized log aggregation. To achieve a complete observability platform, Loki was introduced as the log aggregation system, while Promtail served as the log collector responsible for forwarding logs from Kubernetes nodes into Loki. Grafana would then provide a single interface for visualizing both metrics and logs.

This implementation was deployed using the existing GitOps workflow managed by ArgoCD, ensuring that all infrastructure and application changes remained version-controlled and reproducible.

12.2 Objectives

The objectives of this implementation phase were:

Deploy Loki using Helm through ArgoCD.
Configure persistent storage for Loki.
Ensure Promtail successfully ships logs into Loki.
Integrate Loki with Grafana.
Validate end-to-end log ingestion.
Complete the logging layer of the observability platform.
12.3 Existing Platform

Prior to implementing Loki, the platform consisted of the following components.

Component	Status
Amazon EKS	Healthy
Terraform Infrastructure	Complete
ArgoCD	Healthy
Prometheus	Running
Alertmanager	Running
Grafana	Running
Promtail	Running
External Secrets	Running
AWS Secrets Manager	Configured
GP3 Persistent Storage	Operational

Grafana was already configured with two data sources:

Prometheus
Alertmanager

However, centralized logging had not yet been completed.

12.4 Loki Deployment

Loki was deployed using the official Helm chart and managed through ArgoCD.

The deployment followed the existing GitOps model where:

Configuration changes were committed to Git.
ArgoCD continuously monitored the repository.
Any changes detected were synchronized into the Kubernetes cluster.

Initially, the deployment appeared successful within ArgoCD, but Kubernetes resources failed to become healthy.

12.5 Problems Encountered

Several issues were encountered during deployment.

12.5.1 Loki Pod Remained Pending

The Loki pod failed to start.

Instead of entering the Running state, Kubernetes continuously reported the pod as:

Pending

This indicated that Kubernetes could not schedule the pod onto a worker node.

12.5.2 Persistent Volume Claim Was Not Bound

Inspection of the monitoring namespace revealed that the Persistent Volume Claim remained in the Pending state.

Since Loki stores log data on persistent storage, Kubernetes requires a bound volume before scheduling the StatefulSet.

Without storage, the pod could never start.

12.5.3 ArgoCD Application Never Became Healthy

Within ArgoCD, the Loki application remained in either:

Progressing
OutOfSync

The application never transitioned into a Healthy state.

12.5.4 Promtail Connection Errors

While Loki remained unavailable, Promtail continuously produced errors similar to:

connection refused

POST /loki/api/v1/push

Initially this appeared to be a Promtail problem.

Further investigation revealed that Promtail itself was functioning correctly.

The errors occurred simply because Loki was unavailable to receive log data.

12.6 Root Cause Analysis

After reviewing the Helm configuration, it became clear that the persistence configuration had been placed under the wrong section of the values file.

The configuration had originally been defined similarly to:

loki:
  persistence:

However, the deployed Helm chart was running Loki in Single Binary Mode.

In this deployment model, persistence must instead be configured under:

singleBinary:
  persistence:

Although the YAML syntax itself was valid, Helm ignored the configuration because it was defined under an unsupported hierarchy.

As a result:

no persistent storage was provisioned,
the Persistent Volume Claim remained pending,
the StatefulSet could not schedule,
Loki never started.
12.7 StatefulSet Immutability

After correcting the Helm values, ArgoCD attempted to synchronize the application.

However, Kubernetes rejected the update because StatefulSets do not allow certain fields to be modified after creation.

The storage specification is immutable.

This is an important characteristic of StatefulSets because changing storage definitions after deployment could compromise persistent data.

Since the storage configuration had changed, Kubernetes refused the update.

12.8 Resolution

To resolve the issue, the existing StatefulSet was deleted.

The corrected Helm values remained in Git.

Once ArgoCD synchronized the application again, Kubernetes created an entirely new StatefulSet using the corrected configuration.

This time:

the Persistent Volume Claim was created correctly,
AWS dynamically provisioned a GP3 persistent volume,
the PVC transitioned to Bound,
the Loki pod entered the Running state.

The deployment was successfully completed.

12.9 Deployment Validation

The deployment was validated using Kubernetes.

The following resources were inspected:

StatefulSet
Persistent Volume Claim
Pods

Successful validation confirmed:

StatefulSet Ready
PVC Bound
Loki Running

This demonstrated that persistent storage had been correctly attached and Loki was now operational.

12.10 Promtail Recovery

After Loki became operational, Promtail automatically resumed log shipping.

The previous connection refused errors disappeared without making any changes to Promtail itself.

This confirmed that the root cause had always been Loki availability rather than a Promtail configuration issue.

The log collection pipeline was now functioning correctly.

12.11 Grafana Integration

Although Loki was now running successfully, Grafana still displayed only two configured data sources:

Prometheus
Alertmanager

Loki was missing.

This highlighted an important architectural concept.

Deploying Loki into Kubernetes does not automatically configure Grafana.

Grafana requires an explicit datasource definition before it can communicate with Loki.

12.12 Configuring the Loki Datasource

The existing Grafana Helm values already enabled datasource discovery.

However, no datasource definition existed for Loki.

The following datasource was added to the Grafana Helm values.

grafana:
  additionalDataSources:
    - name: Loki
      type: loki
      access: proxy
      url: http://loki.monitoring.svc.cluster.local:3100
      editable: true
      isDefault: false

      jsonData:
        maxLines: 1000

This configuration allows Grafana to communicate directly with the Loki service running inside the Kubernetes cluster.

Managing the datasource through Helm ensures that the configuration remains version-controlled and automatically recreated whenever Grafana is redeployed.

12.13 GitOps Synchronization

After updating the Helm values, the changes were committed to Git.

ArgoCD detected that the monitoring application had become:

OutOfSync

A synchronization was performed.

During synchronization ArgoCD regenerated the Grafana datasource ConfigMap.

Once synchronization completed, the application returned to:

Synced

Healthy

This confirmed that the updated configuration had been successfully applied.

12.14 Verifying the Grafana Datasource

Following synchronization, Grafana displayed three configured data sources.

Prometheus
Alertmanager
Loki

The Loki datasource was selected and tested using the built-in Save & Test function.

Grafana returned:

Data source successfully connected.

This verified that:

Grafana could communicate with Loki.
Kubernetes networking was functioning correctly.
The datasource configuration was correct.
12.15 Verifying Log Ingestion

The next step involved validating that logs were actually being ingested.

Grafana Explore was opened and the Loki datasource selected.

An initial query using:

{}

returned an error.

The error indicated that newer versions of Loki require at least one non-empty label matcher.

Instead, queries such as:

{namespace=~".+"}

or

{namespace="monitoring"}

were used.

These queries successfully returned log entries.

12.16 Label Verification

The Grafana Label Browser displayed indexed labels including:

app
component
job
namespace

The presence of these labels confirmed that:

Promtail was successfully scraping logs.
Loki was indexing log metadata.
Grafana could query the Loki index.
The complete logging pipeline was operational.
12.17 Credentials and Administrative Access
Grafana
Port Forward
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

Access URL:

http://localhost:3000

Username:

admin

Retrieve username:

kubectl get secret grafana-secret -n monitoring -o jsonpath="{.data.username}" | base64 -d

Retrieve password:

kubectl get secret grafana-secret -n monitoring -o jsonpath="{.data.password}" | base64 -d

Current password used during implementation:

AdminAdmin
ArgoCD
Port Forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

Access URL:

https://localhost:8080

Username:

admin

Retrieve password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
12.18 Lessons Learned

Several important engineering lessons were learned during this implementation.

Helm values must match the exact chart schema.
StatefulSet storage definitions cannot be modified after deployment.
Persistent Volume Claims should always be verified before troubleshooting Pods.
Promtail connection failures are often symptoms of Loki availability rather than Promtail configuration errors.
Deploying an application into Kubernetes does not automatically integrate it with Grafana.
Managing Grafana datasources through GitOps provides a reproducible and version-controlled deployment model.
Validation should always include both infrastructure health and functional testing.
12.19 Current Platform Status

At the conclusion of this implementation phase, the observability platform successfully provides:

✅ Amazon EKS

✅ Terraform-managed infrastructure

✅ GitOps deployment with ArgoCD

✅ Prometheus metrics collection

✅ Alertmanager alert routing

✅ Loki centralized log aggregation

✅ Promtail log shipping

✅ Grafana visualization

✅ External Secrets integration

✅ AWS Secrets Manager integration

✅ GP3 persistent storage

The monitoring and logging layers are now fully operational.

12.20 Next Phase

With metrics and logging fully implemented, the next phase of the project will focus on enhancing observability through dashboards, alerting, and distributed tracing.

The planned activities include:

Importing production-ready Kubernetes dashboards into Grafana.
Creating custom dashboards for cluster health, node utilization, pod status, namespaces, and application logs.
Configuring Alertmanager to deliver notifications through Slack, Microsoft Teams, or email.
Deploying Grafana Tempo for distributed tracing.
Instrumenting applications using OpenTelemetry.
Correlating metrics, logs, and traces to provide complete end-to-end observability across the platform.

End of Chapter 12

This chapter documents the successful completion of the centralized logging layer and serves as the foundation for the next stage of the observability platform: dashboards, alerting, and distributed tracing.