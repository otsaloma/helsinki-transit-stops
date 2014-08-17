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
    SilicaListView {
        id: listView
        anchors.fill: parent
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: ListItem {
        }
        footer: Column {
            width: parent.width
            ListItem {
                id: aboutItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
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
                ListItemLabel {
                    color: findNearbyItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: "Find nearby stops"
                }
            }
            ListItem {
                id: findByNameItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    color: findByNameItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: "Find stops by name"
                }
            }
        }
        model: ListModel {
        }
        VerticalScrollDecorator {}
    }
}
