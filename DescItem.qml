import QtQuick 2.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

SwipeBox{
    id: swipeBox

    property var postObj: activePostObj

    height: descHeader.height + divider.height + descContent.height
    anchors {
        left: parent.left
        right: parent.right
    }

    onSwipedRight: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.upvote()
            activePostObjChanged()
            voteConnObj.onSuccess.connect(function(){
                activePostObjChanged()
            })
        }
    }
    onSwipedLeft: {
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.downvote()
            activePostObjChanged()
            voteConnObj.onSuccess.connect(function(){
                activePostObjChanged()
            })
        }
    }

    PostLayout {
        id: descHeader
        postObj: swipeBox.postObj
    }
    Rectangle {
        id: descHeaderBG
        anchors.fill: descHeader
        color: "#f2f2f2"
        z: -1
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
