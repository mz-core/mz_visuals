(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const mount = $("mount");
  const fpsMini = $("fps-mini");
  const demo =
    window.__MZ_DEMO__ === true ||
    new URLSearchParams(location.search).has("demo");
  const icons = {
    original: "↺",
    batata: "ϟ",
    baixo: "▤",
    equilibrado: "◈",
    alto: "☀",
    ultra: "✧",
    auto: "↗",
    custom: "☷",
  };
  const tabInfo = {
    profiles: [
      "PERFIS GRÁFICOS",
      "Escolha sua experiência",
      "Do máximo desempenho ao visual cinematográfico. O controle está com você.",
    ],
    customize: [
      "AJUSTES FINOS",
      "Ajuste cada detalhe",
      "Customize os efeitos que o resource consegue controlar sem alterar configurações nativas do menu GTA.",
    ],
    performance: [
      "DESEMPENHO",
      "Conheça seu desempenho",
      "Média estimada do cliente e configurações de monitoramento.",
    ],
  };
  const english = {
    tabs: {
      profiles: [
        "GRAPHICS PRESETS",
        "Choose your experience",
        "From performance-focused to cinematic visuals. The choice is yours.",
      ],
      customize: [
        "FINE TUNING",
        "Tune every detail",
        "Customize supported visual effects without changing GTA V native graphics options.",
      ],
      performance: [
        "PERFORMANCE",
        "Understand your performance",
        "Estimated local frame rate and monitoring preferences.",
      ],
    },
    static: {
      ".side-hero h1": ["Your game.<br><em>Your visuals.</em>", true],
      ".side-hero p": [
        "Customize lighting and performance with settings for your computer.",
      ],
      ".side-eyebrow": [
        '<span class="pulse"></span> GRAPHICS ENGINE ONLINE',
        true,
      ],
      ".stat-name": null,
      "#tab-profiles .section-head strong": ["AVAILABLE PRESETS"],
      "#tab-profiles .hint-text": [
        "FPS mode may help with resource usage but cannot change GTA V resolution, textures or MSAA.",
      ],
      "#tab-customize .section-head strong": ["VISUAL CONTROLS"],
      "#tab-customize .section-head span": ["CUSTOM"],
      "#tab-customize .inline-note": [
        "<b>ⓘ</b> Changes are applied locally. Original restores the visual values captured at resource startup.",
        true,
      ],
      "#tab-performance .section-head strong": ["CLIENT DIAGNOSTICS"],
      "#tab-performance .section-head span": ["FPS MONITOR"],
      "#tab-performance .perf-card:nth-child(1) small": [
        "AVERAGE BEFORE BOOST",
      ],
      "#tab-performance .perf-card:nth-child(1) span": ["FPS / baseline"],
      "#tab-performance .perf-card:nth-child(2) small": ["AVERAGE AFTER BOOST"],
      "#tab-performance .perf-card:nth-child(2) span": ["FPS / recent sample"],
      "#tab-performance .perf-card:nth-child(3) small": [
        "AVAILABLE PARAMETERS",
      ],
      "#tab-performance .perf-card:nth-child(3) span": [
        "Values read on this client",
      ],
      "#tab-performance .setting-row strong": ["On-screen FPS monitor"],
      "#tab-performance .setting-row span": [
        "Display a compact counter while playing.",
      ],
      "#tab-performance .inline-note": [
        "<b>ⓘ</b> FPS varies with location, density and scene. This is not a controlled benchmark. Auto changes gradually between Low, Balanced and High.",
        true,
      ],
      "#reset": ["↶ Restore original"],
      "#done": ["Done <span>↗</span>", true],
      ".footer-caption": [
        '<span class="footer-orb"></span> INDIVIDUAL SETTINGS <span class="footer-divider">/</span> NO GAME RESTART',
        true,
      ],
      ".side-bottom": [
        '<span class="status-circle"></span> LOCAL CLIENT <span class="version">v1.0.0</span>',
        true,
      ],
    },
    nav: ["Graphics presets", "Fine tuning", "Performance"],
    stat: ["CURRENT FPS", "RECENT AVERAGE", "ACTIVE PRESET"],
    customized: "Local custom settings",
    active: (name) => `Running: ${name}`,
  };
  let currentTab = "profiles";
  let state = null;
  let customTimer = 0;
  let isVisible = false;
  let currentLocale = "pt-BR";

  // ===== DEFESA: forca esconder tudo no boot =====
  // Se algum dia o atributo 'hidden' falhar, garantimos que nada aparece.
  document.documentElement.style.background = "transparent";
  document.body.style.background = "transparent";
  if (mount) mount.hidden = true;
  if (fpsMini) fpsMini.hidden = true;
  console.log(
    "[mz_visuals] NUI carregada | demo=" +
      demo +
      " | mount.hidden=" +
      (mount ? mount.hidden : "n/a"),
  );
  // =================================================

  const defaultDemo = {
    profile: "equilibrado",
    effectiveProfile: "equilibrado",
    boost: false,
    overlay: false,
    settings: {
      headlights: 50,
      coronas: 45,
      bloom: 45,
      distantLights: 48,
      rainLook: 50,
      motionBlur: 40,
    },
    fps: 78,
    average: 75,
    boostBefore: null,
    boostAfter: null,
    diagnostics: { available: 13, skipped: 0, captured: true },
    profiles: [
      ["original", "Original", "Valores do GTA / cliente"],
      ["batata", "Batata", "Máximo foco em estabilidade"],
      ["baixo", "Baixo", "Efeitos discretos"],
      ["equilibrado", "Equilibrado", "Visual limpo e balanceado"],
      ["alto", "Alto", "Iluminação mais rica"],
      ["ultra", "Ultra", "Efeitos gráficos aprimorados"],
      ["auto", "Automático", "Adapta de acordo com FPS"],
      ["custom", "Personalizado", "Ajuste fino individual"],
    ].map(([id, label, description]) => ({ id, label, description })),
    controls: [
      ["headlights", "Faróis", "Brilho e alcance visual"],
      ["coronas", "Coronas", "Halos de luz"],
      ["bloom", "Bloom", "Luzes difusas"],
      ["distantLights", "Luzes distantes", "Aparência da cidade"],
      ["rainLook", "Visual da chuva", "Brilho aparente; não reduz partículas"],
      ["motionBlur", "Desfoque", "Intensidade de movimento"],
    ].map(([id, label, description]) => ({
      id,
      label,
      description,
      min: 0,
      max: 100,
    })),
    allowCustom: true,
    allowOverlay: true,
  };
  const esc = (value) =>
    String(value ?? "").replace(
      /[&<>"']/g,
      (c) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
        })[c],
    );
  const num = (value) => (Number.isFinite(Number(value)) ? Number(value) : 0);
  const getProfileName = (id) =>
    state?.profiles?.find((p) => p.id === id)?.label || id || "--";

  async function request(action, data = {}) {
    if (demo) {
      if (action === "selectPreset" || action === "restoreDefaults") {
        const next = action === "restoreDefaults" ? "original" : data.id;
        if (!state.profiles.some((p) => p.id === next)) return { ok: false };
        state.profile = next;
        state.effectiveProfile = next === "auto" ? "equilibrado" : next;
        if (next !== "custom" && next !== "auto" && next !== "original") {
          const defaults = {
            batata: [30, 12, 0, 20, 35, 0],
            baixo: [38, 30, 15, 32, 40, 0],
            equilibrado: [50, 45, 45, 48, 50, 40],
            alto: [65, 70, 65, 68, 65, 48],
            ultra: [80, 86, 78, 80, 75, 55],
          };
          state.settings = Object.fromEntries(
            Object.keys(state.settings).map((key, i) => [
              key,
              defaults[next][i],
            ]),
          );
        }
        if (next === "original")
          state.settings = Object.fromEntries(
            Object.keys(state.settings).map((key) => [key, 50]),
          );
        state.boost = false;
      }
      if (action === "updateSettings") {
        state.profile = "custom";
        state.effectiveProfile = "custom";
        state.settings = { ...data.settings };
        state.boost = false;
      }
      if (action === "toggleOverlay") state.overlay = !!data.value;
      if (action === "close") setVisibility(false);
      return { ok: true, state: { ...state } };
    }
    const name =
      typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : "mz_visuals";
    try {
      const response = await fetch(`https://${name}/${action}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data),
      });
      return await response.json();
    } catch (error) {
      console.warn("[mz_visuals] NUI request failed", action, error);
      return { ok: false };
    }
  }

  function setVisibility(show) {
    isVisible = !!show;
    if (!show) clearTimeout(customTimer);
    mount.hidden = !show;
    if (show) {
      render();
      requestAnimationFrame(() => {
        $("close").focus();
      });
    }
    drawMini();
    console.log(
      "[mz_visuals] setVisibility(" + show + ") | mount.hidden=" + mount.hidden,
    );
  }

  function translateStatic() {
    if (currentLocale !== "en-US") return;
    document.documentElement.lang = "en-US";
    for (const [selector, payload] of Object.entries(english.static)) {
      if (!payload) continue;
      const element = document.querySelector(selector);
      if (!element) continue;
      if (payload[1]) element.innerHTML = payload[0];
      else element.textContent = payload[0];
    }
    document.querySelectorAll(".nav-item").forEach((element, i) => {
      for (const node of element.childNodes) {
        if (node.nodeType === Node.TEXT_NODE && node.textContent.trim())
          node.textContent = " " + english.nav[i] + " ";
      }
    });
    document.querySelectorAll(".stat-name").forEach((element, i) => {
      const dot = i === 0 ? '<span class="stat-dot"></span>' : "";
      element.innerHTML = english.stat[i] + " " + dot;
    });
    const text = english.tabs[currentTab];
    if (text) {
      $("breadcrumb-tab").textContent = text[0];
      $("section-title").textContent = text[1];
      $("section-desc").textContent = text[2];
    }
  }

  function setState(next) {
    if (!next || typeof next !== "object") return;
    state = next;
    currentLocale = next.locale === "en-US" ? "en-US" : "pt-BR";
    translateStatic();
    render();
  }

  function setTab(tab) {
    if (!tabInfo[tab]) return;
    currentTab = tab;
    document
      .querySelectorAll(".nav-item")
      .forEach((el) => el.classList.toggle("active", el.dataset.tab === tab));
    for (const id of Object.keys(tabInfo)) $(`tab-${id}`).hidden = id !== tab;
    const [crumb, title, desc] =
      currentLocale === "en-US" ? english.tabs[tab] : tabInfo[tab];
    $("breadcrumb-tab").textContent = crumb;
    $("section-title").textContent = title;
    $("section-desc").textContent = desc;
    render();
  }

  function render() {
    if (!state) return;
    const profile = getProfileName(state.profile);
    const effective =
      state.profile === "auto"
        ? currentLocale === "en-US"
          ? english.active(getProfileName(state.effectiveProfile))
          : `Executando: ${getProfileName(state.effectiveProfile)}`
        : currentLocale === "en-US"
          ? english.customized
          : "Configuração individual";
    $("stat-profile").textContent = profile;
    $("stat-effective").textContent = effective;
    $("stat-fps").textContent = state.fps > 0 ? state.fps : "--";
    $("stat-avg").textContent = state.average > 0 ? state.average : "--";
    $("stat-bars").style.opacity = Math.max(
      0.25,
      Math.min(0.95, num(state.fps) / 120),
    ).toString();
    $("perf-before").textContent =
      state.boostBefore > 0 ? state.boostBefore : "--";
    $("perf-after").textContent =
      state.boostAfter > 0 ? state.boostAfter : "--";
    $("perf-keys").textContent = state.diagnostics?.captured
      ? num(state.diagnostics?.available)
      : "--";
    $("overlay-toggle").disabled = !state.allowOverlay;
    $("overlay-toggle").classList.toggle("on", state.overlay);
    $("overlay-toggle").setAttribute("aria-checked", String(!!state.overlay));
    renderPresets();
    renderControls();
    drawMini();
  }

  function renderPresets() {
    const list = $("preset-list");
    list.innerHTML = (state.profiles || [])
      .map(
        (p) => `
      <button type="button" class="preset ${p.id === state.profile ? "selected" : ""}" data-preset="${esc(p.id)}" aria-pressed="${p.id === state.profile ? "true" : "false"}">
        <span class="preset-icon" aria-hidden="true">${esc(icons[p.id] || "◈")}</span>
        <span class="preset-copy"><span class="preset-name">${esc(p.label)}</span><span class="preset-desc">${esc(p.description)}</span></span>
        ${p.id === state.profile ? '<span class="check" aria-hidden="true">✓</span>' : ""}
      </button>`,
      )
      .join("");
    list.querySelectorAll("[data-preset]").forEach((btn) =>
      btn.addEventListener("click", async () => {
        const id = btn.dataset.preset;
        if (!id) return;
        clearTimeout(customTimer);
        const result = await request("selectPreset", { id });
        if (result.ok) setState(result.state);
      }),
    );
  }

  function renderControls() {
    const list = $("sliders");
    list.innerHTML = (state.controls || [])
      .map((c) => {
        const value = num(state.settings?.[c.id]);
        return `<div class="slider-card">
        <div class="slider-top"><strong>${esc(c.label)}</strong><span class="slider-value" id="slider-val-${esc(c.id)}">${value}%</span></div>
        <p>${esc(c.description)}</p>
        <input type="range" data-control="${esc(c.id)}" min="${num(c.min)}" max="${num(c.max)}" value="${value}" style="--fill:${value}%" ${state.allowCustom ? "" : "disabled"} aria-label="${esc(c.label)}"/>
      </div>`;
      })
      .join("");
    list.querySelectorAll("input[data-control]").forEach((input) =>
      input.addEventListener("input", () => {
        const val = num(input.value);
        input.style.setProperty("--fill", val + "%");
        const label = $("slider-val-" + input.dataset.control);
        if (label) label.textContent = val + "%";
        if (!state.allowCustom) return;
        const settings = {};
        list.querySelectorAll("input[data-control]").forEach((node) => {
          settings[node.dataset.control] = num(node.value);
        });
        clearTimeout(customTimer);
        customTimer = setTimeout(async () => {
          const result = await request("updateSettings", { settings });
          if (result.ok) setState(result.state);
        }, 220);
      }),
    );
  }

  function drawMini() {
    const visible = !!state?.overlay && !isVisible;
    $("fps-mini").hidden = !visible;
    if (visible) {
      $("mini-fps").textContent = state.fps > 0 ? state.fps : "--";
      $("mini-avg").textContent = state.average > 0 ? state.average : "--";
    }
  }

  function updateStats(data) {
    if (!state || !data) return;
    for (const key of [
      "fps",
      "average",
      "boostBefore",
      "boostAfter",
      "overlay",
      "effectiveProfile",
    ]) {
      if (Object.hasOwn(data, key)) state[key] = data[key];
    }
    if (isVisible) {
      $("stat-fps").textContent = state.fps > 0 ? state.fps : "--";
      $("stat-avg").textContent = state.average > 0 ? state.average : "--";
      $("perf-before").textContent =
        state.boostBefore > 0 ? state.boostBefore : "--";
      $("perf-after").textContent =
        state.boostAfter > 0 ? state.boostAfter : "--";
      $("stat-effective").textContent =
        state.profile === "auto"
          ? currentLocale === "en-US"
            ? english.active(getProfileName(state.effectiveProfile))
            : `Executando: ${getProfileName(state.effectiveProfile)}`
          : currentLocale === "en-US"
            ? english.customized
            : "Configuração individual";
    }
    drawMini();
  }

  window.addEventListener("message", (event) => {
    const data = event?.data;
    if (!data || typeof data !== "object") return;
    console.log(
      "[mz_visuals] msg recebida:",
      data.action,
      data.open ?? data.data?.profile ?? "",
    );
    if (data.action === "visibility") setVisibility(data.open);
    if (data.action === "state") setState(data.data);
    if (data.action === "stats") updateStats(data.data);
  });
  document
    .querySelectorAll(".nav-item")
    .forEach((btn) =>
      btn.addEventListener("click", () => setTab(btn.dataset.tab)),
    );
  $("close").addEventListener("click", async () => {
    await request("close");
    setVisibility(false);
  });
  $("done").addEventListener("click", async () => {
    await request("close");
    setVisibility(false);
  });
  $("reset").addEventListener("click", async () => {
    clearTimeout(customTimer);
    const result = await request("restoreDefaults");
    if (result.ok) setState(result.state);
  });
  $("overlay-toggle").addEventListener("click", async () => {
    const result = await request("toggleOverlay", { value: !state?.overlay });
    if (result.ok) setState(result.state);
  });
  document.addEventListener("keydown", async (event) => {
    if (event.key === "Escape" && isVisible) {
      event.preventDefault();
      await request("close");
      setVisibility(false);
    }
  });

  if (demo) {
    state = defaultDemo;
    setVisibility(true);
  }
})();
