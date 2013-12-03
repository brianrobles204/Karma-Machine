import QtQuick 2.0
import Ubuntu.Components 0.1

SwipeBox{
    id: swipeBox
    property var postObj
    height: headerAdditionHolder.height + postBox.height + divider.height
    width: parent.width
    property string vote: postObj.data.likes === true ? "up" : postObj.data.likes === false ? "down" : ""

    onClicked: openPostContent(postObj)

    onSwipedRight: {
        checkTutorial()
        if(storageHandler.modhash !== "") {
            if(vote == "up") {
                vote = ""
                actionHandler.unvote(postObj.data.name)
            } else {
                vote = "up"
                actionHandler.upvote(postObj.data.name)
            }
        }
    }
    onSwipedLeft: {
        checkTutorial()
        if(storageHandler.modhash !== "") {
            if(vote == "down") {
                vote = ""
                actionHandler.unvote(postObj.data.name)
            } else {
                vote = "down"
                actionHandler.downvote(postObj.data.name)
            }
        }
    }

    function checkTutorial() {
        if(postObj.data.id == "tutorialID") {
            settingsHandler.firstTime = false
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
