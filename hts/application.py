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

"""Show departures from HSL public transportation stops."""

__all__ = ("Application",)

import hts


class Application:

    """Show departures from HSL public transportation stops."""

    def __init__(self):
        """Initialize an :class:`Application` instance."""
        self.favorites = hts.Favorites()
        self.history = hts.HistoryManager()

    def save(self):
        """Write configuration files."""
        self.favorites.write()
        self.history.write()
