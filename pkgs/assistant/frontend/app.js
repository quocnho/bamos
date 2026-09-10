// BamOS Mascot AI Assistant - Frontend Controller
(function() {
  const petWrapper = document.getElementById('pet-wrapper');
  const speechBubble = document.getElementById('speech-bubble');
  const chatStream = document.getElementById('chat-stream');
  const chatInput = document.getElementById('chat-input');
  const btnSend = document.getElementById('btn-send');
  const btnRagToggle = document.getElementById('btn-rag-toggle');
  const ragBadge = document.getElementById('rag-badge');
  const statusLabel = document.getElementById('status-label');
  const btnMinimize = document.getElementById('btn-minimize');
  const btnClose = document.getElementById('btn-close');
  const heartBurst = document.getElementById('heart-burst');

  let useRag = true;
  let currentState = 'idle';
  let sleepTimer = null;
  let isDragging = false;
  let startX = 0;
  let startY = 0;

  // Đổi trạng thái hiển thị của cún
  function setState(state) {
    currentState = state;
    document.body.className = `state-${state}`;
    resetSleepTimer();
  }

  function resetSleepTimer() {
    clearTimeout(sleepTimer);
    if (currentState === 'sleeping') {
      setState('idle');
    }
    // Sau 2 phút không hoạt động sẽ ngủ gật
    sleepTimer = setTimeout(() => {
      if (speechBubble.classList.contains('hidden')) {
        setState('sleeping');
      }
    }, 120000);
  }

  // Hiệu ứng vuốt ve cún (Petting)
  function petHappy() {
    heartBurst.classList.add('animate');
    setTimeout(() => {
      heartBurst.classList.remove('animate');
    }, 600);
    setState('happy');
    setTimeout(() => {
      if (currentState === 'happy') setState('idle');
    }, 1500);
  }

  // Toggle bong bóng thoại
  function toggleBubble() {
    const isHidden = speechBubble.classList.contains('hidden');
    if (isHidden) {
      speechBubble.classList.remove('hidden');
      chatInput.focus();
    } else {
      speechBubble.classList.add('hidden');
    }
  }

  // Tương tác kéo thả và click cún
  petWrapper.addEventListener('mousedown', (e) => {
    isDragging = false;
    startX = e.screenX;
    startY = e.screenY;

    // Lắng nghe di chuyển để phân biệt click vs drag
    const onMouseMove = (moveEvent) => {
      const dx = Math.abs(moveEvent.screenX - startX);
      const dy = Math.abs(moveEvent.screenY - startY);
      if (dx > 5 || dy > 5) {
        isDragging = true;
        window.removeEventListener('mousemove', onMouseMove);
        // Gọi native drag window qua backend Go
        if (window.assistantNative && window.assistantNative.dragWindow) {
          window.assistantNative.dragWindow();
        }
      }
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
      if (!isDragging) {
        petHappy();
        toggleBubble();
      }
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  });

  // Kéo thả từ header của bong bóng
  document.querySelector('.bubble-header').addEventListener('mousedown', (e) => {
    if (e.target.tagName !== 'BUTTON' && window.assistantNative && window.assistantNative.dragWindow) {
      window.assistantNative.dragWindow();
    }
  });

  // Nút đóng / thu nhỏ
  btnMinimize.addEventListener('click', (e) => {
    e.stopPropagation();
    speechBubble.classList.add('hidden');
  });

  btnClose.addEventListener('click', (e) => {
    e.stopPropagation();
    if (window.assistantNative && window.assistantNative.closeApp) {
      window.assistantNative.closeApp();
    } else {
      speechBubble.classList.add('hidden');
    }
  });

  // Toggle chế độ RAG
  btnRagToggle.addEventListener('click', () => {
    useRag = !useRag;
    if (useRag) {
      btnRagToggle.classList.add('active');
      ragBadge.classList.remove('off');
      ragBadge.textContent = '📚 RAG';
    } else {
      btnRagToggle.classList.remove('active');
      ragBadge.classList.add('off');
      ragBadge.textContent = '⚡ LLM';
    }
    chatInput.focus();
  });

  // Gửi câu hỏi tới AI
  function sendQuestion() {
    const question = chatInput.value.trim();
    if (!question) return;

    chatInput.value = '';
    chatStream.innerHTML = `<div class="user-query"><b>Bạn:</b> ${escapeHtml(question)}</div><div class="ai-reply" id="current-reply"><i>Đang tra cứu và suy nghĩ...</i></div>`;
    chatStream.scrollTop = chatStream.scrollHeight;

    statusLabel.textContent = useRag ? 'Đang đọc tri thức...' : 'Đang suy nghĩ...';
    setState('thinking');

    if (window.assistantNative && window.assistantNative.ask) {
      window.assistantNative.ask(question, useRag);
    } else {
      // Fallback mô phỏng nếu chạy trong browser test độc lập
      setTimeout(() => {
        window.onAIChunk("Gâu gâu! Em nhận được câu hỏi rồi. Đang kết nối tới mô hình BamOS AI...");
        window.onAIDone();
      }, 800);
    }
  }

  btnSend.addEventListener('click', sendQuestion);
  chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      sendQuestion();
    }
  });

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Các hàm callback được gọi từ Golang Backend
  window.onAIChunk = function(chunkText, isFirst) {
    setState('talking');
    statusLabel.textContent = 'Cún đang trả lời...';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      if (isFirst || replyEl.querySelector('i')) {
        replyEl.innerHTML = '';
      }
      replyEl.innerHTML += escapeHtml(chunkText).replace(/\n/g, '<br>');
      chatStream.scrollTop = chatStream.scrollHeight;
    }
  };

  window.onAIDone = function() {
    setState('idle');
    statusLabel.textContent = 'Sẵn sàng!';
  };

  window.onAIError = function(errMsg) {
    setState('idle');
    statusLabel.textContent = 'Gặp lỗi rồi!';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      replyEl.innerHTML = `<span style="color: #E53E3E;">Lỗi: ${escapeHtml(errMsg)}</span>`;
    }
  };

  // Đánh thức khi di chuyển chuột
  window.addEventListener('mousemove', resetSleepTimer);
  resetSleepTimer();

})();
