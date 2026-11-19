import hmac
import os
import time
from pathlib import Path

import jwt
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

app = FastAPI(title="auth-service", docs_url=None, redoc_url=None)


def _read(file_env: str, plain_env: str):
    """Prefer secret mounted from Key Vault (CSI) as a file; fall back to env for tests."""
    p = os.getenv(file_env)
    if p and Path(p).exists():
        return Path(p).read_text().strip()
    return os.getenv(plain_env)


class Login(BaseModel):
    username: str
    password: str


@app.get("/health/startup")
def startup():
    # Fails until the Key Vault secret is mounted -> startupProbe protects slow secret mounts
    if not _read("JWT_SECRET_FILE", "JWT_SECRET"):
        raise HTTPException(status_code=503, detail="secret not available")
    return {"status": "started"}


@app.get("/health/live")
def live():
    return {"status": "alive"}


@app.get("/health/ready")
def ready():
    return startup()


@app.post("/login")
def login(body: Login):
    pw = _read("DEMO_PASSWORD_FILE", "DEMO_PASSWORD")
    secret = _read("JWT_SECRET_FILE", "JWT_SECRET")
    if not pw or not secret:
        raise HTTPException(status_code=503, detail="not configured")
    if body.username != "demo" or not hmac.compare_digest(body.password, pw):
        raise HTTPException(status_code=401, detail="invalid credentials")
    now = int(time.time())
    token = jwt.encode({"sub": body.username, "iat": now, "exp": now + 900}, secret, algorithm="HS256")
    return {"token": token}


@app.get("/verify")
def verify(authorization: str = Header(default="")):
    secret = _read("JWT_SECRET_FILE", "JWT_SECRET")
    if not authorization.startswith("Bearer ") or not secret:
        raise HTTPException(status_code=401, detail="missing token")
    try:
        claims = jwt.decode(authorization[7:], secret, algorithms=["HS256"])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="invalid token")
    return {"sub": claims["sub"]}
