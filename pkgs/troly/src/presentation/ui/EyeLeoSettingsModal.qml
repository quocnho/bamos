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
            Switch { checked: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Nghỉ Ngắn (Short Break):"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                model: ["Mỗi 10 phút (Khuyên dùng)", "Mỗi 15 phút", "Mỗi 20 phút"]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Nghỉ Dài (Long Break):"; color: "#CDD6F4"; Layout.fillWidth: true }
            ComboBox {
                model: ["Mỗi 50 phút (Nghỉ 5p)", "Mỗi 60 phút (Nghỉ 5p)", "Mỗi 90 phút (Nghỉ 7p)"]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Chế độ nghiêm ngặt (Strict Mode):"; color: "#CDD6F4"; Layout.fillWidth: true }
            Switch { checked: false }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "👁️ Thử bài tập ngay"
                onClicked: {
                    chatVM.setMascotState("excited");
                    eyeleoDialog.close();
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Lưu Cài Đặt"
                onClicked: eyeleoDialog.close()
            }
        }
    }
}
