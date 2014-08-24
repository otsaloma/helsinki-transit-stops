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
