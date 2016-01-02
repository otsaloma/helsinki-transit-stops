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
    property var skip: []
    property string title: ""
    // Column widths to be set based on data.
    property int lineWidth: 0
    property int timeWidth: 0
    SilicaListView {
        id: view
        anchors.fill: parent
        delegate: DepartureListItem {}
        header: PageHeader { title: page.title }
        model: ListModel {}
        PullDownMenu {
            visible: !page.loading || false
            MenuItem {
                text: qsTr("Add to favorites")
                onClicked: {
                    var dialog = pageStack.push("AddFavoritePage.qml", {
                        "code": page.props.code,
                        "name": page.props.name
                    });
                    dialog.accepted.connect(function() {
                        var stop = {};
                        stop.code = page.props.code;
                        stop.name = page.props.name;
                        stop.short_code = page.props.short_code;
                        stop.type = page.props.type;
                        stop.x = page.props.x;
                        stop.y = page.props.y;
                        py.call_sync("hts.app.favorites.add_stop", [dialog.key, stop]);
                        menu.populate();
                        py.call("hts.app.save", [], null);
                    });
                }
            }
            MenuItem {
                text: qsTr("Filter lines")
                onClicked: {
                    var dialog = pageStack.push("LineFilterPage.qml", {
                        "codes": [page.props.code],
                        "skip": page.skip
                    });
                    dialog.accepted.connect(function() {
                        for (var i = 0; i < view.model.count; i++) {
                            var item = view.model.get(i);
                            item.visible = dialog.skip.indexOf(item.line) < 0;
                        }
                        page.skip = dialog.skip;
                        page.update();
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
        // Update times remaining and colors periodically.
        interval: 30000
        repeat: true
        running: app.running && page.populated
        triggeredOnStart: true
        onTriggered: page.update();
    }
    Timer {
        // Load more departures from the API periodically.
        // TODO: If the API at some point provides real-time data,
        // we need to drop this interval to around 1-3 minutes.
        interval: 600000
        repeat: true
        running: app.running && page.populated
        triggeredOnStart: false
        onTriggered: page.populate(true);
    }
    onStatusChanged: {
        if (page.populated) {
            return;
        } else if (page.status === PageStatus.Activating) {
            view.model.clear();
            page.loading = true;
            page.title = "";
            busy.text = qsTr("Loading");
        } else if (page.status === PageStatus.Active) {
            page.populate();
        }
    }
    function getModel() {
        // Return list view model with current departures.
        return view.model;
    }
    function populate(silent) {
        // Load departures from the Python backend.
        silent = silent || false;
        silent || view.model.clear();
        var code = page.props.code;
        py.call("hts.query.find_departures", [code], function(results) {
            if (results && results.error && results.message) {
                if (!silent) {
                    page.title = "";
                    busy.error = qsTr(results.message);
                }
            } else if (results && results.length > 0) {
                view.model.clear();
                page.lineWidth = 0;
                page.timeWidth = 0;
                page.results = results;
                page.title = page.props.name;
                for (var i = 0; i < results.length; i++) {
                    results[i].color = "#aaaaaa";
                    results[i].visible = true;
                    view.model.append(results[i]);
                }
            } else {
                if (!silent) {
                    page.title = "";
                    busy.error = qsTr("No departures found");
                }
            }
            page.loading = false;
            page.populated = true;
            view.forceLayout();
            page.update();
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
        for (var i = view.model.count-1; i >= 0; i--) {
            var item = view.model.get(i);
            var dist = gps.position.coordinate.distanceTo(
                QtPositioning.coordinate(item.y, item.x));
            var getTime = "hts.util.format_departure_time";
            var getColor = "hts.util.departure_time_to_color";
            item.time = py.call_sync(getTime, [item.unix_time]);
            item.color = py.call_sync(getColor, [dist, item.unix_time]);
            // Remove departures already passed.
            item.time || view.model.remove(i);
        }
    }
    function updateWidths() {
        // Update column widths based on visible items.
        var lineWidth = 0;
        var timeWidth = 0;
        for (var i = 0; i < view.model.count; i++) {
            var item = view.model.get(i);
            if (item.visible && item.lineWidth)
                lineWidth = Math.max(lineWidth, item.lineWidth);
            if (item.visible && item.timeWidth)
                timeWidth = Math.max(timeWidth, item.timeWidth);
        }
        page.lineWidth = lineWidth;
        page.timeWidth = timeWidth;
    }
}
