import QtQuick 2.0
import QtWebKit 3.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Layouts 0.1
import "Utils/Misc.js" as MiscUtils
import "QReddit/QReddit.js" as QReddit

MainView {
    objectName: "mainView"
    applicationName: "com.ubuntu.developer.brianrobles204.karma-machine"
    id: window
    automaticOrientation: true
    anchorToKeyboard: true

    width: units.gu(45)
    //width: units.gu(120)
    height: units.gu(71)

    backgroundColor: "#dadada"

    Layouts { id: dummyLayout; anchors.fill: parent;}
    property bool isPhone: dummyLayout.width <= units.gu(85)
    property string bigTitle: frontPageItem.title
    property string littleTitle: postPageItem.subTitle
    property bool linkOpen: postPageItem.linkOpen
    property variant currentPage: pageStack.currentPage
    property bool canBeToggled: postPageItem.canBeToggled

    property var redditObj: new QReddit.QReddit("Karma Machine Reddit App 0.78", "karma-machine")
    property var redditNotifier: redditObj.notifier

    function togglePostPageItem() {
        postPageItem.toggle()
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        Component.onCompleted: {
            pageStack.push(frontPage)
        }

        Page {
            id: frontPage
            visible: false
            title: isPhone ? frontPageItem.title : " "
            flickable: isPhone ? frontPageItem.flickable : dummyFlickable

            /*Rectangle{
                id: debugtangle
                width: units.gu(30)
                height: units.gu(20)
                anchors.centerIn: parent
                color: "#fafafa"
                z: 10000000000
                Label {
                    property string testText: "&gt;te&lt;s&gt;lol&lt;/s&gt;t\n
&gt;&gt;test &gt;this&gt; is a &gt;&gt;test"
                    text: MiscUtils.getHtmlText(testText, "#fafafa")
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                }
            }*/

            onStateChanged: {
                if(state == "tabletState") {
                    if(pageStack.currentPage == postPage ) {
                        pageStack.pop()
                    }
                } else {
                    //TODO: be smarter
                    //if the current post is not visible on the frontPage, go back to the frontPage
                    //if we go from phoneLayout(frontPage) to tabletLayout to back to phoneLayout, make sure it's on frontPage
                    if(postPageItem.internalModel) {
                        pageStack.push(postPage)
                    }
                }
            }

            states: [
                State {
                    name: "phoneState"
                    when: isPhone
                    PropertyChanges {
                        target: frontPageItem
                        anchors.fill: parent
                        anchors.topMargin: 0
                    }
                    ParentChange {
                        target: postPageItem
                        parent: postPage
                    }
                    PropertyChanges {
                        target: postPageItem
                        anchors.topMargin: 0
                        anchors.fill: parent
                    }

                    ParentChange {
                        target: postPageToolbarButtons
                        parent: postPageToolbarContainer
                    }
                },
                State {
                    name: "tabletState"
                    when: !isPhone
                    AnchorChanges {
                        target: frontPageItem
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }
                    PropertyChanges {
                        target: frontPageItem
                        width: parent.width * (0.35) > units.gu(40) ? parent.width * (0.35) : units.gu(40)
                    }
                    PropertyChanges {
                        target: frontPageItem.flickable
                        topMargin: pageStack.header.height
                    }

                    ParentChange {
                        target: postPageItem
                        parent: frontPage
                    }
                    AnchorChanges {
                        target: postPageItem
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: frontPageItem.right
                        anchors.right: parent.right
                    }

                    ParentChange {
                        target: postPageToolbarButtons
                        parent: frontPageToolbarContainer
                    }
                }

            ]

            Flickable {
                id: dummyFlickable
                interactive: false
            }

            FrontPageItem {
                id: frontPageItem
                header: pageStack.header
            }

            PostPageItem {
                id: postPageItem
                //internalModel: linkHandler.internalModel
                z: 100
            }
            Image {
                source: "media/separatorShadow.png"
                width: units.gu(80)
                height: units.gu(3)
                rotation: 270
                opacity: 0.2
                z: 99
                visible: !isPhone
                anchors {
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: pageStack.header.height/2
                    horizontalCenter: frontPageItem.right
                    horizontalCenterOffset: -height/2
                }
            }

            //To disable opening comments when the toolbar is open
            MouseArea {
                anchors.fill: parent
                enabled: frontPageToolbarItems.opened
                z: 300
                onClicked: {return true}
            }

            tools: ToolbarItems{
                id: frontPageToolbarItems
                Item {
                    anchors{
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: frontPage.width - units.gu(4)

                    //dumb workaround for strange problem. Refresh doesn't seem to work sometimes, so this fixes it
                    MouseArea {
                        anchors.fill: frontPageToolbarButtons
                        onClicked: refreshAction.trigger()
                    }

                    Row {
                        id: frontPageToolbarButtons
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }
                        spacing: units.gu(1)
                        z: 1000

                        states: [
                            State {
                                name: "tabletState"
                                when: !isPhone
                                AnchorChanges {
                                    target: frontPageToolbarButtons
                                    anchors.right: undefined
                                    anchors.left: parent.left
                                }
                            }
                        ]

                        ToolbarButton {
                            action: Action {
                                id: refreshAction
                                text: "Refresh"
                                iconSource: "media/toolbar/reload.svg"
                                onTriggered: {
                                    frontPageItem.reloadFrontPage()
                                    frontPageToolbarItems.opened = false
                                }
                            }
                        }
                    }
                    Item {
                        id: frontPageToolbarContainer
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }
                        width: postPageToolbarButtons.width
                        z: -100
                    }
                }
            }
        }

        Page {
            id: postPage
            anchors.fill: parent
            visible: false

            Component {
                id: commentComposerSheetComponent
                ComposerSheet {
                    id: commentComposerSheet
                    title: "Post a Comment"
                    TextArea {
                        id: commentTextArea
                        anchors{
                            fill: parent
                            margins: units.gu(1.5)
                        }
                    }

                    onCancelClicked: PopupUtils.close(commentComposerSheet)
                    onConfirmClicked: {
                        actionHandler.comment(commentTextArea.text, postPageItem.internalModel.data.name)
                        PopupUtils.close(commentComposerSheet)
                    }
                }
            }

            tools: ToolbarItems {
                id: postPageToolbarItems
                Item {
                    id: postPageToolbarContainer
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: postPageToolbarButtons.width

                    Row {
                        id: postPageToolbarButtons
                        visible: postPageItem.internalModel != null
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }
                        spacing: units.gu(1)

                        ToolbarButton {
                            action: Action {
                                text: "Comment"
                                iconSource: "media/Comments.png"
                                enabled: storageHandler.modhash != ""
                                onTriggered: PopupUtils.open(commentComposerSheetComponent) //actionHandler.comment("test", postPageItem.internalModel.data.name)
                            }
                        }
                        ToolbarButton {
                            action: Action {
                                text: "Upvote"
                                iconSource: postPageItem.vote == "up" ? "media/toolbar/up-vote.png" : "media/toolbar/up-empty.png"
                                enabled: storageHandler.modhash != ""
                                onTriggered: {
                                    if(postPageItem.vote == "up") {
                                        postPageItem.vote = ""
                                        actionHandler.unvote(postPageItem.internalModel.data.name)
                                    } else {
                                        postPageItem.vote = "up"
                                        actionHandler.upvote(postPageItem.internalModel.data.name)
                                    }
                                }
                            }
                        }
                        ToolbarButton {
                            action: Action {
                                text: "Downvote"
                                iconSource: postPageItem.vote == "down" ? "media/toolbar/down-vote.png" : "media/toolbar/down-empty.png"
                                enabled: storageHandler.modhash != ""
                                onTriggered: {
                                    if(postPageItem.vote == "down") {
                                        postPageItem.vote = ""
                                        actionHandler.unvote(postPageItem.internalModel.data.name)
                                    } else {
                                        postPageItem.vote = "down"
                                        actionHandler.downvote(postPageItem.internalModel.data.name)
                                    }
                                }
                            }
                        }
                        ToolbarButton {
                            action: Action {
                                text: (linkOpen && postPageItem.__webSection.loading) ? "Cancel" : "Refresh"
                                iconSource: (linkOpen && postPageItem.__webSection.loading) ? "media/toolbar/cancel.png" : "media/toolbar/reload.svg"
                                onTriggered: {
                                    var web = postPageItem.__webSection
                                    if(linkOpen){
                                        if(web.loading){
                                            web.stop()
                                        } else {
                                            web.reload()
                                        }
                                    } else {
                                        postPageItem.reloadComments()
                                    }
                                }
                            }
                        }
                        ToolbarButton {
                            action: Action {
                                text: "Previous"
                                iconSource: "media/toolbar/go-previous.png"
                                enabled:  postPageItem.__webSection.canGoBack
                                onTriggered: postPageItem.__webSection.goBack()
                            }
                            visible: linkOpen
                        }
                        /*ToolbarButton {
                            action: Action {
                                text: "Forward"
                                iconSource: "media/toolbar/go-next.png"
                                enabled: postPageItem.__webSection.canGoForward
                                onTriggered: postPageItem.__webSection.goForward()
                            }
                            visible: linkOpen
                        }*//* Ubuntu Touch does not support services, apparently. No API for opening links externally as of yet
                        //TODO: implement opening links, look at source code of Shorts or something
                        ToolbarButton {
                            action: Action {
                                text: "External"
                                iconSource: "media/toolbar/text-html-symbolic.svg"
                                onTriggered: {
                                    Qt.openUrlExternally(linkOpen ? postPageItem.webUrl : postPageItem.commentsUrl)
                                }
                            }
                        }*/
                    }
                }
            }
        }
    }

    QtObject {
        id: actionHandler
        property string loginStatus: "none"
        property string loginError: ""

        signal finishedLoading

        function upvote(name) {
            vote("1", name)
        }

        function downvote(name) {
            vote("-1", name)
        }

        function unvote(name) {
            vote("0", name)
        }

        function vote(direction, name) {
            var http = new XMLHttpRequest()
            var voteurl = "http://www.reddit.com/api/vote"
            var params = "dir=" + direction + "&id=" + name + "&uh="+storageHandler.modhash+"&api_type=json";
            http.open("POST", voteurl, true);
            console.debug(params)

            // Send the proper header information along with the request
            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            http.setRequestHeader("Content-length", params.length);
            http.setRequestHeader("User-Agent", "Karma Machine Reddit App 0.1")
            http.setRequestHeader("Connection", "close");

            http.onreadystatechange = function() {
                if (http.readyState == 4) {
                    if (http.status == 200) {
                        console.debug(http.responseText)
                        var jsonresponse = JSON.parse(http.responseText)
                        if (jsonresponse.json !== undefined) {
                            console.debug("error")
                        } else {
                            console.debug("Voted!")
                        }
                    } else {
                        console.debug("error: " + http.status)
                    }
                }
            }
            http.send(params);
        }

        function comment(text, thing_id) {
            var http = new XMLHttpRequest()
            var commenturl = "http://www.reddit.com/api/comment"
            var params = "text=" + text + "&thing_id=" + thing_id + "&uh="+storageHandler.modhash+"&api_type=json";
            http.open("POST", commenturl, true);
            console.debug(params)

            // Send the proper header information along with the request
            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            http.setRequestHeader("Content-length", params.length);
            http.setRequestHeader("User-Agent", "Karma Machine Reddit App 0.1")
            http.setRequestHeader("Connection", "close");

            http.onreadystatechange = function() {
                if (http.readyState == 4) {
                    if (http.status == 200) {
                        console.debug(http.responseText)
                        var jsonresponse = JSON.parse(http.responseText)
                        if (jsonresponse.json !== undefined) {
                            console.debug("error")
                        } else {
                            console.debug("Posted!")
                        }
                    } else {
                        console.debug("error: " + http.status)
                    }
                }
            }
            http.send(params);
        }

        function login(username, passwd) {
            var http = new XMLHttpRequest()
            var loginurl = "https://ssl.reddit.com/api/login";
            var params = "user=" + username + "&passwd=" + passwd + "&api_type=json";
            if(storageHandler.autologin) {
                storageHandler.setProp('username', username);
                storageHandler.setProp('passwd', passwd);
                storageHandler.tmpUsername = username
            } else {
                storageHandler.setProp('username', '');
                storageHandler.setProp('passwd', '');
                storageHandler.tmpUsername = username
            }

            http.open("POST", loginurl, true);

            // Only display params, with password, if needed.
            //console.debug(params)

            // Send the proper header information along with the request
            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            http.setRequestHeader("Content-length", params.length);
            http.setRequestHeader("User-Agent", "Karma Machine Reddit App 0.1")
            http.setRequestHeader("Connection", "close");

            http.onreadystatechange = function() {
                if (http.readyState == 4) {
                    if (http.status == 200) {
                        var jsonresponse = JSON.parse(http.responseText)
                        if (jsonresponse.json.data === undefined) {
                            //loginstatus.text = "failed, try again" + "\n" + jsonresponse["json"]["errors"]
                            loginStatus = "error"
                            loginError = jsonresponse["json"]["errors"][0][1]
                            console.debug("error")
                            finishedLoading()
                        } else {
                            // store this user mod hash to pass to later api methods that require you to be logged in
                            //console.log(jsonresponse["json"]["data"]["modhash"])
                            loginStatus = "success"
                            loginError = ""
                            storageHandler.modhash = jsonresponse["json"]["data"]["modhash"]
                            console.debug("success")
                            //reloadTabs()
                            //loginstatus.text = "log in successful"
                            //subredditpagetoolbar.children[6].text = "logout"
                            finishedLoading()
                        }
                    } else {
                        loginStatus = "failed"
                        loginError = ""
                        console.debug("error: " + http.status)
                        finishedLoading()
                        //loginstatus.text = "failed, try again"
                    }
                }
            }
            http.send(params);
        }

        function logout() {
            storageHandler.setProp('username', '')
            storageHandler.setProp('passwd', '')
            storageHandler.setProp('autologin', false)
            storageHandler.setProp('modhash', '')
            storageHandler.setProp('defaultSubList', storageHandler.roDefaultsSubList)
            storageHandler.tmpUsername = 'user'
        }
    }

    QtObject {
        id: linkHandler

        function openLink(link) {
            postPageItem.openLink(link)
        }

        function openNewLink(internalModel) {
            if(internalModel.data.is_self) {
                if(internalModel != postPageItem.internalModel) postPageItem.openComments(internalModel)
            } else {
                postPageItem.openNewLink(internalModel)
            }
            if (isPhone) {
                pageStack.push(postPage)
            }
        }

        function openCommentsIM(internalModel) {
            postPageItem.openComments(internalModel)
            if (isPhone) {
                pageStack.push(postPage)
            }
        }
    }

    QtObject {
        id: storageHandler
        property variant keyArray: ['defaultSubList', 'commentsSort', 'modhash', 'username', 'passwd', 'autologin', 'firstTutorial']
        property string defaultSubList: "Adviceanimals,Askreddit,Aww,Bestof,Books,Earthporn,Explainlikeimfive,Funny,Gaming,Gifs,Iama,Movies,Music,News,Pics,Science,Technology,Television,Todayilearned,Videos,Worldnews,Wtf"
        property string commentsSort: "confidence"
        property string modhash: ""
        property string username: ''
        property string passwd: ''
        property bool autologin: false
        property bool firstTutorial: true

        //temporary values, to be erased on next startup
        property string tmpUsername: 'user'
        property bool tmpIsInitialized: false

        readonly property string roDefaultsSubList: "Adviceanimals,Askreddit,Aww,Bestof,Books,Earthporn,Explainlikeimfive,Funny,Gaming,Gifs,Iama,Movies,Music,News,Pics,Science,Technology,Television,Todayilearned,Videos,Worldnews,Wtf"

        function setProp(name, value) {
            setSetting(name, value)
            storageHandler[name] = getSetting(name)
        }

        function getDatabase() {
             return LocalStorage.openDatabaseSync("karma-machine", "1.0", "StorageDatabase", 1000000);
        }

        function initialize() {
            var db = getDatabase();
            db.transaction(
                function(tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)');
              });
            if (getSetting("initialized") !== "true") {
                // initialize settings
                console.debug("reset settings")
                setSetting("initialized", "true")
                setSetting("defaultSubList", roDefaultsSubList)
                setSetting("commentsSort", "confidence")
                setSetting("modhash", "")
                setSetting("username", '')
                setSetting("passwd", '')
                setSetting("autologin", false)
                setSetting("firstTutorial", true)
            } else {
                //load settings
                for (var i = 0; i < keyArray.length; i++) {
                    var setting = getSetting(keyArray[i])
                    if (setting === '1') {
                        setting = true
                    } else if (setting === '0') {
                        setting = false
                    }

                    if(setting !== "Unknown") storageHandler[keyArray[i]] = setting
                }
            }
            tmpIsInitialized = true
        }

        function setSetting(setting, value) {
            var db = getDatabase();
            var res = "";
            db.transaction(function(tx) {
                var rs = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?);', [setting,value]);
                      //-console.log(rs.rowsAffected)
                      if (rs.rowsAffected > 0) {
                        res = "OK";
                      } else {
                        res = "Error";
                      }
                }
          );
          return res;
        }

        function getSetting(setting) {
           var db = getDatabase();
           var res="";

           try {
               db.transaction(function(tx) {
                 var rs = tx.executeSql('SELECT value FROM settings WHERE setting=?;', [setting]);
                 if (rs.rows.length > 0) {
                      res = rs.rows.item(0).value;
                 } else {
                     res = "Unknown";
                 }
              })
           } catch(e) {
               return "";
           }

          return res
        }

    }

    Component.onCompleted: {
        storageHandler.initialize()
        //if(storageHandler.autologin) actionHandler.login(storageHandler.username, storageHandler.passwd)
        var loginConnObj = redditObj.loginActiveUser()
        loginConnObj.onSuccess.connect(function(){
            frontPageItem.reloadFrontPage()
        })


        var component = Qt.createComponent("HeaderArea.qml")
        var header = component.createObject(pageStack.header)
        pageStack.header.__styleInstance.textColor = "#fafafa"
        pageStack.header.__styleInstance.separatorSource = "media/PageHeaderBaseDividerLight.sci"
    }

}
