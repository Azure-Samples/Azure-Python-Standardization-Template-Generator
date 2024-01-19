import subprocess
import re

import rich
from rich.traceback import install

install()

def check_not_implemented() -> None:
    if 'mongodb' in "{{cookiecutter.db_resource}}"  and "{{cookiecutter.project_backend}}" in ('fastAPI', 'django'):
        raise NotImplementedError(
            "MongoDB is not yet supported for FastAPI or Django projects"
        )

    if "{{cookiecutter.project_host}}" == "appservice" and "{{cookiecutter.db_resource}}" == "mongodb":
        raise NotImplementedError(
            "MongoDB is not yet supported for App Service projects"
        )


def tests_bicep_is_installed():
    """Tests that bicep is installed"""

    bicep_check = subprocess.run(["az", "bicep", "version"], capture_output=True)



if __name__ == "__main__":
    check_not_implemented()
    tests_bicep_is_installed()
