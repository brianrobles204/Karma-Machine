/* JSONListModel - a QML ListModel with JSON and JSONPath support
 *
 * Copyright (c) 2012 Romain Pokrzywka (KDAB) (romain@kdab.com)
 * Licensed under the MIT licence (http://opensource.org/licenses/mit-license.php)
 */

import QtQuick 2.0
import "JSONListModel/jsonpath.js" as JSONPath

ListModel {
    id: postFeedModel
    property string source: ""
    property string json: ""
    property string query: "$[1].data.children[*]"
    property bool status: false
    property bool debug: false

    property string urlBase: 'http://www.reddit.com/comments'
    property string article: ''
    property string comment: ''
    property string context: ''
    property int limit: 40
    property string depth: ''
    property string sort: 'confidence'

    property string firstArticleId: ''
    property string lastArticleId: ''

    signal clearCalled
    signal appendCalled

    onUrlBaseChanged: __rebuildSource()
    onArticleChanged: __rebuildSource()
    onCommentChanged: __rebuildSource()
    onContextChanged: __rebuildSource()
    onDepthChanged: __rebuildSource()
    onLimitChanged: __rebuildSource()
    onSortChanged: __rebuildSource()

    function __rebuildSource() {
        var newSource = urlBase
        newSource += "/" + article
        newSource += ".json"

        newSource += '?'
        if (comment != '') {
            newSource += "&comment="+comment
        }
        if (context != '') {
            newSource += "&context="+context
        }
        if (limit > 0){
            newSource += "&limit="+limit
        }
        if (depth != '') {
            newSource += "&depth="+depth
        }
        if (sort != '') {
            newSource += "&sort="+sort
        }

        source = article == '' ? source : debug ? "media/comments.json" : newSource
    }

    onSourceChanged: __loadSource()
    function __loadSource() {
        status = false
        console.log('Loading: '+source)
        var xhr = new XMLHttpRequest();
        xhr.open("GET", source);
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE){
                if(json == xhr.responseText) {
                    updateJSONModel()
                } else {
                    json = xhr.responseText;
                }
            }
        }
        xhr.send();
    }

    function reload() {
        __loadSource()
    }

    onJsonChanged: updateJSONModel()
    onQueryChanged: updateJSONModel()

    function updateJSONModel() {
        clear();
        clearCalled();

        if ( json === "" )
            return;

        var objectArray = parseJSONString(json, query);
        for ( var key in objectArray ) {
            var jo = objectArray[key];
            append( jo );
            appendCalled();
        }
        status = true
    }

    function parseJSONString(jsonString, jsonPathQuery) {
        var objectArray = JSON.parse(jsonString);
        if ( jsonPathQuery !== "" )
            objectArray = JSONPath.jsonPath(objectArray, jsonPathQuery);

        if (objectArray) {
            firstArticleId = objectArray[0].data.name
            lastArticleId = objectArray[objectArray.length-1].data.name
        }
        return objectArray;
    }
}
