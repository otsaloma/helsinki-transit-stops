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

    def test_calculate_bearing(self):
        # From Helsinki to Lissabon.
        bearing = hts.util.calculate_bearing(24.94, 60.17, -9.14, 38.72)
        assert round(bearing) == 240

    def test_calculate_distance(self):
        # From Helsinki to Lissabon.
        dist = hts.util.calculate_distance(24.94, 60.17, -9.14, 38.72)
        assert round(dist/1000) == 3361
