Helsinki Transit Stops 1.3
==========================

* Show distances to favorites on main page and highlight nearest ones

Helsinki Transit Stops 1.2
==========================

* Write config files atomically to avoid data loss in case of crash
* Add new application icon sizes for tablet and whatever else

Helsinki Transit Stops 1.1
==========================

* Allow all default orientations (all on a tablet and all except
  inverted portrait on a phone)

Helsinki Transit Stops 1.0.1
============================

* Fix error resetting HTTP connection
* Ensure that blocking HTTP connection pool operations terminate
  immediately and gracefully on application exit
* Write favorites and history to file only once on application exit

Helsinki Transit Stops 1.0
==========================

* Add Finnish user interface translation
* Make Reittiopas API calls in Finnish, Swedish or English
  depending on user's default language (English doesn't change much,
  but Swedish brings in Swedish names for stops and streets)

Helsinki Transit Stops 0.4.1
============================

* Use QtPositioning 5.2 API instead of 5.0
* Don't install %doc files (COPYING, README, etc.)
* Remove python3-base from RPM dependencies
* Prevent provides in RPM package

Helsinki Transit Stops 0.4
==========================

* Allow landscape in pages adding and editing favorites
* Change main menu layout to be simpler and more compact
* Fix cover display if no departures left
* Fix application icon rasterization

Helsinki Transit Stops 0.3
==========================

* Add line filters (accessible via pulldown menu, for favorite
  stops remembered across sessions)
* Add a proper, active cover

Helsinki Transit Stops 0.2
==========================

* Allow multiple stops to be grouped as one favorite
* Allow landscape only for keyboarded pages
* Show passed departures for one minute
* Fix display of stop numbers in search results
* Fix search field history list filtering to be faster and smoother
* Fix detection and coloring of tram stops

Helsinki Transit Stops 0.1
==========================

Initial release.
