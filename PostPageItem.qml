import QtQuick 2.0
import QtWebKit 3.0
import QtGraphicalEffects 1.0
import Ubuntu.Components 0.1
import "Utils/Misc.js" as MiscUtils

Item {
    id: postPageItem

    property var postObj: activePostObj
    property var toolbar
    property Flickable flickable
    property WebView __webSection: webSection

    property string title: postHeader.title == "" ? " " : postHeader.title
    property string subTitle: postObj ? MiscUtils.simpleFixHtmlChars(postObj.data.title) : ""

    property bool linkOpen: commentsSection.state == "linkOpen"
    property bool canBeToggled: webSection.canBeOpened && postObj != null

    property string webUrl: webSection.url
    property string commentsUrl: postObj ? "http://reddit.com" + postObj.data.permalink : "http://reddit.com"

    function openPostContent(content, forceComments) {
        if (typeof content === "string") {
            //content is a url.
            commentsSection.peek()
            webSection.open(content)
        } else if (content.toString() === "[object PostObject]") {
            //content is a postObj
            if(history.indexOf(content.data.name) == -1) {
                settingsHandler.history += "," + content.data.name
            }

            if(content.data.is_self || forceComments) {
                commentsSection.show()
                if(postObj && content.data.name === postObj.data.name) return
                activePostObj = content
                webSection.open("about:blank")
                reloadComments()
            } else {
                if(postObj && content.data.name === postObj.data.name) return
                activePostObj = content
                webSection.clearOpen(postObj.data.url)
                webSection.openPeekBG()
                reloadComments()
            }
        }
    }

    function toggle() {
        var cstate = commentsSection.state
        if(cstate === "linkOpen") {
            commentsSection.show()
        } else if (webSection.canBeOpened){
            commentsSection.peek()
            postHeader.ignoreHide = true
            postHeader.exception = true
            postHeader.hide()
        }
    }

    function reloadComments() {
        commentsPageItem.reload()
        commentsSection.contentY = 0
    }

    function insertCommentObj(commentObj) {
        commentsPageItem.insertComment(commentObj)
        commentsSection.contentY = commentsPageItem.beginningCommentsPos - units.gu(0.6)
        postHeaderShowTimer.start()
    }

    Timer {
        id: postHeaderShowTimer
        onTriggered: postHeader.show()
        interval: UbuntuAnimation.SlowDuration
    }

    Header {
        id: postHeader

        property bool exception: false
        property bool ignoreHide: false

        property real contentHeight: units.gu(7.5)
        property int fontWeight: Font.Light
        property string fontSize: "x-large"
        property color textColor: "#fafafa"
        property real textLeftMargin: units.gu(2)

        function show() {
            //needed because changing flickables causes the header to show automatically
            if(commentsSection.state == "commentsOpen" || (webSection.atYEnd && !webSection.atYBeginning) || !exception) postHeader.y = 0
        }

        contents: headerContents
        title: commentsSection.state == "linkOpen" ? webSection.title : commentsSection.title
        flickable: postPageItem.flickable
        z: 120

        onYChanged: {
            if(commentsSection.state == "linkOpen"/* && !commentsSection.isPressed*/) {
                if(y === -height) {
                    if(flickable.contentY > 0 && !ignoreHide){
                        commentsSection.hide()
                    } else {
                        ignoreHide = false
                    }
                } else if( y === 0) {
                    commentsSection.peek()
                }
            }
        }

        Behavior on y {
            enabled: (postHeader.flickable && !postHeader.flickable.moving) || postHeader.exception
            SmoothedAnimation {
                duration: UbuntuAnimation.BriskDuration
            }
        }

        Item {
            id: headerContents
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: postHeader.contentHeight

            Label {
                id: headerLabel
                width: (implicitWidth < parent.width - headerArrow.width - units.gu(5)) ? implicitWidth : parent.width - headerArrow.width - units.gu(5)
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: postHeader.textLeftMargin
                }
                text: postHeader.title
                font.weight: postHeader.fontWeight
                fontSize: postHeader.fontSize
                elide: Text.ElideRight
                color: postHeader.textColor
            }
            Image {
                id: headerArrow
                anchors {
                    left: headerLabel.right
                    leftMargin: units.gu(1.3)
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: units.gu(0.2)
                }
                visible: webSection.canBeOpened
                source: "media/ui/header_toggle.png"
                rotation: commentsSection.state == "commentsOpen" ? 0 : 180
                Behavior on rotation {UbuntuNumberAnimation{}}
            }
        }

        HeaderArea {
            onClicked: postPageItem.toggle()
        }
    }

    Rectangle {
        id: postPageCover
        anchors.fill: parent
        z: 110
        color: "#dadada"
        visible: !postPageItem.postObj

        Item {
            property real margin: units.gu(6)
            anchors.centerIn: postPageCover
            width: parent.width - margin
            height: childrenRect.height

            Image {
                id: coverImage
                source: "media/noSignal.png"
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(25)
                height: units.gu(25)
                opacity: 0.45
            }
            Label {
                id: coverLabel
                text: "Open posts on the left to view them here."
                anchors{
                    top: coverImage.bottom
                    topMargin: units.gu(2)
                }
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                fontSize: "large"
            }
        }
    }

    WebView {
        id: webSection
        width: parent.width
        height: parent.height
        y: isAtEnd ? -commentsPeekItem.height : isPhone ? 0 : pageStack.header.height
        smooth: false

        property bool isAtEnd: false
        property bool protectHiding: false
        property string title: ""
        property bool canBeOpened: url != "about:blank"
        Behavior on y {UbuntuNumberAnimation{}}

        onDragStarted: openPeekBG()
        onAtYEndChanged: openPeekBG()
        onAtYBeginningChanged: openPeekBG()

        function openPeekBG() {
            if(!canBeToggled) return
            if (atYBeginning){
                //hide header but peek comments
                postHeader.exception = true
                postHeader.hide()
                commentsSection.peek()
                postHeader.exception = false
            } else if(atYEnd) {
                //only set to true after some time
                if(!protectHiding) isAtEnd = true
                //show header and peek comments
                postHeader.exception = true
                postHeader.show()
                commentsSection.peek()
                postHeader.exception = false
            } else {
                postHeader.exception = false
                if(postHeader.y === -postHeader.height) {
                    commentsSection.hide()
                } else if( postHeader.y === 0) {
                    commentsSection.peek()
                }
                isAtEnd = false
                protectHiding = true
                atEndTimer.start()
            }
        }

        Timer {
            id: atEndTimer
            interval: 200
            onTriggered: webSection.protectHiding = false
        }

        onUrlChanged: {
            //console.log(url)
            postHeader.y = 0

            try {
                var urlStr = url.toString()
                var matchedUrl = urlStr.match(/^([\w]+:\/\/)([\w.-]+)[\/]?/)
                var domain = matchedUrl[2]
            } catch (error) {
                //The link does not seem to match an arbitrary url format
                webSection.title = "Link"
                return
            }

            var splitDomain = domain.split('.')
            var baseDomain = (splitDomain[0].indexOf('www') !== -1) ? domain.slice(splitDomain[0].length + 1) : domain
            webSection.title = baseDomain
        }

        function open(link) {
            url = link
        }

        function clearOpen(link) {
            url = "about:blank"
            url = link
        }
    }

    Item{
        //Wrapper to ensure that the left edge of the progressbar is always straight and not rounded (by using clip: true)
        anchors {
            top: isPhone ? postHeader.bottom : postPageItem.top
            topMargin: isPhone ? 0 : postHeader.height
            left: parent.left
            right: parent.right
            rightMargin: -linkProgressBar.radius
        }
        height: linkProgressBar.height
        clip: true

        Rectangle {
            id: linkProgressBar
            height: units.gu(0.5)
            radius: height/2
            width: {
                if (webSection.loadProgress !== 100) {
                    var progressWidth = ((webSection.loadProgress)/100)*parent.width
                    return minWidth > progressWidth ? minWidth : progressWidth
                } else {
                    return 0
                }
            }
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: -radius
            visible: webSection.loading
            color: "orange"

            property real minWidth: units.gu(2)
            Behavior on width { UbuntuNumberAnimation{} }
        }
    }

    Flickable {
        id: commentsSection

        property string title: "Comments"

        function peek() {
            state = "linkOpen"
            commentsPeekItem.state = "peek"
        }
        function hide() {
            state = "linkOpen"
            commentsPeekItem.state = "hideBottom"
        }
        function show() {
            state = "commentsOpen"
            commentsPeekItem.state = "peek"
        }

        width: parent.width; height: parent.height - postHeader.height
        contentHeight: commentsPageItem.height
        state: "normal"
        z: 99

        onDragEnded: {
            if(contentY < -units.gu(20) && webSection.canBeOpened) {
                peek()
                postHeader.ignoreHide = true
                postHeader.exception = true
                postHeader.hide()
            }
        }

        onAtYBeginningChanged: {
            if(atYBeginning) {
                postHeader.exception = true
                postHeader.show()
            } else {
                postHeader.exception = false
            }
        }

        Behavior on contentY { UbuntuNumberAnimation { duration: UbuntuAnimation.SlowDuration } }

        CommentsPageItem {
            id: commentsPageItem
        }

        transitions: [
            Transition {
                to: "commentsOpen"
                SequentialAnimation{
                    ScriptAction {
                        script: webSection.visible = false
                    }
                    UbuntuNumberAnimation{ properties: 'y'}
                }
            }, Transition {
                to: "linkOpen"
                SequentialAnimation{
                    UbuntuNumberAnimation{ properties: 'y'}
                    ScriptAction {
                        script: webSection.visible = true
                    }
                }
            }
        ]

        states: [
            State {
                name: "linkOpen"
                PropertyChanges {
                    target: commentsSection
                    y: parent.height
                    clip: true
                }
                PropertyChanges {
                    target: postPageItem
                    flickable: webSection
                }
                PropertyChanges {
                    target: commentsPeekRect
                    visible: true
                }
            },
            State {
                name: "commentsOpen"
                PropertyChanges {
                    target: postPageItem
                    flickable: commentsSection
                }
                PropertyChanges {
                    target: commentsSection
                    y: postHeader.height
                    clip: false
                }
                PropertyChanges {
                    target: linkProgressBar
                    visible: false
                }
                PropertyChanges {
                    target: commentsPeekRect
                    visible: false
                }
            }
        ]
    }

    Column {
        id: linkHint
        visible: (commentsSection.state == "commentsOpen") && (commentsSection.contentY < -units.gu(5)) && (webSection.canBeOpened)
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: postHeader.height + units.gu(2.5) + ((-commentsSection.contentY + units.gu(5))/units.gu(20))*units.gu(3)
        }
        height: childrenRect.height
        spacing: units.gu(1)
        opacity: Math.min(((-commentsSection.contentY)/units.gu(20)), 1)
        Image {
            source: 'media/ui/web-hint.svg'
            anchors.horizontalCenter: parent.horizontalCenter
            width: units.gu(2); height: units.gu(2)
            sourceSize { height: height; width: width }
        }
        Image {
            source: 'media/ui/up-hint.png'
            anchors.horizontalCenter: parent.horizontalCenter
            width: units.gu(2); height: units.gu(2)
            rotation: commentsSection.contentY < -units.gu(20) ? 0 : 180
            sourceSize { height: height; width: width }
            Behavior on rotation{UbuntuNumberAnimation{}}
        }
    }

    MouseArea {
        id: commentsPeekMouseArea

        onClicked: commentsSection.show()

        width: commentsPeekItem.width; height: commentsPeekItem.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 98
    }

    Item {
        id: commentsPeekItem

        property real maxWidth: units.gu(50)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: commentsPeekRect.childrenRect.height + commentsPeekRect.margins*2 + commentsPeekRect.childMargins*2
        width: parent.width > maxWidth ? maxWidth : parent.width
        z: 97

        states: [
            State {
                name: "peek"
                PropertyChanges{
                    target: commentsPeekItem
                    anchors.bottomMargin: toolbar.opened ? toolbar.height : 0
                }
                PropertyChanges{
                    target: commentsPeekMouseArea
                    anchors.bottomMargin: toolbar.opened ? toolbar.height : 0
                }
            },
            State {
                name: "hideBottom"
                PropertyChanges{
                    target: commentsPeekItem
                    anchors.bottomMargin: -height
                }
                PropertyChanges{
                    target: commentsPeekMouseArea
                    anchors.bottomMargin: -height
                }
            }
        ]

        Behavior on anchors.bottomMargin { UbuntuNumberAnimation {} }

        Connections {
            target: postPageItem.toolbar
            onOpenedChanged: if(postPageItem.toolbar.opened) commentsPeekItem.state = "peek"
        }

        Rectangle {
            id: commentsPeekRect
            property real margins: units.gu(2)
            property real childMargins: units.gu(1)
            anchors{
                fill: parent
                margins: margins
            }
            color: "#f3f3f3"
            radius: units.gu(0.2)

            Label {
                id: commentsPeekTitle
                property real margins: parent.childMargins
                property real maxHeight: units.gu(5.6)
                anchors {
                    left: parent.left
                    leftMargin: margins*2
                    right: parent.right
                    rightMargin: margins*2
                    top: parent.top
                    topMargin: margins
                }
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                clip: true
                height: implicitHeight < maxHeight ? implicitHeight : maxHeight
                text: postPageItem.postObj ? MiscUtils.simpleFixHtmlChars(postPageItem.postObj.data.title) : ""
                font.weight: Font.DemiBold
                color: UbuntuColors.coolGrey
            }
            Item {
                id: commentsPeekSpace
                anchors {
                    left: parent.left
                    right: parent.right
                    top: commentsPeekTitle.bottom
                }
                height: commentsPeekTitle.height == commentsPeekTitle.maxHeight ? 0 : parent.childMargins
            }

            Rectangle {
                id: commentsPeekDivider
                property real margins: parent.childMargins
                anchors {
                    left: parent.left
                    leftMargin: margins
                    right: parent.right
                    rightMargin: margins
                    top: commentsPeekSpace.bottom
                }
                color: "#dadada"
                height: units.gu(0.1)
            }

            Image {
                source: "media/ui/peek_shadow.png"
                width: units.gu(30)
                height: units.gu(3)
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: commentsPeekDivider.top
                }
                visible: commentsPeekTitle.height == commentsPeekTitle.maxHeight
            }

            Item {
                id: commentsPeekContainer
                property real margins: parent.childMargins
                width: childrenRect.width
                height: childrenRect.height
                anchors {
                    horizontalCenter: commentsPeekRect.horizontalCenter
                    top: commentsPeekDivider.bottom
                    topMargin: margins
                }

                Image {
                    id: commentsPeekIcon
                    source: "media/ui/comments@30.svg"
                    width: units.gu(1.75); height: units.gu(1.75)
                    sourceSize { width: width; height: height }
                }
                ColorOverlay {
                    anchors.fill: commentsPeekIcon
                    source: commentsPeekIcon
                    color: "#555555"
                }

                Label {
                    id: commentsPeekNum
                    text: postPageItem.postObj ? postPageItem.postObj.data.num_comments : ""
                    anchors{
                        left: commentsPeekIcon.right
                        leftMargin: units.gu(0.6)
                        verticalCenter: commentsPeekIcon.verticalCenter
                    }
                    font {
                        pixelSize: units.gu(1.65)
                        weight: Font.Black
                    }
                    color: "#555555"
                }
            }

            Label {
                id: commentsPeekScore
                text: postPageItem.postObj ? postPageItem.postObj.data.score + " pts <b>·</b> " : "0 pts <b>·</b> "
                anchors{
                    right: commentsPeekContainer.left
                    rightMargin: units.gu(0.5)
                    verticalCenter: commentsPeekContainer.verticalCenter
                    verticalCenterOffset: -units.gu(0.1)
                }
                font{
                    weight: Font.DemiBold
                    pixelSize: units.gu(1.5)
                }
            }

            Label {
                id: commentsPeekTime
                text: {
                    var timeRaw = postPageItem.postObj ? postPageItem.postObj.data.created_utc : new Date()
                    var time = MiscUtils.timeSince(new Date(timeRaw * 1000))
                    return " <b>·</b> " + time
                }

                anchors{
                    left: commentsPeekContainer.right
                    leftMargin: units.gu(0.5)
                    verticalCenter: commentsPeekContainer.verticalCenter
                    verticalCenterOffset: -units.gu(0.1)
                }
                font{
                    weight: Font.DemiBold
                    pixelSize: units.gu(1.5)
                }
            }

        }
    }

    DropShadow {
        anchors.fill: commentsPeekItem
        radius: units.gu(0.6)
        fast: true
        color: "#90000000"
        cached: true
        source: commentsPeekItem
        verticalOffset: units.gu(0.1)
    }
}
