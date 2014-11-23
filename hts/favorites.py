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
import time

__all__ = ("Favorites",)


class Favorites:

    """A collection of favorite stop groups and their metadata."""

    def __init__(self):
        """Initialize a :class:`Favorites` instance."""
        self._path = os.path.join(hts.CONFIG_HOME_DIR, "favorites.json")
        self._favorites = []
        self._read()

    def add(self, name):
        """Add `name` to the list of favorites and return key."""
        key = str(int(1000*time.time()))
        self._favorites.append(dict(key=key, name=name, stops=[]))
        return key

    def add_stop(self, key, props):
        """Add stop to given favorite."""
        favorite = self.get(key)
        self.remove_stop(key, props["code"])
        favorite["stops"].append(dict(code=props["code"],
                                      name=props["name"],
                                      short_code=props["short_code"],
                                      type=props["type"],
                                      x=props["x"],
                                      y=props["y"]))

    @property
    def favorites(self):
        """Return a list of favorites."""
        favorites = copy.deepcopy(self._favorites)
        favorites.sort(key=lambda x: x["name"])
        for favorite in favorites:
            types = [x["type"] for x in favorite["stops"]]
            favorite["color"] = hts.util.types_to_color(types)
            favorite["stops"].sort(key=lambda x: x["name"])
        return favorites

    def find_departures(self, key):
        """Return a list of departures from given favorite."""
        favorite = self.get(key)
        codes = [x["code"] for x in favorite["stops"]]
        return hts.query.find_departures(codes)

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
        types = [x["type"] for x in favorite["stops"]]
        return hts.util.types_to_color(types)

    def get_name(self, key):
        """Return name of favorite matching `key`."""
        favorite = self.get(key)
        return favorite["name"]

    def get_stops(self, key):
        """Return a list of stops of favorite matching `key`."""
        stops = self.get(key)["stops"]
        for stop in stops:
            stop["color"] = hts.util.type_to_color(stop["type"])
        stops.sort(key=lambda x: x["name"])
        return stops

    def _read(self):
        """Read list of favorites from file."""
        if os.path.isfile(self._path):
            with hts.util.silent(Exception):
                self._favorites = hts.util.read_json(self._path)
        # Favorite format changed in version 0.2.
        for favorite in self._favorites:
            if not "stops" in favorite:
                favorite["stops"] = [dict(code=favorite["code"],
                                          name=favorite["name"],
                                          short_code=None,
                                          type=favorite["type"],
                                          x=favorite["x"],
                                          y=favorite["y"])]

                favorite.pop("code")
                favorite.pop("type")
                favorite.pop("x")
                favorite.pop("y")

    def remove(self, key):
        """Remove `key` from the list of favorites."""
        for i in list(reversed(range(len(self._favorites)))):
            if self._favorites[i]["key"] == key:
                self._favorites.pop(i)

    def remove_stop(self, key, code):
        """Remove `code` from stops of favorite `key`."""
        favorite = self.get(key)
        for i in list(reversed(range(len(favorite["stops"])))):
            if favorite["stops"][i]["code"] == code:
                favorite["stops"].pop(i)

    def rename(self, key, name):
        """Give an existing favorite a new name."""
        favorite = self.get(key)
        favorite["name"] = name.strip()

    def write(self):
        """Write list of favorites to file."""
        with hts.util.silent(Exception):
            hts.util.write_json(self._favorites, self._path)
