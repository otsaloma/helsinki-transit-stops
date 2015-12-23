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
    property bool canCover: true
    property bool loading: false
    property bool populated: false
    property var props: {}
    property var results: {}
    property string title: ""
    // Column widths to be set based on data.
    property int lineWidth: 0
    property int timeWidth: 0
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: DepartureListItem {}
        header: PageHeader { title: page.title }
        model: ListModel {}
        PullDownMenu {
            visible: !page.loading || false
            MenuItem {
                text: qsTr("Filter lines")
                onClicked: {
                    var getCodes = "hts.app.favorites.get_stop_codes";
                    var getSkip = "hts.app.favorites.get_skip_lines";
                    var dialog = pageStack.push("LineFilterPage.qml", {
                        "codes": py.call_sync(getCodes, [page.props.key]),
                        "skip": py.call_sync(getSkip, [page.props.key])
                    });
                    dialog.accepted.connect(function() {
                        var setSkip = "hts.app.favorites.set_skip_lines";
                        py.call_sync(setSkip, [page.props.key, dialog.skip]);
                        for (var i = 0; i < listView.model.count; i++) {
                            var item = listView.model.get(i);
                            item.visible = dialog.skip.indexOf(item.line) < 0;
                        }
                        page.update();
                        py.call("hts.app.save", [], null);
                    });
                }
            }
        }
        VerticalScrollDecorator {}
    }
    BusyModal {
        id: busy
        running: page.loading
    }
    Timer {
        // Assuming we have only schedule data, i.e. not real-time,
        // it is sufficient to download data only once, then update
        // time remaining and colors periodically.
        interval: 30000
        repeat: true
        running: app.running && page.populated
        triggeredOnStart: true
        onTriggered: page.update();
    }
    onStatusChanged: {
        if (page.populated) {
            return;
        } else if (page.status === PageStatus.Activating) {
            listView.model.clear();
            page.loading = true;
            page.title = "";
            busy.text = qsTr("Loading")
        } else if (page.status === PageStatus.Active) {
            page.populate();
        }
    }
    function getModel() {
        // Return list view model with current departures.
        return listView.model;
    }
    function populate() {
        // Load departures from the Python backend.
        listView.model.clear();
        page.lineWidth = 0;
        page.timeWidth = 0;
        var key = page.props.key;
        py.call("hts.app.favorites.find_departures", [key], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busy.error = qsTr(results.message);
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = page.props.name;
                var skip = py.call_sync("hts.app.favorites.get_skip_lines", [key]);
                for (var i = 0; i < results.length; i++) {
                    results[i].color = "#aaaaaa";
                    results[i].visible = skip.indexOf(results[i].line) < 0;
                    listView.model.append(results[i]);
                }
            } else {
                page.title = "";
                busy.error = qsTr("No departures found");
            }
            page.loading = false;
            page.populated = true;
        });
        app.cover.update();
    }
    function update() {
        page.updateTimes();
        page.updateWidths();
        app.cover.update();
    }
    function updateTimes() {
        // Update colors and times remaining to departure.
        for (var i = listView.model.count-1; i >= 0; i--) {
            var item = listView.model.get(i);
            var dist = gps.position.coordinate.distanceTo(
                QtPositioning.coordinate(item.y, item.x));
            var getTime = "hts.util.format_departure_time";
            var getColor = "hts.util.departure_time_to_color";
            item.time = py.call_sync(getTime, [item.unix_time]);
            item.color = py.call_sync(getColor, [dist, item.unix_time]);
            // Remove departures already passed.
            item.time || listView.model.remove(i);
        }
    }
    function updateWidths() {
        // Update column widths based on visible items.
        var lineWidth = 0;
        var timeWidth = 0;
        for (var i = 0; i < listView.model.count; i++) {
            var item = listView.model.get(i);
            if (item.visible && item.lineWidth)
                lineWidth = Math.max(lineWidth, item.lineWidth);
            if (item.visible && item.timeWidth)
                timeWidth = Math.max(timeWidth, item.timeWidth);
        }
        page.lineWidth = lineWidth;
        page.timeWidth = timeWidth;
    }
}
