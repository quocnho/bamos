// ============================================================================
// features/eyeleo/exercises.js — Danh sách bài tập mắt kèm hoạt hoạ CSS
// ----------------------------------------------------------------------------
// `cssClass` được gắn vào <body> để CSS chạy hoạt hoạ tương ứng cho chú cún.
// ============================================================================

export const EYE_EXERCISES = [
    {
        id: "blink",
        name: "Chớp Mắt Liên Tục",
        icon: "✨",
        cssClass: "exercise-blink",
        instruction:
            "Chủ nhân hãy nhìn theo mắt em và chớp mắt liên tục để tuyến lệ làm ẩm màng giác mạc nhé!",
    },
    {
        id: "left-right",
        name: "Liếc Mắt Trái - Phải",
        icon: "👀",
        cssClass: "exercise-left-right",
        instruction:
            "Chủ nhân hãy cùng em liếc mắt sang trái 2 giây, rồi sang phải 2 giây để thư giãn cơ vận nhãn nhé!",
    },
    {
        id: "roll",
        name: "Xoay Tròn Mắt 360°",
        icon: "🔄",
        cssClass: "exercise-roll",
        instruction:
            "Chủ nhân hãy đảo mắt chầm chậm theo hình vòng tròn cùng em để xua tan mỏi mắt nhé!",
    },
    {
        id: "look-far",
        name: "Nhìn Ra Xa (>6m)",
        icon: "🏞️",
        cssClass: "exercise-look-far",
        instruction:
            "Chủ nhân hãy phóng tầm mắt qua cửa sổ hoặc nhìn một điểm thật xa để cơ thể mi được thả lỏng hoàn toàn nhé!",
    },
];

/** Tất cả lớp CSS hoạt hoạ mắt (dùng để dọn dẹp trước khi áp dụng bài mới). */
export const EXERCISE_CLASSES = [
    "exercise-blink",
    "exercise-left-right",
    "exercise-roll",
    "exercise-look-far",
    "exercise-stretch",
];
