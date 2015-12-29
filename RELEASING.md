Releasing a New Version
=======================

* Update translations
    - `make translations`
    - `virtaal translations/en.ts`
    - `virtaal translations/fi.ts`
    - XXX: lconvert fucks shit up, check manually:
    - `make translations`
    - `meld translations/helsinki-transit-stops.ts translations/fi.ts`
* Do final quality checks
    - `make check`
    - `make test`
* Bump version numbers
    - `hts/__init__.py`
    - `rpm/*.spec`
    - `Makefile`
* Update `NEWS.md` and `TODO.md`
* Build RPM
    - `make rpm`
* Check that RPM is Harbour-OK, installs and works
    - `rpm -qpil rpm/*.noarch.rpm`
    - `rpmvalidation.sh rpm/*.noarch.rpm`
    - `pkcon install-local rpm/*.noarch.rpm`
* Commit changes
    - `git commit -a -m "RELEASE X.Y.Z"`
    - `git tag -s X.Y.Z`
    - `git push`
    - `git push --tags`
* Build final RPM
    - `make rpm`
    - `pkcon install-local rpm/*.noarch.rpm`
* Add release notes on GitHub
* Upload and announce
