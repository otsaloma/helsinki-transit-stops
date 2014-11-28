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

ListItem {
    id: listItem
    contentHeight: nameLabel.height + addressLabel.height + repeater.height
    property var result: page.results[index]
    // Column width to be set based on data.
    property int lineWidth: 0
    ListItemLabel {
        id: nameLabel
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        color: listItem.highlighted ?
            Theme.highlightColor : Theme.primaryColor;
        height: implicitHeight + Theme.paddingMedium
        text: model.name
        verticalAlignment: Text.AlignBottom
        Component.onCompleted: {
            if (model.short_code && model.short_code.length > 0) {
                nameLabel.textFormat = Text.RichText;
                nameLabel.text += " <small>(" + model.short_code + ")</small>";
            }
        }
    }
    ListItemLabel {
        id: addressLabel
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        anchors.top: nameLabel.bottom
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: model.address + " · " + model.dist
    }
    Repeater {
        // List at most three lines using the stop along with their
        // destinations to understand which stop and on which side
        // of the street it is located on.
        id: repeater
        anchors.top: addressLabel.bottom
        height: Theme.paddingMedium
        model: listItem.result ? Math.min(3, listItem.result.lines.length) : 0
        width: parent.width
        Item {
            id: row
            height: lineLabel.height
            width: listItem.width
            property var line: listItem.result.lines[index]
            Label {
                id: lineLabel
                anchors.left: parent.left
                anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: line.line
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
                Component.onCompleted: {
                    // Add an ellipsis to indicate that only
                    // the first three of all lines are shown.
                    (index == 2) && destinationLabel.text += " …";
                }
            }
            Component.onCompleted: repeater.height += row.height;
        }
    }
    Rectangle {
        anchors.bottom: repeater.bottom
        anchors.bottomMargin: 1.5*Theme.paddingMedium
        anchors.right: nameLabel.left
        anchors.rightMargin: Theme.paddingLarge
        anchors.top: nameLabel.top
        anchors.topMargin: 1.5*Theme.paddingMedium
        color: model.color;
        radius: Theme.paddingSmall/3
        width: Theme.paddingSmall
    }
}
