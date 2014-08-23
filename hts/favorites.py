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

"""A collection of favorite stops and their metadata."""

import copy
import hts
import os

__all__ = ("Favorites",)


class Stop:

    """A transit stop and its metadata."""

    def __init__(self, **kwargs):
        """Initialize a :class:`Stop` instance."""
        self.code = None
        self.name = None
        self.type = None
        self.x = None
        self.y = None
        for name in set(kwargs) & set(dir(self)):
            setattr(self, name, kwargs[name])


class Favorites:

    """A collection of favorite stops and their metadata."""

    def __init__(self):
        """Initialize a :class:`Favorites` instance."""
        self._path = os.path.join(hts.CONFIG_HOME_DIR, "favorites.json")
        self._read()
        self._stops = []

    def add(self, code, name, type, x, y):
        """Add stop to the list of stops."""
        self.remove(code)
        stop = Stop(code=code, name=name, type=type, x=x, y=y)
        self._stops.append(stop)

    def has(self, code):
        """Return ``True`` if `code` is among stops."""
        for stop in self._stops:
            if stop.code == code:
                return True
        return False

    def _read(self):
        """Read list of favorites from file."""
        with hts.util.silent(Exception):
            self._stops = hts.util.read_json(self._path)

    def remove(self, code):
        """Remove stop from the list of stops."""
        for i in list(reversed(range(len(self._stops)))):
            if self._stops[i].code == code:
                self._stops.pop(i)

    @property
    def stops(self):
        """Return a list of stops."""
        stops = copy.deepcopy(self._stops)
        stops.sort(key=lambda x: x["name"])
        return stops

    def write(self):
        """Write list of favorites to file."""
        with hts.util.silent(Exception):
            hts.util.write_json(self._stops, self._path)
