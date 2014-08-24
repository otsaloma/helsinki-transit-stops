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
    allowedOrientations: Orientation.All
    property string code: ""
    property var coordinate: QtPositioning.coordinate(0, 0)
    property bool loading: true
    property string name: ""
    property var results: {}
    property string title: ""
    // Column widths to be set based on data.
    property var timeWidth: 0
    property var lineWidth: 0
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: ListItem {
            id: listItem
            contentHeight: Theme.itemSizeSmall
            property var result: page.results[index]
            Label {
                id: timeLabel
                anchors.left: parent.left
                anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingMedium
                height: Theme.itemSizeSmall
                horizontalAlignment: Text.AlignRight
                text: model.time
                verticalAlignment: Text.AlignVCenter
                width: page.timeWidth
                Component.onCompleted: {
                    if (timeLabel.implicitWidth > page.timeWidth)
                        page.timeWidth = timeLabel.implicitWidth;
                }
            }
            Label {
                id: lineLabel
                anchors.left: timeLabel.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: timeLabel.top
                height: Theme.itemSizeSmall
                horizontalAlignment: Text.AlignRight
                text: model.line
                verticalAlignment: Text.AlignVCenter
                width: page.lineWidth
                Component.onCompleted: {
                    if (lineLabel.implicitWidth > page.lineWidth)
                        page.lineWidth = lineLabel.implicitWidth;
                }
            }
            Label {
                id: destinationLabel
                anchors.left: lineLabel.right
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: lineLabel.top
                color: Theme.secondaryColor
                height: Theme.itemSizeSmall
                text: " → " + model.destination
                truncationMode: TruncationMode.Fade
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                id: block
                anchors.bottom: timeLabel.bottom
                anchors.bottomMargin: Theme.paddingMedium
                anchors.right: timeLabel.left
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: timeLabel.top
                anchors.topMargin: Theme.paddingMedium
                color: "#4E9A06";
                width: Theme.paddingMedium
                property var position: gps.position
                Component.onCompleted: block.updateColor();
                onPositionChanged: block.updateColor();
                function updateColor() {
                    // Color block based on whether one can make it in time.
                    // Normal walking speed 70 m/min, fast 100 m/min,
                    // from the HSL Journey Planner, reittiopas.fi.
                    var dist = 1.2*gps.position.coordinate.distanceTo(page.coordinate);
                    if (dist / 70 < model.time_left) {
                        block.color = "#4E9A06";
                    } else if (dist / 100 < model.time_left) {
                        block.color = "#FCE94F";
                    } else {
                        block.color = "#EF2929";
                    }
                }
            }
        }
        header: PageHeader { title: page.title }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
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
    onStatusChanged: {
        if (page.status == PageStatus.Activating) {
            page.loading = true;
            page.title = "";
            busyLabel.text = "Loading"
        } else if (page.status == PageStatus.Active) {
            page.populate();
        } else if (page.status == PageStatus.Inactive) {
            listView.model.clear();
        }
    }
    function populate() {
        // Load departures from the Python backend.
        listView.model.clear();
        page.timeWidth = 0;
        page.lineWidth = 0;
        py.call("hts.query.find_departures", [page.code], function(results) {
            if (results.error && results.message) {
                page.title = "";
                busyLabel.text = results.message;
            } else if (results.length > 0) {
                page.results = results;
                page.title = page.name;
                for (var i = 0; i < results.length; i++)
                    listView.model.append(results[i]);
            } else {
                page.title = "";
                busyLabel.text = "No departures found";
            }
            page.loading = false;
        });
    }
}
