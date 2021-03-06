import QtQuick 2.11
import QtQuick.Controls 2.4
import QtWebSockets 1.0

import Launcher 1.0
import JsonFile 1.0

import "qrc:/scripts/websocket.js" as JSWebsocket
import "qrc:/scripts/softwareupdate.js" as JSUpdate

import "basic_ui" as BasicUI

ApplicationWindow {
    id: applicationWindow

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\
    //
    // CURRENT SOFTWARE VERSION
    property real _current_version: 0.1 // change this when bumping the software version

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MAIN WINDOW PROPERTIES
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    visible: true
    width: 480
    height: 800
    color: colorBackground


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // COLORS
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    property int cornerRadius: 18

    property bool darkMode: true

    property string colorBackground: darkMode ? "#000000" : "#ffffff"
    property string colorBackgroundTransparent: darkMode ? "#00000000" :  "#00000000"

    property string colorText: darkMode ? "#ffffff" : "#000000"
    property string colorLine: darkMode ? "#ffffff" : "#000000"
    property string colorHighlight: "#918682"

    property string colorLight: darkMode ? "#2E373D" : "#CBCBCB"
    property string colorMedium: darkMode ? "#121519" : "#D4D4D4"
    property string colorDark: darkMode ? "#16191E" : "#ffffff"
    property string colorDarkest: darkMode ? "#0E0F12" : "#0E0F12"

    property string colorGreen: "#19D37B"
    property string colorRed: "#EA003C"

    property string colorSwitch: darkMode ? "#1E242C" : "#B9B9B9"
    property string colorSwitchOn : darkMode ? "#ffffff" : "#ffffff"
    property string colorSwitchBackground: darkMode ? "#000000" : "#ffffff"

    property string colorButton: darkMode ? "#121519" : "#EAEAEA"
    property string colorButtonPressed :darkMode ? "#16191E" : "#D7D7D7"
    property string colorButtonFav: darkMode ? "#1A1D23" : "#1A1D23"

//    property string colorRoundButton: "#1A1D23"


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TRANSLATIONS
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    property string languange: "en-us" // default language is English
    property var translations: {"en-us": default_language.read()}

    JsonFile {
        id: default_language
        name: "/Users/marton/Qt\ Projects/remote/translations/en-us.json"
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // SOFTWARE UPDATE
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    property bool updateAvailable: false
    property real _new_version
    property string updateURL
    property bool autoUpdate: false

    Timer {
        repeat: true
        running: true
        interval: 7200000

        onTriggered: {
            JSUpdate.checkForUpdate();
        }
    }

    Launcher { id: mainLauncher }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CONFIGURATION
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    property var config: jsonConfig.read()
    property var integration // holds the integration qml

    JsonFile { // this module loads the config file
        id: jsonConfig
        name: "/Users/marton/Qt\ Projects/remote/config.json"
    }

    Component.onCompleted: {
        var comp;
        var obj;

        // load the hub integration
        comp = Qt.createComponent("qrc:/integrations/"+ config.integration +".qml");
        integration = comp.createObject(applicationWindow);

        // load the entities from the config file that are supported
        for (var i=0; i<config.entities.length; i++) {
            for (var k=0; k<supported_entities.length; k++) {
                if (supported_entities[k] == config.entities[i].type) {
                    // load the supported entity
                    applicationWindow["entities_"+config.entities[i].type] = config.entities[i].data;

                    comp = Qt.createComponent("qrc:/components/" + supported_entities[k] + "/Main.qml");
                    obj = comp.createObject(applicationWindow);

                    loaded_entities.push(supported_entities[k]);
                    loaded_components.push(obj);
                }
            }
        }

        // check for software update
        JSUpdate.checkForUpdate();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // SUPPORTED COMPONENTS
    // Create a variable for the supported component. For example one variable for lights, one for blinds, etc.
    // It is necessary to have a seperate variable for every entity type, otherwise when an event comes all entities and their component would be updated too.
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    property var supported_entities: ["light"]
    property var loaded_entities: []
    property var loaded_components: []
    property var entities_light

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // SYSTEM VARIABLES
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    property bool firstRun: true // tells if the application is running for the first time

    property real battery_voltage: 0
    property real battery_level: 0
    property real battery_time: (new Date()).getTime()
    property bool wasBatteryWarning: false

    property int display_brightness

    property bool favoriteAdded: false


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // WEBSOCKET SERVER
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    WebSocketServer { // for communication with battery control, backlight control, etc.
        id: socketServer
        port: 8234
        listen: true

        property var clientId

        onClientConnected: {
            webSocket.sendTextMessage("OK")
            webSocket.onTextMessageReceived.connect(function(message) {
                JSWebsocket.parseWSServerMessage(message);
                if (message == "display") {
                    clientId = webSocket;
                    console.debug("got websocket client id");
                }
            });
        }
        onErrorStringChanged: {
            console.debug("Server error: " + errorString);
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // QML GUI STUFF
    // The main container holds almost all the GUI elements. The secondary container is used to load the buttons into, with their open state.

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MAIN CONTAINER
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Loader {
        id: loader_main
        asynchronous: true
        visible: false
        width: 480
        height: 800
        x: 0
        y: 0
        source: "qrc:/MainContainer.qml"

        transform: Scale {
            id: scale
            origin.x: loader_main.width/2
            origin.y: loader_main.height/2
        }

        states: [
            State { name: "hidden"; PropertyChanges {target: loader_main; y: -60; scale: 0.8; opacity: 0.4}},
            State { name: "visible"; PropertyChanges {target: loader_main; scale: 1; opacity: 1; visible: true}}
        ]
        transitions: [
            Transition {to: "hidden"; PropertyAnimation { target: loader_main; properties: "y, scale, opacity"; easing.type: Easing.OutExpo; duration: 800 }},
            Transition {to: "visible"; SequentialAnimation {
                    PropertyAnimation { target: loader_main; properties: "y, scale, opacity"; easing.type: Easing.InExpo; duration: 300 }
                }}
        ]

        onStatusChanged: if (loader_main.status == Loader.Ready) {
                             firstRun = false;
                             loader_main.visible = true;
                             connectionLoader.state = "connected";
                         }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // SECONDARY CONTAINER
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CHARING SCREEN
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Visible when charging

    BasicUI.ChargingScreen {
        id: chargingScreen
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // LOW BATTERY POPUP NOTIFICAITON
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Pops up when battery level is under 20%
    onBattery_levelChanged: {
        if (battery_level < 0.2 && !wasBatteryWarning) {
            lowBatteryNotification.open();
            wasBatteryWarning = true;
            if (socketServer.clientId != undefined) {
                socketServer.clientId.sendTextMessage("wakeup");
            }
        }
        if (battery_level > 0.3) {
            wasBatteryWarning = false;
        }
    }

    BasicUI.PopupLowBattery {
        id: lowBatteryNotification
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CONNECTION SCREEN
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Visible when connecting, reconnecting to the integration
    BasicUI.ConnectionScreen {
        id: connectionLoader
    }
}
