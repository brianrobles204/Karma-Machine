import QtQuick 2.0

QtObject {
    id: connectionObject
    property string errorMessage: ""
    property int timeout: 30000

    signal connectionSuccess(variant response) //called when the connection is successful
    signal success(variant response) //called when the connection is successful and reddit.com returned no input errors
    signal raiseRetry() //called when the server is taking too long to respond and appropriate action may need to be taken
    signal error(string error)
    signal abort()

    onSuccess: connectionObject.destroy()
    onError: {
        abort();
        if(error) errorMessage = error
        console.error("Error: " + errorMessage)
        connectionObject.destroy()
    }
}
