# OpenTelemetry

## Overview

OpenTelemetry is an open-source observability framework used to collect telemetry data from applications.

It provides:

* Metrics
* Logs
* Traces

through a standardized approach.

---

# Why OpenTelemetry Exists

Before OpenTelemetry:

Each monitoring vendor required different SDKs.

This created:

* Vendor lock-in
* Complex instrumentation
* Inconsistent telemetry collection

OpenTelemetry standardizes telemetry collection.

---

# Architecture

Application
↓
OpenTelemetry SDK
↓
OpenTelemetry Collector
↓
Backend Systems

Examples:

* Prometheus
* Grafana
* Jaeger
* Tempo

---

# Distributed Tracing

Example:

User Login Request

Frontend
↓
Auth Service
↓
User Service
↓
Database

OpenTelemetry tracks the entire request path.

---

# Benefits

* Vendor neutral
* Standardized instrumentation
* Distributed tracing
* Better troubleshooting

---

# Interview Questions

Q: What is OpenTelemetry?

A:

An open-source observability framework used to collect metrics, logs, and traces from applications.

Q: What problem does distributed tracing solve?

A:

It allows engineers to trace requests across multiple services and identify bottlenecks.

---

# Concepts Learned

* Telemetry
* Instrumentation
* Distributed Tracing
* OpenTelemetry Collector
* Service Dependencies
