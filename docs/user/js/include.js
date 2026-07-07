// BamOS Docs — Multi-page support (file:// compatible)
document.addEventListener("DOMContentLoaded", () => {
  // Hamburger toggle
  const sidebar = document.getElementById("sidebar");
  if (sidebar) {
    document.addEventListener("click", (e) => {
      if (
        e.target.closest(".md-hamburger") ||
        e.target.closest("[for=__drawer]")
      ) {
        sidebar.classList.toggle("open");
      }
    });
  }

  // Highlight current page in sidebar
  const page = document.body.dataset.page;
  if (page) {
    document.querySelectorAll(".md-nav__link").forEach((l) => {
      if (l.dataset.page === page) l.classList.add("md-nav__link--active");
    });
  }

  // Close sidebar when clicking a link (mobile)
  document.querySelectorAll(".md-nav__link").forEach((l) => {
    l.addEventListener("click", () => {
      if (sidebar) sidebar.classList.remove("open");
    });
  });

  // Search
  window.doSearch = function (query) {
    const results = document.getElementById("search-results");
    if (!results) return;
    if (!query || query.length < 2) {
      results.classList.remove("active");
      return;
    }
    const pages = [
      { title: "🏠 Home", url: "index.html" },
      { title: "❓ FAQ", url: "faq.html" },
      { title: "📖 Installation Guide", url: "installation/guide.html" },
      { title: "🔧 Post-Installation", url: "installation/post-install.html" },
      { title: "🛠 Troubleshooting", url: "installation/troubleshoot.html" },
      { title: "💻 Legacy Hardware", url: "installation/legacy.html" },
      { title: "🔄 Alternative Methods", url: "installation/alternative.html" },
      { title: "📋 Editions", url: "general/editions.html" },
      { title: "🔄 System Comparison", url: "general/comparison.html" },
      { title: "⚙ Tweaks", url: "general/tweaks.html" },
      { title: "🔒 VPN", url: "general/vpn.html" },
      { title: "🗑 Uninstalling", url: "general/uninstalling.html" },
      { title: "🎮 Gaming Introduction", url: "gaming/introduction.html" },
      { title: "🚀 Game Launchers", url: "gaming/launchers.html" },
      { title: "⚙ Launch Options", url: "gaming/launch-options.html" },
      { title: "🖥 Software Center", url: "software/center.html" },
      { title: "📂 Flatpak", url: "software/flatpak.html" },
      { title: "🐳 Containers", url: "software/containers.html" },
      { title: "📦 Distrobox", url: "software/distrobox.html" },
      { title: "🗜 AppImage", url: "software/appimage.html" },
      { title: "📱 Waydroid", url: "software/waydroid.html" },
      { title: "🔄 Updates & Rollbacks", url: "software/updates.html" },
      { title: "⌨ CLI Tools", url: "advanced/cli.html" },
      { title: "🛠 Custom Image", url: "advanced/custom-image.html" },
      { title: "🔑 Reset Password", url: "advanced/reset-password.html" },
      { title: "🤝 Contributing", url: "community/contributing.html" },
      { title: "🐛 Report Bugs", url: "community/bugs.html" },
      { title: "🔗 Links", url: "community/links.html" },
      { title: "🔧 Specifications", url: "resources/specs.html" },
      { title: "🧠 Kernel", url: "resources/kernel.html" },
      { title: "💾 Binary Cache", url: "resources/cache.html" },
      { title: "⬇ Download", url: "resources/download.html" },
    ];
    const q = query.toLowerCase();
    const matches = pages
      .filter((p) => p.title.toLowerCase().includes(q))
      .slice(0, 6);
    if (matches.length === 0) {
      results.classList.remove("active");
      return;
    }
    results.innerHTML = matches
      .map((m) => `<a href="${m.url}" class="sr-item">${m.title}</a>`)
      .join("");
    results.classList.add("active");
  };
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape")
      document.getElementById("search-results")?.classList.remove("active");
  });
});
