from app import create_app


def test_status_is_healthy():
    response = create_app().test_client().get("/api/v1/status")
    assert response.status_code == 200
    assert response.json["status"] == "ok"


def test_readiness_endpoint():
    response = create_app().test_client().get("/health/ready")
    assert response.status_code == 200
    assert response.json["status"] == "ready"
