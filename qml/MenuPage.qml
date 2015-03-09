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
    allowedOrientations: Orientation.Portrait
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: FavoriteListItem {
            id: listItem
            menu: ContextMenu {
                id: contextMenu
                MenuItem {
                    text: "Edit"
                    onClicked: {
                        var dialog = pageStack.push("EditFavoritePage.qml", {
                            "key": model.key,
                            "name": model.name
                        });
                        dialog.accepted.connect(function() {
                            // Rename favorite and/or remove associated stops.
                            py.call_sync("hts.app.favorites.rename", [model.key, dialog.name]);
                            for (var i = 0; i < dialog.removals.length; i++)
                                py.call_sync("hts.app.favorites.remove_stop",
                                             [model.key, dialog.removals[i]]);

                            var i = model.index;
                            listView.model.setProperty(i, "name", dialog.name);
                            listView.model.setProperty(i, "color", py.call_sync(
                                "hts.app.favorites.get_color", [model.key]));
                            py.call("hts.app.save", [], null);
                        });
                    }
                }
                MenuItem {
                    text: "Remove"
                    onClicked: {
                        remorseAction("Removing", function() {
                            py.call_sync("hts.app.favorites.remove", [model.key]);
                            listView.model.remove(index);
                        });
                    }
                }
            }
            ListView.onRemove: animateRemoval(listItem);
            onClicked: app.pageStack.push("FavoritePage.qml", {"props": model});
        }
        footer: Column {
            height: aboutItem.height
            width: parent.width
            ListItem {
                id: aboutItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
                    color: aboutItem.highlighted ? Theme.highlightColor : Theme.secondaryColor
                    height: Theme.itemSizeSmall
                    text: "About Helsinki Transit Stops"
                }
                onClicked: app.pageStack.push("AboutPage.qml");
            }
        }
        header: Column {
            height: header.height + nearbyItem.height + searchItem.height
            width: parent.width
            PageHeader {
                id: header
                title: "Helsinki Transit Stops"
            }
            ListItem {
                id: nearbyItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    id: nearbyLabel
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
                    color: nearbyItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    opacity: gps.ready ? 1.0 : 0.4
                    text: "Nearby"
                }
                BusyIndicator {
                    anchors.right: nearbyLabel.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: nearbyLabel.verticalCenter
                    running: !gps.ready
                    size: BusyIndicatorSize.Medium
                }
                onClicked: gps.ready && app.pageStack.push("NearbyPage.qml");
            }
            ListItem {
                id: searchItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
                    color: searchItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: "Search"
                }
                onClicked: {
                    app.pageStack.push("SearchPage.qml");
                    app.pageStack.pushAttached("SearchResultsPage.qml");
                }
            }
        }
        model: ListModel {}
        VerticalScrollDecorator {}
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
    function populate() {
        // Load favorites from the Python backend.
        listView.model.clear();
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < favorites.length; i++)
            listView.model.append(favorites[i]);
    }
}
