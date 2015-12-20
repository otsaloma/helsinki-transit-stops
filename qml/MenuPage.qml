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
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: FavoriteListItem {
            id: listItem
            menu: ContextMenu {
                id: contextMenu
                MenuItem {
                    text: qsTr("Edit")
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
                    text: qsTr("Remove")
                    onClicked: {
                        remorseAction(qsTr("Removing"), function() {
                            py.call_sync("hts.app.favorites.remove", [model.key]);
                            listView.model.remove(index);
                        });
                    }
                }
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
        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: app.pageStack.push("AboutPage.qml");
            }
            MenuItem {
                text: qsTr("Search")
                onClicked: {
                    app.pageStack.push("SearchPage.qml");
                    app.pageStack.pushAttached("SearchResultsPage.qml");
                }
            }
            MenuItem {
                enabled: gps.ready
                text: qsTr("Nearby")
                onClicked: app.pageStack.push("NearbyPage.qml");
            }
        }
        VerticalScrollDecorator {}
    }
    Label {
        id: onboardLabel
        anchors.centerIn: parent
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
        font.pixelSize: Theme.fontSizeExtraLarge
        horizontalAlignment: Text.AlignHCenter
        opacity: 0.6
        text: qsTr("Once added, favorites appear here. Pull down to search for nearby stops or stops by name or number")
        verticalAlignment: Text.AlignVCenter
        visible: false
        width: parent.width - Theme.paddingLarge*2
        wrapMode: Text.WordWrap
    }
    Timer {
        id: timer
        interval: 5000
        repeat: true
        running: app.applicationActive && gps.ready &&
            listView.model.count > 0
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
    function populate() {
        // Load favorites from the Python backend.
        listView.model.clear();
        var favorites = py.evaluate("hts.app.favorites.favorites");
        for (var i = 0; i < favorites.length; i++) {
            favorites[i].dist = "";
            favorites[i].highlight = false;
            favorites[i].fade = false;
            listView.model.append(favorites[i]);
        }
        if (listView.model.count === 0)
            onboardLabel.visible = true;
    }
    function update() {
        // Update distances based on positioning.
        // Find out which favorite is closest, then round up that distance
        // and highlight all stops closer than that threshold -- e.g.
        // if the closest is 1.3 km away, highlight all closer than 1.5 km.
        if (listView.model.count === 0) return;
        var dists = [];
        for (var i = 0; i < listView.model.count; i++) {
            var item = listView.model.get(i);
            var dist = gps.position.coordinate.distanceTo(
                QtPositioning.coordinate(item.y, item.x));
            dists.push(dist);
        }
        var minDist = Math.min.apply(null, dists);
        var threshold = Math.ceil(minDist / 500) * 500;
        threshold = Math.max(1000, Math.min(3000, threshold));
        for (var i = 0; i < listView.model.count; i++) {
            var item = listView.model.get(i);
            var dist = gps.position.coordinate.distanceTo(
                QtPositioning.coordinate(item.y, item.x));
            item.dist = py.call_sync("hts.util.format_distance", [dist]);
            item.highlight = dist < threshold;
            item.fade = dist >= threshold;
        }
    }
}
