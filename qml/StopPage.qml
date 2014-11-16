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
import QtPositioning 5.0
import Sailfish.Silica 1.0
import "."

Page {
    id: page
    allowedOrientations: Orientation.Portrait
    property bool loading: false
    property bool populated: false
    property var props: {}
    property var results: {}
    property string title: ""
    // Column widths to be set based on data.
    property int lineWidth: 0
    property int timeWidth: 0
    DepartureListView { id: listView }
    Label {
        id: busyLabel
        anchors.bottom: busyIndicator.top
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        height: Theme.itemSizeLarge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: page.loading || text != "Loading"
        width: parent.width
    }
    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: page.loading
        size: BusyIndicatorSize.Large
        visible: page.loading
    }
    Timer {
        // Assuming we have only schedule data, i.e. not real-time,
        // it is sufficient to download data only once, then update
        // time remaining and colors periodically.
        interval: 30000
        repeat: true
        running: app.running && page.populated
        triggeredOnStart: true
        onTriggered: page.update();
    }
    onStatusChanged: {
        if (page.populated) {
            return;
        } else if (page.status == PageStatus.Activating) {
            listView.model.clear();
            page.loading = true;
            page.title = "";
            busyLabel.text = "Loading"
        } else if (page.status == PageStatus.Active) {
            page.populate();
        }
    }
    function populate() {
        // Load departures from the Python backend.
        listView.model.clear();
        page.lineWidth = 0;
        page.timeWidth = 0;
        var code = page.props.code;
        py.call("hts.query.find_departures", [code], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busyLabel.text = results.message;
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = page.props.name;
                for (var i = 0; i < results.length; i++) {
                    results[i].color = "#888888";
                    listView.model.append(results[i]);
                }
            } else {
                page.title = "";
                busyLabel.text = "No departures found";
            }
            page.loading = false;
            page.populated = true;
        });
    }
    function update() {
        // Update colors and times remaining to departure.
        var dist = gps.position.coordinate.distanceTo(
            QtPositioning.coordinate(page.props.y, page.props.x));
        for (var i = listView.model.count-1; i >= 0; i--) {
            var item = listView.model.get(i);
            item.time = py.call_sync(
                "hts.util.format_departure_time",
                [item.unix_time]
            );
            item.color = py.call_sync(
                "hts.util.departure_time_to_color",
                [dist, item.unix_time]
            );
            // Remove departures already passed.
            if (item.time.length == 0)
                listView.model.remove(i);
        }
    }
}
