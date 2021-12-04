import pytest
from baseconv import base64
from fastapi.testclient import TestClient
from shortener.init_db import create_tables, drop_tables
from shortener.main import BASE_URL, app

client = TestClient(app)
url = "http://example.com/"
url_with_idn = "http://кц.рф/"
url_with_idn_punycode = "http://xn--j1ay.xn--p1ai/"


@pytest.fixture
def init_db():
    drop_tables()
    create_tables()


def test_create_short(init_db):  # pylint: disable=unused-argument,redefined-outer-name
    response = client.post("/", json={"url": url})
    assert response.status_code == 201
    data = response.json()
    assert data["url"] == f"{BASE_URL}/1"
    response = client.get("/1", allow_redirects=False)
    assert response.status_code == 307
    assert response.headers["location"] == url
    cached_response = client.get("/1", allow_redirects=False)
    assert cached_response.status_code == 307
    assert cached_response.headers["location"] == url

    custom_id = "2"
    response = client.post(
        "/", json={"url": url_with_idn, "custom_id": custom_id}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["url"] == f"{BASE_URL}/{custom_id}"
    response = client.get(f"/{custom_id}", allow_redirects=False)
    assert response.status_code == 307
    assert response.headers["location"] == url_with_idn_punycode

    response = client.post("/", json={"url": url})
    assert response.status_code == 201
    data = response.json()
    assert data["url"] == f"{BASE_URL}/3"


def test_create_custom_short_with_base64_digits(init_db):  # pylint: disable=unused-argument,redefined-outer-name
    first_part = base64.digits[:32]
    response = client.post("/", json={"url": url, "custom_id": first_part})
    assert response.status_code == 201
    data = response.json()
    assert data["url"] == f"{BASE_URL}/{first_part}"

    second_part = base64.digits[32:]
    response = client.post("/", json={"url": url, "custom_id": second_part})
    assert response.status_code == 201
    data = response.json()
    assert data["url"] == f"{BASE_URL}/{second_part}"


def test_errors_reading_creating_short(init_db):  # pylint: disable=unused-argument,redefined-outer-name
    non_existing_id = "non-exist"
    response = client.get(f"/{non_existing_id}", allow_redirects=False)
    assert response.status_code == 404

    invalid_url = "http:/invalid-url"
    response = client.post("/", json={"url": invalid_url})
    assert response.status_code == 422

    invalid_id = "="
    response = client.post("/", json={"url": url, "custom_id": invalid_id})
    assert response.status_code == 422

    longer_than_supported_id = 'a' * (50 + 1)
    response = client.post(
        "/", json={"url": invalid_url, "custom_id": longer_than_supported_id}
    )
    assert response.status_code == 422

    alredy_existing_id = non_existing_id = "someid"
    response = client.post(
        "/", json={"url": url, "custom_id": non_existing_id}
    )
    assert response.status_code == 201
    response = client.post(
        "/", json={"url": url, "custom_id": alredy_existing_id}
    )
    assert response.status_code == 409
