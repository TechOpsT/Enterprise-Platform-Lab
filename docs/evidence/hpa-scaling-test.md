# HPA Scaling Test

**Date:** 2026-08-12  
**Cluster:** Kind `platform-lab`  
**Namespace:** `platform-lab`  
**Target workload:** `api` Deployment  
**Autoscaling policy:** Minimum 2 replicas, maximum 6 replicas, CPU target 70%.

## Objective

Verify that the Kubernetes Horizontal Pod Autoscaler scales the API deployment during increased CPU utilization and safely scales it back down after traffic stops.

## Test procedure

1. Confirmed Metrics Server was healthy with `kubectl top nodes`.
2. Confirmed the API HPA was configured with a 70% CPU target.
3. Started a restricted-policy-compliant load-generator pod in the `platform-lab` namespace.
4. Generated concurrent HTTP requests against:

   ```text
   http://api:8080/api/v1/status

5. Watched HPA behavior:

   ```powershell
   kubectl get hpa api -n platform-lab --watch

6. Observed request rate, p95 latency, and CPU usage in the Platform API Overview Grafana dashboard at:
http://localhost:3001

7. Stopped the test and confirmed automatic scale-down:
kubectl delete pod load-generator -n platform-lab
kubectl get hpa api -n platform-lab --watch