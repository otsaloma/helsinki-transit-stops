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
    property var codes: []
    property bool loading: false
    property var skip: []
    SilicaGridView {
        id: view
        anchors.fill: parent
        cellWidth: {
            // Use a dynamic column count based on available screen width.
            var width = page.isPortrait ? Screen.width : Screen.height;
            width = width - Theme.horizontalPageMargin;
            return width / Math.floor(width / (Theme.pixelRatio*170));
        }
        // Prevent list items from stealing focus.
        currentIndex: -1
        delegate: ListItem {
            id: listItem
            clip: true
            contentHeight: lineSwitch.height
            width: view.cellWidth
            TextSwitch {
                id: lineSwitch
                checked: model.checked
                description: model.destination
                text: model.line
                // Avoid wrapping description.
                width: 3*page.width
                Component.onCompleted: view.cellHeight = lineSwitch.height;
                onCheckedChanged: view.model.setProperty(
                    model.index, "checked", lineSwitch.checked);
            }
            OpacityRampEffect {
                // Try to match appearance of Label with TruncationMode.Fade.
                direction: OpacityRamp.LeftToRight
                offset: (view.cellWidth - Theme.paddingLarge) / lineSwitch.width
                slope: lineSwitch.width / Theme.paddingLarge
                sourceItem: lineSwitch
            }
        }
        header: DialogHeader {}
        model: ListModel {}
        PullDownMenu {
            visible: !page.loading && view.model.count > 0
            MenuItem {
                text: qsTranslate("", "Mark all")
                onClicked: {
                    for (var i = 0; i < view.model.count; i++)
                        view.model.setProperty(i, "checked", true);
                }
            }
            MenuItem {
                text: qsTranslate("", "Unmark all")
                onClicked: {
                    for (var i = 0; i < view.model.count; i++)
                        view.model.setProperty(i, "checked", false);
                }
            }
        }
        VerticalScrollDecorator {}
    }
    BusyModal {
        id: busy
        running: page.loading
    }
    Component.onCompleted: {
        page.loading = true;
        busy.text = qsTranslate("", "Loading")
        page.populate();
    }
    onAccepted: {
        // Construct an array out of unchecked lines.
        page.skip = [];
        for (var i = 0; i < view.model.count; i++) {
            var item = view.model.get(i);
            item.checked || page.skip.push(item.line);
        }
    }
    function populate() {
        // Load lines from the Python backend.
        view.model.clear();
        py.call("hts.query.find_lines", [page.codes], function(results) {
            if (results && results.error && results.message) {
                busy.error = results.message;
            } else if (results && results.length > 0) {
                for (var i = 0; i < results.length; i++) {
                    results[i].checked = page.skip.indexOf(results[i].line) < 0;
                    view.model.append(results[i]);
                }
            } else {
                busy.error = qsTranslate("", "No lines found");
            }
            page.loading = false;
        });
    }
}
