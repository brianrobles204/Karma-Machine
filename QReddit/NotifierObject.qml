import QtQuick 2.0

QtObject {
    property string activeUser: ""
    readonly property bool isLoggedIn: activeUser !== ""
    property string authStatus //Status of user authentication. May be 'none', 'loading', 'done' or 'error'
}
