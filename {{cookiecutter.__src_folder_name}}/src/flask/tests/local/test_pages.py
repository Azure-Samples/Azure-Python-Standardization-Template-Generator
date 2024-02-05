import pytest

{% if "postgres" in cookiecutter.db_resource %}
from flaskapp import db, models
from sqlalchemy import select
{% endif %}
{% if "mongodb" in cookiecutter.db_resourec %}
from flaskapp import models
{% endif %}


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
    {% if "postgres" in cookiecutter.db_resource %}
    sun = select(models.Destination).where(models.Destination.name == "The Sun")
    {% endif %}
    {% if "mongodb" in cookiecutter.db_resource %}
    sun = models.Destination.objects(name="The Sun").first() 
    {% endif %}
    response = client.get(f"/destination/{sun.id}")

    assert response.status_code == 200
    assert b"The Sun" in response.data


def test_cruise_detail(client):
    {% if "postgres" in cookiecutter.db_resource %}
    sun_and_earth = select(models.Destination).where(models.Destination.name == "The Sun and Earth")
    {% endif %}
    {% if "mongodb" in cookiecutter.db_resource %}
    sun_and_earth = models.Destination.objects(name="The Sun and Earth").first() 
    {% endif %}
    response = client.get(f"/cruise/{sun_and_earth.id}")

    assert response.status_code == 200
    assert b"The Sun and Earth" in response.data


def test_info_request(client):
    {% if "postgres" in cookiecutter.db_resource %}
    sun_and_earth = select(models.Destination).where(models.Destination.name == "The Sun and Earth")
    {% endif %}
    {% if "mongodb" in cookiecutter.db_resource %}
    sun_and_earth = models.Destination.objects(name="The Sun and Earth").first() 
    {% endif %}
    response = client.get("/info_request")

    assert response.status_code == 200
    assert b"Request Info" in response.data


def test_create_info_request(app_with_db, client):
    {% if "postgres" in cookiecutter.db_resource %}
    sun_and_earth = select(models.Destination).where(models.Destination.name == "The Sun and Earth")
    {% endif %}
    {% if "mongodb" in cookiecutter.db_resource %}
    sun_and_earth = models.Destination.objects(name="The Sun and Earth").first() 
    {% endif %}
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

    with app_with_db.app_context():
        info_request = db.session.query(models.InfoRequest).order_by(models.InfoRequest.id.desc()).first()
        assert info_request.name == "Amanda Valdez"
        assert info_request.email == "michellewatson@gmail.com"
        assert info_request.notes == "Please send me more information."
        assert info_request.cruise_id == sun_and_earth
