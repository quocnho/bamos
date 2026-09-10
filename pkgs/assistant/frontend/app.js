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

  // Cục Xương Context Elements
  const boneContextBar = document.getElementById('bone-context-bar');
  const boneDirText = document.getElementById('bone-dir-text');
  const btnClearBone = document.getElementById('btn-clear-bone');
  const mouthBone = document.getElementById('mouth-bone');
  let currentContextDir = "";

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

  // Thêm các phần tử mới: Dừng cưỡng chế & Đính kèm (+)
  const btnStopStream = document.getElementById('btn-stop-stream');
  const btnAttach = document.getElementById('btn-attach');
  const fileUploadInput = document.getElementById('file-upload-input');
  const attachedPreviewBar = document.getElementById('attached-preview-bar');
  const attachedFilename = document.getElementById('attached-filename');
  const attachedIcon = document.getElementById('attached-icon');
  const btnRemoveAttachment = document.getElementById('btn-remove-attachment');

  let currentAttachment = null; // { name: string, content: string, type: 'file' | 'image' }
  let fullAccumulatedReply = "";

  // Xử lý nút dừng cưỡng chế câu trả lời (Stop Button)
  btnStopStream.addEventListener('click', (e) => {
    e.stopPropagation();
    console.log('[BamAI] Chủ nhân yêu cầu dừng cưỡng chế câu trả lời...');
    if (window.assistantNative && window.assistantNative.stopGeneration) {
      window.assistantNative.stopGeneration();
    }
    btnStopStream.classList.add('hidden');
    setState('idle');
    statusLabel.textContent = 'Đã dừng câu trả lời theo yêu cầu';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      replyEl.innerHTML += '<div style="color: #E76F51; font-size: 11.5px; margin-top: 6px;"><i>⏹ (Đã dừng trả lời)</i></div>';
    }
    resetInactivityTimer();
  });

  // Xử lý nút (+) đính kèm hình ảnh hoặc tài liệu
  btnAttach.addEventListener('click', (e) => {
    e.stopPropagation();
    fileUploadInput.click();
  });

  fileUploadInput.addEventListener('change', (e) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      const isImg = file.type.startsWith('image/');
      
      const reader = new FileReader();
      reader.onload = (loadEvent) => {
        currentAttachment = {
          name: file.name,
          type: isImg ? 'image' : 'file',
          content: loadEvent.target.result // text hoặc data URL
        };
        attachedIcon.textContent = isImg ? '🖼️' : '📄';
        attachedFilename.textContent = file.name;
        attachedPreviewBar.classList.remove('hidden');
        chatInput.focus();
      };

      if (isImg) {
        reader.readAsDataURL(file);
      } else {
        reader.readAsText(file);
      }
    }
  });

  btnRemoveAttachment.addEventListener('click', () => {
    currentAttachment = null;
    fileUploadInput.value = '';
    attachedPreviewBar.classList.add('hidden');
  });

  // Gửi câu hỏi AI
  function sendQuestion() {
    let question = chatInput.value.trim();
    if (!question && !currentAttachment) return;

    if (!aiWoken) {
      wakeUpCún();
    }
    resetInactivityTimer();

    // Nếu có tài liệu/hình ảnh đính kèm (+), ghép vào yêu cầu
    let displayUserMsg = question;
    if (currentAttachment) {
      if (currentAttachment.type === 'image') {
        displayUserMsg = `🖼️ [Đính kèm ảnh: ${currentAttachment.name}] ` + question;
        question = `[Chủ nhân gửi kèm tệp ảnh ${currentAttachment.name}]\n` + question;
      } else {
        displayUserMsg = `📄 [Đính kèm file: ${currentAttachment.name}] ` + question;
        question = `=== NỘI DUNG TỆP ĐÍNH KÈM: ${currentAttachment.name} ===\n${currentAttachment.content}\n===================================\n` + (question || `Chủ nhân gửi tệp ${currentAttachment.name}, hãy đọc và phân tích tóm tắt nội dung này nhé!`);
      }
      currentAttachment = null;
      fileUploadInput.value = '';
      attachedPreviewBar.classList.add('hidden');
    }

    chatInput.value = '';
    fullAccumulatedReply = "";
    btnStopStream.classList.remove('hidden'); // Hiển thị nút Stop cưỡng chế

    chatStream.innerHTML = `
      <div class="user-query"><b>Chủ nhân:</b> ${escapeHtml(displayUserMsg)}</div>
      <div class="ai-reply" id="current-reply"><i>Em đang tra cứu và xử lý...</i></div>
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

  // Bộ chuyển đổi Visual HTML Markdown giàu sắc thái (màu sắc, đậm nhạt, thụt dòng, terminal live)
  function renderVisualMarkdown(text) {
    // 1. Tách và parse thẻ <terminal cmd="...">...</terminal>
    let processed = text.replace(/<terminal(?:\s+cmd="([^"]*)")?>([\s\S]*?)<\/terminal>/g, (match, cmd, termBody) => {
      const displayCmd = cmd || 'bam';
      return `
        <div class="terminal-window">
          <div class="terminal-header">
            <div class="terminal-dots">
              <div class="terminal-dot dot-red"></div>
              <div class="terminal-dot dot-yellow"></div>
              <div class="terminal-dot dot-green"></div>
            </div>
            <div class="terminal-title">🖥️ BamOS Terminal: <code>${escapeHtml(displayCmd)}</code></div>
          </div>
          <div class="terminal-body">${escapeHtml(termBody.trim())}</div>
        </div>
      `;
    });

    // Nếu thẻ <terminal cmd="..."> chưa kịp đóng do đang streaming:
    processed = processed.replace(/<terminal(?:\s+cmd="([^"]*)")?>([\s\S]*)$/g, (match, cmd, termBody) => {
      const displayCmd = cmd || 'bam';
      return `
        <div class="terminal-window">
          <div class="terminal-header">
            <div class="terminal-dots">
              <div class="terminal-dot dot-red"></div>
              <div class="terminal-dot dot-yellow"></div>
              <div class="terminal-dot dot-green"></div>
            </div>
            <div class="terminal-title">⚡ Đang chạy lệnh: <code>${escapeHtml(displayCmd)}</code>...</div>
          </div>
          <div class="terminal-body">${escapeHtml(termBody)}<span style="animation: fastWagTail 0.8s infinite;">▋</span></div>
        </div>
      `;
    });

    // 2. Format Code blocks ```lang ... ```
    processed = processed.replace(/```([a-zA-Z0-9_\-]*)\n([\s\S]*?)```/g, (match, lang, code) => {
      return `<pre><code>${escapeHtml(code.trim())}</code></pre>`;
    });

    // 3. Format Inline code `code`
    processed = processed.replace(/`([^`\n]+)`/g, (match, code) => {
      return `<code>${escapeHtml(code)}</code>`;
    });

    // 4. Format Tiêu đề h1, h2, h3
    processed = processed.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    processed = processed.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    processed = processed.replace(/^# (.*$)/gim, '<h1>$1</h1>');

    // 5. Format In đậm **text** hoặc __text__
    processed = processed.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    processed = processed.replace(/__(.*?)__/g, '<strong>$1</strong>');

    // 6. Format In nghiêng *text* hoặc _text_
    processed = processed.replace(/\*([^\*\n]+)\*/g, '<em>$1</em>');
    processed = processed.replace(/_([^_\n]+)_/g, '<em>$1</em>');

    // 7. Format trích dẫn blockquote > text
    processed = processed.replace(/^> (.*$)/gim, '<blockquote>$1</blockquote>');

    // 8. Format danh sách - hoặc * (thụt dòng)
    processed = processed.replace(/^\s*[\-\*]\s+(.*$)/gim, '<ul><li>$1</li></ul>');
    processed = processed.replace(/<\/ul>\s*<ul>/g, ''); // Gộp ul liền kề

    // 9. Format liên kết tự động http/https
    processed = processed.replace(/(https?:\/\/[^\s<]+)/g, '<a href="$1" target="_blank">$1</a>');

    // 10. Chuyển đổi ngắt dòng thành <br>
    processed = processed.replace(/\n/g, '<br>');

    return processed;
  }

  // Callbacks streaming chat
  window.onAIChunk = function(chunkText, isFirst) {
    setState('talking');
    statusLabel.textContent = 'Em đang trả lời...';
    btnStopStream.classList.remove('hidden');

    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      if (isFirst || replyEl.querySelector('i')) {
        replyEl.innerHTML = '';
        fullAccumulatedReply = "";
      }
      fullAccumulatedReply += chunkText;
      replyEl.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
      chatStream.scrollTop = chatStream.scrollHeight;
    }
    resetInactivityTimer();
  };

  window.onAIDone = function() {
    setState('idle');
    btnStopStream.classList.add('hidden');
    statusLabel.textContent = 'Sẵn sàng phục vụ Chủ nhân!';
    const replyEl = document.getElementById('current-reply');
    if (replyEl && fullAccumulatedReply) {
      replyEl.innerHTML = renderVisualMarkdown(fullAccumulatedReply);
    }
    resetInactivityTimer();
  };

  window.onAIError = function(errMsg) {
    setState('idle');
    btnStopStream.classList.add('hidden');
    statusLabel.textContent = 'Gặp lỗi rồi!';
    const replyEl = document.getElementById('current-reply');
    if (replyEl) {
      replyEl.innerHTML = `<span style="color: #E53E3E; font-weight: bold;">Lỗi: ${escapeHtml(errMsg)}</span>`;
    }
    resetInactivityTimer();
  };

  // ===================================================
  // TÍNH NĂNG CỤC XƯƠNG: NẠP VÀ GỠ BỐI CẢNH THƯ MỤC
  // ===================================================
  function setBoneContext(dirPath) {
    if (!dirPath) return;
    currentContextDir = dirPath;
    boneDirText.textContent = dirPath;
    boneContextBar.classList.remove('hidden');
    if (mouthBone) mouthBone.classList.remove('hidden');

    if (window.assistantNative && window.assistantNative.setContextDir) {
      window.assistantNative.setContextDir(dirPath);
    }

    if (!aiWoken) wakeUpCún();
    petHappy();
    speechBubble.classList.remove('hidden');
    statusLabel.textContent = 'Đã nhận Cục Xương bối cảnh!';
    chatStream.innerHTML = `
      <div class="ai-reply">
        🍖 <b>Gâu gâu! Em đã ngậm Cục Xương bối cảnh:</b><br>
        <code>${escapeHtml(dirPath)}</code><br><br>
        Chủ nhân muốn em làm gì trong thư mục này ạ? (Ví dụ: <i>"thống kê số lượng tập tin nix"</i>, <i>"tìm file cấu hình"</i>, <i>"chạy lệnh git status"</i>...)
      </div>
    `;
    chatInput.placeholder = `Hỏi về thư mục ${dirPath}...`;
    chatInput.focus();
  }

  function clearBoneContext() {
    currentContextDir = "";
    boneContextBar.classList.add('hidden');
    if (mouthBone) mouthBone.classList.add('hidden');
    if (window.assistantNative && window.assistantNative.clearContextDir) {
      window.assistantNative.clearContextDir();
    }
    chatInput.placeholder = "Nói chuyện cùng em... (Enter để gửi)";
    statusLabel.textContent = 'Đã gỡ bối cảnh thư mục';
  }

  btnClearBone.addEventListener('click', (e) => {
    e.stopPropagation();
    clearBoneContext();
  });

  // Cho phép gọi từ ngoài (ví dụ CGo hoặc IPC)
  window.setDirectoryContext = function(dirPath) {
    setBoneContext(dirPath);
  };

  // ===================================================
  // HỆ THỐNG BẢO VỆ MẮT EYELEO CÔNG THÁI HỌC TOÀN DIỆN
  // ===================================================
  class EyeLeoController {
    constructor() {
      // Elements
      this.prebreakToast = document.getElementById('eyeleo-prebreak-toast');
      this.prebreakSeconds = document.getElementById('prebreak-seconds');
      this.btnPrebreakDismiss = document.getElementById('btn-prebreak-dismiss');

      this.shortbreakBubble = document.getElementById('eyeleo-shortbreak-bubble');
      this.shortbreakExerciseName = document.getElementById('shortbreak-exercise-name');
      this.shortbreakIcon = document.getElementById('shortbreak-icon');
      this.shortbreakInstruction = document.getElementById('shortbreak-instruction');
      this.shortbreakProgress = document.getElementById('shortbreak-progress');
      this.shortbreakCountdown = document.getElementById('shortbreak-countdown');
      this.btnShortbreakSkip = document.getElementById('btn-shortbreak-skip');

      this.longbreakOverlay = document.getElementById('eyeleo-longbreak-overlay');
      this.longbreakClock = document.getElementById('longbreak-clock');
      this.longbreakTitle = document.getElementById('longbreak-title');
      this.longbreakDesc = document.getElementById('longbreak-desc');
      this.strictModeIndicator = document.getElementById('strict-mode-indicator');
      this.btnLongbreakPostpone = document.getElementById('btn-longbreak-postpone');
      this.btnLongbreakSkip = document.getElementById('btn-longbreak-skip');

      this.settingsModal = document.getElementById('eyeleo-settings-modal');
      this.btnCloseSettings = document.getElementById('btn-close-eyeleo-settings');
      this.btnSaveSettings = document.getElementById('btn-save-settings');

      // Cài đặt mặc định theo chuẩn công thái học thị giác
      this.config = {
        enabled: true,
        shortIntervalMinutes: 10,
        shortDurationSeconds: 8,
        longIntervalMinutes: 50,
        longDurationSeconds: 300, // 5 phút
        strictMode: false,
        prebreakNotify: true,
        autoIdle: true,
        soundEnabled: true,
        idleThresholdMs: 3 * 60 * 1000 // 3 phút
      };

      this.loadConfig();

      // State counters
      this.workSeconds = 0;
      this.lastShortBreakAt = 0;
      this.lastLongBreakAt = 0;
      this.prebreakFired = false;
      this.activeBreak = null; // 'short' | 'long' | null

      this.ticker = null;
      this.breakCountdown = null;
      this.audioCtx = null;

      // Danh sách bài tập mắt kèm hoạt họa
      this.eyeExercises = [
        {
          id: 'blink',
          name: 'Chớp Mắt Liên Tục',
          icon: '✨',
          cssClass: 'exercise-blink',
          instruction: 'Chủ nhân hãy nhìn theo mắt em và chớp mắt liên tục để tuyến lệ làm ẩm màng giác mạc nhé!'
        },
        {
          id: 'left-right',
          name: 'Liếc Mắt Trái - Phải',
          icon: '👀',
          cssClass: 'exercise-left-right',
          instruction: 'Chủ nhân hãy cùng em liếc mắt sang trái 2 giây, rồi sang phải 2 giây để thư giãn cơ vận nhãn nhé!'
        },
        {
          id: 'roll',
          name: 'Xoay Tròn Mắt 360°',
          icon: '🔄',
          cssClass: 'exercise-roll',
          instruction: 'Chủ nhân hãy đảo mắt chầm chậm theo hình vòng tròn cùng em để xua tan mỏi mắt nhé!'
        },
        {
          id: 'look-far',
          name: 'Nhìn Ra Xa (>6m)',
          icon: '🏞️',
          cssClass: 'exercise-look-far',
          instruction: 'Chủ nhân hãy phóng tầm mắt qua cửa sổ hoặc nhìn một điểm thật xa để cơ thể mi được thả lỏng hoàn toàn nhé!'
        }
      ];

      this.initEvents();
    }

    loadConfig() {
      try {
        const saved = localStorage.getItem('eyeleo_config');
        if (saved) {
          this.config = Object.assign(this.config, JSON.parse(saved));
        }
      } catch (e) {
        console.warn('[EyeLeo] Lỗi đọc localStorage:', e);
      }
    }

    saveConfig() {
      try {
        localStorage.setItem('eyeleo_config', JSON.stringify(this.config));
      } catch (e) {
        console.warn('[EyeLeo] Lỗi lưu localStorage:', e);
      }
    }

    initEvents() {
      // Nút mở modal cài đặt từ header cún
      btnEyeleoToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openSettingsModal();
      });

      this.btnCloseSettings.addEventListener('click', () => {
        this.closeSettingsModal();
      });

      this.btnSaveSettings.addEventListener('click', () => {
        this.readSettingsFromForm();
        this.closeSettingsModal();
      });

      // Prebreak dismiss
      this.btnPrebreakDismiss.addEventListener('click', () => {
        this.prebreakToast.classList.add('hidden');
      });

      // Short break skip
      this.btnShortbreakSkip.addEventListener('click', () => {
        this.endShortBreak();
      });

      // Long break buttons
      this.btnLongbreakPostpone.addEventListener('click', () => {
        this.postponeLongBreak(2 * 60); // Hoãn 2 phút
      });

      this.btnLongbreakSkip.addEventListener('click', () => {
        if (!this.config.strictMode) {
          this.endLongBreak();
        }
      });

      // Lắng nghe cập nhật idle từ Go CGo Mutter D-Bus
      window.onIdleTimeUpdate = (idleMs) => {
        if (this.config.autoIdle && idleMs >= this.config.idleThresholdMs) {
          // Người dùng đã rời máy tính hơn 3 phút -> Tự động reset bộ đếm chu kỳ
          if (this.workSeconds > 60) {
            console.log(`[EyeLeo] Phát hiện người dùng không hoạt động ${Math.round(idleMs/1000)}s -> Reset chu kỳ làm việc.`);
            this.workSeconds = 0;
            this.lastShortBreakAt = 0;
            this.lastLongBreakAt = 0;
            this.prebreakFired = false;
          }
        }
      };
    }

    start() {
      if (this.ticker) clearInterval(this.ticker);

      // Bộ đếm 1 giây
      this.ticker = setInterval(() => {
        if (!this.config.enabled || this.activeBreak) return;

        this.workSeconds++;

        // Cứ mỗi 15 giây gửi yêu cầu kiểm tra idle time từ hệ điều hành qua native
        if (this.workSeconds % 15 === 0 && window.assistantNative && window.assistantNative.getIdleTime) {
          window.assistantNative.getIdleTime();
        }

        const shortIntervalSec = this.config.shortIntervalMinutes * 60;
        const longIntervalSec = this.config.longIntervalMinutes * 60;

        // 1. Kiểm tra cảnh báo trước 30 giây (Pre-break notification)
        if (this.config.prebreakNotify && !this.prebreakFired) {
          const secUntilLong = longIntervalSec - (this.workSeconds - this.lastLongBreakAt);
          if (secUntilLong > 0 && secUntilLong <= 30) {
            this.showPrebreakNotification(secUntilLong);
          }
        }

        // 2. Kiểm tra kích hoạt Nghỉ Dài (Long Break)
        if (this.workSeconds - this.lastLongBreakAt >= longIntervalSec) {
          this.triggerLongBreak();
          return;
        }

        // 3. Kiểm tra kích hoạt Nghỉ Ngắn (Short Break)
        if (this.workSeconds - this.lastShortBreakAt >= shortIntervalSec) {
          this.triggerShortBreak();
        }
      }, 1000);
    }

    // Âm thanh chuông thư giãn (Web Audio API Synthesizer)
    playChime(type = 'bell') {
      if (!this.config.soundEnabled) return;
      try {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;
        if (!this.audioCtx) this.audioCtx = new AudioCtx();
        if (this.audioCtx.state === 'suspended') this.audioCtx.resume();

        const now = this.audioCtx.currentTime;
        const osc = this.audioCtx.createOscillator();
        const gain = this.audioCtx.createGain();

        if (type === 'bell') {
          // Chuông bát xoay Tây Tạng (Tibetan Singing Bowl ấm áp 528Hz -> 1056Hz)
          osc.type = 'sine';
          osc.frequency.setValueAtTime(528, now);
          osc.frequency.exponentialRampToValueAtTime(1056, now + 0.35);

          gain.gain.setValueAtTime(0.3, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 1.6);

          osc.connect(gain);
          gain.connect(this.audioCtx.destination);
          osc.start(now);
          osc.stop(now + 1.6);
        } else if (type === 'finish') {
          // 2 tiếng ting nhẹ nhàng mừng hoàn thành
          [587.33, 880].forEach((freq, i) => {
            const o = this.audioCtx.createOscillator();
            const g = this.audioCtx.createGain();
            o.type = 'triangle';
            o.frequency.setValueAtTime(freq, now + i * 0.18);
            g.gain.setValueAtTime(0.2, now + i * 0.18);
            g.gain.exponentialRampToValueAtTime(0.001, now + i * 0.18 + 0.8);
            o.connect(g);
            g.connect(this.audioCtx.destination);
            o.start(now + i * 0.18);
            o.stop(now + i * 0.18 + 0.8);
          });
        }
      } catch (err) {
        console.warn('[EyeLeo Audio] Không thể phát âm thanh:', err);
      }
    }

    // --- 1. PRE-BREAK NOTIFICATION ---
    showPrebreakNotification(remainingSeconds) {
      this.prebreakFired = true;
      this.prebreakSeconds.textContent = remainingSeconds;
      this.prebreakToast.classList.remove('hidden');

      // Kích hoạt ứng dụng và đưa lên cửa sổ trên cùng top màn hình
      if (window.assistantNative && window.assistantNative.activateAndRaise) {
        window.assistantNative.activateAndRaise();
      }

      setTimeout(() => {
        this.prebreakToast.classList.add('hidden');
      }, 10000);
    }

    // --- 2. SHORT BREAK (8s với Cún làm mẫu) ---
    triggerShortBreak() {
      this.activeBreak = 'short';
      this.lastShortBreakAt = this.workSeconds;
      this.prebreakToast.classList.add('hidden');
      speechBubble.classList.add('hidden');

      // Kích hoạt ứng dụng và đưa lên cửa sổ trên cùng top màn hình
      if (window.assistantNative && window.assistantNative.activateAndRaise) {
        window.assistantNative.activateAndRaise();
      }

      // Chọn ngẫu nhiên 1 trong 4 bài tập mắt
      const ex = this.eyeExercises[Math.floor(Math.random() * this.eyeExercises.length)];
      this.shortbreakExerciseName.textContent = ex.name;
      this.shortbreakIcon.textContent = ex.icon;
      this.shortbreakInstruction.textContent = ex.instruction;

      // Áp dụng class cử động mắt cho chú cún
      document.body.classList.remove('exercise-blink', 'exercise-left-right', 'exercise-roll', 'exercise-look-far', 'exercise-stretch');
      document.body.classList.add(ex.cssClass);

      this.playChime('bell');
      this.shortbreakBubble.classList.remove('hidden');

      let remaining = this.config.shortDurationSeconds;
      const total = remaining;
      this.shortbreakCountdown.textContent = `${remaining}s`;
      this.shortbreakProgress.style.width = '100%';

      if (this.breakCountdown) clearInterval(this.breakCountdown);
      this.breakCountdown = setInterval(() => {
        remaining--;
        const pct = Math.max(0, (remaining / total) * 100);
        this.shortbreakProgress.style.width = `${pct}%`;
        this.shortbreakCountdown.textContent = `${remaining}s`;

        if (remaining <= 0) {
          clearInterval(this.breakCountdown);
          this.endShortBreak();
        }
      }, 1000);
    }

    endShortBreak() {
      if (this.breakCountdown) clearInterval(this.breakCountdown);
      this.shortbreakBubble.classList.add('hidden');
      document.body.classList.remove('exercise-blink', 'exercise-left-right', 'exercise-roll', 'exercise-look-far', 'exercise-stretch');
      this.activeBreak = null;
      this.playChime('finish');
      petHappy();
    }

    // --- 3. LONG BREAK (5 phút với vươn vai, ly nước, strict mode) ---
    triggerLongBreak() {
      this.activeBreak = 'long';
      this.lastLongBreakAt = this.workSeconds;
      this.lastShortBreakAt = this.workSeconds; // Reset cả short break
      this.prebreakFired = false;
      this.prebreakToast.classList.add('hidden');
      speechBubble.classList.add('hidden');
      this.shortbreakBubble.classList.add('hidden');

      // Kích hoạt ứng dụng và đưa lên cửa sổ trên cùng top màn hình
      if (window.assistantNative && window.assistantNative.activateAndRaise) {
        window.assistantNative.activateAndRaise();
      }

      // Chú cún chuyển tư thế vươn vai và bưng ly nước 3D
      document.body.classList.remove('exercise-blink', 'exercise-left-right', 'exercise-roll', 'exercise-look-far');
      document.body.classList.add('exercise-stretch');

      // Xử lý Chế độ nghiêm ngặt (Strict Mode)
      if (this.config.strictMode) {
        this.strictModeIndicator.classList.remove('hidden');
        this.btnLongbreakSkip.style.display = 'none'; // Ẩn hoàn toàn nút bỏ qua
      } else {
        this.strictModeIndicator.classList.add('hidden');
        this.btnLongbreakSkip.style.display = '';
      }

      this.playChime('bell');
      this.longbreakOverlay.classList.remove('hidden');

      let remaining = this.config.longDurationSeconds;
      this.updateLongbreakClock(remaining);

      if (this.breakCountdown) clearInterval(this.breakCountdown);
      this.breakCountdown = setInterval(() => {
        remaining--;
        this.updateLongbreakClock(remaining);

        if (remaining <= 0) {
          clearInterval(this.breakCountdown);
          this.endLongBreak();
        }
      }, 1000);
    }

    updateLongbreakClock(sec) {
      const m = Math.floor(sec / 60);
      const s = sec % 60;
      this.longbreakClock.textContent = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }

    postponeLongBreak(seconds) {
      if (this.breakCountdown) clearInterval(this.breakCountdown);
      this.longbreakOverlay.classList.add('hidden');
      document.body.classList.remove('exercise-stretch');
      this.activeBreak = null;
      // Lùi mốc thời gian lại
      this.workSeconds = (this.config.longIntervalMinutes * 60) - seconds;
      this.lastLongBreakAt = 0;
      this.prebreakFired = false;
    }

    endLongBreak() {
      if (this.breakCountdown) clearInterval(this.breakCountdown);
      this.longbreakOverlay.classList.add('hidden');
      document.body.classList.remove('exercise-stretch');
      this.activeBreak = null;
      this.prebreakFired = false;
      this.playChime('finish');
      petHappy();
    }

    // --- 4. MODAL CÀI ĐẶT EYELEO ---
    openSettingsModal() {
      document.getElementById('set-eyeleo-active').checked = this.config.enabled;
      document.getElementById('set-short-interval').value = String(this.config.shortIntervalMinutes);
      document.getElementById('set-short-duration').value = String(this.config.shortDurationSeconds);
      document.getElementById('set-long-interval').value = String(this.config.longIntervalMinutes);
      document.getElementById('set-long-duration').value = String(Math.round(this.config.longDurationSeconds / 60));
      document.getElementById('set-strict-mode').checked = this.config.strictMode;
      document.getElementById('set-prebreak-notify').checked = this.config.prebreakNotify;
      document.getElementById('set-auto-idle').checked = this.config.autoIdle;
      document.getElementById('set-sound-enabled').checked = this.config.soundEnabled;

      this.settingsModal.classList.remove('hidden');
    }

    closeSettingsModal() {
      this.settingsModal.classList.add('hidden');
    }

    readSettingsFromForm() {
      this.config.enabled = document.getElementById('set-eyeleo-active').checked;
      this.config.shortIntervalMinutes = parseInt(document.getElementById('set-short-interval').value, 10);
      this.config.shortDurationSeconds = parseInt(document.getElementById('set-short-duration').value, 10);
      this.config.longIntervalMinutes = parseInt(document.getElementById('set-long-interval').value, 10);
      this.config.longDurationSeconds = parseInt(document.getElementById('set-long-duration').value, 10) * 60;
      this.config.strictMode = document.getElementById('set-strict-mode').checked;
      this.config.prebreakNotify = document.getElementById('set-prebreak-notify').checked;
      this.config.autoIdle = document.getElementById('set-auto-idle').checked;
      this.config.soundEnabled = document.getElementById('set-sound-enabled').checked;

      this.saveConfig();
      btnEyeleoToggle.classList.toggle('active', this.config.enabled);
      btnEyeleoToggle.title = this.config.enabled ? 'Cài đặt EyeLeo (Đang BẬT)' : 'Cài đặt EyeLeo (Đang TẮT)';
      petHappy();
    }
  }

  const eyeleoController = new EyeLeoController();

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

  // Bắt đầu bộ đếm bảo vệ mắt EyeLeo
  eyeleoController.start();

  // Khởi động mặc định: nhảy nhảy, vẫy đuôi mừng rỡ đón chào Chủ nhân
  setState('welcoming');
  scheduleStartupSleep();

})();
