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
    allowedOrientations: Orientation.All
    canAccept: nameField && nameField.text.length > 0
    property string key: ""
    property string name: ""
    property var nameField
    property var removals: []
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
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                height: Theme.itemSizeSmall
                text: model.name
                Component.onCompleted: {
                    if (model.short_code && model.short_code.length > 0) {
                        nameLabel.textFormat = Text.RichText;
                        nameLabel.text += " <small>(" + model.short_code + ")</small>";
                    }
                }
            }
            Rectangle {
                anchors.bottom: nameLabel.bottom
                anchors.bottomMargin: Theme.paddingMedium
                anchors.right: nameLabel.left
                anchors.rightMargin: Theme.paddingLarge
                anchors.top: nameLabel.top
                anchors.topMargin: Theme.paddingMedium
                color: model.color
                radius: Theme.paddingSmall/3
                width: Theme.paddingSmall
            }
            ContextMenu {
                id: contextMenu
                MenuItem {
                    text: "Remove"
                    onClicked: {
                        // Mark stop to be removed once dialog is accepted.
                        page.removals.push(model.code);
                        listView.model.remove(index);
                    }
                }
            }
            ListView.onRemove: animateRemoval(listItem);
            onClicked: listItem.showMenu();
        }
        header: Column {
            height: header.height + nameField.height + titleLabel.height
            width: parent.width
            DialogHeader { id: header }
            TextField {
                id: nameField
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                label: "Name"
                text: page.name
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: nameField.focus = false;
            }
            ListItemLabel {
                id: titleLabel
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                height: implicitHeight
                horizontalAlignment: Text.AlignRight
                text: "Stops"
            }
            Component.onCompleted: page.nameField = nameField;
        }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
    Component.onCompleted: {
        // Load stops from the Python backend.
        listView.model.clear();
        var stops = py.call_sync("hts.app.favorites.get_stops", [page.key]);
        for (var i = 0; i < stops.length; i++)
            listView.model.append(stops[i]);
    }
    onAccepted: {
        // Save name to use for renaming.
        page.name = nameField.text;
    }
}
