import QtQuick 2.0

QtObject {

    property string activeUser: ""
    property string currentAuthUser: ""

    readonly property bool isLoggedIn: currentAuthUser !== ""
    property string authStatus //Status of user authentication. May be 'none', 'loading', 'done' or 'error'
}
