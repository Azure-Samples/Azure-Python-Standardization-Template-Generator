# Filing Issues

**TLDR: File an issue in this repo or one of the generated repos and trust our maintainers to ensure we're triaging them.**

When working with templated issues it's important to understand where the problem is originating. In most cases the error is from this repo. We're working to help users understand that and here are some **pending** actions we're taking to ensure that.

- Create GitHub Issue Template that makes it easier to check the boxes similar to the options in the cookiecutter.json
- Capture issues in projects and discussions with active moderation
- Create GitHub Actions that can transfer issues to the correct repo

# Troubleshooting

## non-Python Package dependencies

`Cookiecutter-relecloud` builds instances that include support for [DevContainers](https://containers.dev) and deployments via [Azure CLI](https://aka.ms/azure-cli) or [Azure Developer CLI](https://aka.ms/azd).

You will need to ensure all required products are installed and up to date.

### Installing Dev Containers (VS Code)

If using VS Code you can install Dev Containers using the Dev Containers Extension. You will need docker installed. Alternatively, you can develop inside of a [GitHub Codespaces](https://github.com/features/codespaces) Instance.

### Installing Azure CLI and Updating the Bicep Template

To install the Azure CLI, follow the instructions that best fit your platform at <https://aka.ms/azure-cli>

Azure CLI includes the Bicep CLI you can ensure that it is up to date using the command:

```shell
az bicep upgrade
```

### Install Azure Developer CLI (AZD)

To install the Azure Developer CLI, follow the instructions that best fit your platform at <https://aka.ms/azd>.

You can ensure that it is up to date using the command:

```shell
curl -fsSL https://aka.ms/install-azd.sh | bash
```

## Testing

### Creating Tests

We have two sets of tests:

1. Generation tests - Tests that verify project generation is accurate
2. Application tests - Tests that are created by cookiecutter that are ran by the generated project

Both sets of tests are created using [Pytest](https://pytest.org).

### Generation tests

The generation tests are located at `/tests/`

Generation tests use [pytest-cookies](https://github.com/hackebrot/pytest-cookies) to generate an iteration of each project and run a series of tests.

You'll need to include the fixture `bakery` in your new tests to ensure that the desired outcome is happening across all of the products.

```python
def tests_something_happened(bakery, context)
```

### Application tests

Application tests are in `{{cookiecutter.__src_folder_name}}/tests/`.

Application tests use [playwright](https://playwright.dev/python/) and [pytest-playwright](https://github.com/microsoft/playwright-pytest). If you're testing the generated projects, you'll need to have `playwright` installed with dependencies.

```sh
playwright install chromium --with-deps
```

### Running Tests

Our goal is to ensure that the template is always up to date with the latest versions of the tools we use. Tests are run using [GitHub Actions](https://github.com/kjaymiller/cookiecutter-relecloud/actions). You should also run the tests locally before submitting a PR.

There are plenty of tests our repo. The majority of tests are focused on testing deployment scendarios. These cannot be tested without creating a subprocess. These tests are relatively slow and should not be ran on every commit. Instead, they are ran when a PR is submitted.

## Adding a New Framework

If you would like to add a new framework there are a few things that you need to consider.

- What database technologies is the framework compatible with?
- What deployment technologies is the framework compatible with?
- How do you test the framework?
- What are the best practices for the framework?
- What are the best practices for the framework on Azure?

### Database Technology Support

We currently support the following database technologies:
    - PostgreSQL
    - MongoDB

Your framework should be compatible with at least one of these technologies. If it is not, you will need to add support for the technology to the framework.

## Adding a New Database

## Post Build Work

### Linting Files

Generating files often have issues with whitespace among other things. To ensure that our generated code is a clean as possible, we run a linter on the generated files. You can add your linter function in `{{cookiecutter.__src_folder_name}}/hooks/linters.py`. If you are trying to add a linting function, be sure to call it in the `lint()` function.

```python
# {{cookiecutter.__src_folder_name}}/hooks/linters.py

def my_new_linter() -> None:
    """Linting function for file type"""
    # Do something

... # Other linters

def lint() -> None:
    ... # other linters
    my_new_linter()
```

```python
```

### Removing Unused Files

If you are adding functionality that requires specific files for that resource to work, you will need to add a post build step to remove the files that are not needed if that resource is not selected.

You can add your removal function in `{{cookiecutter.__src_folder_name}}/hooks/removers.py` and add a check for it in the `check for files()` function.

```python

## Testing Frameworks and Databases
In our `tests/conftest.py` we have a fixture style we refer to as `bakery`. These session fixtures are used to generate a project and run tests against it.

You'll need to create a new bakery for your scenario (if one does not already exist). You can do this by adding a new fixture to the `conftest.py` file.

```python
@pytest.fixture(
        scope="module",
        params=[*CONTEXT_OVERRIDE(["<ALL>","<RELEVANT>","<FRAMEWORKS"], ["<ALL>","<RELEVANT>","<DATABASES>"])],
)
def new_bakery(
    request,
    scope="module",
    default_context,
    cookies_session,
):
    """Validates settings and options for Flask Deployments"""
    extra_context = {**default_context, **request.param}
    result = cookies_session.bake(extra_context=extra_context)
    yield result
