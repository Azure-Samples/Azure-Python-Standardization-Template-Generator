# Tools

## Force updating all the repos

There is a tool for force updating all the repositories or specified repos.

### To update all of the template repositories
From the main directory:

- Branch (`your_branch_name`) must be unique in the remote
- Title is the title of all the PRs, make this relevant (not "Updates")
- `Fork` is your username. You must have forked the repositories first

```console
$ python tools/update_info.py repos update --pr --source=. --branch=your_branch_name --title="example PR" --fork=myusername
```


### To update a specific repository
From the main directory:

- Branch (`your_branch_name`) must be unique in the remote
- Title is the title of all the PRs, make this relevant (not "Updates")
- `Fork` is your username. You must have forked the repositories first

```console
$ python tools/update_info.py repos update --pr --source=. --branch=your_branch_name --title="example PR" --fork=myusername <repository-to-be-updated-name>
```

To update a single repository, e.g. `azure-fastapi-postgres-flexible-appservice`:

```console
$ python tools/update_info.py repos update --pr --source=. --branch=your_branch_name --title="example PR" --fork=myusername azure-fastapi-postgres-flexible-appservice
```