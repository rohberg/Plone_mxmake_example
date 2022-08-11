# Plone 6 backend installation from scratch

With add-on collective.easyform.\
plone.api and plone.restapi checked out from source.

See project settings: https://github.com/rohberg/Plone_mxmake_example/compare/initial-commit...working-instance-with-test-script


## Files

Plone packages

- mx.ini
- Makefile

Installation Add-ons

- requirements.txt
- constraints.txt

Zope configuration

- instance.yaml


## Installation

local Python:

```shell
python3.9 -m venv venv
source venv/bin/activate
pip install -U pip wheel mxdev
mxdev -c mx.ini
```

Install your Plone packages:

```shell
pip install -r requirements-mxdev.txt
```

Generate your Zope configuration with cookiecutter.
This is also necessary after changes of `instance.yaml`.

```shell
cookiecutter -f --no-input --config-file instance.yaml https://github.com/plone/cookiecutter-zope-instance
```

Run Zope:

```shell
runwsgi instance/etc/zope.ini
```
