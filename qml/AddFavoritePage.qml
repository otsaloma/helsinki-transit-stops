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
    canAccept: textField && textField.visible && textField.text.length > 0
    property string code: ""
    property string key: ""
    property string name: ""
    property var textField
    SilicaListView {
        id: listView
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: FavoriteListItem {
            onClicked: {
                // Accept existing favorite.
                page.canAccept = true;
                page.key = model.key;
                page.accept();
            }
        }
        header: Column {
            height: pageHeader.height + comboBox.height + textField.height
            width: parent.width
            DialogHeader { id: pageHeader }
            ComboBox {
                id: comboBox
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge + Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                currentIndex: 0
                label: "Favorite"
                menu: ContextMenu {
                    MenuItem { text: "Create new" }
                    MenuItem { text: "Add to existing" }
                }
                onCurrentIndexChanged: {
                    textField.visible = (comboBox.currentIndex == 0);
                    listView.model.clear();
                    if (comboBox.currentIndex == 1)
                        page.populate();
                }
            }
            TextField {
                id: textField
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge + Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                height: visible ? implicitHeight : 0
                label: "Name"
                text: page.name
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: page.accept();
            }
            Component.onCompleted: page.textField = textField;
        }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
    onAccepted: {
        if (textField.visible)
            page.key = py.call_sync(
                "hts.app.favorites.add", [textField.text]);
    }
    function populate() {
        // Load favorites from the Python backend.
        listView.model.clear();
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < favorites.length; i++)
            listView.model.append(favorites[i]);
    }
}
