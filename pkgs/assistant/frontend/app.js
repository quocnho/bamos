// BamOS Mascot AI Assistant & EyeLeo Health Companion
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
  const btnSleep = document.getElementById('btn-sleep-cún');
  const btnEyeleoToggle = document.getElementById('btn-eyeleo-toggle');
  const heartBurst = document.getElementById('heart-burst');

  // EyeLeo Elements
  const eyeleoBubble = document.getElementById('eyeleo-bubble');
  const eyeleoTypeBadge = document.getElementById('eyeleo-type-badge');
  const eyeleoTimerLabel = document.getElementById('eyeleo-timer-label');
  const eyeleoIcon = document.getElementById('eyeleo-icon');
  const eyeleoMsg = document.getElementById('eyeleo-msg');
  const eyeleoCountdown = document.getElementById('eyeleo-countdown');
  const btnEyeleoDone = document.getElementById('btn-eyeleo-done');
  const btnEyeleoSnooze = document.getElementById('btn-eyeleo-snooze');
  const btnEyeleoDismiss = document.getElementById('btn-eyeleo-dismiss');

  let useRag = true;
  let currentState = 'welcoming'; // Khởi động ban đầu: vẫy đuôi chào mừng
  let aiWoken = false;            // Chưa kích hoạt AI backend
  let isDragging = false;
  let startX = 0;
  let startY = 0;

  // Timers
  let startupWelcomeTimer = null;
  let aiInactivityTimer = null;
  const STARTUP_TIMEOUT_MS = 60 * 1000;    // 1 phút: không bấm gì sẽ nằm ngủ canh nhà
  const INACTIVITY_TIMEOUT_MS = 5 * 60 * 1000; // 5 phút: không dùng AI sẽ tự động tắt/ngủ dịch vụ

  // Cấu hình EyeLeo Health
  let eyeleoEnabled = true;
  let eyeleoTimer = null;
  let countdownInterval = null;
  let workDurationMinutes = 0;

  function setState(state) {
    currentState = state;
    document.body.className = `state-${state}`;
  }

  // Khởi tạo timer 5 phút sau khi dùng AI
  function resetInactivityTimer() {
    if (aiInactivityTimer) clearTimeout(aiInactivityTimer);
    if (!aiWoken) return;

    aiInactivityTimer = setTimeout(() => {
      // 5 phút trôi qua không active
      console.log('[BamAI] 5 phút không tương tác -> Kiểm tra thói quen người dùng để ngủ/tắt dịch vụ AI...');
      if (window.assistantNative && window.assistantNative.evaluateSleepOrStop) {
        window.assistantNative.evaluateSleepOrStop();
      }
      aiWoken = false;
      putCúnToSleep();
      statusLabel.textContent = 'Đã tạm nghỉ để tiết kiệm tài nguyên';
    }, INACTIVITY_TIMEOUT_MS);
  }

  // Khởi tạo timer 1 phút lúc bật máy tính
  function scheduleStartupSleep() {
    if (startupWelcomeTimer) clearTimeout(startupWelcomeTimer);
    startupWelcomeTimer = setTimeout(() => {
      if (!aiWoken) {
        putCúnToSleep();
      }
    }, STARTUP_TIMEOUT_MS);
  }

  // Hiệu ứng vuốt ve cún
  function petHappy() {
    heartBurst.classList.add('animate');
    setTimeout(() => {
      heartBurst.classList.remove('animate');
    }, 600);
    setState('happy');
    setTimeout(() => {
      if (currentState === 'happy') setState(aiWoken ? 'idle' : 'sleeping');
    }, 1500);
  }

  // Đánh thức cún và kích hoạt toàn bộ AI
  function wakeUpCún() {
    if (startupWelcomeTimer) {
      clearTimeout(startupWelcomeTimer);
      startupWelcomeTimer = null;
    }

    if (!aiWoken) {
      aiWoken = true;
      petHappy();
      speechBubble.classList.remove('hidden');
      statusLabel.textContent = 'Đang khởi động toàn bộ AI & RAG...';
      chatStream.innerHTML = `
        <div class="ai-reply">
          🐶 <b>Gâu gâu!</b> Em đã thức dậy phục vụ Chủ nhân rồi đây ạ! Đang khởi động llama-server và cơ sở tri thức... Vui lòng đợi em trong giây lát nhé!
        </div>
      `;

      if (window.assistantNative && window.assistantNative.wakeAI) {
        window.assistantNative.wakeAI();
      }
    } else {
      // Nếu đã thức rồi thì toggle bong bóng chat
      const isHidden = speechBubble.classList.contains('hidden');
      if (isHidden) {
        speechBubble.classList.remove('hidden');
        chatInput.focus();
        setState('idle');
      } else {
        speechBubble.classList.add('hidden');
      }
    }
    resetInactivityTimer();
  }

  // Callback từ Go khi AI đang khởi động
  window.onAIWaking = function(progressMsg) {
    statusLabel.textContent = progressMsg;
    setState('thinking');
  };

  // Callback từ Go khi AI và RAG đã sẵn sàng
  window.onAIReady = function() {
    setState('idle');
    statusLabel.textContent = 'Sẵn sàng phục vụ Chủ nhân!';
    chatStream.innerHTML = `
      <div class="ai-reply">
        ✨ <b>Gâu gâu!</b> Toàn bộ dịch vụ AI và RAG đã sẵn sàng 100%! Chủ nhân hãy hỏi em bất cứ điều gì nhé!
      </div>
    `;
    chatInput.focus();
    resetInactivityTimer();
  };

  // Cho cún nằm xuống ngủ canh nhà (tiết kiệm tài nguyên tuyệt đối)
  function putCúnToSleep() {
    setState('sleeping');
    speechBubble.classList.add('hidden');
  }

  btnSleep.addEventListener('click', (e) => {
    e.stopPropagation();
    if (window.assistantNative && window.assistantNative.evaluateSleepOrStop) {
      window.assistantNative.evaluateSleepOrStop();
    }
    aiWoken = false;
    putCúnToSleep();
  });

  // Tương tác kéo thả và click chuột vào cún
  petWrapper.addEventListener('mousedown', (e) => {
    isDragging = false;
    startX = e.screenX;
    startY = e.screenY;

    const onMouseMove = (moveEvent) => {
      const dx = Math.abs(moveEvent.screenX - startX);
      const dy = Math.abs(moveEvent.screenY - startY);
      if (dx > 5 || dy > 5) {
        isDragging = true;
        window.removeEventListener('mousemove', onMouseMove);
        if (window.assistantNative && window.assistantNative.dragWindow) {
          window.assistantNative.dragWindow();
        }
      }
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
      if (!isDragging) {
        wakeUpCún();
      }
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  });

  // Kéo thả từ header
  document.querySelector('.bubble-header').addEventListener('mousedown', (e) => {
    if (e.target.tagName !== 'BUTTON' && window.assistantNative && window.assistantNative.dragWindow) {
      window.assistantNative.dragWindow();
    }
  });

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

  // Toggle RAG
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

  // Gửi câu hỏi AI
  function sendQuestion() {
    const question = chatInput.value.trim();
    if (!question) return;

    if (!aiWoken) {
      wakeUpCún();
    }
    resetInactivityTimer();

    chatInput.value = '';
    chatStream.innerHTML = `
      <div class="user-query"><b>Chủ nhân:</b> ${escapeHtml(question)}</div>
      <div class="ai-reply" id="current-reply"><i>Em đang tra cứu và suy nghĩ...</i></div>
    `;
    chatStream.scrollTop = chatStream.scrollHeight;

    statusLabel.textContent = useRag ? 'Đang đọc tri thức...' : 'Đang suy nghĩ...';
    setState('thinking');

    if (window.assistantNative && window.assistantNative.ask) {
      window.assistantNative.ask(question, useRag);
    }
  }

  btnSend.addEventListener('click', sendQuestion);
  chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') sendQuestion();
  });

  // Khi click hoặc focus vào ô chat, nếu cún đang ngủ hoặc đón chào thì kích hoạt ngay
  chatInput.addEventListener('focus', () => {
    if (!aiWoken) {
      wakeUpCún();
    }
    resetInactivityTimer();
  });

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Callbacks streaming chat
  window.onAIChunk = function(chunkText, isFirst) {
    setState('talking');
    statusLabel.textContent = 'Em đang trả lời...';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      if (isFirst || replyEl.querySelector('i')) {
        replyEl.innerHTML = '';
      }
      replyEl.innerHTML += escapeHtml(chunkText).replace(/\n/g, '<br>');
      chatStream.scrollTop = chatStream.scrollHeight;
    }
    resetInactivityTimer();
  };

  window.onAIDone = function() {
    setState('idle');
    statusLabel.textContent = 'Sẵn sàng phục vụ Chủ nhân!';
    resetInactivityTimer();
  };

  window.onAIError = function(errMsg) {
    setState('idle');
    statusLabel.textContent = 'Gặp lỗi rồi!';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      replyEl.innerHTML = `<span style="color: #E53E3E;">Lỗi: ${escapeHtml(errMsg)}</span>`;
    }
    resetInactivityTimer();
  };

  // ===================================================
  // HỆ THỐNG CHĂM SÓC SỨC KHỎE EYELEO (MẮT, NƯỚC, VƯƠN VAI)
  // ===================================================
  function startEyeleoScheduler() {
    // Mỗi 1 phút tăng biến đếm
    eyeleoTimer = setInterval(() => {
      if (!eyeleoEnabled) return;
      workDurationMinutes++;

      // Mỗi 25 phút: Nghỉ mắt (Eye Break)
      if (workDurationMinutes % 25 === 0 && workDurationMinutes % 50 !== 0) {
        triggerEyeBreak();
      }
      // Mỗi 50 phút: Uống nước & Vươn vai (Long Break)
      else if (workDurationMinutes % 50 === 0) {
        triggerLongBreak();
      }
    }, 60000);
  }

  function triggerEyeBreak() {
    eyeleoTypeBadge.textContent = '👀 Nghỉ Mắt 20-20-20';
    eyeleoTypeBadge.style.background = '#F4A261';
    eyeleoTimerLabel.textContent = 'Quy tắc 20 giây';
    eyeleoIcon.textContent = '👀';
    eyeleoMsg.textContent = 'Chủ nhân ơi, hãy rời mắt khỏi màn hình và nhìn ra xa 20 mét trong 20 giây nhé!';
    
    // Cún làm mẫu đảo mắt
    setState('eyeroll');
    showEyeleoCountdown(20, () => {
      closeEyeleoBubble();
      setState(aiWoken ? 'idle' : 'sleeping');
    });
  }

  function triggerLongBreak() {
    eyeleoTypeBadge.textContent = '💧 Uống Nước & Vươn Vai';
    eyeleoTypeBadge.style.background = '#0077B6';
    eyeleoTimerLabel.textContent = 'Nghỉ ngơi 1 phút';
    eyeleoIcon.textContent = '💧';
    eyeleoMsg.textContent = 'Chủ nhân đã ngồi làm việc gần 1 tiếng rồi! Hãy đứng dậy uống một ly nước và vươn vai thư giãn nhé!';

    setState('happy');
    showEyeleoCountdown(60, () => {
      closeEyeleoBubble();
      setState(aiWoken ? 'idle' : 'sleeping');
    });
  }

  function showEyeleoCountdown(seconds, onFinish) {
    clearInterval(countdownInterval);
    speechBubble.classList.add('hidden'); // Ưu tiên hiện cảnh báo sức khỏe
    eyeleoBubble.classList.remove('hidden');

    let remaining = seconds;
    eyeleoCountdown.textContent = `${remaining}s`;

    countdownInterval = setInterval(() => {
      remaining--;
      eyeleoCountdown.textContent = `${remaining}s`;
      if (remaining <= 0) {
        clearInterval(countdownInterval);
        if (onFinish) onFinish();
      }
    }, 1000);
  }

  function closeEyeleoBubble() {
    clearInterval(countdownInterval);
    eyeleoBubble.classList.add('hidden');
  }

  btnEyeleoDone.addEventListener('click', () => {
    closeEyeleoBubble();
    petHappy();
  });

  btnEyeleoDismiss.addEventListener('click', closeEyeleoBubble);

  btnEyeleoSnooze.addEventListener('click', () => {
    closeEyeleoBubble();
    // Hoãn 5 phút
    workDurationMinutes -= 20; 
  });

  btnEyeleoToggle.addEventListener('click', () => {
    eyeleoEnabled = !eyeleoEnabled;
    btnEyeleoToggle.classList.toggle('active', eyeleoEnabled);
    btnEyeleoToggle.title = eyeleoEnabled ? 'EyeLeo đang BẬT' : 'EyeLeo đang TẮT';
  });

  // Xử lý click các chip gợi ý nhanh (Smart Suggestions)
  document.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const q = chip.getAttribute('data-query');
      if (q) {
        chatInput.value = q;
        sendQuestion();
      }
    });
  });

  // Xử lý kéo thả tệp tin từ desktop/file manager vào chú cún
  window.addEventListener('dragover', (e) => {
    e.preventDefault();
    petWrapper.style.transform = 'scale(1.08)';
  });

  window.addEventListener('dragleave', (e) => {
    e.preventDefault();
    petWrapper.style.transform = 'none';
  });

  window.addEventListener('drop', (e) => {
    e.preventDefault();
    petWrapper.style.transform = 'none';
    if (!aiWoken) wakeUpCún();

    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const file = e.dataTransfer.files[0];
      const filePath = file.name;
      petHappy();
      speechBubble.classList.remove('hidden');
      chatInput.value = `Đọc file ${filePath}`;
      chatInput.focus();
    }
  });

  // Bắt đầu bộ đếm EyeLeo
  startEyeleoScheduler();

  // Khởi động mặc định: nhảy nhảy, vẫy đuôi mừng rỡ đón chào Chủ nhân
  setState('welcoming');
  scheduleStartupSleep();

})();
