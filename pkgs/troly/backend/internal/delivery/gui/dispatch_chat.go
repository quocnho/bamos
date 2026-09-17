package gui

import (
	"context"
	"fmt"

	"troly/backend/internal/domain"
)

func (d *Dispatcher) handleAsk(msg domain.NativeMessage) {
	if d.chatUc == nil {
		return
	}
	if d.currentCancel != nil {
		d.currentCancel()
	}
	ctx, cancel := context.WithCancel(context.Background())
	d.currentCancel = cancel

	go func() {
		defer func() {
			d.currentCancel = nil
		}()
		isFirst := true
		d.chatUc.AskStream(
			ctx,
			msg.Question,
			msg.UseRAG,
			msg.History,
			func(chunk string) {
				EvalJS(fmt.Sprintf("window.onAIChunk && window.onAIChunk('%s', %t);", EscapeJSString(chunk), isFirst))
				isFirst = false
			},
			func() {
				EvalJS("window.onAIDone && window.onAIDone();")
			},
			func(errMsg string) {
				EvalJS(fmt.Sprintf("window.onAIError && window.onAIError('%s');", EscapeJSString(errMsg)))
			},
		)
	}()
}

func (d *Dispatcher) handleStop() {
	if d.currentCancel != nil {
		d.currentCancel()
		d.currentCancel = nil
	}
}

func (d *Dispatcher) handleWakeAI() {
	if d.llamaServer != nil {
		go d.llamaServer.EnsureRunning(
			func(progressMsg string) {
				PushJSON("onAIWaking", progressMsg)
			},
			func(started bool) {
				EvalJS(fmt.Sprintf("window.onAIReady && window.onAIReady(%t);", started))
			},
		)
	}
}
