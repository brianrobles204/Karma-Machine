import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox

    property var commentObj
    property int level: 1
    property int additionalHeight: 0
    property string vote: commentObj.data.likes === true ? "up" : commentObj.data.likes === false ? "down" : ""

    property color primaryColor: "#f2f2f2"
    property color altColor: "#eaeaea"

    readonly property bool isLevelOdd: ((level % 2) === 1)

    anchors {
        left: parent.left
        leftMargin: units.gu(1) * level
        right: parent.right
        rightMargin: units.gu(1)
    }

    height: commentInfoLabel.height + commentBody.height + units.gu(2.5)

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

    Rectangle {
        property real size: units.gu(1)
        property string vote: swipeBox.vote
        anchors {
            top: parent.top
            right: parent.right
            topMargin: units.gu(1)
            rightMargin: units.gu(1)
        }
        width: size
        height: size
        radius: size/2
        color: vote == "up" ? "#FF8B60" : "#9494FF"
        visible: vote == "up" || vote == "down"
        z: 100
    }

    Label {
        id: commentInfoLabel
        text: {
            var author = commentObj ? commentObj.data.author : "[:(]"
            var score = commentObj ? (commentObj.data.ups - commentObj.data.downs) : 0
            var timeRaw = commentObj ? commentObj.data.created_utc : new Date()
            var time = MiscUtils.timeSince(new Date(timeRaw * 1000))
            return "<b>" + author + "</b> <b>·</b> " + score + " points <b>·</b> " + time
        }
        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(1)
        }
        fontSize: "x-small"
        color: "#999999"
    }

    Label {
        id: commentBody
        text: commentObj ? MiscUtils.getHtmlText(commentObj.data.body, "#000000") : ""
        textFormat: Text.RichText
        anchors {
            top: commentInfoLabel.bottom
            topMargin: units.gu(0.5)
            left: parent.left
            leftMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(1)
        }
        wrapMode: Text.Wrap
        fontSize: "small"
        color: UbuntuColors.coolGrey
        onLinkActivated: openPostContent(link)
    }

    Rectangle {
        id: bgRect
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: parent.height + swipeBox.additionalHeight
        color: swipeBox.isLevelOdd ? primaryColor : altColor
        z: -2
    }
}
