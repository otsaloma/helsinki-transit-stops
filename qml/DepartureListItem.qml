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

ListItem {
    id: listItem
    contentHeight: visible ? Theme.itemSizeSmall : 0
    enabled: false
    visible: model.visible
    property var result: page.results[index]
    Rectangle {
        id: bar
        anchors.bottom: lineLabel.bottom
        anchors.bottomMargin: Theme.paddingMedium
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.top: lineLabel.top
        anchors.topMargin: Theme.paddingMedium
        color: model.color
        radius: width/3
        width: Theme.paddingSmall
    }
    Label {
        id: lineLabel
        anchors.left: bar.right
        anchors.leftMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeLarge
        height: Theme.itemSizeSmall
        horizontalAlignment: Text.AlignRight
        text: model.line
        verticalAlignment: Text.AlignVCenter
        width: page.lineWidth
        Component.onCompleted: lineLabel.updateWidth();
        onTextChanged: lineLabel.updateWidth();
        function updateWidth() {
            var width = lineLabel.implicitWidth;
            view.model.setProperty(model.index, "lineWidth", width);
            page.lineWidth = Math.max(page.lineWidth, model.visible * width);
        }
    }
    Label {
        id: destinationLabel
        anchors.baseline: lineLabel.baseline
        anchors.left: lineLabel.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.right: timeLabel.left
        color: Theme.secondaryColor
        text: model.destination
        truncationMode: TruncationMode.Fade
        Component.onCompleted: {
            // Add a dotted line long enough for all orientations.
            var dots = " . . . . . . . . . . . . . . . . . . . .";
            var dots = dots + dots + dots + dots + dots;
            var size = Math.max(page.width, page.height);
            while (destinationLabel.implicitWidth < size) {
                var prev = destinationLabel.implicitWidth;
                destinationLabel.text += dots;
                if (destinationLabel.implicitWidth < prev + 1) break;
            }
        }
    }
    Label {
        id: timeLabel
        anchors.baseline: lineLabel.baseline
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignRight
        text: model.time
        width: page.timeWidth
        Component.onCompleted: timeLabel.updateWidth();
        onTextChanged: timeLabel.updateWidth();
        function updateWidth() {
            var width = timeLabel.implicitWidth;
            view.model.setProperty(model.index, "timeWidth", width);
            page.timeWidth = Math.max(page.timeWidth, model.visible * width);
        }
    }
    ListView.onRemove: animateRemoval(listItem);
}
