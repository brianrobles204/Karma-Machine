import QtQuick 2.0
import Ubuntu.Components 0.1

SwipeBox{
    id: swipeBox

    property var postObj
    readonly property string vote: postObj.data.likes === true ? "up" : postObj.data.likes === false ? "down" : ""

    signal commentsTriggered

    height: headerAdditionHolder.height + postBox.height + divider.height
    width: parent.width

    onClicked: {
        window.resetPostObj()
        openPostContent(postObj)
        onActivePostObjChanged.connect(updatePostObj)
    }
    onCommentsTriggered: {
        window.resetPostObj()
        openPostContent(postObj, true)
        onActivePostObjChanged.connect(updatePostObj)
    }

    onSwipedRight: {
        checkTutorial()
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.upvote()
            voteConnObj.onSuccess.connect(function(){
                //Update the comment object (as it does not emit a changed signal automatically)
                activePostObjChanged()
            })
        }
    }
    onSwipedLeft: {
        checkTutorial()
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.downvote()
            voteConnObj.onSuccess.connect(function(){
                //Update the comment object (as it does not emit a changed signal automatically)
                activePostObjChanged()
            })
        }
    }

    function updatePostObj(){
        postObj = activePostObj
    }

    function checkTutorial() {
        if(postObj.data.id === "tutorialID") {
            settingsHandler.firstTime = false
        }
    }

    Connections {
        target: window
        onResetPostObj: {
            onActivePostObjChanged.disconnect(updatePostObj)
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

    Item{
        id: headerAdditionHolder
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 0
        Behavior on height {UbuntuNumberAnimation{}}
    }

    PostLayout {
        id: postBox
        anchors.top: headerAdditionHolder.bottom

        onCommentsTriggered: swipeBox.commentsTriggered()
    }

    Item {
        id: divider
        anchors {
            top: postBox.bottom
            left: parent.left
            right: parent.right
        }
        height: units.gu(0.1)
    }

    function giveSpace() {
        headerAdditionHolder.height = units.gu(12)
    }
    function hideSpace() {
        headerAdditionHolder.height = 0
    }
}
