import QtQuick 2.11
import QtQuick.Controls 2.4

import "basic_ui" as BasicUI
import "basic_ui/main_navigation" as Navigation

Item {
    id: main_container
    width: parent.width
    height: parent.height
    clip: true

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MAIN CONTAINER CONTENT
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    SwipeView {
        id: mainNavigationSwipeview
        width: parent.width-20
        height: parent.height-statusBar.height-mainNavigation.height-miniMediaPlayer.height
        anchors.top: statusBar.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // DASHBOARD
        Item {
            Flickable {
                id: dashboardFlickable
                width: parent.width
                height: parent.height
                maximumFlickVelocity: 4000
                flickDeceleration: 1000
                clip: true
                contentHeight: 2000 // dashboardFlow.height
                boundsBehavior: Flickable.DragAndOvershootBounds
                flickableDirection: Flickable.VerticalFlick

                ScrollBar.vertical: ScrollBar {
                    opacity: 0.5
                }

                Flow {
                    id: dashboardFlow
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                }
            }
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // ROOMS

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // SETTINGS
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // BOTTOM GRADIENT FADE
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: bottomGradient
        width: parent.width
        height: 80
        anchors.bottom: mainNavigation.top

        opacity: mainNavigationSwipeview.currentItem.children[0].atYEnd ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutExpo
            }
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: colorBackgroundTransparent }
            GradientStop { position: 1.0; color: colorBackground }
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MAIN NAVIGATION
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
    Navigation.MainNavigation {
        id: mainNavigation
        anchors.bottom: miniMediaPlayer.top
        anchors.horizontalCenter: parent.horizontalCenter
        state: mainNavigationSwipeview.currentItem.children[0].atYBeginning ? "open" : "closed"
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MINI MEDIA PLAYER
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Rectangle {
        id: miniMediaPlayer
        width: parent.width
        height: 0
        anchors.bottom: parent.bottom
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // STATUS BAR
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    BasicUI.StatusBar {
        id: statusBar
    }
}