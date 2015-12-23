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

CoverBackground {
    id: cover
    anchors.fill: parent
    property bool active: status === Cover.Active
    Image {
        id: image
        anchors.centerIn: parent
        height: width/sourceSize.width * sourceSize.height
        opacity: 0.1
        source: "icons/cover.png"
        width: 1.5 * parent.width
    }
    Label {
        id: title
        anchors.centerIn: parent
        color: Theme.primaryColor
        font.family: Theme.fontFamilyHeading
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        text: "Helsinki\nTransit\nStops"
        width: parent.width
    }
    SilicaListView {
        id: listView
        anchors.centerIn: parent
        width: parent.width
        delegate: Item {
            id: listItem
            height: lineLabel.height
            width: parent.width
            Label {
                id: lineLabel
                anchors.left: parent.left
                font.pixelSize: Theme.fontSizeLarge
                height: implicitHeight + 2*Theme.paddingSmall
                horizontalAlignment: Text.AlignRight
                text: model.line
                truncationMode: TruncationMode.Fade
                verticalAlignment: Text.AlignVCenter
                width: parent.width/2 - Theme.paddingLarge/2
            }
            Label {
                anchors.baseline: lineLabel.baseline
                anchors.right: parent.right
                height: implicitHeight + 2*Theme.paddingSmall
                horizontalAlignment: Text.AlignLeft
                text: model.time
                truncationMode: TruncationMode.Fade
                verticalAlignment: Text.AlignVCenter
                width: parent.width/2 - Theme.paddingLarge/2
            }
            Component.onCompleted: {
                listView.height = listView.model.count * listItem.height;
            }
        }
        model: ListModel {}
    }
    Timer {
        // Assuming we have only schedule data, i.e. not real-time,
        // it is sufficient to download data only once, then update
        // time remaining and colors periodically.
        interval: 30000
        repeat: true
        running: app.running
        triggeredOnStart: true
        onTriggered: cover.update();
    }
    Component.onCompleted: {
        // Pre-fill list view model with blank entries.
        // XXX: Item count should depend on screen size.
        for (var i = 0; i < 5; i++)
            listView.model.append({"line": "", "time": ""});
        app.pageStack.onCurrentPageChanged.connect(cover.update);
    }
    function clear() {
        // Clear the visible list of departures.
        for (var i = 0; i < listView.model.count; i++) {
            listView.model.setProperty(i, "line", "");
            listView.model.setProperty(i, "time", "");
        }
    }
    function copyFrom(model) {
        // Copy departure items from given model.
        var row = 0;
        for (var i = 0; i < model.count && row < listView.model.count; i++) {
            if (!model.get(i).visible) continue;
            listView.model.setProperty(row, "line", model.get(i).line);
            listView.model.setProperty(row, "time", model.get(i).time);
            row++;
        }
        for (var i = row; i < listView.model.count; i++) {
            listView.model.setProperty(i, "line", "");
            listView.model.setProperty(i, "time", "");
        }
    }
    function update() {
        // Query departures from the current page.
        var page = app.pageStack.currentPage;
        var model = null;
        var countVisible = 0;
        if (page && page.canCover) {
            var model = page.getModel();
            for (var i = 0; i < model.count; i++) {
                // Departures can be hidden by line filters.
                if (model.get(i).visible)
                    countVisible++;
            }
            if (model && countVisible > 0) {
                // Show the first few departures.
                cover.copyFrom(model);
                image.opacity = 0.05;
                title.visible = false;
            }
        }
        if (!model || countVisible === 0) {
            // No departures; show icon and title.
            cover.clear();
            image.opacity = 0.1;
            title.visible = true;
        }
    }
}
