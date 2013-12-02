import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox
    property var internalModel
    height: descHeader.height + divider.height + descContent.height
    anchors {
        left: parent.left
        right: parent.right
    }
    /*property string vote: internalModel.data.likes === true ? "up" : internalModel.data.likes === false ? "down" : ""
    onInternalModelChanged: console.log("vote: " + vote)*/
    property string vote: ""

    onInternalModelChanged: {
        vote = internalModel.data.likes === true ? "up" : internalModel.data.likes === false ? "down" : ""
    }

    onSwipedRight: {
//        if(storageHandler.modhash !== "") {
//            if(vote == "up") {
//                vote = ""
//                actionHandler.unvote(internalModel.data.name)
//            } else {
//                vote = "up"
//                actionHandler.upvote(internalModel.data.name)
//            }
//        }
    }
    onSwipedLeft: {
//        if(storageHandler.modhash !== "") {
//            if(vote == "down") {
//                vote = ""
//                actionHandler.unvote(internalModel.data.name)
//            } else {
//                vote = "down"
//                actionHandler.downvote(internalModel.data.name)
//            }
//        }
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

    PostLayout {
        id: descHeader
    }
    Rectangle {
        id: divider
        width: parent.width
        anchors{
            left: parent.left
            top: descHeader.bottom
        }
        height: 1
        color: "transparent"
    }
    Item {
        id: descContent
        visible: descContentLabel.hasContent
        height: descContentLabel.hasContent ? descContentLabel.height + units.gu(2) : 0
        anchors {
            left: parent.left
            top: divider.bottom
        }
        width: parent.width
        Label {
            id: descContentLabel
            property variant hasContent: post ? post.data.is_self : false
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
                topMargin: units.gu(1)
            }

            property variant post: swipeBox.internalModel
            text: post ? MiscUtils.getHtmlText(post.data.selftext, "#f2f2f2") : ""
            textFormat: Text.RichText
            fontSize: "small"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            color: UbuntuColors.coolGrey
            onLinkActivated: linkHandler.openLink(link)
        }
        Rectangle {
            id: descContentBG
            anchors.fill: parent
            color: "#f2f2f2"
            z: -1
        }
    }
}
