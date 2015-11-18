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
    contentHeight: Theme.itemSizeSmall
    Rectangle {
        anchors.fill: parent
        color: Theme.highlightColor
        opacity: model.highlight ? 0.1 : 0
    }
    Label {
        id: nameLabel
        anchors.left: parent.left
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        anchors.right: distLabel.left
        anchors.rightMargin: 0
        color: listItem.highlighted ? Theme.highlightColor : (
            model.fade ? Theme.secondaryColor : Theme.primaryColor)
        height: Theme.itemSizeSmall
        horizontalAlignment: Text.AlignLeft
        text: model.name
        truncationMode: TruncationMode.Fade
        verticalAlignment: Text.AlignVCenter
    }
    Label {
        id: distLabel
        anchors.right: parent.right
        anchors.rightMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        color: listItem.highlighted ? Theme.highlightColor : (
            model.fade ? Theme.secondaryColor : Theme.primaryColor)
        font.pixelSize: Theme.fontSizeSmall
        height: Theme.itemSizeSmall
        horizontalAlignment: Text.AlignRight
        text: model.dist
        truncationMode: TruncationMode.Fade
        verticalAlignment: Text.AlignVCenter
    }
    Rectangle {
        anchors.bottom: nameLabel.bottom
        anchors.bottomMargin: Theme.paddingMedium
        anchors.right: nameLabel.left
        anchors.rightMargin: Theme.paddingLarge
        anchors.top: nameLabel.top
        anchors.topMargin: Theme.paddingMedium
        color: model.color
        opacity: model.fade ? 0.65 : 1
        radius: Theme.paddingSmall/3
        width: Theme.paddingSmall
    }
}
