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

Dialog {
    id: page
    allowedOrientations: Orientation.Portrait
    property var codes: []
    property string key: ""
    property bool loading: false
    property var skip: []
    SilicaGridView {
        id: gridView
        anchors.fill: parent
        cellWidth: page.width/2
        delegate: ListItem {
            id: listItem
            clip: true
            width: gridView.cellWidth
            TextSwitch {
                id: lineSwitch
                checked: model.checked
                description: model.destination
                rightMargin: Theme.paddingLarge
                text: model.line
                // Avoid wrapping description.
                width: 3*page.width
                Component.onCompleted: {
                    listItem.contentHeight = lineSwitch.height;
                    gridView.cellHeight = lineSwitch.height;
                }
                onCheckedChanged: gridView.model.setProperty(
                    model.index, "checked", lineSwitch.checked);
            }
        }
        header: DialogHeader {}
        model: ListModel {}
        PullDownMenu {
            visible: !page.loading && gridView.model.count > 0
            MenuItem {
                text: "Mark all"
                onClicked: {
                    for (var i = 0; i < gridView.model.count; i++)
                        gridView.model.setProperty(i, "checked", true);
                }
            }
            MenuItem {
                text: "Unmark all"
                onClicked: {
                    for (var i = 0; i < gridView.model.count; i++)
                        gridView.model.setProperty(i, "checked", false);
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
    Component.onCompleted: {
        page.loading = true;
        busyLabel.text = "Loading"
        page.populate();
    }
    onAccepted: {
        // Put unchecked lines into an array.
        page.skip = [];
        for (var i = 0; i < gridView.model.count; i++) {
            var item = gridView.model.get(i);
            item.checked || page.skip.push(item.line);
        }
    }
    function populate() {
        // Load lines from the Python backend.
        gridView.model.clear();
        py.call("hts.query.find_lines", [page.codes], function(results) {
            if (results && results.error && results.message) {
                busyLabel.text = results.message;
            } else if (results && results.length > 0) {
                if (page.key && page.key.length > 0) {
                    var skip = py.call_sync(
                        "hts.app.favorites.get_skip_lines",
                        [page.key]);
                } else {
                    var skip = [];
                }
                for (var i = 0; i < results.length; i++) {
                    results[i].checked = skip.indexOf(results[i].line) < 0;
                    gridView.model.append(results[i]);
                }
            } else {
                busyLabel.text = "No lines found";
            }
            page.loading = false;
        });
    }
}
