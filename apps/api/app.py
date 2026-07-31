import os
import time

from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

REQUESTS = Counter(
    "platform_api_requests_total", "HTTP requests handled by the platform API", ["method", "endpoint", "status"]
)
LATENCY = Histogram(
    "platform_api_request_duration_seconds", "HTTP request duration", ["endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)


def create_app():
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(service="platform-api", message="Platform Engineering Home Lab API")

    @app.get("/api/v1/status")
    def status():
        return jsonify(status="ok", version=os.getenv("APP_VERSION", "dev"), timestamp=int(time.time()))

    @app.get("/health/live")
    def live():
        return jsonify(status="alive")

    @app.get("/health/ready")
    def ready():
        # Add real PostgreSQL/Redis checks here once client libraries are enabled.
        return jsonify(status="ready", dependencies={"postgres": "configured", "redis": "configured"})

    @app.before_request
    def start_timer():
        from flask import g
        g.start_time = time.perf_counter()

    @app.after_request
    def record_metrics(response):
        from flask import g, request
        endpoint = request.url_rule.rule if request.url_rule else "unmatched"
        REQUESTS.labels(request.method, endpoint, str(response.status_code)).inc()
        LATENCY.labels(endpoint).observe(time.perf_counter() - g.start_time)
        return response

    return app


app = create_app()
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
