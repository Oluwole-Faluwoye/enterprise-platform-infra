# Horizontal Pod Autoscaler (HPA)

## Overview

The Horizontal Pod Autoscaler automatically adjusts the number of running Pods based on resource utilization or custom metrics.

---

# Why Autoscaling Matters

Without HPA:

Traffic Spike
↓
Application Overloaded

With HPA:

Traffic Spike
↓
Additional Pods Created

---

# Example

Minimum Pods:

```text
2
```

Maximum Pods:

```text
10
```

CPU Target:

```text
70%
```

If CPU exceeds target:

Kubernetes creates additional Pods.

---

# HPA Workflow

Metrics Server
↓
CPU Metrics
↓
HPA Controller
↓
Scale Pods

---

# Example Command

```bash
kubectl get hpa
```

---

# Benefits

* Improved availability
* Better resource utilization
* Reduced operational effort

---

# Common Issues

* Metrics Server missing
* Incorrect resource requests
* Delayed scaling events

---

# Interview Questions

Q: What is HPA?

A:

A Kubernetes controller that automatically scales Pods based on resource utilization or custom metrics.

Q: What metrics can HPA use?

A:

CPU, memory, and custom application metrics.

---

# Concepts Learned

* Horizontal Scaling
* Kubernetes Autoscaling
* Metrics Server
* Resource Utilization
* Elasticity
