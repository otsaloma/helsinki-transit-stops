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

"""
Query stops and departures from the HSL Journey Planner API.

http://developer.reittiopas.fi/pages/en/http-get-interface-version-2.php
"""

import copy
import datetime
import functools
import hts
import locale
import math
import re
import socket
import traceback
import urllib.parse

from hts.i18n import _


def get_default_language():
    """Return the system default language code."""
    language = locale.getdefaultlocale()[0] or ""
    with hts.util.silent(Exception):
        for prefix in ("fi", "sv", "en"):
            if language.startswith(prefix):
                return prefix
    # XXX: Fall back on Finnish?
    return "fi"

URL_PREFIX = ("http://api.reittiopas.fi/hsl/prod/"
              "?user=helsinki-transit-stops"
              "&pass=38220661"
              "&format=json"
              "&epsg_in=4326"
              "&epsg_out=4326"
              "&lang={LANG}").format(LANG=get_default_language())

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

@api_query(fallback=[])
def _find_departures(code):
    """Return a list of departures from stop matching `code`."""
    url = URL_PREFIX + ("&request=stop"
                        "&code={code}"
                        "&time_limit=360"
                        "&dep_limit=20")

    url = url.format(code=code)
    output = hts.http.request_json(url)
    if not output or not output[0]: return []
    destinations = dict(
        (code, parse_destination(destination))
        for code, destination in
        map(lambda x: x.split(":", 1),
            output[0]["lines"]))

    results = [dict(
        time=parse_time(departure["time"]),
        unix_time=parse_unix_time(departure["time"]),
        line=parse_line(departure["code"]),
        x=float(output[0]["coords"].split(",")[0]),
        y=float(output[0]["coords"].split(",")[1]),
        destination=destinations[departure["code"]],
    ) for departure in output[0]["departures"] or []]
    return results

def find_departures(*codes):
    """Return a list of departures from stops matching `codes`."""
    results = []
    for code in codes:
        value = _find_departures(code)
        if isinstance(value, dict):
            # Error value.
            return value
        results.extend(value)
    results.sort(key=lambda x: (x["unix_time"], line_to_sort_key(x["line"])))
    return results

def find_lines(codes):
    """Return a list of lines at stops matching `codes`."""
    lines = []
    for code in codes:
        value = find_stops(code, 0, 0)
        if isinstance(value, dict):
            # Error value.
            return value
        lines.extend(value[0]["lines"])
    lines = unique_lines(lines)
    lines.sort(key=lambda x: line_to_sort_key(x["line"]))
    return lines

@api_query(fallback=[])
def find_nearby_stops(x, y):
    """Return a list of stops near given coordinates."""
    url = URL_PREFIX + ("&request=reverse_geocode"
                        "&coordinate={x:.5f},{y:.5f}"
                        "&limit=50"
                        "&radius=1000"
                        "&result_contains=stop")

    url = url.format(x=x, y=y)
    output = hts.http.request_json(url)
    if not output: return []
    results = [dict(
        name=parse_name(result.get("shortName", result["name"])),
        address=result["details"].get("address", "???"),
        x=float(result["coords"].split(",")[0]),
        y=float(result["coords"].split(",")[1]),
        code=result["details"]["code"],
        short_code=result["details"]["shortCode"],
        lines=unique_lines([dict(
            code=code,
            line=parse_line(code),
            destination=parse_destination(destination),
        ) for code, destination in
          map(lambda x: x.split(":", 1),
              result["details"]["lines"])]),
    ) for result in output]
    for result in results:
        # Strip trailing municipality from stop name.
        result["name"] = re.sub(r",[^,]*$", "", result["name"])
        result["type"] = guess_type(
            [line.pop("code") for line in result["lines"]])
        result["color"] = hts.util.types_to_color(result["type"])
        result["dist"] = hts.util.format_distance(
            hts.util.calculate_distance(x, y, result["x"], result["y"]))
    return results

@api_query(fallback=[])
def find_stops(name, x, y):
    """Return a list of stops matching `name`."""
    url = URL_PREFIX + ("&request=geocode"
                        "&key={name}"
                        "&loc_types=stop")

    url = url.format(name=urllib.parse.quote_plus(name))
    output = hts.http.request_json(url)
    if not output: return []
    results = [dict(
        name=parse_name(result.get("shortName", result["name"])),
        address=result["details"].get("address", "???"),
        x=float(result["coords"].split(",")[0]),
        y=float(result["coords"].split(",")[1]),
        code=result["details"]["code"],
        short_code=result["details"]["shortCode"],
        lines=unique_lines([dict(
            code=code,
            line=parse_line(code),
            destination=parse_destination(destination),
        ) for code, destination in
          map(lambda x: x.split(":", 1),
              result["details"]["lines"])]),
    ) for result in output]
    for result in results:
        result["type"] = guess_type(
            [line.pop("code") for line in result["lines"]])
        result["color"] = hts.util.types_to_color(result["type"])
        result["dist"] = hts.util.format_distance(
            hts.util.calculate_distance(x, y, result["x"], result["y"]))
    return sort_stops(results)

def guess_type(codes):
    """Guess stop type from line `codes`."""
    # Journey Planner returns 7-character JORE-codes.
    for code in codes:
        if code.startswith("3"): return "train"
        if code.startswith("13"): return "metro"
        if code.startswith("1019"): return "ferry"
        line = code[1:4].strip()
        while len(line) > 1 and line.startswith("0"):
            line = line[1:]
        if line and line.isnumeric():
            if code.startswith("1") and int(line) <= 10:
                return "tram"
    # In addition to actual bus stops,
    # fall back on bus for unrecognized types.
    return "bus"

def line_to_sort_key(line):
    """Construct a sortable key from `line`."""
    # Break into line and modifier, pad with zeros.
    head, tail = line, ""
    while head and head[0].isdigit() and head[-1].isalpha():
        tail = head[-1] + tail
        head = head[:-1]
    return head.zfill(3), tail.zfill(3)

def parse_destination(destination):
    """Parse human readable destination name."""
    # Strip platform numbers from terminals.
    destination = destination.split(",")[0]
    return parse_name(destination)

def parse_line(code):
    """Parse human readable line number from `code`."""
    # Journey Planner returns 7-character JORE-codes.
    if code.startswith(("13", "3")):
        # Metro and trains.
        line = code[4]
    else:
        # Buses, trams and ferries.
        line = code[1:5].strip()
        while len(line) > 1 and line.startswith("0"):
            line = line[1:]
    if not line.strip():
        return "?"
    return line

def parse_name(name):
    """Parse human readable stop name."""
    # Fix inconsistent naming of stops at metro stations.
    return re.sub(r"(\S)\(", r"\1 (", name)

def parse_time(departure):
    """Parse human readable time from `departure`."""
    # Journey Planner returns a 'HHMM' string.
    departure = float(departure)
    hour = math.floor(departure/100) % 24
    minute = departure % 100
    return "{:.0f}:{:02.0f}".format(hour, minute)

def parse_unix_time(departure):
    """Parse Unix time from `departure`."""
    # Journey Planner returns a 'HHMM' string.
    hour = math.floor(departure/100) % 24
    minute = departure % 100
    now = datetime.datetime.today()
    departure = now.replace(hour=hour, minute=minute)
    departure = departure.timestamp()
    if departure < now.timestamp() - 3600:
        departure = departure + 86400
    return departure

def sort_stops(stops):
    """Sort stops of same name by short code."""
    for i, stop in enumerate(stops):
        stop["sort_key"] = [i, stop["short_code"]]
        if i > 0 and stop["name"] == stops[i-1]["name"]:
            stop["sort_key"][0] = stops[i-1]["sort_key"][0]
    stops.sort(key=lambda x: x["sort_key"])
    for stop in stops:
        del stop["sort_key"]
    return stops

def unique_lines(lines):
    """Return `lines` with duplicates discarded."""
    ll = [x["line"] for x in lines]
    ulines = []
    for i in range(len(lines)):
        if not lines[i]["line"] in ll[:i]:
            ulines.append(lines[i])
    return ulines
