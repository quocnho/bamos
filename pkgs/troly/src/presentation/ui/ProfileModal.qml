import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ModalDialog {
    id: profileDialog
    title: "👤 Hồ Sơ, Màu Sắc & Đánh Giá Năng Lực"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 8
            color: ThemeManager.cardBg
            border.color: ThemeManager.borderDim
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text { text: "🧑‍💻"; font.pixelSize: 18 }
                ColumnLayout {
                    Text {
                        text: "Xưng hô: " + (typeof userProfileVM !== "undefined" ? userProfileVM.addressing : "Chủ nhân") + " (" + (typeof userProfileVM !== "undefined" ? userProfileVM.userName : "quocnho") + ")"
                        color: ThemeManager.textPrimary
                        font.bold: true
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Trình độ: " + (typeof userProfileVM !== "undefined" ? userProfileVM.technicalLevel : "Senior Systems Architect")
                        color: ThemeManager.textSecondary
                        font.pixelSize: 11
                    }
                }
            }
        }

        // 🎨 Chọn phong cách màu sắc giao diện (Kế thừa từ assistant)
        RowLayout {
            Layout.fillWidth: true
            Text { text: "🎨 Phong cách màu sắc:"; color: ThemeManager.textPrimary; Layout.fillWidth: true }
            ComboBox {
                id: themeCombo
                model: [
                    { id: "teal", label: "Xanh Ngọc BamOS (Mặc định)" },
                    { id: "amber", label: "Cam Hổ Phách Ấm Áp" },
                    { id: "cyan", label: "Cyberpunk Cyan Neon" },
                    { id: "purple", label: "Tím Hoàng Gia" },
                    { id: "mocha", label: "Catppuccin Mocha Tối" }
                ]
                textRole: "label"
                currentIndex: {
                    var current = (typeof userProfileVM !== "undefined" && userProfileVM.themeStyle !== "") ? userProfileVM.themeStyle : ThemeManager.currentTheme;
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].id === current) return i;
                    }
                    return 0;
                }
                onActivated: function(index) {
                    var selected = model[index].id;
                    ThemeManager.setTheme(selected);
                    if (typeof userProfileVM !== "undefined") {
                        userProfileVM.themeStyle = selected;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Cách xưng hô:"; color: ThemeManager.textPrimary; Layout.fillWidth: true }
            TextField {
                text: typeof userProfileVM !== "undefined" ? userProfileVM.addressing : "Chủ nhân"
                color: ThemeManager.textPrimary
                background: Rectangle { color: ThemeManager.inputBg; radius: 6; border.color: ThemeManager.borderDim }
                onEditingFinished: {
                    if (typeof userProfileVM !== "undefined") userProfileVM.addressing = text;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Cấp độ kỹ thuật:"; color: ThemeManager.textPrimary; Layout.fillWidth: true }
            TextField {
                text: typeof userProfileVM !== "undefined" ? userProfileVM.technicalLevel : "Senior Systems Architect"
                color: ThemeManager.textPrimary
                background: Rectangle { color: ThemeManager.inputBg; radius: 6; border.color: ThemeManager.borderDim }
                onEditingFinished: {
                    if (typeof userProfileVM !== "undefined") userProfileVM.technicalLevel = text;
                }
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            text: "Lưu Hồ Sơ & Cài Đặt"
            Layout.alignment: Qt.AlignRight
            onClicked: {
                if (typeof userProfileVM !== "undefined") userProfileVM.saveProfile();
                profileDialog.close();
            }
        }
    }
}
