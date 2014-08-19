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
    property bool loading: true
    property var results: {}
    property string title: ""
    SilicaListView {
        anchors.fill: parent
        delegate: ListItem {
            id: listItem
            contentHeight: nameLabel.height + addressLabel.height + repeater.height
            property var result: page.results[index]
            // Column width to be set based on data.
            property int lineWidth: 0
            ListItemLabel {
                id: nameLabel
                color: listItem.highlighted ?
                    Theme.highlightColor : Theme.primaryColor;
                height: implicitHeight + Theme.paddingMedium
                text: model.name + " <small>(" + model.short_code + ")</small>"
                textFormat: Text.RichText
                verticalAlignment: Text.AlignBottom
            }
            ListItemLabel {
                id: addressLabel
                anchors.top: nameLabel.bottom
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: model.dist_label + " · " + model.address
                verticalAlignment: Text.AlignVCenter
            }
            Repeater {
                id: repeater
                anchors.top: addressLabel.bottom
                height: Theme.paddingMedium
                model: Math.min(3, listItem.result.lines.length)
                width: parent.width
                Item {
                    id: row
                    height: lineLabel.height
                    width: parent.width
                    property var line: listItem.result.lines[index]
                    Label {
                        id: lineLabel
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        text: line.line
                        verticalAlignment: Text.AlignVCenter
                        width: listItem.lineWidth
                        y: repeater.y + index * row.height
                        Component.onCompleted: {
                            if (lineLabel.implicitWidth > listItem.lineWidth)
                                listItem.lineWidth = lineLabel.implicitWidth;
                        }
                    }
                    Label {
                        id: destinationLabel
                        anchors.left: lineLabel.right
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        anchors.top: lineLabel.top
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        text: " → " + line.destination
                        truncationMode: TruncationMode.Fade
                        verticalAlignment: Text.AlignVCenter
                        Component.onCompleted: {
                            // Add an ellipsis to indicate that only
                            // a couple first of all lines are shown.
                            if (index == 2)
                                destinationLabel.text += "   …"
                        }
                    }
                    Component.onCompleted: {
                        repeater.height += row.height;
                    }
                }
            }
            onClicked: {
                console.log("Clicked!");
            }
        }
        header: PageHeader { title: page.title }
        model: ListModel { id: listModel }
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
        if (page.status == PageStatus.Activating) {
            page.loading = true;
            page.title = "";
            busyLabel.text = "Searching"
        } else if (page.status == PageStatus.Active) {
            page.populate();
        } else if (page.status == PageStatus.Inactive) {
            listModel.clear();
        }
    }
    function populate() {
        // Query stops from the Python backend.
        listModel.clear();
        var x = gps.position.coordinate.longitude || 0;
        var y = gps.position.coordinate.latitude || 0;
        py.call("hts.query.find_nearby_stops", [x, y], function(results) {
            if (results.error && results.message) {
                page.title = "";
                busyLabel.text = results.message;
            } else if (results.length > 0) {
                page.results = results;
                page.title = results.length == 1 ?
                    "1 Result" : results.length + " Results";
                for (var i = 0; i < results.length; i++)
                    listModel.append(results[i]);
            } else {
                page.title = "";
                busyLabel.text = "No results";
            }
            page.loading = false;
        });
    }
}
