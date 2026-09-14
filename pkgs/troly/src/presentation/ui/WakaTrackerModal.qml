import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: wakaDialog
    title: "📊 WakaTracker & Nhịp Sinh Hoạt"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "⏱️"; font.pixelSize: 18 }
                ColumnLayout {
                    Text {
                        text: "Hôm nay: " + (typeof wakaTrackerVM !== "undefined" ? wakaTrackerVM.formattedTime : "4 giờ 25 phút") + " lập trình"
                        color: "#CDD6F4"
                        font.bold: true
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Ngôn ngữ: " + (typeof wakaTrackerVM !== "undefined" ? ("C++ (" + wakaTrackerVM.cppPercent + "%), Nix (" + wakaTrackerVM.nixPercent + "%), QML (" + wakaTrackerVM.qmlPercent + "%)") : "C++ (72%), Nix (18%), QML (10%)")
                        color: "#A6ADC8"
                        font.pixelSize: 11
                    }
                }
            }
        }

        Text {
            text: "Phân bổ theo dự án:"
            color: "#CDD6F4"
            font.bold: true
            font.pixelSize: 12
        }

        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 6
            color: "#181825"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "troly (current project)"; color: "#89B4FA"; font.pixelSize: 12; Layout.fillWidth: true }
                Text { text: "3h 10m"; color: "#A6ADC8"; font.pixelSize: 11 }
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            text: "Đóng"
            Layout.alignment: Qt.AlignRight
            onClicked: wakaDialog.close()
        }
    }
}
