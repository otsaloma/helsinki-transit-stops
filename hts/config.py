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

"""Attribute dictionary of configuration values."""

import copy
import hts
import os

__all__ = ("ConfigurationStore",)

DEFAULTS = {
    "departure_time_cutoff": 10,
    "favorite_highlight_radius": 1000,
}


class AttrDict(dict):

    """Dictionary with attribute access to keys."""

    def __init__(self, *args, **kwargs):
        """Initialize an :class:`AttrDict` instance."""
        dict.__init__(self, *args, **kwargs)
        self.__dict__ = self


class ConfigurationStore(AttrDict):

    """Attribute dictionary of configuration values."""

    def __init__(self):
        """Initialize a :class:`ConfigurationStore` instance."""
        AttrDict.__init__(self, copy.deepcopy(DEFAULTS))

    def get(self, option):
        """Return the value of `option`."""
        return copy.deepcopy(self[option])

    def get_default(self, option):
        """Return the default value of `option`."""
        return copy.deepcopy(DEFAULTS[option])

    def read(self, path=None):
        """Read values of options from JSON file at `path`."""
        if path is None:
            path = os.path.join(hts.CONFIG_HOME_DIR, "helsinki-transit-stops.json")
        if not os.path.isfile(path): return
        values = {}
        with hts.util.silent(Exception):
            values = hts.util.read_json(path)
        for option, value in values.items():
            with hts.util.silent(Exception):
                self.set(option, value)

    def set(self, option, value):
        """Set the value of `option`."""
        if option in DEFAULTS:
            value = type(DEFAULTS[option])(value)
        self[option] = copy.deepcopy(value)

    def write(self, path=None):
        """Write values of options to JSON file at `path`."""
        if path is None:
            path = os.path.join(hts.CONFIG_HOME_DIR, "helsinki-transit-stops.json")
        out = dict((x, self.get(x)) for x in DEFAULTS)
        out["version"] = hts.__version__
        with hts.util.silent(Exception):
            hts.util.write_json(out, path)
