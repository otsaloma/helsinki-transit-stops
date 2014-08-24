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
import json
import math
import os
import sys


def calculate_distance(x1, y1, x2, y2):
    """Calculate distance in meters from point 1 to point 2."""
    # Using the haversine formula.
    # http://www.movable-type.co.uk/scripts/latlong.html
    x1, y1, x2, y2 = map(math.radians, (x1, y1, x2, y2))
    a = (math.sin((y2-y1)/2)**2 + math.sin((x2-x1)/2)**2 *
         math.cos(y1) * math.cos(y2))

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return 6371000 * c

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
        print("Failed to create directory {}: {}"
              .format(repr(directory), str(error)),
              file=sys.stderr)
        raise # OSError
    return directory

def read_json(path):
    """Read data from JSON file at `path`."""
    try:
        with open(path, "r", encoding="utf_8") as f:
            return json.load(f)
    except Exception as error:
        print("Failed to read file {}: {}"
              .format(repr(path), str(error)),
              file=sys.stderr)
        raise # Exception

@contextlib.contextmanager
def silent(*exceptions):
    """Try to execute body, ignoring `exceptions`."""
    try:
        yield
    except exceptions:
        pass

def type_to_color(type):
    """Return color based on vehicle `type`."""
    if type == "train":
        return "#2DBE2C"
    if type == "metro":
        return "#FF6319"
    if type == "ferry":
        return "#00B9E4"
    if type == "tram":
        return "#00985F"
    if type == "bus":
        return "#007AC9"
    raise ValueError("Unrecognized type: {}"
                     .format(repr(type)))

def write_json(data, path):
    """Write `data` to JSON file at `path`."""
    try:
        makedirs(os.path.dirname(path))
        with open(path, "w", encoding="utf_8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4, sort_keys=True)
    except Exception as error:
        print("Failed to write file {}: {}"
              .format(repr(path), str(error)),
              file=sys.stderr)
        raise # Exception
