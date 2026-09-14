import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * @brief EyeLeoBreakOverlay: Lớp phủ bán trong suốt kính mờ khi đến giờ nghỉ
 * Hiển thị bài tập đảo mắt cùng cún cưng (Nghỉ ngắn) hoặc khóa nghỉ ngơi (Nghỉ dài kèm Strict Mode)
 */
Rectangle {
    id: overlayRoot
    anchors.fill: parent
    visible: typeof eyeLeoVM !== "undefined" && (eyeLeoVM.isBreakActive || eyeLeoVM.isPrebreakActive)
    color: (typeof eyeLeoVM !== "undefined" && eyeLeoVM.breakType === "long") ? "#F211111B" : "#D9181825"
    z: 9999

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        width: Math.min(parent.width - 40, 420)

        // Biểu tượng & Hoạt ảnh cún cưng trong giờ nghỉ
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 90
            height: 90

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: (typeof eyeLeoVM !== "undefined" && eyeLeoVM.breakType === "long") ? "../../../assets/pet/cho ngu.png" : "../../../assets/pet/cho nhay.png"
            }
        }

        // Tiêu đề & Thông điệp
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (typeof eyeLeoVM === "undefined") return "⏰ Chế độ bảo vệ mắt";
                if (eyeLeoVM.isPrebreakActive) return "⏰ Sắp tới giờ nghỉ dài (30 giây nữa)";
                if (eyeLeoVM.breakType === "short") return "👁️ Hãy chớp mắt và nhìn ra xa (20-20-20)";
                return "☕ Đã đến giờ nghỉ ngơi và vận động!";
            }
            font.bold: true
            font.pixelSize: 16
            color: "#F9E2AF"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        // Bộ đếm ngược thời gian
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 110
            height: 44
            radius: 22
            color: "#313244"
            border.color: "#89B4FA"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: {
                    var sec = typeof eyeLeoVM !== "undefined" ? eyeLeoVM.countdownSec : 20;
                    var m = Math.floor(sec / 60);
                    var s = sec % 60;
                    return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
                }
                font.bold: true
                font.pixelSize: 20
                color: "#A6E3A1"
            }
        }

        // Hướng dẫn bài tập mắt chuyển động
        Text {
            Layout.fillWidth: true
            text: {
                if (typeof eyeLeoVM !== "undefined") {
                    if (eyeLeoVM.breakType === "short")
                        return "Di chuyển mắt theo hình tròn, nhìn vào một điểm xa ngoài cửa sổ trong 20 giây.";
                    if (eyeLeoVM.breakType === "long")
                        return "Rời khỏi ghế, vươn vai, uống một cốc nước ấm và thả lỏng cơ thể.";
                }
                return "Chuẩn bị lưu công việc, sắp tới giờ nghỉ ngơi định kỳ.";
            }
            font.pixelSize: 12
            color: "#BAC2DE"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        // Các nút thao tác (Hoãn, Bỏ qua, Đóng)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                text: "Hoãn 3 phút"
                visible: typeof eyeLeoVM !== "undefined" && eyeLeoVM.breakType === "long" && !eyeLeoVM.isStrict
                onClicked: {
                    if (typeof eyeLeoVM !== "undefined") eyeLeoVM.postponeLongBreak();
                }
            }

            Button {
                text: (typeof eyeLeoVM !== "undefined" && eyeLeoVM.isPrebreakActive) ? "Đã hiểu" : "Bỏ qua"
                visible: !(typeof eyeLeoVM !== "undefined" && eyeLeoVM.isStrict && eyeLeoVM.breakType === "long")
                onClicked: {
                    if (typeof eyeLeoVM !== "undefined") {
                        if (eyeLeoVM.isPrebreakActive) eyeLeoVM.dismissPrebreak();
                        else eyeLeoVM.skipBreak();
                    } else {
                        overlayRoot.visible = false;
                    }
                }
            }
        }
    }
}
