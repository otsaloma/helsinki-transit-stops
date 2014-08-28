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
import QtPositioning 5.0
import Sailfish.Silica 1.0
import "."

Page {
    id: page
    allowedOrientations: Orientation.All
    SilicaListView {
        id: listView
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: ListItem {
            id: listItem
            contentHeight: Theme.itemSizeSmall
            menu: contextMenu
            ListView.onRemove: animateRemoval(listItem)
            ListItemColorLabel {
                blockColor: model.color;
                color: listItem.highlighted ?
                    Theme.highlightColor : Theme.primaryColor
                height: Theme.itemSizeSmall
                text: model.name
            }
            ContextMenu {
                id: contextMenu
                MenuItem {
                    text: "Rename"
                    onClicked: {
                        var dialog = pageStack.push("FavoriteDialog.qml", {
                            "name": model.name});
                        dialog.accepted.connect(function() {
                            var args = [model.key, dialog.name];
                            py.call_sync("hts.app.favorites.rename", args);
                            model.name = dialog.name;
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
            onClicked: {
                app.pageStack.push("StopPage.qml", {
                    "favorite": model.key,
                    "stopCode": model.code,
                    "stopName": model.name,
                    "stopType": model.type,
                    "coordinate": QtPositioning.coordinate(model.y, model.x)
                });
            }
        }
        footer: Column {
            width: parent.width
            ListItem {
                id: aboutItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingMedium
                    color: aboutItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: "About Helsinki Transit Stops"
                }
                onClicked: app.pageStack.push("AboutPage.qml");
            }
        }
        header: Column {
            width: parent.width
            PageHeader { title: "Helsinki Transit Stops" }
            ListItem {
                id: findNearbyItem
                contentHeight: Theme.itemSizeSmall
                property bool applicable: gps.position.horizontalAccuracy &&
                    gps.position.horizontalAccuracy >= 0 &&
                    gps.position.horizontalAccuracy < 1000
                ListItemLabel {
                    id: findNearbyLabel
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingMedium
                    color: findNearbyItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    opacity: findNearbyItem.applicable ? 1.0 : 0.4
                    text: "List nearby stops"
                }
                BusyIndicator {
                    anchors.right: findNearbyLabel.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: findNearbyLabel.verticalCenter
                    running: !findNearbyItem.applicable
                    size: BusyIndicatorSize.Medium
                }
                onClicked: {
                    if (findNearbyItem.applicable)
                        app.pageStack.push("NearbyPage.qml");
                }
            }
            ListItem {
                id: findNameItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingMedium
                    color: findNameItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: "Find stop by name"
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
    onStatusChanged: {
        if (page.status == PageStatus.Activating) {
            if (py.ready) {
                page.populate();
            } else {
                py.onReadyChanged.connect(function() {
                    page.populate();
                });
            }
        }
    }
    function populate() {
        // Load favorite stops from the Python backend.
        listView.model.clear();
        var stops = py.evaluate("hts.app.favorites.stops");
        for (var i = 0; i < stops.length; i++) {
            stops[i].color = py.call_sync("hts.util.type_to_color", [stops[i].type]);
            listView.model.append(stops[i]);
        }
    }
}
