{% from 'pages_macros.py' import get_all, get_one with context %}
from flask import Blueprint, redirect, render_template, request, url_for

{% if 'postgres' in cookiecutter.db_resource %}
from . import db
{% endif %}
from . import models

bp = Blueprint("pages", __name__)


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/about")
def about():
    return render_template("about.html")


@bp.get("/destinations")
def destinations():
    {{ get_all("Destination") }}
    return render_template("destinations.html", destinations=all_destinations)


@bp.get("/destination/<pk>")
def destination_detail(pk):
    {{ get_one("Destination") }}
    return render_template(
        "destination_detail.html",
        destination=destination,
        cruises={% if 'mongodb' in cookiecutter.db_resource %}models.Cruise.objects(destinations__in=[destination]){% else %}destination.cruises{% endif %},
    )


@bp.get("/cruise/<pk>")
def cruise_detail(pk: int):
    {{ get_one("Cruise") }}
    return render_template(
        "cruise_detail.html",
        cruise=cruise,
        destinations=cruise.destinations,
    )


@bp.get("/info_request")
def info_request():
    {{ get_all("Cruise") }}
    return render_template("info_request_create.html", cruises=all_cruises, message=request.args.get("message"))


@bp.post("/info_request")
def create_info_request():
    name = request.form["name"]
    db_info_request = models.InfoRequest(
        name=name,
        email=request.form["email"],
        notes=request.form["notes"],
        cruise=request.form["cruise_id"],
    )
    {% if 'postgres' in cookiecutter.db_resource %}
    db.session.add(db_info_request)
    db.session.commit()
    {% endif %}
    {% if 'mongodb' in cookiecutter.db_resource %}
    db_info_request.save()
    {% endif %}
    success_message = f"Thank you, {name}! We will email you when we have more information!"
    return redirect(url_for("pages.info_request", message=success_message))
