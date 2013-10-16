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
    property string query: "$.data.children[*]"
    property bool status: false
    property bool debug: false
    property bool ignoreClearFlag: false

    property string urlBase: 'http://www.reddit.com'
    property string subreddit: ''
    property string filter: 'hot'
    property int limit: 0
    property string before: ''
    property string after: ''
    property string firstArticleId: ''
    property string lastArticleId: ''
    property string time: ''
    property string modhash: storageHandler.modhash

    signal clearCalled
    signal appendCalled
    signal ignoreUsed

    onUrlBaseChanged: __rebuildSource()
    onSubredditChanged: { after=''; before=''; __rebuildSource()}
    onFilterChanged: { after=''; before=''; __rebuildSource()}
    onTimeChanged: { after=''; before=''; __rebuildSource()}
    onModhashChanged: { after=''; before=''; __rebuildSource()}
    onLimitChanged: __rebuildSource()
    onBeforeChanged: __rebuildSource()
    onAfterChanged: __rebuildSource()

    function __rebuildSource() {
        var newSource = urlBase
        if (subreddit != '') {
            newSource += "/r/"+subreddit
        }
        if (filter != '') {
            newSource += "/"+filter
        }
        newSource += ".json"

        newSource += '?'
        if (limit > 0) {
            newSource += "&limit="+limit
        }
        if (before != '') {
            newSource += "&before="+before
        }
        if (after != '') {
            newSource += "&after="+after
        }
        if (modhash != '') {
            newSource += "&uh="+modhash
        }
        if (time != '') {
            if(filter == 'top' || filter == 'controversial') {
                newSource += "&t="+time
            }
        }

        source = debug ? "media/hot.json" : newSource
    }

    onSourceChanged: __loadSource()

    function __loadSource() {
        if(storageHandler && storageHandler.tmpIsInitialized && actionHandler) {
            if (storageHandler.autologin === (actionHandler.loginStatus == "success")) {
                __loadCheckedSource()
            }
        }
    }

    function __loadCheckedSource() {
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
        if (after != '') {
            after = ''
        } else {
            __loadSource()
        }
    }

    function getTutorialPost() {
        var tutorialPost = {
            kind: "t3",
            data: {
                domain: "self.karmaMachine",
                banned_by: null,
                media_embed: { },
                subreddit: "KarmaMachine",
                selftext_html: null,
                selftext: "# A Reddit app\n View the frontpage of the internet on your Ubuntu touch device. Thank you for trying Karma Machine!",
                likes: null,
                secure_media: null,
                saved: false,
                id: "tutorialID",
                secure_media_embed: { },
                clicked: false,
                stickied: true,
                author: "xineoph",
                media: null,
                score: 1234,
                approved_by: null,
                over_18: false,
                hidden: false,
                thumbnail: "karmaMachine.png",
                subreddit_id: "tutorialSubredditID",
                edited: false,
                link_flair_css_class: null,
                author_flair_css_class: null,
                downs: 0,
                is_self: true,
                permalink: "/r/Ubuntu",
                name: "t3_tutorialID",
                created: 1379245312,
                url: "http://www.reddit.com/r/Ubuntu",
                author_flair_text: null,
                title: "Swipe posts (and comments) to the right to upvote, and left to downvote. Try it on this post! (Note: You need to sign in first to cast a vote.)",
                created_utc: 1379216512,
                link_flair_text: null,
                ups: 1234,
                num_comments: 0,
                num_reports: null,
                distinguished: null
            }
        }
        return tutorialPost
    }

    onJsonChanged: updateJSONModel()
    onQueryChanged: updateJSONModel()

    function updateJSONModel() {
        if(!ignoreClearFlag) {
            clear();
            clearCalled();
        } else {
            ignoreClearFlag = false
            ignoreUsed();
        }

        if ( json === "" )
            return;

        if(storageHandler.firstTutorial) {
            var tutorialPost = getTutorialPost()
            append(tutorialPost)
            appendCalled();
        }

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
