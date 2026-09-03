from app import create_app
import json


def test_status_is_healthy():
    response = create_app().test_client().get("/api/v1/status")
    assert response.status_code == 200
    assert response.json["status"] == "ok"


def test_readiness_endpoint():
    response = create_app().test_client().get("/health/ready")
    assert response.status_code == 200
    assert response.json["status"] == "ready"


def test_request_id_is_returned_and_logged(capsys):
    app = create_app()
    capsys.readouterr()
    response = app.test_client().get("/api/v1/status", headers={"X-Request-ID": "test-request-123"})

    assert response.headers["X-Request-ID"] == "test-request-123"
    log_lines = [json.loads(line) for line in capsys.readouterr().err.splitlines()]
    request_record = next(record for record in log_lines if record.get("event") == "http.request")
    assert request_record["request_id"] == "test-request-123"
    assert request_record["status"] == 200


def test_json_formatter_outputs_machine_readable_event():
    from app import JsonFormatter
    import logging

    record = logging.LogRecord("platform", logging.INFO, __file__, 1, "ready", (), None)
    record.event = "application.ready"
    payload = json.loads(JsonFormatter().format(record))

    assert payload["level"] == "info"
    assert payload["event"] == "application.ready"
