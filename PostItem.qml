import QtQuick 2.0
import Ubuntu.Components 0.1

SwipeBox{
    id: swipeBox

    property var postObj

    readonly property string vote: postObj ? postObj.data.likes === true ? "up" : postObj.data.likes === false ? "down" : "" : ""
    readonly property bool selected: activePostObj ? postObj.data.name === activePostObj.data.name : false

    signal commentsTriggered

    anchors {
        left: parent.left
        right: parent.right
    }
    height: headerAdditionHolder.height + postBox.height + units.dp(1)

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
                if (selected) {
                    activePostObjChanged()
                } else {
                    postObjChanged()
                }
            })
        }
    }
    onSwipedLeft: {
        checkTutorial()
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.downvote()
            voteConnObj.onSuccess.connect(function(){
                //Update the comment object (as it does not emit a changed signal automatically)
                if (selected) {
                    activePostObjChanged()
                } else {
                    postObjChanged()
                }
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

    Item{
        id: headerAdditionHolder
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 0
        Behavior on height {UbuntuNumberAnimation{}}
    }

    PostLayout {
        id: postBox
        anchors.top: headerAdditionHolder.bottom
        selected: swipeBox.selected
        postObj: swipeBox.postObj
        vote: swipeBox.vote

        onCommentsTriggered: swipeBox.commentsTriggered()
    }

    function giveSpace() {
        headerAdditionHolder.height = units.gu(12)
    }
    function hideSpace() {
        headerAdditionHolder.height = 0
    }
}
