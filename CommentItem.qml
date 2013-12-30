import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox

    property var commentObj
    property int level: 1
    property var replyObjects: commentObj && commentObj.data.replies.data ? commentObj.data.replies.data.children : []
    property string vote: commentObj ? commentObj.data.likes === true ? "up" : commentObj.data.likes === false ? "down" : "" : ""

    property real internalPadding: units.gu(1)
    property real bottomPadding: isMinimizeable && !isMinimized ? units.gu(0.6) : 0
    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)
    readonly property color backgroundColor: isLevelOdd ? primaryColor : altColor
    readonly property int replyNo: {
        var number = 0
        var replyList = replyColumn.children
        for (var i = 0; i < replyList.length; i++) {
            var replyItem = replyList[i].item
            if (replyItem) {
                number += replyItem.replyNo
                if(replyItem.commentObj) number += 1
            }
        }
        return number
    }

    property bool isMinimizeable: replyObjects.length > 0
    property bool isMinimized: false

    signal minimize()
    signal maximize()

    function appendReply(replyObj) {
        replyObjects.push(replyObj)
        replyListModel.append({kind: replyObj.kind, index: replyObjects.length - 1})
    }

    anchors {
        left: parent.left
        leftMargin: units.gu(1)
        right: parent.right
        rightMargin: level === 1 ? units.gu(1) : 0
    }

    height: commentInfo.height + commentBody.height + replyColumn.height + minimizeRect.height + internalPadding * 1.5 + bottomPadding

    onSwipedRight: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = commentObj.upvote()
            commentObjChanged()
            voteConnObj.onSuccess.connect(function(){
                commentObjChanged()
            })
        }
    }
    onSwipedLeft: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = commentObj.downvote()
            commentObjChanged()
            voteConnObj.onSuccess.connect(function(){
                commentObjChanged()
            })
        }
    }
    onClicked: {
        if(!isMinimizeable) return
        if(isMinimized) {
            maximize()
        } else {
            minimize()
        }
    }

    onMinimize: {
        heightBehavior.enabled = true
        isMinimized = true
        enableBehaviorTimer.restart()
    }
    onMaximize: {
        heightBehavior.enabled = true
        isMinimized = false
        enableBehaviorTimer.restart()
    }

    onReplyObjectsChanged: {
        replyListModel.clear()
        for (var i = 0; i < replyObjects.length; i++) {
            replyListModel.append({kind: replyObjects[i].kind, index: i})
        }
    }

    onContentXChanged: {
        //Disable the reply comments from being swiped as well
        replyColumn.x = contentX
    }

    Timer {
        id: enableBehaviorTimer
        interval: UbuntuAnimation.BriskDuration
        onTriggered: heightBehavior.enabled = false
    }

    Behavior on height {
        id: heightBehavior
        enabled: false
        UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration }
    }

    EmblemRow {
        id: emblemRow
        thingObj: commentObj
        padding: swipeBox.internalPadding
        animate: false
    }

    Label {
        id: commentInfo

        function generateText(inlineFlair) {
            var author = commentObj ? commentObj.data.author : "[:(]"
            var includeFlair = commentObj && typeof commentObj.data.author_flair_text === "string" && commentObj.data.author_flair_text !== ""
            var score = commentObj ? (commentObj.data.ups - commentObj.data.downs) : 0
            var timeRaw = commentObj ? commentObj.data.created_utc : new Date()
            var time = MiscUtils.timeSince(new Date(timeRaw * 1000))

            var infoText = "<b>"
            if (commentObj && commentObj.data.distinguished === "admin"){
                infoText += "<font color='#DF4D4D'>" + author + " [a]</font>"
            } else if (commentObj && commentObj.data.distinguished === "moderator"){
                infoText += "<font color='#6EAF6E'>" + author + " [m]</font>"
            } else if(activePostObj && author === activePostObj.data.author) {
                infoText += "<font color='#6E8CAF'>" + author + " [s]</font>"
            } else {
                infoText += author
            }

            infoText += "</b>"
            if(includeFlair && inlineFlair) {
                infoText += " <b>·</b> " + commentObj.data.author_flair_text
            }
            infoText += " <b>·</b> "

            if(commentObj && commentObj.data.score_hidden) {
                infoText += "[score hidden]"
            } else {
                infoText += score + " points"
            }

            infoText += " <b>·</b> " + time
            if(includeFlair && !inlineFlair) {
                infoText += "<br/>&nbsp; <font color='#a5a5a5'>" + commentObj.data.author_flair_text + "</font>"
            }

            return infoText
        }

        function updateInfo() {
            text = generateText(true)
            wrapMode = Text.NoWrap
            if(contentWidth > width) {
                text = generateText(false)
                wrapMode = Text.Wrap
            }
        }

        text: "Loading…"
        anchors {
            top: parent.top
            topMargin: swipeBox.internalPadding
            left: parent.left
            leftMargin: swipeBox.internalPadding
            right: emblemRow.left
            rightMargin: swipeBox.internalPadding
        }
        fontSize: "x-small"
        lineHeight: 1.2
        color: "#999999"

        Connections {
            target: swipeBox
            onCommentObjChanged: commentInfo.updateInfo()
            onWidthChanged: commentInfo.updateInfo()
        }
    }

    Label {
        id: commentBody
        text: commentObj ? MiscUtils.getHtmlText(commentObj.data.body, bgRect.color) : ""
        textFormat: Text.RichText
        anchors {
            top: commentInfo.bottom
            topMargin: swipeBox.internalPadding/2
            left: parent.left
            leftMargin: swipeBox.internalPadding
            right: parent.right
            rightMargin: swipeBox.internalPadding
        }
        wrapMode: Text.Wrap
        fontSize: "small"
        color: UbuntuColors.coolGrey
        onLinkActivated: openPostContent(link)
    }

    Column {
        id: replyColumn

        property bool isMinimized: swipeBox.isMinimized
        property real defaultHeight: !isMinimized ? implicitHeight: 0

        anchors {
            top: commentBody.bottom
        }
        width: parent.width
        height: defaultHeight;
        spacing: units.gu(0.6)
        opacity: !isMinimized ? 1 : 0
        visible: opacity !== 0

        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration } }

        Item { width: 1; height: swipeBox.internalPadding - replyColumn.spacing }

        Repeater {
            id: replyRepeater
            model: ListModel {
                id: replyListModel
            }

            delegate: Loader {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                source: {
                    if(kind === "t1") {
                        return "CommentItem.qml"
                    } else if (kind === "more") {
                        return "MoreItem.qml"
                    } else {
                        return ""
                    }
                }
                Component.onCompleted: {
                    item.level = level + 1
                    if(kind === "t1") {
                        item.commentObj = swipeBox.replyObjects[index]
                    } else if (kind === "more") {
                        item.moreObj = swipeBox.replyObjects[index]
                        item.parentComment = swipeBox
                        item.onDestroyItem.connect(function(){
                            replyListModel.remove(replyListModel.count - 1)
                        })
                    }
                }
            }
        }
    }

    Item {
        id: minimizeRect

        property real padding: units.gu(1)
        property real defaultHeight: swipeBox.isMinimized ? minimizeLabel.height + 2*padding : 0

        anchors {
            top: replyColumn.bottom
            left: parent.left
            leftMargin: swipeBox.internalPadding
            right: parent.right
        }
        height: defaultHeight
        opacity: swipeBox.isMinimized ? 1 : 0
        visible: opacity !== 0

        Behavior on opacity { UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration } }

        Label {
            id: minimizeLabel
            text: swipeBox.replyNo !== 1 ? swipeBox.replyNo + " Hidden comments" : "One hidden comment"
            fontSize: "x-small"
            font.weight: Font.Bold
            color: "#999999"
            anchors {
                top: parent.top
                topMargin: minimizeRect.padding
                left: parent.left
                leftMargin: minimizeRect.padding
            }
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: swipeBox.backgroundColor
        z: -2
        radius: units.gu(0.6)
    }
}
