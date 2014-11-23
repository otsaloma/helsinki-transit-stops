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
    canAccept: textField && textField.text.length > 0
    property string key: ""
    property string name: ""
    property var removals: []
    property var textField
    SilicaListView {
        id: listView
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: ListItem {
            id: listItem
            contentHeight: Theme.itemSizeSmall
            menu: contextMenu
            ListItemLabel {
                id: nameLabel
                anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
                color: listItem.highlighted ?
                    Theme.highlightColor : Theme.primaryColor;
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
                Component.onCompleted: {
                    if (model.short_code && model.short_code.length > 0) {
                        nameLabel.textFormat = Text.RichText;
                        nameLabel.text += " <small>(" + model.short_code + ")</small>";
                    }
                }
            }
            ContextMenu {
                id: contextMenu
                MenuItem {
                    text: "Remove"
                    onClicked: {
                        page.removals.push(model.code);
                        listView.model.remove(index);
                    }
                }
            }
            ListView.onRemove: animateRemoval(listItem)
        }
        header: Column {
            height: pageHeader.height + textField.height + titleLabel.height
            width: parent.width
            DialogHeader { id: pageHeader }
            TextField {
                id: textField
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                label: "Name"
                text: page.name
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: textField.focus = false;
            }
            ListItemLabel {
                id: titleLabel
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                height: implicitHeight
                horizontalAlignment: Text.AlignRight
                text: "Stops"
            }
            Component.onCompleted: page.textField = textField;
        }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
    Component.onCompleted: {
        // Load favorites from the Python backend.
        listView.model.clear();
        var stops = py.call_sync("hts.app.favorites.get_stops", [page.key]);
        for (var i = 0; i < stops.length; i++)
            listView.model.append(stops[i]);
    }
    onAccepted: {
        page.name = textField.text;
    }
}
