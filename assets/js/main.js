// ==========================================
// BamOS — Theme Toggle (Dark / Light)
// ==========================================
(function () {
  const html = document.documentElement;
  const toggle = document.getElementById("themeToggle");
  const icon = document.getElementById("themeIcon");

  const systemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  const savedTheme = localStorage.getItem("bamos-theme");

  function setTheme(isDark) {
    html.setAttribute("data-bs-theme", isDark ? "dark" : "light");
    icon.className = isDark ? "bi bi-sun-fill" : "bi bi-moon-stars-fill";
    localStorage.setItem("bamos-theme", isDark ? "dark" : "light");
  }

  if (savedTheme) {
    setTheme(savedTheme === "dark");
  } else {
    setTheme(systemDark);
  }

  toggle.addEventListener("click", () => {
    const isDark = html.getAttribute("data-bs-theme") === "dark";
    setTheme(!isDark);
  });

  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", (e) => {
      if (!localStorage.getItem("bamos-theme")) {
        setTheme(e.matches);
      }
    });
})();

// ==========================================
// Countdown Timer — to 01/06/2026 00:00:00 (GMT+7)
// ==========================================
(function () {
  var launchDate = new Date("2026-06-06T00:00:00+07:00").getTime();
  var daysEl = document.getElementById("days");
  var hoursEl = document.getElementById("hours");
  var minutesEl = document.getElementById("minutes");
  var secondsEl = document.getElementById("seconds");

  function pad(n) {
    return n < 10 ? "0" + n : n;
  }

  function updateCountdown() {
    var now = new Date().getTime();
    var distance = launchDate - now;

    if (distance <= 0) {
      daysEl.textContent = "00";
      hoursEl.textContent = "00";
      minutesEl.textContent = "00";
      secondsEl.textContent = "00";
      return;
    }

    var days = Math.floor(distance / (1000 * 60 * 60 * 24));
    var hours = Math.floor(
      (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60),
    );
    var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    var seconds = Math.floor((distance % (1000 * 60)) / 1000);

    daysEl.textContent = pad(days);
    hoursEl.textContent = pad(hours);
    minutesEl.textContent = pad(minutes);
    secondsEl.textContent = pad(seconds);
  }

  updateCountdown();
  setInterval(updateCountdown, 1000);
})();

// ==========================================
// Header shadow on scroll
// ==========================================
(function () {
  var header = document.getElementById("header");

  window.addEventListener(
    "scroll",
    function () {
      if (window.scrollY > 10) {
        header.classList.add("scrolled");
      } else {
        header.classList.remove("scrolled");
      }
    },
    { passive: true },
  );
})();

// ==========================================
// Intersection Observer for fade-in animations
// ==========================================
(function () {
  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.style.animationPlayState = "running";
        }
      });
    },
    { threshold: 0.1 },
  );

  document.querySelectorAll(".fade-in-up").forEach(function (el) {
    el.style.animationPlayState = "paused";
    observer.observe(el);
  });
})();

// ==========================================
// Mobile Bottom Nav — Scroll Spy
// ==========================================
(function () {
  var items = document.querySelectorAll(".mobile-nav-item");
  var sections = [];
  items.forEach(function (item) {
    var id = item.getAttribute("data-section");
    var el = document.getElementById(id);
    if (el) sections.push({ id: id, el: el, nav: item });
  });

  function updateActive() {
    var scrollY = window.scrollY + 100;
    var current = sections[0];
    sections.forEach(function (s) {
      if (s.el.offsetTop <= scrollY) current = s;
    });
    items.forEach(function (item) {
      item.classList.remove("active");
    });
    if (current) current.nav.classList.add("active");
  }

  window.addEventListener("scroll", updateActive, { passive: true });
  updateActive();

  // Smooth scroll on tap
  items.forEach(function (item) {
    item.addEventListener("click", function (e) {
      e.preventDefault();
      var id = this.getAttribute("data-section");
      var el = document.getElementById(id);
      if (el) {
        var offset = el.offsetTop - 60;
        window.scrollTo({ top: offset, behavior: "smooth" });
      }
    });
  });
})();

// ==========================================
// Maintenance active — dim page, glow bar
// ==========================================
(function () {
  var body = document.body;
  var bar = document.querySelector(".maintenance-bar");
  if (bar) {
    setTimeout(function () {
      body.classList.add("maintenance-active");
    }, 1500);
    bar.addEventListener("click", function () {
      body.classList.toggle("maintenance-active");
    });
  }
})();

// ==========================================
// BamOS Builder — Interactive options
// ==========================================
(function () {
  document.querySelectorAll(".builder-step").forEach(function (step) {
    var buttons = step.querySelectorAll(".builder-opt");
    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        buttons.forEach(function (b) {
          b.classList.remove("active");
        });
        this.classList.add("active");
      });
    });
  });
})();
