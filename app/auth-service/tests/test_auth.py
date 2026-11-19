import os

os.environ["JWT_SECRET"] = "unit-test-secret-unit-test-secret-1234"
os.environ["DEMO_PASSWORD"] = "unit-test-password"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

c = TestClient(app)


def test_health():
    assert c.get("/health/live").status_code == 200
    assert c.get("/health/startup").status_code == 200


def test_login_and_verify():
    r = c.post("/login", json={"username": "demo", "password": "unit-test-password"})
    assert r.status_code == 200
    t = r.json()["token"]
    assert c.get("/verify", headers={"Authorization": f"Bearer {t}"}).json()["sub"] == "demo"


def test_bad_password():
    assert c.post("/login", json={"username": "demo", "password": "x"}).status_code == 401
