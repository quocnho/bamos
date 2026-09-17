package chat

import (
	"context"
	"fmt"
	"strings"
	"time"
)

func (u *ChatUsecase) rememberExchange(question, answer string) {
	if u.ragRepo == nil || !u.cfg.EnableRAG {
		return
	}
	q := strings.TrimSpace(question)
	a := strings.TrimSpace(answer)
	if len([]rune(q)) < 4 || len([]rune(a)) < 40 {
		return
	}

	content := fmt.Sprintf(
		"=== HỘI THOẠI NGÀY %s ===\nCâu hỏi: %s\nTrả lời: %s",
		time.Now().Format("2006-01-02 15:04"),
		TruncateRunes(q, 1200),
		TruncateRunes(a, 4000),
	)

	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	id := fmt.Sprintf("hoi-thoai-%d", time.Now().UnixNano())
	_ = u.ragRepo.IndexDocument(ctx, id, content, map[string]string{
		"type":  "conversation",
		"title": TruncateRunes(q, 80),
	})
}
