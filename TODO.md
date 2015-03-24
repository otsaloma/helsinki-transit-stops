Helsinki Transit Stops 0.4.1
============================

 * [X] Use QtPositioning 5.2 API instead of 5.0
 * [X] Don't install %doc files (COPYING, README, etc.)

Helsinki Transit Stops 1.0
==========================

 * Add user interface translations
   - Strings in QML: mark with `qsTr`, run `lupdate`
   - Strings in Python: mark with `tr`, run `pylupdate`?
     * `tr` being just syntax for the parser, i.e. `tr = lambda x: x`
     * Actually translate strings in QML using `qsTr`,
       e.g. `qsTr(py.call_sync(...))`
   - API calls: send `lang` parameter based on system default
   - In `Makefile`, compile translations to `$(datadir)/translations`,
   - Translate to Finnish self, use Transifex for rest?
 * Add disruption listing from Poikkeusinfo XML API?
