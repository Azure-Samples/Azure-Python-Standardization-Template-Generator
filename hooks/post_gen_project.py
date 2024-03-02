import rich
import shutil
import os
import pathlib
import importlib.util
import logging
import subprocess

def move_db_files(db_resource: str):
    """
    Moves the correct db files to the correct location
    Delete the remaining files in the db folder and the db folder itself
    """

    if "postgres" in db_resource or "mysql" in db_resource:
        logging.debug("{{ cookiecutter.db_resource }} selected. Renaming {{ cookiecutter.db_resource }} files")
        shutil.move(
            "src/db/sql_db_models.py",
            "src/flask/flaskapp/models.py"
        )
        shutil.move(
            "src/db/sql_db_seeder.py",
            "src/flask/flaskapp/seeder.py",
        )
        if "postgres" in db_resource:
            shutil.move(
                ".github/workflows/test_postgres.yml",
                ".github/workflows/tests.yml"
            )
            pathlib.Path(".github/workflows/test_mysql.yml").unlink()
        if "mysql" in db_resource:
            shutil.move(
                ".github/workflows/test_mysql.yml",
                ".github/workflows/tests.yml"
            )
            pathlib.Path(".github/workflows/test_postgres.yml").unlink()
    else:
        pathlib.Path(".github/workflows/test_postgres.yml").unlink()
        pathlib.Path(".github/workflows/test_mysql.yml").unlink()

    if "mongo" in db_resource:
        logging.debug("MongoDB selected. Renaming MongoDB files")
        shutil.move(
            "src/db/mongo_models.py",
            "src/flask/flaskapp/models.py"
        )
        shutil.move(
            "src/db/mongo_seeder.py",
            "src/flask/flaskapp/seeder.py",
        )
        shutil.move(
            ".github/workflows/test_mongodb.yml",
            ".github/workflows/tests.yml"
        )
    else:
        pathlib.Path(".github/workflows/test_mongodb.yml").unlink()
def remove_aca_files() -> None:
    """Removes unneeded files if aca is not selected"""
    file_names = (
        "src/Dockerfile",
        "src/.dockerignore"
    )

    for file_name in file_names:
        os.remove(file_name)

def remove_flask_migration_files() -> None:
    """
    Removes the flask migration files if postgres or mysql is not selected
    This only applies to flask projects
    """
    if "{{ cookiecutter.project_backend }}" == "flask" and "mongo" in "{{cookiecutter.db_resource }}":
        shutil.rmtree("src/flask/flaskapp/migrations")
    else:
        pass

def rename_backend_files():
    """
    Rename the selected backend folder corresponding to the selected option.
    remove the project_backend folders that are not selected
    """

    selected_backend = "{{cookiecutter.project_backend}}"

    project_backends = ["django", "fastapi", "flask"]
    project_backends.remove(selected_backend)

    src = pathlib.Path('src')

    for unused_backend in project_backends:
        shutil.rmtree(src / pathlib.Path(unused_backend))

    shutil.copytree(
        src / pathlib.Path(selected_backend),
        pathlib.Path.cwd() / src,
        dirs_exist_ok=True,
    )
    shutil.rmtree(src / pathlib.Path(selected_backend))


def choose_web_bicep():
    """Selects the correct web.bicep file"""
    bicep_files = {
        "aca": "infra/aca.bicep",
        "appservice": "infra/appservice.bicep",
    }

    shutil.move(
        bicep_files.pop("{{cookiecutter.project_host}}"),
        "infra/web.bicep",
    )

    for file_name in bicep_files.values():
        os.remove(file_name)


def check_for_files() -> None:
    """
    Iterate through the cookiecutter options.
    remove the files corresponding to the results
    TODO: Add task progress
    """

    # DB Options
    # The chosen db option is stored in src.
    move_db_files("{{cookiecutter.db_resource}}")
    shutil.rmtree("src/db") # Clean up remaining db folder

    # Backend Options
    remove_flask_migration_files()

    # Azure Host Options
    choose_web_bicep()
    if "{{cookiecutter.project_host }}" != "aca":
        remove_aca_files()

    if "{{cookiecutter.project_host}}" == "appservice":
        pass


    rename_backend_files()


def error_msg(pkg: str) -> str:
    return f"`{pkg}` is not installed. Run `pip install {pkg}` to install it."

def run_ruff_lint_and_format() -> None:
    """checks if ruff are installed and runs it on the project"""
    if importlib.util.find_spec("ruff"):
        subprocess.run(["python3", "-m" "ruff", "check", "--fix", "src"])
        subprocess.run(["python3", "-m", "ruff", "format", "src"])
    else:
        logging.warning(error_msg("ruff"))

def run_bicep_format() -> None:
    """formats your bicep files"""
    subprocess.run(["az", "bicep", "format", "--file", "infra/main.bicep"])


def lint() -> None:
    """Runs all linters"""
    run_ruff_lint_and_format()
    run_bicep_format()

if __name__ == "__main__":
    rich.print("Removing unecessary files")
    check_for_files()
    rich.print("Linting and formatting files")
    lint()
