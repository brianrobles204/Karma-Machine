//QReddit does not yet support moderator actions, user account creation, nor wiki actions
var API = {
    //*Links and Comments
    'login': '/api/login',
    'logout': '/logout',
    'comment': '/api/comment',
    'del': '/api/del',
    'editusertext': '/api/editusertext',
    'hide': '/api/hide',
    //'info': '/api/info',
    'morechildren': '/api/morechildren',
    'report': '/api/report',
    'save': '/api/save',
    'submit': '/api/submit',
    'unhide': '/api/unhide',
    'unsave': '/api/unsave',
    'vote': '/api/vote',

    //*Listings
    'comments': '/comments/%s',
    'hot': '[/r/%s]/hot',
    'new': '[/r/%s]/new',
    'rising': '[/r/%s]/rising',
    //'random': '[/r/%s]/random',
    'top': '[/r/%s]/top',
    'controversial': '[/r/%s]/controversial',
    'message': '/message/%s',
    'search': '[/r/%s]/search',

    //*Private Messages
    'block': '/api/block',
    'compose': '/api/compose',
    'read_message': '/api/read_message',
    'unread_message': '/api/unread_message',

    //*Subreddits
    'search_reddit_names': '/api/search_reddit_names.json',
    'subreddit_recommendations': '/api/subreddit_recommendations',
    'subreddits_by_topic': '/api/subreddits_by_topic',
    'subreddit_about': '/r/%s/about',
    //Subreddit Listings
    'subreddits_search': '/subreddits/search',
    'subreddits_popular': '/subreddits/popular',
    'subreddits_new': '/subreddits/new',
    'subreddits_banned': '/subreddits/banned',
    'subreddits_mine': '/subreddits/mine/%s',
    'subreddits_default': '/reddits',

    //*Users
    'friend': '/api/friend',
    'unfriend': '/api/unfriend',
    'user_about': '/user/%s/about',
    //User Listings
    'user_where': '/user/%s/%s'
};

var SSLPaths = ['login'];
var GETPaths = ['comments', 'hot', 'new', 'rising', 'random', 'top', 'controversial', 'message', 'search',
                'subreddit_recommendations', 'subreddits_by_topic', 'subreddit_about', 'subreddits_search',
                'subreddits_new', 'subreddits_popular', 'subreddits_banned', 'subreddits_mine', 'subreddits_default',
                'user_about', 'user_where']
var DefaultURL = 'www.reddit.com';
var SecureURL = 'ssl.reddit.com';

var PostsSort = {
    Hot: 'hot',
    New: 'new',
    Top: 'top',
    Controversial: 'controversial',
    Rising: 'rising'
};

var SearchSort = {
    Hot: 'hot',
    New: 'new',
    Top: 'top',
    Relevance: 'relevance'
};

var CommentsSort = {
    Hot: 'hot',
    New: 'new',
    Top: 'top',
    Controversial: 'controversial',
    Best: 'confidence',
    Old: 'old',
    Random: 'random'
};

var TimeFilter = {
    Hour: 'hour',
    Day: 'day',
    Week: 'week',
    Month: 'month',
    Year: 'year',
    All: 'all'
}


function createObject(ObjectStr) {
    var component = Qt.createComponent(ObjectStr);
    return component.createObject(Qt.application);
}

function createTimer(timeout) {
    return Qt.createQmlObject('import QtQuick 2.0; Timer{ interval: ' + timeout + '; running: true; repeat: false}', Qt.application);
}


var BaseReddit = function() {
    this.modhash = "";

    this.toString = function() {
        return "[object BaseRedditObject]"
    }

    this._getConnection = function(method, url, actionObj) {
        var request = new XMLHttpRequest();
        var connObj = createObject("ConnectionObject.qml");
        var timeout = 30000;
        console.log(url);

        var timer = createTimer(timeout);
        timer.onTriggered.connect(function(){
            if(request.readyState !== request.DONE) {
                connObj.raiseRetry();
                timer.destroy();
            }
        });

        connObj.onAbort.connect(function(){
            request.abort();
        });

        request.open(method, url, true);
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        request.setRequestHeader("User-Agent", this.userAgent);
        request.setRequestHeader("Connection", "close");
        if(this.modhash !== "") request.setRequestHeader("X-Modhash", this.modhash);

        request.onreadystatechange = function() {
            if (request.readyState == request.DONE) {
                if(timer.stop) {
                    timer.stop();
                    timer.destroy();
                }
                if (request.status == 200) {
                    var response = JSON.parse(request.responseText);
                    connObj.connectionSuccess(response);
                } else {
                    connObj.error("Could not connect to Reddit.");
                }
            }
        }

        request.send();
        return connObj;
    }


    this.getAPIConnection = function(apiCommand, paramObj) {
        var redditURL = 'http://' + DefaultURL;
        var method = 'POST';
        var paramStr = '';

        if (!paramObj) paramObj = {};

        if(SSLPaths.indexOf(apiCommand) !== -1) {
            redditURL = 'https://' + SecureURL;
        }

        var apiCommandArray = apiCommand.split(' ');
        var apiBaseCommand = apiCommandArray[0];
        var apiUrl = API[apiBaseCommand];
        var i = 1;
        apiUrl = apiUrl.replace(/\[(.*?)\]|(%s)/g, function(match, p1, p2) {
            if(i >= apiCommandArray.length) return "";
            var replacedText = "";

            if(p1) {
                //Match is inside brackets. Remove brackets and replace %s
                replacedText = p1.replace('%s', apiCommandArray[i]);
            } else if (p2) {
                //Match is just %s. Simply replace it.
                replacedText = apiCommandArray[i];
            }

            i++;
            return replacedText;
        });

        redditURL += apiUrl;

        if(GETPaths.indexOf(apiBaseCommand) !== -1) {
            redditURL += '.json';
            method = 'GET';
        } else {
            paramObj['api_type'] = 'json'
        }

        //if(this.modhash !== "") paramObj['uh'] = this.modhash;

        for (var key in paramObj) {
            if(paramStr !== "") paramStr += "&"
            paramStr += key + "=" + encodeURIComponent(paramObj[key]);
        }

        if(paramStr !== "") redditURL += "?" + paramStr;

        return this._getConnection(method, redditURL);
    }
}

var SubredditObj = function (reddit, srName) {
    this.srName = srName || "";
    this.currentCommand = "";
    this.currentParamObj = {};
    this.data = {};

    function getCommand(command) {
        if(srName !== "" && srName !== undefined) command += " " + srName;
        return command;
    }

    function getPostObjArray(postArray) {
        var postObjArray = [];
        for(var i = 0; i < postArray.length; i++) {
            postObjArray.push(new PostObj(reddit, postArray[i]));
        }
        return postObjArray;
    }

    this.toString = function() {
        return "[object SubredditObject]"
    }

    this._setCurrentProperties = function(apiCommand, paramObj) {
        this.currentCommand  = apiCommand;
        this.currentParamObj = paramObj;
        this.data = {};
    }

    this.getPostsListing = function(sort, paramObj) {
        //Returns a Connection object. Has a response property containing the Posts Array.
        var apiCommand = getCommand(sort);
        paramObj = paramObj || {};
        paramObj.limit = paramObj.limit || 25;
        this._setCurrentProperties(apiCommand, paramObj);

        var connSubrObj = reddit.getAPIConnection(apiCommand, paramObj);
        var that = this;

        connSubrObj.onConnectionSuccess.connect(function(response){
            that.data = response.data;
            var postObjArray = getPostObjArray(response.data.children)
            that.data.children = postObjArray;
            connSubrObj.response = postObjArray;
            connSubrObj.success();
        });

        return connSubrObj;
    }

    this.getSearchListing = function(sort, query, paramObj) {
        //Returns a Listing object
    }

    this.getMoreListing = function(limitNo) {
        //Returns a Connection object. Has a response property containing the Posts Array.
        if (this.currentCommand === "") throw "Error: getMoreListing(): Cannot get more."

        var paramObj = this.currentParamObj;
        paramObj.limit = limitNo || paramObj.limit || 25;
        paramObj.after = this.data.after;

        var connMoreObj = reddit.getAPIConnection(this.currentCommand, paramObj);
        var that = this;

        connMoreObj.onConnectionSuccess.connect(function(response){
            var postObjArray = getPostObjArray(response.data.children)
            that.data.children.push(postObjArray);
            that.data.after = response.data.after;
            connMoreObj.response = postObjArray;
            connMoreObj.success();
        });

        return connMoreObj;
    }
}

var BaseThing = function(reddit, thing) {

    for (var key in thing) {
        this[key] = thing[key];
    }

    this.toString = function() {
        return "[object BaseThing]"
    }

    this.comment = function(text) {
        //Submit a new comment or reply to a message
        //Returns a Connection Object. Has a response property containing the new comment/reply
        var commentConnObj = reddit.getAPIConnection('comment', {
                                                         text: text,
                                                         thing_id: this.data.name
                                                     });
        var that = this;
        commentConnObj.onConnectionSuccess.connect(function(response){
            if(response.json.data) {
                var comment = response.json.data.things[0]
                //Reddit returns a "thing" object, but its interface differs from a normal comment/reply
                //Here, we extend it so it behaves like normal.
                comment.data.name = comment.data.id;
                comment.data.body = comment.data.contentText;
                comment.data.author = reddit.notifier.currentAuthUser;
                comment.data.likes = true;
                comment.data.created = comment.data.created_utc = Math.floor(Date.now() / 1000);
                comment.data.score = comment.data.ups = 1;
                comment.data.downs = 0;

                if (that.toString() === "[object CommentObject]" || that.toString() === "[object PostObject]") {
                    commentConnObj.response = new CommentObj(reddit, comment);
                } //TODO handle replies to message objects

                commentConnObj.success();
            } else {
                commentConnObj.error(response.json.errors[0][1]);
            }
        });

        return commentConnObj;
    }

    this.report = function() {
        //
    }
}

var ThingObj = function(reddit, thing) {

    BaseThing.apply(this, arguments);

    this.toString = function() {
        return "[object ThingObject]"
    }

    this.deleteThing = function() {
        //Simple `delete` is a reserved name in javascript
    }

    this.edit = function(text) {
        //
    }

    this.vote = function(direction) {
        //direction is an int. One of (0, 1, -1)
        var voteConnObj = reddit.getAPIConnection("vote", {
                                                    dir: direction,
                                                    id: this.data.name
                                                });
        var that = this;
        voteConnObj.onConnectionSuccess.connect(function(response){
            if(direction === 0) {
                that.data.likes = null
            } else if(direction === 1) {
                that.data.likes = true
            } else if(direction === -1) {
                that.data.likes = false
            }

            voteConnObj.success()
        })
        return voteConnObj
    }

    this.unvote = function() {
        //Un-votes a thingObj.
        return this.vote(0);
    }

    this.upvote = function() {
        //Either upvotes or un-votes a thingObj, based on its current vote direction
        if (!(this.data.likes === true)) {
            return this.vote(1);
        } else {
            return this.unvote();
        }
    }

    this.downvote = function() {
        //Either downvotes or un-votes a thingObj, based on its current vote direction
        if (!(this.data.likes === false)) {
            return this.vote(-1);
        } else {
            return this.unvote();
        }
    }

}

var PostObj = function(reddit, post) {

    ThingObj.apply(this, arguments);

    function getCommentsObjArray(commentsArray) {
        var commentsObjArray = [];
        for(var i = 0; i < commentsArray.length; i++) {
            commentsObjArray.push(new CommentObj(reddit, commentsArray[i]));
        }
        return commentsObjArray;
    }

    this.toString = function() {
        return "[object PostObject]"
    }

    this.hide = function() {
        //
    }

    this.save = function() {
        //
    }

    this.unhide = function() {
        //
    }

    this.unsave = function() {
        //
    }

    //TODO: Deprecate this in favor of getComments(), which returns the entire response as opposed to simply the listing
    this.getCommentsListing = function(sort, paramObj) {
        paramObj = paramObj || {};
        paramObj.sort = sort;
        var apiCommand = 'comments ' + this.data.id;

        var commentsConnObj = reddit.getAPIConnection(apiCommand, paramObj);
        commentsConnObj.onConnectionSuccess.connect(function(response){
            var commentsObjArray = getCommentsObjArray(response[1].data.children)
            commentsConnObj.response = commentsObjArray;
            commentsConnObj.success();
        });

        return commentsConnObj;
    }
}

var CommentObj = function(reddit, comment) {

    ThingObj.apply(this, arguments);

    this.toString = function() {
        return "[object CommentObject]"
    }
}

var UserObj = function(reddit, username) {

    this.toString = function() {
        return "[object UserObject]"
    }

    this.getActivityListing = function(where) {
        where = where || "overview";
    }
}
