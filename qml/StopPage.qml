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
    property var coordinate: QtPositioning.coordinate(0, 0)
    property string favorite: ""
    property bool loading: true
    property bool populated: false
    property var results: {}
    property string stopCode: ""
    property string stopName: ""
    property string stopType: ""
    property string title: ""
    // Column widths to be set based on data.
    property var timeWidth: 0
    property var lineWidth: 0
    RemorsePopup { id: remorse }
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: ListItem {
            id: listItem
            contentHeight: Theme.itemSizeExtraSmall
            property var result: page.results[index]
            Label {
                id: lineLabel
                anchors.left: parent.left
                anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingMedium
                font.pixelSize: Theme.fontSizeLarge
                height: Theme.itemSizeExtraSmall
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
                id: timeLabel
                anchors.baseline: lineLabel.baseline
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
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
                id: destinationLabel
                anchors.baseline: lineLabel.baseline
                anchors.left: lineLabel.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: timeLabel.left
                anchors.rightMargin: Theme.paddingLarge
                color: Theme.secondaryColor
                text: model.destination
                truncationMode: TruncationMode.Fade
                verticalAlignment: Text.AlignVCenter
                Component.onCompleted: {
                    // Add a dotted line long enough for landscape as well.
                    var size = Math.max(page.width, page.height);
                    var dots = " . . . . . . . . . . . . . . . . . . . .";
                    while (dots.length < 200)
                        dots += dots.substr(0, 20);
                    while (destinationLabel.implicitWidth < size) {
                        destinationLabel.text += dots;
                        // Just in case, to avoid an infinite loop.
                        if (destinationLabel.text.length > 1000) break;
                    }
                }
            }
            Rectangle {
                id: block
                anchors.bottom: lineLabel.bottom
                anchors.bottomMargin: Theme.paddingMedium
                anchors.right: lineLabel.left
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: lineLabel.top
                anchors.topMargin: Theme.paddingMedium
                color: "#888888";
                width: Theme.paddingMedium
                property var position: gps.position
                Component.onCompleted: block.updateColor();
                onPositionChanged: block.updateColor();
                function updateColor() {
                    // Color block based on whether one can make it in time.
                    var dist = gps.position.coordinate.distanceTo(page.coordinate);
                    block.color = py.call_sync("hts.util.departure_time_to_color",
                                               [dist, model.unix_time]);

                }
            }
        }
        header: PageHeader { title: page.title }
        model: ListModel {}
        PullDownMenu {
            visible: !page.loading
            MenuItem {
                text: "Add to favorites"
                onClicked: {
                    var dialog = pageStack.push("FavoriteDialog.qml", {
                        "name": page.stopName});
                    dialog.accepted.connect(function() {
                        var key = py.call_sync("hts.app.favorites.add", [
                            page.stopCode,
                            dialog.name,
                            page.stopType,
                            page.coordinate.longitude,
                            page.coordinate.latitude
                        ]);
                        page.favorite = key;
                        page.stopName = dialog.name;
                        page.title = dialog.name;
                    });
                }
            }
            MenuItem {
                text: "Remove from favorites"
                visible: page.favorite.length > 0
                onClicked: {
                    remorse.execute("Removing", function() {
                        py.call_sync("hts.app.favorites.remove", [page.favorite]);
                        page.favorite = "";
                    });
                }
            }
        }
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
        page.timeWidth = 0;
        page.lineWidth = 0;
        py.call("hts.query.find_departures", [page.stopCode], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busyLabel.text = results.message;
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = page.stopName;
                for (var i = 0; i < results.length; i++)
                    listView.model.append(results[i]);
            } else {
                page.title = "";
                busyLabel.text = "No departures found";
            }
            page.loading = false;
            page.populated = true;
        });
    }
}
