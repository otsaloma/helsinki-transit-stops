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

import hts.test


class TestModule(hts.test.TestCase):

    def test_find_departures(self):
        # Departures might be empty at night time,
        # in which case query should return a blank list.
        departures = hts.query.find_departures("1301103")
        assert isinstance(departures, list)
        for departure in departures:
            assert departure["destination"]
            assert departure["line"]
            assert departure["time"]
            assert departure["unix_time"]
            assert departure["x"]
            assert departure["y"]

    def test_find_lines(self):
        lines = hts.query.find_lines(["1020601"])
        assert isinstance(lines, list)
        assert len(lines) > 0
        for line in lines:
            assert line["destination"]
            assert line["line"]

    def test_find_nearby_stops(self):
        stops = hts.query.find_nearby_stops(24.951, 60.167)
        assert isinstance(stops, list)
        assert len(stops) > 0
        for stop in stops:
            assert stop["address"]
            assert stop["code"]
            assert stop["color"]
            assert stop["dist"]
            assert stop["lines"]
            assert stop["name"]
            assert stop["short_code"]
            assert stop["type"]
            assert stop["x"]
            assert stop["y"]

    def test_find_stops(self):
        stops = hts.query.find_stops("Erottaja", 24.941, 60.169)
        assert isinstance(stops, list)
        assert len(stops) > 0
        for stop in stops:
            assert stop["address"]
            assert stop["code"]
            assert stop["color"]
            assert stop["dist"]
            assert stop["lines"]
            assert stop["name"]
            assert stop["short_code"]
            assert stop["type"]
            assert stop["x"]
            assert stop["y"]

    def test_guess_type(self):
        assert hts.query.guess_type(("3002A 1",)) == "train"
        assert hts.query.guess_type(("1300M 1",)) == "metro"
        assert hts.query.guess_type(("1019  1",)) == "ferry"
        assert hts.query.guess_type(("1002 51",)) == "tram"
        assert hts.query.guess_type(("1058B 1",)) == "bus"

    def test_parse_line(self):
        assert hts.query.parse_line("3002A 1") == "A"
        assert hts.query.parse_line("1300M 1") == "M"
        assert hts.query.parse_line("1019  1") == "19"
        assert hts.query.parse_line("1002 51") == "2"
        assert hts.query.parse_line("1058B 1") == "58B"
