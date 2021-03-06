dev_venv := ".dev-venv"
python := dev_venv + "/bin/python"
pip := dev_venv + "/bin/pip"
black := dev_venv + "/bin/black"
bumpversion := dev_venv + "/bin/bumpversion"

# Serve the dev environment
serve: _check-docker-compose
    docker-compose up --force-recreate

# Stop and remove all containers
clear-containers: _check-docker-compose
    docker-compose rm --stop --force -v

_check-docker-compose:
    #!/usr/bin/env bash
    if ! [ -x "$(command -v docker-compose)" ]; then
        echo 'Install a Docker engine, probably at https://docs.docker.com/install/'
        exit 1
    fi

# Remove all build, test, coverage and Python artifacts
clean: clean-build clean-pyc clean-test

# Remove build artifacts
clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

# Remove Python file artifacts
clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

# Remove test and coverage artifacts
clean-test:
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

# Package and upload a release
release: create-dev-venv dist
	{{python}} -m twine upload dist/*

# Build source and wheel package
dist: create-dev-venv clean
	{{python}} setup.py sdist
	{{python}} setup.py bdist_wheel
	ls -l dist

# Install the package to the active Python's site-packages
install: create-dev-venv clean
	{{python}} setup.py install

# Format python code base with Black
format-black +opts='': create-dev-venv
    {{black}} . {{opts}}

# Create a dev venv if not exist
create-dev-venv:
    #!/usr/bin/env bash
    if ! [ -d "./{{dev_venv}}" ]
    then
        echo "Creating a new development virtual env: {{dev_venv}} ..."
        python -m venv {{dev_venv}}
        echo "Installing development librairies ..."
        {{pip}} install -r ./requirements_dev.txt
    fi

# Delete dev venv
cleanup-dev-venv:
    rm -rf {{dev_venv}}
    rm -rf .mypy_cache

# Delete dev venv then recreate it
update-dev-venv: cleanup-dev-venv create-dev-venv

# Part is either "major", "minor", or "patch"
bump-version part: create-dev-venv
    {{bumpversion}} {{part}}
