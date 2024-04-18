"""
This module tests the cookiecutter generation of the project.
This DOES NOT TEST AZURE DEPLOYMENT
"""
import re
import pytest
import pathlib
import subprocess


def test_project_generation(bakery):
    """Test that project is generated and fully rendered."""
    assert bakery.exit_code == 0
    assert bakery.exception is None


@pytest.mark.skip(reason="unable to check with caplog but tested in functional test - Issue: #77")
def test_project_post_hook_triggers_warning_if_linters_not_installed(
    cookies_session, default_context, mocker, caplog
    ):
    """If ruff is not installed, the post hook should trigger a warning"""

    mocker.patch("hooks.post_gen_project.importlib.util.find_spec", return_value=None)

    with caplog.at_level("WARNING"):
        cookies_session.bake(extra_context=default_context)



def test_bicep_assertion_working_path_referenced_in_bicep(bakery):
    """Ensures that the generated path name is same as referenced path in azure.yaml"""
    assert bakery.project_path.name == f"long_mixed_case_demo_name_{bakery.context['project_backend']}_{bakery.context['db_resource']}_{bakery.context['project_host']}".replace("-", "_")
    assert bakery.project_path.is_dir()


# FUTURE TESTS
# paths = build_files_list(str(result.project_path))
# assert paths
# check_paths(paths)


def test_all_cookiecutter_paths_generated(bakery):
    """Check for any cookiecutter variables that were not replaced"""
    for path in pathlib.Path(bakery.project_path).rglob("*_"):
        # This path is the only one that should have files
        if rel_path := (path.relative_to(bakery.project_path)) != "/static/res/img":
            matches = re.findall(r"\{\{\s*cookiecutter\.\w+\s*\}\}", path.read_text())
            if matches:
                pytest.fail(f"Found cookiecutter variable in {rel_path} - {matches}")


def test_build_folders_are_deleted(bakery, default_context):
    backend_names = default_context.get("project_backend")
    for path in bakery.project_path.iterdir():
        if path.is_dir():
            if path.name in backend_names:
                pytest.fail(f"Found build folder {path.name}")


def tests_valid_bicep(bakery):
    commands = (
        f"az bicep build --file {bakery.project_path}/infra/main.bicep".split(
            " "
        )
    )
    result = subprocess.run(commands, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr

@pytest.mark.skip(reason="not implmented yet")
def tests_mongo_builds_use_mongo_db_vars(bakery, default_context):
    if "mongodb" in default_context.get("db_resource"):
        # read the contents from the generated
        pass

    devcontainer = bakery.project_path / ".devcontainer" / "devcontainer.json"

    devcontainer_text = pathlib.Path(bakery.project_path / ".devcontainer" / "devcontainer.json").read_text()

    assert port in devcontainer_text
    assert port_label in devcontainer_text


    for check in port_checks:
        assert check in devcontainer.read_text()


def tests_migrations_file_deleted_when_not_using_postgres(bakery):
    """tests that the migrations folder is deleted when not using postgres"""""
    if "postgres" not in bakery.context.get("db_resource") and bakery.context.get("project_backend") == "flask":
        assert not (bakery.project_path / "src/flaskapp/migrations").exists()

    if "postgres" in bakery.context.get("db_resource") and bakery.context.get("project_backend") == "flask":
        assert (bakery.project_path / "src/flaskapp/migrations").exists()

def tests_abbreviations_are_replaced_in_readme(bakery):
    """Tests that abbreviations are replaced"""
    if bakery.context.get('project_backend') == 'flask':
        assert re.findall(r"Flask", (bakery.project_path / "README.md").read_text())

    if bakery.context.get('project_backend') == 'fastapi':
        assert re.findall(r"FastAPI", (bakery.project_path / "README.md").read_text())

    if bakery.context.get('project_backend') == 'django':
        assert re.findall(r"Django", (bakery.project_path / "README.md").read_text())

    if bakery.context.get('project_host') == 'aca':
        assert re.findall(r"Azure Container Apps", (bakery.project_path / "README.md").read_text())

    if bakery.context.get('project_host') == 'appservice':
        assert re.findall(r"Azure App Service", (bakery.project_path / "README.md").read_text())
