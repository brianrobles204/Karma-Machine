import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox
    property var postObj
    height: descHeader.height + divider.height + descContent.height
    anchors {
        left: parent.left
        right: parent.right
    }
    /*property string vote: postObj.data.likes === true ? "up" : postObj.data.likes === false ? "down" : ""
    onPostObjChanged: console.log("vote: " + vote)*/
    property string vote: ""

    onPostObjChanged: {
        vote = postObj.data.likes === true ? "up" : postObj.data.likes === false ? "down" : ""
    }

    onSwipedRight: {
//        if(storageHandler.modhash !== "") {
//            if(vote == "up") {
//                vote = ""
//                actionHandler.unvote(postObj.data.name)
//            } else {
//                vote = "up"
//                actionHandler.upvote(postObj.data.name)
//            }
//        }
    }
    onSwipedLeft: {
//        if(storageHandler.modhash !== "") {
//            if(vote == "down") {
//                vote = ""
//                actionHandler.unvote(postObj.data.name)
//            } else {
//                vote = "down"
//                actionHandler.downvote(postObj.data.name)
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

            readonly property variant hasContent: post ? post.data.selftext !== "" : false
            property variant post: swipeBox.postObj

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
                topMargin: units.gu(1)
            }
            text: post ? MiscUtils.getHtmlText(post.data.selftext, "#f2f2f2") : ""
            textFormat: Text.RichText
            fontSize: "small"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            color: UbuntuColors.coolGrey
            onLinkActivated: openPostContent(link)
        }
        Rectangle {
            id: descContentBG
            anchors.fill: parent
            color: "#f2f2f2"
            z: -1
        }
    }
}
