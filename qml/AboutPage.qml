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
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        Column {
            id: column
            width: parent.width
            PageHeader { title: "About Helsinki Transit Stops" }
            ListItemLabel {
                height: Theme.itemSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                text: "version " + py.evaluate("hts.__version__")
            }
            ListItemLabel {
                font.pixelSize: Theme.fontSizeSmall
                height: Theme.itemSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                linkColor: Theme.highlightColor
                text: '<a href="http://github.com/otsaloma/helsinki-transit-stops">http://github.com/otsaloma/helsinki-transit-stops</a>'
                wrapMode: Text.WordWrap
                onLinkActivated: Qt.openUrlExternally(link);
            }
            ListItemLabel {
                font.pixelSize: Theme.fontSizeSmall
                height: Theme.itemSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                text: "Copyright © 2014–2015 Osmo Salomaa"
            }
            ListItemLabel {
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                height: implicitHeight + Theme.paddingLarge
                text: "Helsinki Transit Stops is free software released under the GNU General Public License (GPL), version 3 or later."
                wrapMode: Text.WordWrap
            }
        }
        VerticalScrollDecorator {}
    }
}
