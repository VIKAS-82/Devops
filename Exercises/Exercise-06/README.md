# Exercise 06: Real-Time Operations Monitoring and Alerting

## 1. Title & Overview
- **Exercise Name:** Real-Time Operations Monitoring and Alerting (Quick-Commerce Delivery Platform)
- **Objective:** Design, deploy, and validate a full observability stack (Prometheus, Grafana, and Python instrumentation) for real-time tracking of operational logistics metrics (Total Deliveries, Pending Orders, On-the-Way Couriers, Average Delivery Duration), establishing automated alert rules and interactive dashboards.
- **Components:**
  1. **Python Instrumentation App:** `delivery_metrics.py` utilizing `prometheus_client` exposing metrics on port `8000`.
  2. **Prometheus Time-Series Engine:** Scrapes targets, evaluates metrics against PromQL expressions, and manages alert rules on port `9090`.
  3. **Grafana Visualization Server:** Connects to Prometheus as a primary datasource to render real-time dashboards on port `3000`.
  4. **Jenkinsfile Automation:** Declarative pipeline definition to build, test, and orchestrate the monitoring stack.

---

## 2. Screenshots & Evidence

### 1. Windows Terminal Interface & Command Execution Output
![Windows Terminal Interface and Output](terminal_screenshot.png)

### 2. Website Interface (Microsoft Edge on Windows)
![Website Interface](website_screenshot.png)

---

## 3. Implementation Details & File Manifest

### `delivery_monitoring/delivery_metrics.py`
```python
from prometheus_client import start_http_server, Summary, Gauge
import random
import time

# Metrics
total_deliveries = Gauge("total_deliveries", "Total number of deliveries")
pending_deliveries = Gauge("pending_deliveries", "Number of pending deliveries")
on_the_way_deliveries = Gauge("on_the_way_deliveries", "Number of deliveries on the way")
average_delivery_time = Summary("average_delivery_time", "Average delivery time in seconds")

def simulate_delivery():
    pending = random.randint(10, 20)
    on_the_way = random.randint(5, 20)
    delivered = random.randint(30, 70)
    avg_time = random.uniform(15, 45)

    total = pending + on_the_way + delivered
    total_deliveries.set(total)
    pending_deliveries.set(pending)
    on_the_way_deliveries.set(on_the_way)
    average_delivery_time.observe(avg_time)

if __name__ == "__main__":
    start_http_server(8000, addr="0.0.0.0")
    while True:
        simulate_delivery()
        time.sleep(1)
```

### `delivery_monitoring/prometheus.yml`
```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "delivery_service"
    static_configs:
      - targets: ["host.docker.internal:8000"]

rule_files:
  - /etc/prometheus/alert_rules.yml
```

### `delivery_monitoring/alert_rules.yml`
```yaml
groups:
  - name: delivery_alerts
    rules:
      - alert: HighPendingDeliveries
        expr: pending_deliveries > 10
        for: 15s
        labels:
          severity: warning
        annotations:
          summary: "High pending deliveries"
          description: "Pending deliveries are above 10 for the last 15 second."

      - alert: HighAverageDeliveryTime
        expr: (average_delivery_time_sum / average_delivery_time_count) > 30
        labels:
          severity: critical
        annotations:
          summary: "High average delivery time"
          description: "Average delivery time is above 30 seconds for the last 15 seconds."
```

---

## 4. Commands Executed & Terminal Output

### Step 1: Start Python Delivery Metrics App
```bash
python delivery_metrics.py
```
**Verification:**
```bash
curl http://localhost:8000/metrics
```
**Output:**
```text
# HELP total_deliveries Total number of deliveries
# TYPE total_deliveries gauge
total_deliveries 99.0
# HELP pending_deliveries Number of pending deliveries
# TYPE pending_deliveries gauge
pending_deliveries 20.0
# HELP on_the_way_deliveries Number of deliveries on the way
# TYPE on_the_way_deliveries gauge
on_the_way_deliveries 15.0
```

### Step 2: Run Prometheus Container
```bash
docker run -d --name prometheus -p 9090:9090 \
  -v ${PWD}/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v ${PWD}/alert_rules.yml:/etc/prometheus/alert_rules.yml \
  prom/prometheus
```
**Verification:**
```bash
curl http://localhost:9090/-/healthy
# Output: Prometheus Server is Healthy.

curl http://localhost:9090/api/v1/targets
# Output confirms target "delivery_service" at "http://host.docker.internal:8000/metrics" with health "up".
```

### Step 3: Run Grafana Container & Configure Data Source
```bash
docker run -d --name grafana -p 3000:3000 grafana/grafana
```
**Add Prometheus Datasource via Grafana API:**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"name":"Prometheus","type":"prometheus","url":"http://host.docker.internal:9090","access":"proxy","isDefault":true}' \
  http://admin:admin@localhost:3000/api/datasources
```
**Output:**
```json
{"id":1,"message":"Datasource added","name":"Prometheus"}
```

### Step 4: Verify Live Alert Rules Firing
```bash
curl http://localhost:9090/api/v1/rules
```
**Output:**
- `HighPendingDeliveries`: state `pending` (value `18`, threshold `> 10`).
- `HighAverageDeliveryTime`: state `firing` (value `30.76`, threshold `> 30`).

---

## 5. Summary & Learning Outcomes
Exercise 06 successfully integrated an end-to-end cloud monitoring solution:
- Custom Python metrics exposure with `Gauge` and `Summary` types.
- Robust Prometheus time-series metric aggregation and rule evaluation.
- Real-time incident detection via alert rules.
- Operational visualization through Grafana's connected analytics dashboard.
