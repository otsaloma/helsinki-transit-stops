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

import gettext
import hts
import locale


class Application:

    """Show departures from HSL public transportation stops."""

    def __init__(self):
        """Initialize an :class:`Application` instance."""
        self.favorites = hts.Favorites()
        self.history = hts.HistoryManager()
        self._init_gettext()

    def _init_gettext(self):
        """Initialize translation settings."""
        with hts.util.silent(Exception):
            # Might fail with misconfigured locales.
            locale.setlocale(locale.LC_ALL, "")
        d = hts.LOCALE_DIR
        with hts.util.silent(Exception):
            # Not available on all platforms.
            locale.bindtextdomain("hts", d)
            locale.textdomain("hts")
        gettext.bindtextdomain("hts", d)
        gettext.textdomain("hts")

    def quit(self):
        """Quit the application."""
        hts.http.pool.terminate()
        self.save()

    def save(self):
        """Write configuration files."""
        hts.conf.write()
        self.favorites.write()
        self.history.write()
