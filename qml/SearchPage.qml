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

Page {
    id: page
    allowedOrientations: Orientation.All
    canNavigateForward: app.searchQuery.length > 0
    property var history: []
    SilicaListView {
        id: listView
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: ListItem {
            id: listItem
            contentHeight: visible ? Theme.itemSizeSmall : 0
            menu: contextMenu
            visible: model.visible
            ListItemLabel {
                anchors.leftMargin: listView.searchField.textLeftMargin
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                height: Theme.itemSizeSmall
                text: model.name
            }
            ContextMenu {
                id: contextMenu
                MenuItem {
                    text: "Remove"
                    onClicked: {
                        py.call_sync("hts.app.history.remove", [model.name]);
                        listView.model.remove(index);
                    }
                }
            }
            ListView.onRemove: animateRemoval(listItem)
            onClicked: {
                app.searchQuery = model.name;
                app.pageStack.navigateForward();
            }
        }
        header: Column {
            height: header.height + searchField.height
            width: parent.width
            PageHeader {
                id: header
                title: "Find Stop by Name"
            }
            SearchField {
                id: searchField
                placeholderText: "Stop name or number"
                width: parent.width
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: app.pageStack.navigateForward();
                onTextChanged: {
                    app.searchQuery = searchField.text;
                    page.filterHistory();
                }
            }
            Component.onCompleted: listView.searchField = searchField;
        }
        model: ListModel {}
        property var searchField
        VerticalScrollDecorator {}
    }
    onStatusChanged: {
        if (page.status == PageStatus.Activating) {
            page.loadHistory();
            page.filterHistory();
        }
    }
    function filterHistory() {
        // Filter search history for current search field text.
        var query = listView.searchField.text.toLowerCase();
        var found = [], n = 0;
        for (var i = 0; i < page.history.length; i++) {
            var item = page.history[i].toLowerCase();
            if (query.length > 0 && item.indexOf(query) == 0) {
                found[n++] = page.history[i];
                if (found.length >= listView.count) break;
            } else if (query.length == 0 || item.indexOf(query) > 0) {
                found[found.length] = page.history[i];
                if (found.length >= listView.count) break;
            }
        }
        for (var i = 0; i < found.length; i++) {
            listView.model.setProperty(i, "name", found[i]);
            listView.model.setProperty(i, "visible", true);
        }
        for (var i = found.length; i < listView.count; i++)
            listView.model.setProperty(i, "visible", false);
    }
    function loadHistory() {
        // Load search history and preallocate list items.
        page.history = py.evaluate("hts.app.history.names");
        while (listView.model.count < 50)
            listView.model.append({"name": "", "visible": false});
    }
}
