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
    property var downloadTime: -1
    property bool loading: false
    property bool populated: false
    property var props: {}
    property var results: {}
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
                text: qsTranslate("", "Filter lines")
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
                        for (var i = 0; i < view.model.count; i++) {
                            var item = view.model.get(i);
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
            view.model.clear();
            page.loading = true;
            page.title = "";
            busy.text = qsTranslate("", "Loading");
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
        var key = page.props.key;
        py.call("hts.app.favorites.find_departures", [key], function(results) {
            if (results && results.error && results.message) {
                if (!silent) {
                    page.title = "";
                    busy.error = results.message;
                }
            } else if (results && results.length > 0) {
                view.model.clear();
                page.lineWidth = 0;
                page.timeWidth = 0;
                page.results = results;
                page.title = page.props.name;
                var skip = py.call_sync("hts.app.favorites.get_skip_lines", [key]);
                for (var i = 0; i < results.length; i++) {
                    results[i].color = "#aaaaaa";
                    results[i].visible = skip.indexOf(results[i].line) < 0;
                    view.model.append(results[i]);
                }
            } else {
                if (!silent) {
                    page.title = "";
                    busy.error = qsTranslate("", "No departures found");
                }
            }
            page.downloadTime = Date.now();
            page.loading = false;
            page.populated = true;
            view.forceLayout();
            page.update();
        });
        app.cover.update();
    }
    function update() {
        if (Date.now() - page.downloadTime > 300000) {
            // Load new departures from the API.
            page.populate(true);
        } else {
            page.updateTimes();
            page.updateWidths();
            app.cover.update();
        }
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
