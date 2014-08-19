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

"""Miscellaneous helper functions."""

import contextlib
import math
import os
import sys


def calculate_bearing(x1, y1, x2, y2):
    """Calculate bearing in degrees from point 1 to point 2."""
    # This is the initial bearing on the great-circle path.
    # http://www.movable-type.co.uk/scripts/latlong.html
    x1, y1, x2, y2 = map(math.radians, (x1, y1, x2, y2))
    x = (math.cos(y1) * math.sin(y2) -
         math.sin(y1) * math.cos(y2) * math.cos(x2-x1))

    y = math.sin(x2-x1) * math.cos(y2)
    bearing = math.degrees(math.atan2(y, x))
    return (bearing + 360) % 360

def calculate_distance(x1, y1, x2, y2):
    """Calculate distance in meters from point 1 to point 2."""
    # Using the haversine formula.
    # http://www.movable-type.co.uk/scripts/latlong.html
    x1, y1, x2, y2 = map(math.radians, (x1, y1, x2, y2))
    a = (math.sin((y2-y1)/2)**2 + math.sin((x2-x1)/2)**2 *
         math.cos(y1) * math.cos(y2))

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return 6371000 * c

def format_bearing(bearing):
    """Format `bearing` to a human readable string."""
    bearing = (bearing + 360) % 360
    bearing = int(round(bearing/45)*45)
    if bearing ==   0: return "north"
    if bearing ==  45: return "north-east"
    if bearing ==  90: return "east"
    if bearing == 135: return "south-east"
    if bearing == 180: return "south"
    if bearing == 225: return "south-west"
    if bearing == 270: return "west"
    if bearing == 315: return "north-west"
    if bearing == 360: return "north"
    raise ValueError("Unexpected bearing: {}"
                     .format(repr(bearing)))

def format_distance(distance, n=2, units="m"):
    """Format `distance` to `n` significant digits and unit label."""
    # XXX: We might need to support for non-SI units here.
    if units == "km" and abs(distance) < 1:
        return format_distance(distance*1000, n, "m")
    if units == "m" and abs(distance) > 1000:
        return format_distance(distance/1000, n, "km")
    ndigits = n - math.ceil(math.log10(abs(max(1, distance)) + 1/1000000))
    if units == "m":
        ndigits = min(0, ndigits)
    distance = round(distance, ndigits)
    fstring = "{{:.{:d}f}} {{}}".format(max(0, ndigits))
    return fstring.format(distance, units)

def makedirs(directory):
    """Create and return `directory` or raise :exc:`OSError`."""
    directory = os.path.abspath(directory)
    if os.path.isdir(directory):
        return directory
    try:
        os.makedirs(directory)
    except OSError as error:
        if os.path.isdir(directory):
            return directory
        print("Failed to create directory {}: {}"
              .format(repr(directory), str(error)),
              file=sys.stderr)
        raise # OSError
    return directory

@contextlib.contextmanager
def silent(*exceptions):
    """Try to execute body, ignoring `exceptions`."""
    try:
        yield
    except exceptions:
        pass
