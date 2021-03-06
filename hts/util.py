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
import copy
import functools
import hts
import json
import math
import os
import random
import shutil
import socket
import stat
import sys
import time
import traceback

from hts.i18n import _


def api_query(fallback):
    """Decorator for API requests with graceful error handling."""
    def outer_wrapper(function):
        @functools.wraps(function)
        def inner_wrapper(*args, **kwargs):
            try:
                # function can fail due to connection errors or errors
                # in parsing the received data. Notify the user of some
                # common errors by returning a dictionary with the error
                # message to be displayed. With unexpected errors, print
                # a traceback and return blank of correct type.
                return function(*args, **kwargs)
            except socket.timeout:
                return dict(error=True, message=_("Connection timed out"))
            except Exception:
                traceback.print_exc()
                return copy.deepcopy(fallback)
        return inner_wrapper
    return outer_wrapper

@contextlib.contextmanager
def atomic_open(path, mode="w", *args, **kwargs):
    """A context manager for atomically writing a file."""
    # This is a simplified version of atomic_open from gaupol.
    # https://github.com/otsaloma/gaupol/blob/master/aeidon/util.py
    path = os.path.realpath(path)
    suffix = random.randint(1, 10**9)
    temp_path = "{}.tmp{}".format(path, suffix)
    try:
        if os.path.isfile(path):
            # If the file exists, use the same permissions.
            # Note that all other file metadata, including
            # owner and group, is not preserved.
            with open(temp_path, "w") as f: pass
            st = os.stat(path)
            os.chmod(temp_path, stat.S_IMODE(st.st_mode))
        with open(temp_path, mode, *args, **kwargs) as f:
            yield f
            f.flush()
            os.fsync(f.fileno())
        try:
            # Requires Python 3.3 or later.
            # Can fail in the unlikely case that
            # paths are on different filesystems.
            os.replace(temp_path, path)
        except OSError:
            # Fall back on a non-atomic operation.
            shutil.move(temp_path, path)
    finally:
        with silent(Exception):
            os.remove(temp_path)

def calculate_distance(x1, y1, x2, y2):
    """Calculate distance in meters from point 1 to point 2."""
    # Using the haversine formula.
    # http://www.movable-type.co.uk/scripts/latlong.html
    x1, y1, x2, y2 = map(math.radians, (x1, y1, x2, y2))
    a = (math.sin((y2-y1)/2)**2 + math.sin((x2-x1)/2)**2 *
         math.cos(y1) * math.cos(y2))

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return 6371000 * c

def departure_time_to_color(dist, departure):
    """
    Return color to use for departure.

    `dist` should be straight-line distance to stop in meters and
    `departure` should be the Unix time of departure.
    """
    # Actual walking distance is usually between 1 and 1.414,
    # on average maybe around 1.2, times the straight-line distance.
    # We can bump that figure a bit to account for traffic lights etc.
    dist = 1.35 * dist
    min_left = (departure - time.time()) / 60
    # Use walking speeds from reittiopas.fi:
    # 70 m/min for normal and 100 m/min for fast speed.
    if min_left > 3 and dist /  70 <= min_left: return "#3890ff"
    if min_left > 1 and dist / 100 <= min_left: return "#fff444"
    return "#ff4744"

def format_departure_time(departure):
    """Format Unix time `departure` for display."""
    min_left = (departure - time.time()) / 60
    if min_left < -1.5:
        return ""
    # Use minutes if below defined threshold,
    # otherwise time as HH:MM.
    if min_left < max((0, hts.conf.departure_time_cutoff)):
        return "{:d} min".format(round(min_left))
    departure = time.localtime(departure)
    return "{:.0f}:{:02.0f}".format(departure.tm_hour,
                                    departure.tm_min)

def format_distance(meters, n=2):
    """Format `meters` to `n` significant digits and unit label."""
    if meters > 1000:
        distance = meters/1000
        units = "km"
    else:
        # Let's not use units less than a meter.
        distance = meters
        units = "m"
    ndigits = n - math.ceil(math.log10(abs(max(1, distance)) + 1/1000000))
    if units == "m":
        ndigits = min(0, ndigits)
    distance = round(distance, ndigits)
    fstring = "{{:.{:d}f}} {{}}".format(max(0, ndigits))
    return fstring.format(distance, units)

def locked_method(function):
    """
    Decorator for methods to be run thread-safe.

    Requires class to have an instance variable '_lock'.
    """
    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        with args[0]._lock:
            return function(*args, **kwargs)
    return wrapper

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
def silent(*exceptions, tb=False):
    """Try to execute body, ignoring `exceptions`."""
    try:
        yield
    except exceptions:
        if tb: traceback.print_exc()

def types_to_color(*types):
    """Return color based on vehicle `types`."""
    if "train" in types:
        return "#2dbe2c"
    if "metro" in types:
        return "#ff6319"
    if "ferry" in types:
        return "#00b9e4"
    if "tram" in types:
        return "#00985f"
    if "bus" in types:
        return "#007ac9"
    # types is allowed to be empty.
    return "#aaaaaa"

def write_json(data, path):
    """Write `data` to JSON file at `path`."""
    try:
        makedirs(os.path.dirname(path))
        with atomic_open(path, "w", encoding="utf_8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4, sort_keys=True)
    except Exception as error:
        print("Failed to write file {}: {}"
              .format(repr(path), str(error)),
              file=sys.stderr)
        raise # Exception
