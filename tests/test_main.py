import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_healthz():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


@pytest.mark.parametrize(
    "payload, expected_output",
    [
        ([1, 2, 3, 4, 5], "3"),
        ([1.5, 3, 1, 7, 4.2], "3.34"),
        ([10], "10"),
        ([0, 0, 0], "0"),
        ([-5, 5], "0"),
    ],
)
def test_mean_success(payload, expected_output):
    response = client.post("/mean", json=payload)
    assert response.status_code == 200
    assert response.text == expected_output


@pytest.mark.parametrize(
    "payload, expected_output",
    [
        ([1, 2, 3, 4, 5], "1.414"),
        ([1.5, 3, 1, 7, 4.2], "2.15"),
        ([10], "0"),
        ([2, 2, 2, 2], "0"),
        ([-2, 2], "2"),
    ],
)
def test_stddev_success(payload, expected_output):
    response = client.post("/stddev", json=payload)
    assert response.status_code == 200
    assert response.text == expected_output


def test_empty_payload_rejection():
    mean_resp = client.post("/mean", json=[])
    assert mean_resp.status_code == 400

    stddev_resp = client.post("/stddev", json=[])
    assert stddev_resp.status_code == 400


def test_invalid_type_rejection():
    response = client.post("/mean", json=["not", "a", "number"])
    assert response.status_code == 422