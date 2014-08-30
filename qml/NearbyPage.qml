/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2014 Osmo Salomaa
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

Page {
    id: page
    allowedOrientations: Orientation.All
    property bool loading: false
    property bool populated: false
    property var results: {}
    property string title: ""
    StopListView { id: listView }
    Label {
        id: busyLabel
        anchors.bottom: busyIndicator.top
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        height: Theme.itemSizeLarge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: page.loading || text != "Searching"
        width: parent.width
    }
    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: page.loading
        size: BusyIndicatorSize.Large
        visible: page.loading
    }
    onStatusChanged: {
        if (page.populated) {
            return;
        } else if (page.status == PageStatus.Activating) {
            listView.model.clear();
            page.loading = true;
            page.title = "";
            busyLabel.text = "Searching"
        } else if (page.status == PageStatus.Active) {
            page.populate();
        }
    }
    function populate() {
        // Load stops from the Python backend.
        listView.model.clear();
        var x = gps.position.coordinate.longitude || 0;
        var y = gps.position.coordinate.latitude || 0;
        py.call("hts.query.find_nearby_stops", [x, y], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busyLabel.text = results.message;
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = results.length == 1 ?
                    "1 Stop" : results.length + " Stops";
                for (var i = 0; i < results.length; i++)
                    listView.model.append(results[i]);
            } else {
                page.title = "";
                busyLabel.text = "No stops found";
            }
            page.loading = false;
            page.populated = true;
        });
    }
}
