import QtQuick
import QtQuick.Controls

Item {
    id: petRoot
    width: 140
    height: 140

    // Các trạng thái hỗ trợ: "greeting", "idle", "excited", "playful_jump", "sleep"
    property string mascotState: typeof chatVM !== "undefined" ? chatVM.mascotState : "greeting"
    property bool isHovered: false
    property bool isWagging: true

    // Tín hiệu khi người dùng vuốt ve/click vào cún
    signal petClicked()
    signal petDoubleClicked()

    // 12 NGUYÊN TẮC DISNEY: Thùng chứa diễn hoạt cún với tâm co giãn tại đáy (Item.Bottom)
    Item {
        id: animContainer
        anchors.fill: parent
        transformOrigin: Item.Bottom

        // 1. Hình ảnh: Chú cún chào (Greeting - Mặc định khi chào hoặc peek)
        Image {
            id: imgGreeting
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            source: Qt.resolvedUrl("../../../assets/pet/cho_chao.png")
            opacity: (petRoot.mascotState === "greeting" || petRoot.mascotState === "peek_tail") ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        // 2. Hình ảnh: Chú cún đứng ngoan (Idle)
        Image {
            id: imgStanding
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            source: Qt.resolvedUrl("../../../assets/pet/cho_dung.png")
            opacity: (petRoot.mascotState === "idle" || (petRoot.mascotState !== "greeting" && petRoot.mascotState !== "peek_tail" && petRoot.mascotState !== "excited" && petRoot.mascotState !== "playful_jump" && petRoot.mascotState !== "sleep")) ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        // 3. Hình ảnh: Chú cún nhảy tung tăng vẫy đuôi (Excited / Playful Jump)
        Image {
            id: imgJumping
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            source: Qt.resolvedUrl("../../../assets/pet/cho_nhay.png")
            opacity: (petRoot.mascotState === "excited" || petRoot.mascotState === "playful_jump") ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        // 4. Hình ảnh: Chú cún cuộn tròn ngủ (Sleep)
        Image {
            id: imgSleeping
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            source: Qt.resolvedUrl("../../../assets/pet/cho_ngu.png")
            opacity: petRoot.mascotState === "sleep" ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        // ============================================================
        // 🐾 CÁC HOẠT CẢNH DISNEY CHUYÊN NGHIỆP (12 DISNEY PRINCIPLES)
        // ============================================================

        // A. Idle Breathing: Nhịp thở co giãn Squash & Stretch nhẹ nhàng, tự nhiên
        SequentialAnimation {
            id: idleBreathingAnim
            running: petRoot.mascotState === "idle" || petRoot.mascotState === "greeting"
            loops: Animation.Infinite

            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 1.035; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { target: animContainer; property: "rotation"; to: 1.2; duration: 1600; easing.type: Easing.InOutSine }
            }
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 0.985; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { target: animContainer; property: "rotation"; to: -1.2; duration: 1600; easing.type: Easing.InOutSine }
            }
        }

        // B. Sleep Breathing: Hít thở sâu và chậm khi ngủ
        SequentialAnimation {
            id: sleepBreathingAnim
            running: petRoot.mascotState === "sleep"
            loops: Animation.Infinite

            NumberAnimation { target: animContainer; property: "scale"; to: 1.025; duration: 2400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: animContainer; property: "scale"; to: 0.98; duration: 2400; easing.type: Easing.InOutQuad }
        }

        // C. Playful Jump: Nhảy tung tăng, co ép trước khi bật và nảy đàn hồi (Anticipation & Stretch & OutBounce)
        SequentialAnimation {
            id: jumpBounceAnim
            running: petRoot.mascotState === "excited" || petRoot.mascotState === "playful_jump"
            loops: petRoot.mascotState === "playful_jump" ? 2 : Animation.Infinite
            onFinished: {
                if (typeof chatVM !== "undefined" && chatVM.mascotState === "playful_jump") {
                    chatVM.setMascotState("idle");
                }
            }

            // Giai đoạn 1: Chuẩn bị bật nhảy (Anticipation - hạ thấp trọng tâm)
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 0.94; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { target: animContainer; property: "y"; to: 4; duration: 140; easing.type: Easing.OutQuad }
            }
            // Giai đoạn 2: Bật lên cao (Stretch - kéo dãn cơ thể)
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 1.14; duration: 260; easing.type: Easing.OutBack }
                NumberAnimation { target: animContainer; property: "y"; to: -22; duration: 260; easing.type: Easing.OutQuad }
                NumberAnimation { target: animContainer; property: "rotation"; to: 3.5; duration: 260; easing.type: Easing.OutQuad }
            }
            // Giai đoạn 3: Tiếp đất đàn hồi (Squash & OutBounce)
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 1.0; duration: 280; easing.type: Easing.OutBounce }
                NumberAnimation { target: animContainer; property: "y"; to: 0; duration: 280; easing.type: Easing.OutBounce }
                NumberAnimation { target: animContainer; property: "rotation"; to: 0; duration: 280; easing.type: Easing.OutBounce }
            }
            PauseAnimation { duration: 150 }
        }

        // D. Petting Reaction: Phản xạ nhí nhảnh khi người dùng click/xoa đầu
        SequentialAnimation {
            id: pettingReactionAnim
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 0.90; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: animContainer; property: "rotation"; to: -4; duration: 90; easing.type: Easing.OutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 1.15; duration: 160; easing.type: Easing.OutBack }
                NumberAnimation { target: animContainer; property: "rotation"; to: 4; duration: 160; easing.type: Easing.OutBack }
            }
            ParallelAnimation {
                NumberAnimation { target: animContainer; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBounce }
                NumberAnimation { target: animContainer; property: "rotation"; to: 0; duration: 180; easing.type: Easing.OutBounce }
            }
        }
    }

    // Vùng chạm & vuốt ve tương tác trên chú cún
    MouseArea {
        id: touchArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            petRoot.isHovered = true;
            if (petRoot.mascotState === "idle") {
                // Nhẹ nhàng chú ý khi trỏ chuột vào
                animContainer.scale = 1.06;
            }
        }

        onExited: {
            petRoot.isHovered = false;
            if (!pettingReactionAnim.running) {
                animContainer.scale = 1.0;
            }
        }

        onClicked: {
            pettingReactionAnim.restart();
            if (typeof chatVM !== "undefined") {
                chatVM.playSound("bark");
                // Chuyển luân phiên trạng thái chào / đứng nếu đang idle
                if (chatVM.mascotState === "idle") {
                    chatVM.setMascotState("greeting");
                } else if (chatVM.mascotState === "greeting") {
                    chatVM.setMascotState("excited");
                } else {
                    chatVM.setMascotState("idle");
                }
            }
            petRoot.petClicked();
        }

        onDoubleClicked: {
            petRoot.petDoubleClicked();
        }
    }
}
