import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox
    property variant internalModel
    property Rectangle bgRect: bgRect
    anchors {
        left: parent.left
        leftMargin: units.gu(1)
        right: parent.right
        rightMargin: units.gu(1)
    }
    height: commentInfoLabel.height + commentBody.height + units.gu(2.5)
    property string vote: internalModel.data.likes === true ? "up" : internalModel.data.likes === false ? "down" : ""

    onSwipedRight: {
        if(storageHandler.modhash !== "") {
            if(vote == "up") {
                vote = ""
                actionHandler.unvote(internalModel.data.name)
            } else {
                vote = "up"
                actionHandler.upvote(internalModel.data.name)
            }
        }
    }
    onSwipedLeft: {
        if(storageHandler.modhash !== "") {
            if(vote == "down") {
                vote = ""
                actionHandler.unvote(internalModel.data.name)
            } else {
                vote = "down"
                actionHandler.downvote(internalModel.data.name)
            }
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
            var author = internalModel ? internalModel.data.author : "[:(]"
            var score = internalModel ? (internalModel.data.ups - internalModel.data.downs) : 0
            var timeRaw = internalModel ? internalModel.data.created_utc : new Date()
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
        text: internalModel ? getHtmlText(internalModel.data.body, bgRect.color) : ""
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
        onLinkActivated: linkHandler.openLink(link)
    }

    Rectangle {
        id: bgRect
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: parent.height
        color: "#fafafa"
        z: -2
    }
}
