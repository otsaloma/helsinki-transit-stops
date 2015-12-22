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
import imp
import os
import tempfile


class TestConfigurationStore(hts.test.TestCase):

    def setup_method(self, method):
        imp.reload(hts.config)
        hts.conf = hts.ConfigurationStore()
        handle, self.path = tempfile.mkstemp()

    def teardown_method(self, method):
        os.remove(self.path)

    def test_get(self):
        assert hts.conf.get("departure_time_cutoff") == 10

    def test_get_default(self):
        assert hts.conf.get_default("departure_time_cutoff") == 10

    def test_read(self):
        hts.conf.departure_time_cutoff = 99
        hts.conf.write(self.path)
        hts.conf.clear()
        assert not hts.conf
        hts.conf.read(self.path)
        assert hts.conf.departure_time_cutoff == 99

    def test_set(self):
        hts.conf.set("departure_time_cutoff", 99)
        assert hts.conf.departure_time_cutoff == 99

    def test_write(self):
        hts.conf.departure_time_cutoff = 99
        hts.conf.write(self.path)
        hts.conf.clear()
        assert not hts.conf
        hts.conf.read(self.path)
        assert hts.conf.departure_time_cutoff == 99
