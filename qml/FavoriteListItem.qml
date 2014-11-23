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
    contentHeight: Theme.itemSizeSmall
    ListItemLabel {
        anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        height: Theme.itemSizeSmall
        text: model.name
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingMedium
            anchors.right: parent.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            color: model.color
            radius: Theme.paddingSmall/3
            width: Theme.paddingSmall
        }
    }
}
