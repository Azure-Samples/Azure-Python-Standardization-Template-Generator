from typing_extensions import Annotated
import cruft
import logging
import pathlib
import subprocess
import random
from typing import Generator
import typer
import re
import json
import itertools
from collections import defaultdict

# Typer CLI Info
app = typer.Typer()
info_app = typer.Typer()
app.add_typer(info_app, name="info")
repos_app = typer.Typer()
app.add_typer(repos_app, name="repos")

# Configure Logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
file_handler = logging.FileHandler("update_info.log")
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
# Add the file handler to the logger
logger.addHandler(file_handler)

with open("cookiecutter.json") as f:
    data = json.load(f)

db_resources = data["__prompts__"]["db_resource"].items()
web_frameworks = data["__prompts__"]["project_backend"].items()
deployment_hosts = data["__prompts__"]["project_host"].items()


combos = list(itertools.product(web_frameworks, db_resources, deployment_hosts))
random_cc_folder_prefix = "".join([str(chr(random.randint(65, 90))) for _ in range(20)])


def get_azure_combinations() -> Generator[tuple[str, str], None, None]:
    """
    Returns the base_keys and base_values for the combinations

    Yields:
        tuple[str, str]: The base_keys and base_values for the combinations
        Example: ("azure-flask-postgresql-azure-app-service", "Flask PostgreSQL Azure App Service")
    """
    for framework, db_resource, host in combos:
        base_keys = (
            (f"azure-{framework[0]}/{db_resource[0]}/{host[0]}")
            .lower()
            .replace("/", "-")
        )

        if re.findall("__prompt", base_keys):
            continue
        base_values = f"azure-{framework[0]}-{db_resource[0]}-{host[0]}"
        yield base_keys, base_values


@info_app.command(name='list_repos')
def metadata_list():
    """
    Creates a json file with the metadata for the combinations

    TODO: #302 Allow passing in a file to update_repos to iterate
    TODO: #303 Add a pattern that will allow for updating a subset of repos
    TODO: #304 Create a list of patterns to exclude
    """
    metadata_dict = defaultdict(list)

    for framework, db_resource, host in combos:
        base_keys = (
            (f"azure-{framework[0]}/{db_resource[0]}/{host[0]}")
            .lower()
            .replace("/", "-")
        )
        if re.findall("__prompt", base_keys):
            continue
        base_values = f"azure-{framework[0]}-{db_resource[0]}-{host[0]}"
        metadata_dict[framework[0]].append(base_values)

    with open("metadata.json", "w") as outfile:
        json.dump(metadata_dict, outfile, indent=4)

@info_app.command()
def update_readme():
    """Updates the README of cookiecutter-relecloud with the list of combinations"""
    web_framework_values = defaultdict(list)

    for framework, db_resource, host in combos:
        base_keys = (
            (f"azure-{framework[0]}/{db_resource[0]}/{host[0]}")
            .lower()
            .replace("/", "-")
        )
        if re.findall("__prompt", base_keys):
            continue
        base_values = f"{framework[1]} {db_resource[1]} {host[1]}"
        url = f"https://github.com/Azure-Samples/{base_keys}"
        md_link = re.sub(r"\[\w+\].*\[\/\w+\]", "", f"- [{base_values}]({url})")
        web_framework_values[framework[0]].append(md_link)

    for key, value in web_framework_values.items():
        print(f"### {key.title()}")
        print("----------")
        for item in value:
            print(item)
        print("\n")

    print(f"{len(list(combos))}: Total Combinations")

def create_base_folder(base_folder=None):
    """Creates the base folder for the repo"""
    if not base_folder:
        base_folder = random_cc_folder_prefix
    base_path = pathlib.Path(f"update_repos/{base_folder}")
    base_path.mkdir(parents=True, exist_ok=True)
    return base_path
    # TODO: Get repos by pattern


def get_repos_by_pattern(pattern:str, repos: list[str]=list(get_azure_combinations())) -> list[str]:
    """
    Returns a list of repos that match the provided pattern.
    TODO: #305 Add Test
    """
    pattern = re.compile(rf".*{pattern}.*")
    matching_repos = [repo[0] for repo in repos if pattern.match(repo[0])]
    return matching_repos

def update_repo(
        repo:str,
        source:str,
        path: pathlib.Path,
        force: bool=False,
        branch:str="cruft/update",
        checkout:str|None=None,
        submit_pr:bool=False,
        **kwargs) -> None:
    """
    Updates the repo with the provided name

    Parameters:
        repo (str): The name of the repo to update.
            It should be the same as seen on GitHub.
        path (pathlib.Path): The parent folder where the will be saved.
        branch (str): The name of the branch to create and push to.
            Defaults to cruft/update.
        checkout (str): The name of the branch to checkout from repo to update.
        **kwargs: Additional keyword arguments to pass to cruft.update as
    """
    # console = console.Console()
    per_file_formatter = logging.Formatter(f'%(asctime)s - {repo} - %(levelname)s - %(message)s')
    file_handler.setFormatter(per_file_formatter)
    url = f"git@github.com:Azure-Samples/{repo}.git"
    logger.info(f"Cloning {checkout} branch from GitHub from {url}")
    logger.info(f"Saving to {path}")
    path = path.joinpath(repo)

    try:
        if checkout is not None:
            subprocess.check_output(
                ["git", "clone", url],
                cwd=path.parent,
            )
        else:
            subprocess.check_output(
                ["git", "clone", url],
                cwd=path.parent,
            )

    except subprocess.CalledProcessError as e:
        logging.warning(f"Could not to clone {checkout} branch on {url}: {e}.\nThis is likely a non-existent repo or branch.")
        return None

    subprocess.check_output(
        ["git", "checkout", "-b", branch],
        text=True,
        cwd=path,
    )
    
    if force:
        with open(path.joinpath(".cruft.json"), "r") as f:
            extra_context=json.loads(f.read())["context"]["cookiecutter"]
            extra_context={ec_key:val for ec_key, val in extra_context.items() if not ec_key.startswith("_")}
        extra_context['__src_folder_name'] = repo 
        logger.info(f"{extra_context=}")
        logger.info(f"Removing cruft.json from {path}")
        path.joinpath(".cruft.json").unlink()
        logger.info(f"Linking {source} to {path}")
        cruft.create(
            source,
            output_dir=path.parent,
            extra_context=extra_context,
            no_input=True,
            overwrite_if_exists=True,
            checkout=checkout if checkout else None,
        )
        subprocess.check_output(
            ["git", "add", "."],
            text=True,
            cwd=path,
        )
        try:
            subprocess.check_output(
                ["git", "commit", "-m", "remove cruft.json"],
                text=True,
                cwd=path,
            )
        except subprocess.CalledProcessError as e:
            if f"On branch {branch}\nnothing to commit" not in e.stdout:
                raise e

    else:
        cruft.update(
            path,
            skip_apply_ask=True,
            extra_context=kwargs,
            checkout=checkout if checkout else None,
        )

    if subprocess.check_output(
        ["git", "status", "--porcelain"],
        text=True,
        cwd=path,
    ):
        logger.info(f"No changes for {path}, skipping.")
        return

    if rejection_files:=list(pathlib.Path(path).rglob("*.rej")):
        files_str = '\n- '.join([str(x) for x in rejection_files])
        logger.error(f"Rejection files found for {path}!\nFiles: {files_str}")
        return None

    logger.info(f"adding Changes and Creating a PR for {path}")

    if submit_pr:
        subprocess.check_output(
            ["git", "add", "."],
            text=True,
            cwd=path,
        )
        try:
            subprocess.check_output(
                ["git", "commit", "-m", "Cruft Update"],
                text=True,
                cwd=path,
            )
        except subprocess.CalledProcessError as e:
            if f"On branch {branch}\nnothing to commit" not in e.stdout:
                raise e

        logger.info(f"Pushing changes to {branch}")
        subprocess.check_output(
            ["git", "push", "--set-upstream", "origin", branch],
            text=True,
            cwd=path,
        )

        try:
            logger.info(f"Creating PR for {path}")
            subprocess.check_output(
                ["gh", "pr", "create", "--title", "Update from Cruft", "--body","update from cruft"],
                text=True,
                cwd=path,
            )
            subprocess.check_output(
                ["gh", "pr", "view", "--web"], 
                text=True,
                cwd=path,
            )
            

        except subprocess.CalledProcessError as e:
            logger.error(f"Could not create PR for {path}: {e}")
            pass

@repos_app.command(name="update")
def update_repos(
    pattern: Annotated[str, typer.Argument(
        help="The pattern to match repos to update.",
        show_default=False,
    )]="",
    branch: Annotated[str, typer.Option(
        "--branch",
        "-b",
        help="The branch to create and push to.",
    )]="cruft/update",
    checkout: Annotated[str, typer.Option(
        "--checkout",
        "-c",
        help="The branch to use for cruft updates `checkout` parameter.",
    )]=None,
    submit_pr: Annotated[bool, typer.Option("--pr", "-P")]=False,
    source: Annotated[str, typer.Option(
        "--source",
        "-s",
        help="The source to use for cruft updates `source` parameter. Setting this will change the .cruft.json file to use the provided source permanently.",
    )]=None,
    base_folder: Annotated[str, typer.Option("--base-folder")]=None,
) -> None:

    """Updates all repos that match the provided pattern or all of the repos if no pattern is provided."""
    logger.info(f"Request updates to repos matching \"{pattern}\" requested. Attrs: \n\t{branch=}\n\t{checkout=}")
    patterns = get_repos_by_pattern(pattern)
    patterns_str = '\n- '.join(patterns)
    logger.info(f"Found {len(patterns)} repos matching \"{pattern}\"\n- {patterns_str}")
    force = source is not None

    for repo in patterns:
        update_repo(
            repo=repo,
            path=create_base_folder(base_folder),
            branch=branch,
            checkout=checkout,
            submit_pr=submit_pr,
            source=source,
            force=force,
        )

if __name__ == "__main__":
    app()
