import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: eyeleoDialog
    title: "⏰ Quản Lý Nghỉ Ngơi & Thị Giác (EyeLeo)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 8
            color: "#181825"
            border.color: "#313244"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text { text: "💡"; font.pixelSize: 16 }
                Text {
                    text: "Quy tắc 20-20-20: Mỗi 20 phút nhìn xa 20 feet (6m) trong 20 giây để ngừa cận thị và mỏi mắt."
                    color: "#A6ADC8"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Bật nhắc nhở EyeLeo:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Switch {
                checked: typeof eyeLeoVM !== "undefined" ? eyeLeoVM.enabled : true
                onToggled: {
                    if (typeof eyeLeoVM !== "undefined") eyeLeoVM.setEnabled(checked)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Chế độ nghiêm ngặt (Strict Mode):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Switch {
                checked: typeof eyeLeoVM !== "undefined" ? eyeLeoVM.strictMode : false
                onToggled: {
                    if (typeof eyeLeoVM !== "undefined") eyeLeoVM.setStrictMode(checked)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Thời gian đã làm việc:"; color: "#CDD6F4"; Layout.fillWidth: true }
            Text {
                text: (typeof eyeLeoVM !== "undefined" ? eyeLeoVM.workMinutes : 0) + " phút"
                color: "#A6E3A1"
                font.bold: true
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "👁️ Thử nghỉ ngắn (20s)"
                onClicked: {
                    if (typeof eyeLeoVM !== "undefined") eyeLeoVM.triggerShortBreak();
                    eyeleoDialog.close();
                }
            }

            Button {
                text: "☕ Thử nghỉ dài"
                onClicked: {
                    if (typeof eyeLeoVM !== "undefined") eyeLeoVM.triggerLongBreak();
                    eyeleoDialog.close();
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Đóng"
                onClicked: eyeleoDialog.close()
            }
        }
    }
}
