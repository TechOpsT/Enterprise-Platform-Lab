import os
import time
import json
import logging
import uuid

from flask import Flask, jsonify, g, request
from prometheus_client import Counter, Histogram, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

REQUESTS = Counter(
    "platform_api_requests_total", "HTTP requests handled by the platform API", ["method", "endpoint", "status"]
)
LATENCY = Histogram(
    "platform_api_request_duration_seconds", "HTTP request duration", ["endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": int(time.time()),
            "level": record.levelname.lower(),
            "logger": record.name,
            "message": record.getMessage(),
        }
        for field in ("event", "method", "path", "status", "duration_ms", "request_id"):
            value = getattr(record, field, None)
            if value is not None:
                payload[field] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, separators=(",", ":"))


def configure_logging(app):
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())
    app.logger.handlers = [handler]
    app.logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())
    app.logger.propagate = False


def create_app():
    app = Flask(__name__)
    configure_logging(app)
    app.logger.info("api started", extra={"event": "application.start"})

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
        g.start_time = time.perf_counter()
        g.request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

    @app.after_request
    def record_metrics(response):
        endpoint = request.url_rule.rule if request.url_rule else "unmatched"
        duration = time.perf_counter() - g.start_time
        REQUESTS.labels(request.method, endpoint, str(response.status_code)).inc()
        LATENCY.labels(endpoint).observe(duration)
        response.headers["X-Request-ID"] = g.request_id
        app.logger.info(
            "request completed",
            extra={
                "event": "http.request",
                "method": request.method,
                "path": endpoint,
                "status": response.status_code,
                "duration_ms": round(duration * 1000, 2),
                "request_id": g.request_id,
            },
        )
        return response

    @app.errorhandler(Exception)
    def handle_unexpected_error(error):
        app.logger.exception(
            "unhandled request error",
            extra={"event": "http.error", "request_id": getattr(g, "request_id", None)},
        )
        return jsonify(status="error", message="internal server error"), 500

    return app


app = create_app()
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
