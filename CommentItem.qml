import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox

    property var commentObj
    property int level: 1
    property var replyObjects: commentObj && commentObj.data.replies.data ? commentObj.data.replies.data.children : []
    property string vote: commentObj ? commentObj.data.likes === true ? "up" : commentObj.data.likes === false ? "down" : "" : ""

    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)
    readonly property color backgroundColor: isLevelOdd ? primaryColor : altColor

    anchors {
        left: parent.left
        leftMargin: units.gu(1)
        right: parent.right
        rightMargin: level === 1 ? units.gu(1) : 0
    }

    height: commentListView.height

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
            replyListModel.append({kind: replyObjects[i].kind, level: level + 1, index: i})
        }
        if (replyObjects.length === 0) replyListModel.append({kind: "", level: level + 1, index: -1})
    }

    ListView {
        id: commentListView
        //Note: All comments have at least one reply element, even if it has no actual replies.
        //This is to ensure that the header(which contains the actual comment) and the footer are instantiated properly

        property real internalPadding: units.gu(1)

        width: parent.width
        height: count > 0 ? contentHeight : 47; interactive: false
        spacing: units.gu(0.6)

        header: Item {
            anchors { left: parent.left; right: parent.right }
            height: commentInfo.height + commentBody.height + commentListView.internalPadding * 2.5

            Rectangle {
                property real size: units.gu(1)
                property string vote: swipeBox.vote
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: commentListView.internalPadding
                    rightMargin: commentListView.internalPadding
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
                    topMargin: commentListView.internalPadding
                    left: parent.left
                    leftMargin: commentListView.internalPadding
                    right: parent.right
                    rightMargin: commentListView.internalPadding
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
                    topMargin: commentListView.internalPadding/2
                    left: parent.left
                    leftMargin: commentListView.internalPadding
                    right: parent.right
                    rightMargin: commentListView.internalPadding
                }
                wrapMode: Text.Wrap
                fontSize: "small"
                color: UbuntuColors.coolGrey
                onLinkActivated: openPostContent(link)
            }
        }

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
                item.level = level
                if(kind === "t1") {
                    item.commentObj = swipeBox.replyObjects[index]
                } else if (kind === "more") {
                    item.moreObj = swipeBox.replyObjects[index]
                }
            }
        }

        footer: Item {
            height: commentListView.spacing
            width: 1
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: commentListView
        color: swipeBox.backgroundColor
        z: -2
        radius: units.gu(0.6)
    }
}
