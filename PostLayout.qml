import QtQuick 2.0
import Ubuntu.Components 0.1
import "MiscUtils.js" as MiscUtils

Item {
    id: postRow
    height: Math.max(postColumn.height, postIcon.height) + units.gu(2.5)
    anchors{
        left: parent.left
        right: parent.right
    }
    property real spacingConstant: units.gu(1.25)

    Rectangle{
        anchors.fill: parent
        z: -1
        color: internalModel ? internalModel.data.stickied ? "#feffae" : "#fafafa" : "#fafafa"
    }

    UbuntuShape {
        id: postIcon
        //color: "lightblue"
        anchors{
            top: parent.top
            topMargin: postRow.spacingConstant
            left: parent.left
            leftMargin: postRow.spacingConstant
        }
        width: visible ? units.gu(6) : 0
        height: units.gu(6)
        image: Image {
            source: {
                var image = internalModel ? internalModel.data.thumbnail: "media/self.png"
                if(image == "self") return "media/self.png"
                if(image == "default") return "media/default.png"
                if(image == "nsfw") return "media/nsfw.png"
                return image
            }
            fillMode: Image.PreserveAspectCrop
        }
        visible: internalModel ? (internalModel.data.thumbnail !== "self" && internalModel.data.thumbnail !== "default" && internalModel.data.thumbnail !== "") : false
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
            text: internalModel ? MiscUtils.htmlspecialchars_decode(internalModel.data.title) : ""
            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            font.weight: Font.DemiBold
            color: UbuntuColors.coolGrey
        }

        Row {
            id: postInfo
            height: Math.max(postScore.height, postMiniInfo.height)
            spacing: units.gu(1)

            Label {
                id: postScore
                text: internalModel ? " " + internalModel.data.score : ":)"
                color: "#999999"
                horizontalAlignment: Text.AlignLeft
                fontSize: "large"
                font.weight: Font.Light
            }

            Label {
                id: postMiniInfo
                text: {
                    var author = internalModel ? internalModel.data.author : "author"
                    var subreddit = internalModel ? internalModel.data.subreddit : "reddit"

                    var timeRaw = internalModel ? internalModel.data.created_utc : 0
                    var time = MiscUtils.timeSince(new Date(timeRaw * 1000))
                    var domain = internalModel ? internalModel.data.domain : "reddit.com"

                    return "<b>" + author + "</b> in <b>r/" + subreddit + "</b><br/>" + time + " <b>·</b> " + domain
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
            top: parent.top
            topMargin: postRow.spacingConstant
            right: parent.right
            rightMargin: postRow.spacingConstant
        }

        onClicked: linkHandler.openCommentsIM(internalModel)
        z: -1

        Label {
            text: internalModel ? MiscUtils.commentsSimple(internalModel.data.num_comments) : "0"
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
            source: "media/CommentsBubble.png"
            width: units.gu(3.125)
            height: units.gu(3.125)
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: units.gu(1)
            }
        }
    }
}
