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

__version__ = "0.4.1"

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!",
          file=sys.stderr)
    class pyotherside:
        def atexit(*args): pass
        def send(*args): pass
    sys.modules["pyotherside"] = pyotherside()

from hts.paths import *
from hts import util
from hts import http
from hts import query
from hts.favorites import *
from hts.history import *
from hts.application import *

def main():
    """Initialize application."""
    global app
    app = Application()
    pyotherside.atexit(app.save)
