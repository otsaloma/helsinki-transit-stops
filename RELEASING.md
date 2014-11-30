Releasing a New Version
=======================

 * Do final quality checks
   - `pyflakes3 hts`
   - `py.test-3 hts`
 * Bump version numbers
   - hts/__init__.py
   - rpm/*.spec
   - Makefile
 * Update NEWS.md and TODO
 * Build tarball and RPM
   - `make dist`
   - `make rpm`
 * Install RPM and check that it works
   - `pkcon install-local rpm/*.noarch.rpm`
 * Commit changes
   - `git commit -a -m "RELEASE X.Y.Z"`
   - `git tag -s helsinki-transit-stops-X.Y.Z`
   - `git push`
   - `git push --tags`
 * Build final tarball and RPM
   - `make dist`
   - `make rpm`
   - `pkcon install-local rpm/*.noarch.rpm`
 * Upload and announce