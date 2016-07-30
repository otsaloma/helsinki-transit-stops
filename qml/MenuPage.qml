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
import QtPositioning 5.2
import Sailfish.Silica 1.0
import "."

Page {
    id: page
    allowedOrientations: app.defaultAllowedOrientations
    SilicaGridView {
        id: view
        anchors.fill: parent
        cellHeight: Theme.itemSizeMedium
        cellWidth: {
            // Use a dynamic column count based on available screen width.
            var width = page.isPortrait ? Screen.width : Screen.height;
            return width / Math.floor(width / (Theme.pixelRatio*400));
        }
        delegate: FavoriteListItem {
            id: listItem
            contentHeight: view.cellHeight
            enabled: !view.menuOpen
            width: view.cellWidth
            menu: ContextMenu {
                id: contextMenu
                MenuItem {
                    text: qsTranslate("", "Edit")
                    onClicked: {
                        var dialog = pageStack.push("EditFavoritePage.qml", {
                            "key": model.key, "name": model.name});
                        dialog.accepted.connect(function() {
                            // Rename favorite and/or remove associated stops.
                            py.call_sync("hts.app.favorites.rename", [model.key, dialog.name]);
                            for (var i = 0; i < dialog.removals.length; i++)
                                py.call_sync(
                                    "hts.app.favorites.remove_stop",
                                    [model.key, dialog.removals[i]]);
                            var i = model.index;
                            view.model.setProperty(i, "name", dialog.name);
                            view.model.setProperty(i, "color", py.call_sync(
                                "hts.app.favorites.get_color", [model.key]));
                            py.call("hts.app.save", [], null);
                        });
                    }
                }
                MenuItem {
                    text: qsTranslate("", "Remove")
                    onClicked: {
                        remorseAction(qsTranslate("", "Removing"), function() {
                            py.call_sync("hts.app.favorites.remove", [model.key]);
                            view.model.remove(index);
                        });
                    }
                }
                onActiveChanged: view.menuOpen = contextMenu.active;
            }
            ListView.onRemove: animateRemoval(listItem);
            onClicked: app.pageStack.push("FavoritePage.qml", {"props": model});
        }
        header: Column {
            height: header.height
            width: parent.width
            PageHeader {
                id: header
                title: "Helsinki Transit Stops"
            }
        }
        model: ListModel {}
        property bool menuOpen: false
        PullDownMenu {
            MenuItem {
                text: qsTranslate("", "About")
                onClicked: app.pageStack.push("AboutPage.qml");
            }
            MenuItem {
                text: qsTranslate("", "Preferences")
                onClicked: app.pageStack.push("PreferencesPage.qml");
            }
            MenuItem {
                text: qsTranslate("", "Search")
                onClicked: {
                    app.pageStack.push("SearchPage.qml");
                    app.pageStack.pushAttached("SearchResultsPage.qml");
                }
            }
            MenuItem {
                enabled: gps.ready
                text: qsTranslate("", "Nearby")
                onClicked: app.pageStack.push("NearbyPage.qml");
            }
        }
        ViewPlaceholder {
            id: viewPlaceholder
            enabled: false
            text: qsTranslate("", "Once added, favorites appear here. Pull down to search for nearby stops or stops by name or number.")
        }
        VerticalScrollDecorator {}
    }
    Timer {
        id: timer
        interval: 5000
        repeat: true
        running: app.applicationActive && gps.ready && view.model.count > 0
        triggeredOnStart: true
        onTriggered: page.update();
    }
    Component.onCompleted: {
        if (py.ready) {
            page.populate();
        } else {
            py.onReadyChanged.connect(function() {
                page.populate();
            });
        }
    }
    onStatusChanged: {
        page.status === PageStatus.Activating && page.update();
    }
    function populate() {
        // Load favorites from the Python backend.
        view.model.clear();
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < favorites.length; i++) {
            favorites[i].near = false;
            view.model.append(favorites[i]);
        }
        if (view.model.count === 0)
            viewPlaceholder.enabled = true;
    }
    function update() {
        // Update favorite display based on positioning.
        if (view.model.count === 0) return;
        var threshold = app.conf.get("favorite_highlight_radius");
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < view.model.count; i++) {
            var item = view.model.get(i);
            var dist = gps.position.coordinate.distanceTo(
                QtPositioning.coordinate(item.y, item.x));
            item.near = dist < threshold;
            if (i < favorites.length && favorites[i].key === item.key) {
                item.color = favorites[i].color;
                item.lines_label = favorites[i].lines_label;
                item.name = favorites[i].name;
            }
        }
    }
}
