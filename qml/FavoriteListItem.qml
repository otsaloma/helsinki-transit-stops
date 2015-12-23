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
    contentHeight: nameLabel.height + linesLabel.height
    Label {
        id: nameLabel
        anchors.left: parent.left
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        color: listItem.highlighted ? Theme.highlightColor : (
            model.near ? Theme.primaryColor : Theme.secondaryColor)
        height: implicitHeight + Theme.paddingMedium
        horizontalAlignment: Text.AlignLeft
        text: model.name
        truncationMode: TruncationMode.Fade
        verticalAlignment: Text.AlignBottom
    }
    Label {
        id: linesLabel
        anchors.left: parent.left
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        anchors.top: nameLabel.bottom
        color: listItem.highlighted ? Theme.highlightColor : (
            model.near ? Theme.primaryColor : Theme.secondaryColor)
        font.pixelSize: Theme.fontSizeSmall
        height: implicitHeight + Theme.paddingMedium
        horizontalAlignment: Text.AlignLeft
        text: model.lines_label || "—"
        truncationMode: TruncationMode.Fade
        verticalAlignment: Text.AlignTop
    }
    Rectangle {
        anchors.bottom: linesLabel.bottom
        anchors.bottomMargin: Theme.paddingMedium
        anchors.right: nameLabel.left
        anchors.rightMargin: Theme.paddingLarge
        anchors.top: nameLabel.top
        anchors.topMargin: Theme.paddingMedium
        color: model.color
        opacity: model.near ? 1 : 0
        radius: Theme.paddingSmall/3
        width: Theme.paddingSmall
    }
}
