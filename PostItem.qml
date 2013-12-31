import QtQuick 2.0
import Ubuntu.Components 0.1

SwipeBox{
    id: swipeBox

    property var postObj
    property bool read: false

    property color primaryColor: "#f2f2f2"
    property color selectedColor: "#ffeaae"
    property color readColor: "#eaeaea"

    readonly property bool selected: activePostObj ? postObj.data.name === activePostObj.data.name : false

    signal commentsTriggered

    anchors {
        left: parent.left
        right: parent.right
    }
    height: headerAdditionHolder.height + postBox.height + units.dp(1)

    onClicked: {
        read = true
        window.resetPostObj()
        openPostContent(postObj)
        onActivePostObjChanged.connect(updatePostObj)
    }
    onCommentsTriggered: {
        read = true
        window.resetPostObj()
        openPostContent(postObj, true)
        onActivePostObjChanged.connect(updatePostObj)
    }

    onSwipedRight: {
        checkTutorial()
        if(redditNotifier.isLoggedIn) {
            var voteConnObj = postObj.upvote()
            if (selected) {
                activePostObjChanged()
            } else {
                postObjChanged()
            }
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
            if (selected) {
                activePostObjChanged()
            } else {
                postObjChanged()
            }
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
        postObj: swipeBox.postObj

        onCommentsTriggered: swipeBox.commentsTriggered()
    }

    Rectangle{
        anchors.fill: postBox
        z: -1
        color: !swipeBox.selected ? !swipeBox.read ? primaryColor : readColor : selectedColor
    }

    function giveSpace() {
        headerAdditionHolder.height = units.gu(12)
    }
    function hideSpace() {
        headerAdditionHolder.height = 0
    }
}
