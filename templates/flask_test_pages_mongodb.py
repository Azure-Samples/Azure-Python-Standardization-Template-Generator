import pytest

from flaskapp import models


@pytest.fixture
def client(app_with_db):
    return app_with_db.test_client()


def test_index(client):
    response = client.get("/")

    assert response.status_code == 200
    assert b"Welcome to ReleCloud" in response.data


def test_about(client):
    response = client.get("/about")

    assert response.status_code == 200
    assert b"About ReleCloud" in response.data


def test_destinations(client):
    response = client.get("/destinations")

    assert response.status_code == 200
    assert b"Destinations" in response.data
    assert b"The Sun" in response.data


def test_destination_detail(client):
    sun = models.Destination.objects(name="The Sun").first()
    response = client.get(f"/destination/{sun.id}")

    assert response.status_code == 200
    assert b"The Sun" in response.data


def test_cruise_detail(client):
    sun_and_earth = models.Cruise.objects(name="The Sun and Earth").first()
    response = client.get(f"/cruise/{sun_and_earth.id}")

    assert response.status_code == 200
    assert b"The Sun and Earth" in response.data


def test_info_request(client):
    response = client.get("/info_request")

    assert response.status_code == 200
    assert b"Request Info" in response.data


def test_create_info_request(client):
    sun_and_earth = models.Cruise.objects(name="The Sun and Earth").first()
    response = client.post(
        "/info_request",
        data={
            "name": "Amanda Valdez",
            "email": "michellewatson@gmail.com",
            "notes": "Please send me more information.",
            "cruise_id": f"{sun_and_earth.id}",
        },
    )

    assert response.status_code == 302
    assert (
        response.headers["Location"]
        == "/info_request?message=Thank+you,+Amanda+Valdez!+We+will+email+you+when+we+have+more+information!"
    )

    info_request = models.InfoRequest.objects(name="Amanda Valdez").first()
    assert info_request.name == "Amanda Valdez"
    assert info_request.email == "michellewatson@gmail.com"
    assert info_request.notes == "Please send me more information."
    assert info_request.cruise == sun_and_earth
