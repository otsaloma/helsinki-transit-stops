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

import hts
import math
import re
import socket
import time
import urllib.parse

URL_PREFIX = ("http://api.reittiopas.fi/hsl/prod/"
              "?user=helsinki-transit-stops"
              "&pass=38220661"
              "&format=json"
              "&epsg_in=4326"
              "&epsg_out=4326"
              "&lang=fi")


def find_departures(code):
    """Return a list of departures from given stop."""
    url = URL_PREFIX + ("&request=stop"
                        "&code={code}"
                        "&time_limit=360"
                        "&dep_limit=20")

    url = url.format(code=code)
    try:
        output = hts.http.request_json(url, fallback=[])
    except socket.timeout:
        return dict(error=True, message="Connection timed out")
    destinations = dict((line, parse_destination(destination))
                        for line, destination in
                        map(lambda x: x.split(":", 1),
                            output[0]["lines"]))

    results = [dict(time=parse_time(departure["time"]),
                    time_left=parse_time_left(departure["time"]),
                    line=parse_line(departure["code"]),
                    destination=destinations[departure["code"]],
                    ) for departure in output[0]["departures"]]

    return results

def find_nearby_stops(x, y):
    """Return a list of stops near given coordinates."""
    url = URL_PREFIX + ("&request=reverse_geocode"
                        "&coordinate={x:.5f},{y:.5f}"
                        "&limit=50"
                        "&radius=1000"
                        "&result_contains=stop")

    url = url.format(x=x, y=y)
    try:
        output = hts.http.request_json(url, fallback=[])
    except socket.timeout:
        return dict(error=True, message="Connection timed out")
    results = [dict(name=parse_name(result["name"]),
                    address=result["details"]["address"],
                    city=result["city"],
                    x=float(result["coords"].split(",")[0]),
                    y=float(result["coords"].split(",")[1]),
                    code=result["details"]["code"],
                    short_code=result["details"]["shortCode"],
                    lines=unique_lines(
                        [dict(line=parse_line(line),
                              destination=parse_destination(destination),
                              ) for line, destination in
                              map(lambda x: x.split(":", 1),
                                  result["details"]["lines"])]),
                    ) for result in output]

    for result in results:
        # Strip trailing municipality from stop name.
        result["name"] = re.sub(r",[^,]*$", "", result["name"])
        coords = (x, y, result["x"], result["y"])
        result.update(dict(
            dist=hts.util.calculate_distance(*coords),
            bearing=hts.util.calculate_bearing(*coords)))
        result.update(dict(
            dist_label=hts.util.format_distance(result["dist"]),
            bearing_label=hts.util.format_bearing(result["bearing"])))

    return results

def find_stops(name, x, y):
    """Return a list of stops matching `name`."""
    url = URL_PREFIX + ("&request=geocode"
                        "&key={name}"
                        "&loc_types=stop")

    url = url.format(name=urllib.parse.quote_plus(name))
    try:
        output = hts.http.request_json(url, fallback=[])
    except socket.timeout:
        return dict(error=True, message="Connection timed out")
    results = [dict(name=parse_name(result["name"]),
                    address=result["details"]["address"],
                    city=result["city"],
                    x=float(result["coords"].split(",")[0]),
                    y=float(result["coords"].split(",")[1]),
                    code=result["details"]["code"],
                    short_code=result["details"]["shortCode"],
                    lines=unique_lines(
                        [dict(line=parse_line(line),
                              destination=parse_destination(destination),
                              ) for line, destination in
                              map(lambda x: x.split(":", 1),
                                  result["details"]["lines"])]),
                    ) for result in output]

    for result in results:
        coords = (x, y, result["x"], result["y"])
        result.update(dict(
            dist=hts.util.calculate_distance(*coords),
            bearing=hts.util.calculate_bearing(*coords)))
        result.update(dict(
            dist_label=hts.util.format_distance(result["dist"]),
            bearing_label=hts.util.format_bearing(result["bearing"])))

    return results

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
        # Buses and trams.
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
    """Parse human readable time of `departure`."""
    departure = float(departure)
    hour = math.floor(departure/100) % 24
    return "{:.0f}:{:.0f}".format(hour, departure % 100)

def parse_time_left(departure):
    """Parse amount of minutes left to `departure`."""
    departure = float(departure)
    departure = (math.floor(departure/100) % 24) * 60 + (departure % 100)
    now = time.localtime()
    now = now.tm_hour * 60 + now.tm_min + now.tm_sec/60
    if departure < now:
        departure += 24*60
    return departure - now

def unique_lines(lines):
    """Return `lines` with duplicates discarded."""
    ulines = []
    for line in lines:
        if not line in ulines:
            ulines.append(line)
    return ulines
