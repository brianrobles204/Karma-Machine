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
    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)
    readonly property color backgroundColor: isLevelOdd ? primaryColor : altColor

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

    height: commentInfo.height + commentBody.height + replyListView.height + internalPadding * 2.5 + units.gu(0.6)

    onSwipedRight: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = commentObj.upvote()
            voteConnObj.onSuccess.connect(function(){
                //Update the comment object (as it does not emit a changed signal automatically)
                commentObjChanged()
            })
        }
    }
    onSwipedLeft: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = commentObj.downvote()
            voteConnObj.onSuccess.connect(function(){
                //Update the comment object (as it does not emit a changed signal automatically)
                commentObjChanged()
            })
        }
    }

    onReplyObjectsChanged: {
        replyListModel.clear()
        for (var i = 0; i < replyObjects.length; i++) {
            replyListModel.append({kind: replyObjects[i].kind, index: i})
        }
        if (replyObjects.length === 0) replyListModel.append({kind: "", index: -1})
    }

    onContentXChanged: {
        //Disable the reply comments from being swiped as well
        replyListView.x = contentX
    }

    Rectangle {
        property real size: units.gu(1)
        property string vote: swipeBox.vote
        anchors {
            top: parent.top
            right: parent.right
            topMargin: swipeBox.internalPadding
            rightMargin: swipeBox.internalPadding
        }
        width: size
        height: size
        radius: size/2
        color: vote == "up" ? "#FF8B60" : "#9494FF"
        visible: vote == "up" || vote == "down"
        z: 100
    }

    Label {
        id: commentInfo
        text: {
            var author = commentObj ? commentObj.data.author : "[:(]"
            var score = commentObj ? (commentObj.data.ups - commentObj.data.downs) : 0
            var timeRaw = commentObj ? commentObj.data.created_utc : new Date()
            var time = MiscUtils.timeSince(new Date(timeRaw * 1000))
            return "<b>" + author + "</b> <b>·</b> " + score + " points <b>·</b> " + time
        }
        anchors {
            top: parent.top
            topMargin: swipeBox.internalPadding
            left: parent.left
            leftMargin: swipeBox.internalPadding
            right: parent.right
            rightMargin: swipeBox.internalPadding
        }
        fontSize: "x-small"
        color: "#999999"
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

    ListView {
        id: replyListView
        //Note: All comments have at least one reply element, even if it has no actual replies.
        //This is to ensure that the header(which contains the actual comment) and the footer are instantiated properly

        anchors {
            top: commentBody.bottom;
            topMargin: swipeBox.internalPadding
        }
        width: parent.width
        height: count > 0 ? contentHeight : 0; interactive: false
        spacing: units.gu(0.6)

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
                if(index === -1) return
                item.level = level + 1
                if(kind === "t1") {
                    item.commentObj = swipeBox.replyObjects[index]
                } else if (kind === "more") {
                    item.moreObj = swipeBox.replyObjects[index]
                    item.index = index
                    item.parentComment = swipeBox
                    item.onDestroyItem.connect(function(indexNo){
                        replyListModel.remove(indexNo)
                    })
                }
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
