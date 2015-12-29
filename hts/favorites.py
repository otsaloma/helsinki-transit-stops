# -*- coding: utf-8 -*-

# Copyright (C) 2014 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""A collection of favorite stop groups and their metadata."""

import copy
import hts
import os
import threading
import time

__all__ = ("Favorites",)


class Favorites:

    """A collection of favorite stop groups and their metadata."""

    def __init__(self):
        """Initialize a :class:`Favorites` instance."""
        self._favorites = []
        self._path = os.path.join(hts.CONFIG_HOME_DIR, "favorites.json")
        self._read()

    def add(self, name):
        """Add `name` to the list of favorites and return key."""
        key = str(int(1000*time.time()))
        self._favorites.append(dict(key=key, name=name, stops=[]))
        self._update_meta(key)
        return key

    def add_stop(self, key, props):
        """Add stop to favorite matching `key`."""
        favorite = self.get(key)
        self.remove_stop(key, props["code"])
        favorite["stops"].append(dict(code=props["code"],
                                      name=props["name"],
                                      short_code=props["short_code"],
                                      type=props["type"],
                                      x=props["x"],
                                      y=props["y"]))

        self._update_meta(key)

    @property
    def favorites(self):
        """Return a list of favorite stop groups."""
        favorites = copy.deepcopy(self._favorites)
        favorites.sort(key=lambda x: x["name"])
        for favorite in favorites:
            favorite["color"] = hts.util.types_to_color(
                *[x["type"] for x in favorite["stops"]])
            favorite["lines_label"] = ", ".join(favorite.get("lines", []))
            favorite["stops"].sort(key=lambda x: x["name"])
        return favorites

    def find_departures(self, key):
        """Return a list of departures from favorite matching `key`."""
        favorite = self.get(key)
        return hts.query.find_departures(
            *[x["code"] for x in favorite["stops"]])

    def get(self, key):
        """Return favorite matching `key` or raise :exc:`LookupError`."""
        for favorite in self._favorites:
            if favorite["key"] == key:
                return favorite
        raise LookupError("Favorite {} not found"
                          .format(repr(key)))

    def get_color(self, key):
        """Return color of favorite matching `key`."""
        favorite = self.get(key)
        return hts.util.types_to_color(
            *[x["type"] for x in favorite["stops"]])

    def get_name(self, key):
        """Return name of favorite matching `key`."""
        favorite = self.get(key)
        return favorite["name"]

    def get_skip_lines(self, key):
        """Return a list of lines to not be displayed."""
        favorite = self.get(key)
        return copy.deepcopy(favorite.get("skip_lines", []))

    def get_stop_codes(self, key):
        """Return a list of stop codes of favorite matching `key`."""
        return [x["code"] for x in self.get_stops(key)]

    def get_stops(self, key):
        """Return a list of stops of favorite matching `key`."""
        favorite = self.get(key)
        stops = copy.deepcopy(favorite["stops"])
        for stop in stops:
            stop["color"] = hts.util.types_to_color(stop["type"])
        stops.sort(key=lambda x: x["name"])
        return stops

    def _read(self):
        """Read list of favorites from file."""
        if os.path.isfile(self._path):
            with hts.util.silent(Exception):
                self._favorites = hts.util.read_json(self._path)
        for favorite in self._favorites:
            # Stop grouping added in version 0.2.
            if not "stops" in favorite:
                favorite["stops"] = [dict(code=favorite.pop("code"),
                                          name=favorite["name"],
                                          short_code=None,
                                          type=favorite.pop("type"),
                                          x=favorite.pop("x"),
                                          y=favorite.pop("y"))]

        self._update_meta()

    def remove(self, key):
        """Remove favorite matching `key` from the list of favorites."""
        for i in list(reversed(range(len(self._favorites)))):
            if self._favorites[i]["key"] == key:
                self._favorites.pop(i)

    def remove_stop(self, key, code):
        """Remove `code` from stops of favorite `key`."""
        favorite = self.get(key)
        for i in list(reversed(range(len(favorite["stops"])))):
            if favorite["stops"][i]["code"] == code:
                favorite["stops"].pop(i)
        self._update_meta(key)

    def rename(self, key, name):
        """Give favorite matching `key` a new name."""
        favorite = self.get(key)
        favorite["name"] = name.strip()

    def set_skip_lines(self, key, skip):
        """Set list of lines to not be displayed."""
        favorite = self.get(key)
        favorite["skip_lines"] = list(skip)
        self._update_meta(key)

    def _update_coordinates(self):
        """Update mean coordinates of favorites."""
        for favorite in self._favorites:
            sumx = sumy = n = 0
            for stop in favorite["stops"]:
                with hts.util.silent(Exception):
                    sumx += stop["x"]
                    sumy += stop["y"]
                    n += 1
            favorite["x"] = (sumx/n if n > 0 else 0)
            favorite["y"] = (sumy/n if n > 0 else 0)

    def _update_lines(self, favorite):
        """Update list of lines using stops of `favorite`."""
        with hts.util.silent(Exception):
            codes = [x["code"] for x in favorite["stops"]]
            lines = [x["line"] for x in hts.query.find_lines(codes)]
            if "?" in lines:
                lines.remove("?")
            for line in favorite.get("skip_lines", []):
                with hts.util.silent(ValueError):
                    lines.remove(line)
            favorite["lines"] = lines

    def _update_meta(self, *keys):
        """Update metadata, forcing update of favorites matching `keys`."""
        for key in keys:
            # Force update by marking as old.
            favorite = self.get(key)
            favorite["updated"] = -1
        self._update_coordinates()
        for favorite in self._favorites:
            if time.time() - favorite.get("updated", -1) > 7*86400:
                favorite["updated"] = int(time.time())
                threading.Thread(target=self._update_lines,
                                 args=[favorite],
                                 daemon=True).start()

    def write(self):
        """Write list of favorites to file."""
        with hts.util.silent(Exception):
            hts.util.write_json(self._favorites, self._path)
