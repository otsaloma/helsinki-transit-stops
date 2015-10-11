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
    allowedOrientations: app.defaultAllowedOrientations
    property bool loading: false
    property string populatedQuery: ""
    property var results: {}
    property string title: ""
    SilicaListView {
        id: listView
        anchors.fill: parent
        delegate: StopListItem {
            onClicked: app.pageStack.push("StopPage.qml", {"props": model});
        }
        header: PageHeader { title: page.title }
        model: ListModel {}
        VerticalScrollDecorator {}
    }
    BusyModal {
        id: busy
        running: page.loading
    }
    onStatusChanged: {
        if (page.populatedQuery === app.searchQuery) {
            return;
        } else if (page.status === PageStatus.Activating) {
            listView.model.clear();
            page.loading = true;
            page.title = "";
            busy.text = qsTr("Searching")
        } else if (page.status === PageStatus.Active) {
            page.populate(app.searchQuery);
        }
    }
    function populate(query) {
        // Load stops from the Python backend.
        py.call_sync("hts.app.history.add", [query]);
        listView.model.clear();
        var x = gps.position.coordinate.longitude || 0;
        var y = gps.position.coordinate.latitude || 0;
        py.call("hts.query.find_stops", [query, x, y], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busy.error = qsTr(results.message);
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = qsTr("%n Stops", "", results.length);
                for (var i = 0; i < results.length; i++)
                    listView.model.append(results[i]);
            } else {
                page.title = "";
                busy.error = qsTr("No stops found");
            }
            page.loading = false;
            page.populatedQuery = query;
        });
    }
}
