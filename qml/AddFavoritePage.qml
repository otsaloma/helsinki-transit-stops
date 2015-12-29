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
    allowedOrientations: app.defaultAllowedOrientations
    canAccept: nameField && nameField.visible && nameField.text.length > 0
    property string code: ""
    property string key: ""
    property string name: ""
    property var nameField
    SilicaListView {
        id: view
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: FavoriteListItem {
            onClicked: {
                // Accept clicked existing favorite.
                page.canAccept = true;
                page.key = model.key;
                page.accept();
            }
        }
        header: Column {
            height: header.height + favoriteCombo.height + nameField.height
            width: parent.width
            DialogHeader { id: header }
            ComboBox {
                id: favoriteCombo
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge + Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                currentIndex: 0
                label: qsTr("Favorite")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Create new") }
                    MenuItem { text: qsTr("Add to existing") }
                }
                onCurrentIndexChanged: {
                    // Show either nameField or view.
                    nameField.visible = (favoriteCombo.currentIndex === 0);
                    view.model.clear();
                    nameField.visible || page.populate();
                }
            }
            TextField {
                id: nameField
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge + Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                height: visible ? implicitHeight : 0
                label: qsTr("Name")
                text: page.name
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: page.accept();
            }
            Component.onCompleted: page.nameField = nameField;
        }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
    onAccepted: {
        // Add new favorite and store value of its key.
        if (page.nameField.visible) {
            var text = page.nameField.text;
            page.key = py.call_sync("hts.app.favorites.add", [text]);
        }
    }
    function populate() {
        // Load favorites from the Python backend.
        view.model.clear();
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < favorites.length; i++) {
            favorites[i].near = true;
            view.model.append(favorites[i]);
        }
    }
}
