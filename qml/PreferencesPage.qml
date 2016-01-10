/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2015 Osmo Salomaa
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
    allowedOrientations: app.defaultAllowedOrientations
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        contentWidth: parent.width
        Column {
            id: column
            anchors.fill: parent
            PageHeader { title: qsTranslate("", "Preferences") }
            SectionHeader { text: qsTranslate("", "Favorites") }
            TextSwitch {
                id: highlightSwitch
                anchors.left: parent.left
                anchors.right: parent.right
                text: qsTranslate("", "Highlight nearby favorites")
                property bool ready: false
                Component.onCompleted: {
                    var radius = app.conf.get("favorite_highlight_radius") / 1000;
                    highlightSwitch.checked = radius >= 0 && radius <= 5;
                    highlightSwitch.ready = true;
                }
                onCheckedChanged: highlightSlider.save();
            }
            Slider {
                id: highlightSlider
                anchors.left: parent.left
                anchors.right: parent.right
                label: qsTranslate("", "Highlight radius")
                maximumValue: 5
                minimumValue: 0
                stepSize: 0.1
                valueText: "%1 km".arg(value)
                visible: highlightSwitch.checked
                property bool ready: false
                Component.onCompleted: {
                    var radius = app.conf.get("favorite_highlight_radius") / 1000;
                    highlightSlider.value = radius >= 0 && radius <= 5 ? radius : 1;
                    highlightSlider.ready = true;
                }
                onValueChanged: highlightSlider.save();
                function save() {
                    if (!highlightSwitch.ready) return;
                    if (!highlightSlider.ready) return;
                    var radius = highlightSwitch.checked ? highlightSlider.value : 999.999;
                    app.conf.set("favorite_highlight_radius", radius * 1000);
                }
            }
            SectionHeader { text: qsTranslate("", "Departures") }
            ListItemLabel {
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTranslate("", "Show minutes remaining to departure instead of departure time when departure is sooner than cutoff.")
                wrapMode: Text.WordWrap
            }
            Slider {
                id: timeSlider
                anchors.left: parent.left
                anchors.right: parent.right
                label: qsTranslate("", "Departure time cutoff")
                maximumValue: 60
                minimumValue: 0
                stepSize: 1
                valueText: "%1 min".arg(value)
                property bool ready: false
                Component.onCompleted: {
                    var cutoff = app.conf.get("departure_time_cutoff");
                    timeSlider.value = Math.max(0, Math.min(60, cutoff));
                    timeSlider.ready = true;
                }
                onValueChanged: {
                    if (!timeSlider.ready) return;
                    app.conf.set("departure_time_cutoff", timeSlider.value);
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
