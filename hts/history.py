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

"""Managing a history of search queries."""

import hts
import os
import sys

__all__ = ("HistoryManager",)


class HistoryManager:

    """Managing a history of search queries."""

    def __init__(self, max_size=1000):
        """Initialize a :class:`HistoryManager` instance."""
        self._max_size = max_size
        self._names = []
        self._path = os.path.join(hts.CONFIG_HOME_DIR, "history.json")
        self._read()

    def add(self, name):
        """Add `name` to the list of names."""
        name = name.strip()
        if not name: return
        self.remove(name)
        self._names.insert(0, name)

    @property
    def names(self):
        """Return a list of names."""
        return self._names[:]

    def _read(self):
        """Read list of names from file."""
        with hts.util.silent(Exception):
            self._names = hts.util.read_json(self._path)

    def remove(self, name):
        """Remove `name` from the list of names."""
        name = name.strip().lower()
        for i in list(reversed(range(len(self._names)))):
            if self._names[i].lower() == name:
                self._names.pop(i)

    def write(self):
        """Write list of names to file."""
        names = self._names[:self._max_size]
        with hts.util.silent(Exception):
            hts.util.write_json(names, self._path)
