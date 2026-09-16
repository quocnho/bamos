package domain

import "encoding/json"

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatCompletionReq struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage `json:"messages"`
	Temperature float32       `json:"temperature"`
	Stream      bool          `json:"stream"`
}

type StreamDelta struct {
	Content string `json:"content"`
}

type StreamChoice struct {
	Delta StreamDelta `json:"delta"`
}

type StreamChunk struct {
	Choices []StreamChoice `json:"choices"`
}

type NativeMessage struct {
	Action      string          `json:"action"`
	Question    string          `json:"question"`
	Directory   string          `json:"directory"`
	UseRAG      bool            `json:"use_rag"`
	Fullscreen  bool            `json:"fullscreen"`
	AlwaysOnTop bool            `json:"always_on_top"`
	Width       int             `json:"width"`
	Height      int             `json:"height"`
	Full        bool            `json:"full"`
	Debug       string          `json:"debug"`
	History     []ChatMessage   `json:"history"`
	Payload     json.RawMessage `json:"payload"`
}
