# Observability

## Overview

Observability is the ability to understand the internal state of a system by examining its outputs.

Modern cloud-native systems rely on observability to identify failures, performance bottlenecks, and reliability issues.

---

# Three Pillars of Observability

Metrics

Examples:

* CPU
* Memory
* Request Rate
* Latency

---

Logs

Examples:

* Application Logs
* Error Logs
* Audit Logs

---

Traces

Examples:

* Request Flow
* Service Dependencies
* Latency Breakdown

---

# Why Observability Matters

Without observability:

* Root cause analysis becomes difficult
* Downtime increases
* Troubleshooting takes longer

---

# Platform Architecture

Applications
↓
Metrics
↓
Prometheus

Applications
↓
Logs
↓
Loki

Applications
↓
Traces
↓
OpenTelemetry

---

# Golden Signals

Google SRE defines four primary signals:

* Latency
* Traffic
* Errors
* Saturation

Monitoring these provides visibility into service health.

---

# Interview Questions

Q: What are the three pillars of observability?

A:

Metrics, Logs, and Traces.

Q: Why is observability important?

A:

It provides visibility into distributed systems and improves troubleshooting capabilities.

---

# Concepts Learned

* Metrics
* Logs
* Traces
* Monitoring
* Telemetry
* SRE Practices
