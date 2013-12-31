import QtQuick 2.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

Item {
    id: postRow

    property var postObj
    property real spacingConstant: units.gu(1.25)
    readonly property bool stickied: postObj ? postObj.data.stickied : false

    signal commentsTriggered

    height: Math.max(postColumn.height, postIcon.height) + units.gu(2.5)
    anchors{
        left: parent.left
        right: parent.right
    }

    EmblemRow {
        id: emblemRow

        thingObj: postRow.postObj
        padding: postRow.spacingConstant
        lineHeight: emblemRow.height
    }

    UbuntuShape {
        id: postIcon

        property bool hasThumbnail: postObj !== undefined && postObj.data.thumbnail !== "self" && postObj.data.thumbnail !== "default" && postObj.data.thumbnail !== "nsfw"

        color: "#2e0020"
        anchors{
            top: parent.top
            topMargin: postRow.spacingConstant
            left: parent.left
            leftMargin: postRow.spacingConstant
        }
        width: visible ? units.gu(6) : 0
        height: units.gu(6)
        image: Image {
            source: postIcon.hasThumbnail ? postObj.data.thumbnail : ""
            fillMode: Image.PreserveAspectCrop
        }
        visible: hasThumbnail
    }

    Column {
        id: postColumn
        height: childrenRect.height
        anchors {
            top: parent.top
            topMargin: postRow.spacingConstant
            left: postIcon.right
            leftMargin: postIcon.visible ? units.gu(1) : 0
            right: postComments.left
        }

        spacing: units.gu(0.25)

        Label {
            id: postTitle
            text: postObj ? MiscUtils.simpleFixHtmlChars(postObj.data.title) : ""
            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            font.weight: Font.DemiBold
            color: !postRow.stickied ? UbuntuColors.coolGrey : "#2D692D"
        }

        Row {
            id: postInfo
            height: Math.max(postScore.height, postMiniInfo.height)
            spacing: units.gu(1)

            Label {
                id: postScore
                text: postObj ? " " + postObj.data.score : ":)"
                color: "#999999"
                horizontalAlignment: Text.AlignLeft
                fontSize: "large"
                font.weight: Font.Light
            }

            Label {
                id: postMiniInfo
                text: {
                    var author = postObj ? postObj.data.author : "author"
                    if (postObj && postObj.data.distinguished === "admin"){
                        author = "<font color='#DF4D4D'>" + author + " [a]</font>"
                    } else if (postObj && postObj.data.distinguished === "moderator"){
                        author = "<font color='#6EAF6E'>" + author + " [m]</font>"
                    }
                    var subreddit = postObj ? postObj.data.subreddit : "reddit"

                    var over18 = postObj && postObj.data.over_18 ? "<b><font color='#D97474'>NSFW</font> ·</b> " : ""
                    var timeRaw = postObj ? postObj.data.created_utc : 0
                    var time = MiscUtils.timeSince(new Date(timeRaw * 1000))
                    var domain = postObj ? postObj.data.domain : "reddit.com"

                    return "<b>" + author + "</b> in <b>r/" + subreddit + "</b><br/>" + over18 + time + " <b>·</b> " + domain
                }
                horizontalAlignment: Text.AlignLeft
                fontSize: "x-small"
                color: "#999999"
            }
        }
    }

    MouseArea {
        id: postComments
        width: units.gu(5)
        height: parent.height - 2*postRow.spacingConstant
        anchors{
            top: emblemRow.bottom
            topMargin: emblemRow.empty ? postRow.spacingConstant : 0
            right: parent.right
            rightMargin: postRow.spacingConstant
        }

        onClicked: postRow.commentsTriggered()
        z: -1

        Label {
            text: postObj ? MiscUtils.commentsSimple(postObj.data.num_comments) : "0"
            color: "white"
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: units.gu(-0.4)
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: units.gu(1)
            }
            fontSize: "xx-small"
            font.weight: Font.DemiBold
            z: 100
        }

        Image {
            id: commentIcon
            source: "media/ui/comments@30.svg"
            width: units.gu(3.125); height: units.gu(3.125)
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: units.gu(1)
            }
            sourceSize { width: width; height: height }
        }
        ColorOverlay {
            anchors.fill: commentIcon
            source: commentIcon
            color: "#bababa"
        }
    }
}
