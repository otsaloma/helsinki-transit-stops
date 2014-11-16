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

SilicaListView {
    id: listView
    anchors.fill: parent
    delegate: ListItem {
        id: listItem
        contentHeight: Theme.itemSizeExtraSmall
        property var result: page.results[index]
        ListView.onRemove: animateRemoval(listItem)
        Label {
            id: lineLabel
            anchors.left: parent.left
            anchors.leftMargin: 2*Theme.paddingLarge + Theme.paddingSmall
            font.pixelSize: Theme.fontSizeLarge
            height: Theme.itemSizeExtraSmall
            horizontalAlignment: Text.AlignRight
            text: model.line
            verticalAlignment: Text.AlignVCenter
            width: page.lineWidth
            Component.onCompleted: {
                if (lineLabel.implicitWidth > page.lineWidth)
                    page.lineWidth = lineLabel.implicitWidth;
            }
        }
        Label {
            id: timeLabel
            anchors.baseline: lineLabel.baseline
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingLarge
            horizontalAlignment: Text.AlignRight
            text: model.time
            verticalAlignment: Text.AlignVCenter
            width: page.timeWidth
            onTextChanged: {
                if (timeLabel.implicitWidth > page.timeWidth)
                    page.timeWidth = timeLabel.implicitWidth;
            }
            Component.onCompleted: {
                if (timeLabel.implicitWidth > page.timeWidth)
                    page.timeWidth = timeLabel.implicitWidth;
            }
        }
        Label {
            id: destinationLabel
            anchors.baseline: lineLabel.baseline
            anchors.left: lineLabel.right
            anchors.leftMargin: Theme.paddingLarge
            anchors.right: timeLabel.left
            anchors.rightMargin: Theme.paddingLarge
            color: Theme.secondaryColor
            text: model.destination
            truncationMode: TruncationMode.Fade
            verticalAlignment: Text.AlignVCenter
            Component.onCompleted: {
                // Add a dotted line long enough for landscape as well.
                var dots = " . . . . . . . . . . . . . . . . . . . .";
                while (dots.length < 200)
                    dots += dots.substr(0, 20);
                var size = Math.max(page.width, page.height);
                while (destinationLabel.implicitWidth < size) {
                    var prev = destinationLabel.implicitWidth;
                    destinationLabel.text += dots;
                    if (destinationLabel.implicitWidth < prev+1) break;
                }
            }
        }
        Rectangle {
            id: block
            anchors.bottom: lineLabel.bottom
            anchors.bottomMargin: Theme.paddingMedium
            anchors.right: lineLabel.left
            anchors.rightMargin: Theme.paddingLarge
            anchors.top: lineLabel.top
            anchors.topMargin: Theme.paddingMedium
            color: model.color
            radius: Theme.paddingSmall/3
            width: Theme.paddingSmall
        }
    }
    header: PageHeader { title: page.title }
    model: ListModel {}
    PullDownMenu {
        visible: !page.loading || false
        MenuItem {
            text: "Add to favorites"
            onClicked: {
                // XXX:
                // var dialog = pageStack.push("FavoriteDialog.qml", {
                //     "name": page.stopName});
                // dialog.accepted.connect(function() {
                //     var key = py.call_sync("hts.app.favorites.add", [
                //         page.stopCode,
                //         dialog.name,
                //         page.stopType,
                //         page.stopCoordinate.longitude,
                //         page.stopCoordinate.latitude
                //     ]);
                //     page.stopKey = key;
                //     page.stopName = dialog.name;
                //     page.title = dialog.name;
                // });
            }
        }
    }
    VerticalScrollDecorator {}
}
