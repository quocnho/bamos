import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: mascot3dRoot
    width: 140
    height: 140

    property real rotationAngle: 0.0
    property bool isWagging: true
    property string currentEmotion: "happy"

    // Vòng quay góc nhìn 3D mô phỏng 60fps
    NumberAnimation {
        target: mascot3dRoot
        property: "rotationAngle"
        from: -15
        to: 15
        duration: 2000
        loops: Animation.Infinite
        running: true
        easing.type: Easing.InOutSine
    }

    Rectangle {
        id: meshBase
        anchors.centerIn: parent
        width: 100
        height: 100
        radius: 50
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F9E2AF" }
            GradientStop { position: 0.7; color: "#FAB387" }
            GradientStop { position: 1.0; color: "#EBA0AC" }
        }
        border.color: "#F5C2E7"
        border.width: 2
        rotation: mascot3dRoot.rotationAngle

        // Đôi tai cách điệu Toon Shaded
        Rectangle {
            id: leftEar
            x: 8; y: -12
            width: 24; height: 36
            radius: 12
            color: "#FAB387"
            rotation: -18 + mascot3dRoot.rotationAngle * 0.5
        }

        Rectangle {
            id: rightEar
            x: 68; y: -12
            width: 24; height: 36
            radius: 12
            color: "#FAB387"
            rotation: 18 + mascot3dRoot.rotationAngle * 0.5
        }

        // Đôi mắt tròn to biểu cảm (Puppy Eyes)
        Rectangle {
            x: 24; y: 34
            width: 16; height: 20
            radius: 8
            color: "#11111B"

            Rectangle {
                x: 4; y: 4
                width: 6; height: 6
                radius: 3
                color: "#FFFFFF"
            }
        }

        Rectangle {
            x: 60; y: 34
            width: 16; height: 20
            radius: 8
            color: "#11111B"

            Rectangle {
                x: 4; y: 4
                width: 6; height: 6
                radius: 3
                color: "#FFFFFF"
            }
        }

        // Chiếc mũi xinh
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 54
            width: 12; height: 8
            radius: 4
            color: "#45475A"
        }

        // Chiếc đuôi lò xo (Spring Bone wagging)
        Rectangle {
            id: tailSpring
            x: -12; y: 64
            width: 18; height: 30
            radius: 9
            color: "#F9E2AF"
            transformOrigin: Item.TopRight
            rotation: mascot3dRoot.isWagging ? (mascot3dRoot.rotationAngle * 2.5) : 0
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: "🐾 3D Stylized POC"
        font.pixelSize: 10
        font.bold: true
        color: "#B4BEFE"
    }
}
