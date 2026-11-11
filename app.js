const storageKeys = {
  logs: "livestock-farm-logs",
  listings: "livestock-market-listings"
};

const today = new Date();
const dateInputValue = [
  today.getFullYear(),
  String(today.getMonth() + 1).padStart(2, "0"),
  String(today.getDate()).padStart(2, "0")
].join("-");

const flocks = [
  { id: "layers-a", name: "Layers Batch A", type: "Layers", birds: 640, startOffset: 48, targetDays: 140, next: "Vaccination check in 2 days" },
  { id: "broilers-b", name: "Broilers Batch B", type: "Broilers", birds: 600, startOffset: 28, targetDays: 42, next: "Feed stock review in 5 days" }
];

const sampleListings = [
  { kind: "Eggs", title: "Example: Fresh layers’ eggs", quantity: "20 trays", price: 600, location: "Example location", sample: true },
  { kind: "Live birds", title: "Example: Market-ready broilers", quantity: "50 birds", price: 3750, location: "Example location", sample: true },
  { kind: "Poultry supplies", title: "Example: Poultry feed", quantity: "10 bags", price: 2800, location: "Example location", sample: true }
];

function readStoredList(key, fallback = []) {
  const stored = localStorage.getItem(key);
  return stored === null ? fallback : JSON.parse(stored);
}

function writeStoredList(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function formatDate(value, options = { month: "short", day: "numeric" }) {
  return new Intl.DateTimeFormat("en-GH", options).format(new Date(`${value}T12:00:00`));
}

function flockAge(flock) {
  return Math.max(1, Math.floor((Date.now() - new Date(`${flockStartDate(flock)}T12:00:00`).getTime()) / 86400000));
}

function flockStartDate(flock) {
  const start = new Date();
  start.setDate(start.getDate() - flock.startOffset);
  return [start.getFullYear(), String(start.getMonth() + 1).padStart(2, "0"), String(start.getDate()).padStart(2, "0")].join("-");
}

function createFlockCard(flock) {
  const age = flockAge(flock);
  const progress = Math.min(100, Math.round((age / flock.targetDays) * 100));
  const card = element("article", "flock-card");
  const top = element("div", "flock-card-top");
  const title = element("div", "flock-title");
  title.append(element("span", "bird-badge", flock.type === "Layers" ? "🐔" : "🐣"));
  const titleText = document.createElement("div");
  titleText.append(element("h3", "", flock.name), element("p", "", `${flock.type} · Started ${formatDate(flockStartDate(flock))}`));
  title.append(titleText);
  top.append(title, element("span", "status-pill", "GROWING"));
  card.append(top);

  const stats = element("div", "flock-stats");
  for (const [label, value] of [["Birds", flock.birds.toLocaleString("en-GH")], ["Age", `${age} days`], ["Target", `${flock.targetDays} days`]]) {
    const item = element("span", "", label);
    item.append(element("strong", "", value));
    stats.append(item);
  }
  card.append(stats);

  const progressLabel = element("div", "progress-label");
  progressLabel.append(element("span", "", "Progress to target"), element("strong", "", `${progress}%`));
  const track = element("div", "progress-track");
  const bar = element("div", "progress-bar");
  bar.style.width = `${progress}%`;
  track.append(bar);
  card.append(progressLabel, track);
  const footer = element("div", "flock-footer");
  footer.append(element("span", "", flock.next), element("span", "", `${Math.max(0, flock.targetDays - age)} days left`));
  card.append(footer);
  return card;
}

function getLogs() {
  return readStoredList(storageKeys.logs);
}

function renderFlocks() {
  for (const container of [document.querySelector("#dashboard-flocks"), document.querySelector("#all-flocks")]) {
    container.replaceChildren(...flocks.map(createFlockCard));
  }
  document.querySelector("#active-birds").textContent = flocks.reduce((sum, flock) => sum + flock.birds, 0).toLocaleString("en-GH");
  document.querySelector("#flock-count").textContent = String(flocks.length);
  for (const select of [document.querySelector("#log-flock"), document.querySelector("#health-flock")]) {
    select.replaceChildren(...flocks.map((flock) => {
      const option = document.createElement("option");
      option.value = flock.id;
      option.textContent = flock.name;
      return option;
    }));
  }
}

function renderLogs() {
  const logs = getLogs();
  const table = document.querySelector("#log-table");
  table.replaceChildren();
  if (!logs.length) {
    const row = element("tr");
    const cell = element("td", "", "No updates yet. Add your first flock record above.");
    cell.colSpan = 4;
    row.append(cell);
    table.append(row);
  } else {
    for (const log of [...logs].reverse()) {
      const row = document.createElement("tr");
      for (const value of [formatDate(log.date, { year: "numeric", month: "short", day: "numeric" }), flockName(log.flock), log.type, log.details]) {
        row.append(element("td", "", value));
      }
      table.append(row);
    }
  }

  const activity = document.querySelector("#activity-list");
  const recent = [...logs].reverse().slice(0, 3);
  activity.replaceChildren();
  if (!recent.length) {
    const item = element("div", "activity-item");
    item.append(element("span", "activity-symbol", "✦"));
    const copy = document.createElement("div");
    copy.append(element("strong", "", "Welcome to your farm log"), element("small", "", "Your updates will appear here"));
    item.append(copy);
    activity.append(item);
  } else {
    for (const log of recent) {
      const item = element("div", "activity-item");
      item.append(element("span", "activity-symbol", activitySymbol(log.type)));
      const copy = document.createElement("div");
      copy.append(element("strong", "", `${log.type} update · ${flockName(log.flock)}`), element("small", "", log.details));
      item.append(copy, element("span", "activity-time", formatDate(log.date)));
      activity.append(item);
    }
  }
}

function flockName(id) {
  return flocks.find((flock) => flock.id === id)?.name ?? "Unknown flock";
}

function activitySymbol(type) {
  return ({ Feed: "◌", Water: "◌", Weight: "↗", Vaccination: "＋", Treatment: "＋", Mortality: "!", "General note": "✎" })[type] ?? "✎";
}

function renderListings(search = "") {
  const ownListings = readStoredList(storageKeys.listings);
  const listings = [...ownListings, ...sampleListings].filter((listing) => {
    const text = `${listing.kind} ${listing.title} ${listing.location}`.toLocaleLowerCase();
    return text.includes(search.toLocaleLowerCase());
  });
  const grid = document.querySelector("#listing-grid");
  grid.replaceChildren();
  document.querySelector("#listing-count").textContent = `${listings.length} listings · examples are labeled`;
  if (!listings.length) {
    grid.append(element("p", "market-note", "No listings match your search."));
    return;
  }
  for (const listing of listings) {
    const card = element("article", "listing-card");
    card.append(element("div", "listing-art", listing.kind === "Eggs" ? "◉" : listing.kind === "Live birds" ? "🐔" : "▤"));
    const body = element("div", "listing-body");
    body.append(element("span", "listing-kind", listing.sample ? `SAMPLE · ${listing.kind}` : listing.kind));
    body.append(element("h3", "", listing.title));
    const details = element("div", "listing-detail");
    details.append(element("span", "", listing.quantity), element("span", "", listing.location));
    body.append(details, element("div", "listing-price", `₵ ${Number(listing.price).toLocaleString("en-GH")}`), element("div", "listing-location", listing.sample ? "Illustrative example, not a live offer" : "Your browser listing · not yet published online"));
    card.append(body);
    grid.append(card);
  }
}

function navigate(viewName) {
  document.querySelectorAll(".view").forEach((view) => {
    const active = view.id === `${viewName}-view`;
    view.classList.toggle("active", active);
    view.hidden = !active;
  });
  document.querySelectorAll(".nav-link").forEach((link) => {
    link.classList.toggle("active", link.dataset.view === viewName);
  });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

document.querySelector("#today-date").textContent = new Intl.DateTimeFormat("en-GH", {
  weekday: "short", month: "short", day: "numeric", year: "numeric"
}).format(today);

document.querySelectorAll(".nav-link").forEach((button) => {
  button.addEventListener("click", () => navigate(button.dataset.view));
});
document.querySelectorAll("[data-go]").forEach((button) => {
  button.addEventListener("click", () => navigate(button.dataset.go));
});

document.querySelector("#show-log-form").addEventListener("click", () => {
  document.querySelector("#log-form").scrollIntoView({ behavior: "smooth", block: "center" });
  document.querySelector("#log-flock").focus();
});

document.querySelector("#log-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = new FormData(form);
  const logs = getLogs();
  logs.push({
    flock: data.get("flock"),
    type: data.get("type"),
    details: String(data.get("details")).trim(),
    date: data.get("date")
  });
  writeStoredList(storageKeys.logs, logs);
  form.reset();
  form.elements.date.value = dateInputValue;
  document.querySelector("#log-status").textContent = "Update saved on this device.";
  renderLogs();
});

document.querySelector("#log-form").elements.date.value = dateInputValue;

document.querySelector("#health-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const urgent = document.querySelector("#urgent-signs").checked;
  const result = document.querySelector("#health-result");
  result.classList.toggle("urgent", urgent);
  result.textContent = urgent
    ? `Contact a qualified veterinary professional or your district veterinary office as soon as possible for ${document.querySelector("#health-flock").selectedOptions[0].textContent}. Describe when the signs began, how many birds are affected, and any recent changes. Do not start medication based only on this tool.`
    : `Write down when the changes began, how many birds are affected, and any changes in feed, water, or routine for ${document.querySelector("#health-flock").selectedOptions[0].textContent}. Share these observations with a qualified veterinary professional before treating the flock. This tool cannot determine the cause.`;
  result.hidden = false;
});

document.querySelector("#show-listing-form").addEventListener("click", () => {
  const panel = document.querySelector("#listing-panel");
  panel.hidden = !panel.hidden;
  if (!panel.hidden) {
    panel.scrollIntoView({ behavior: "smooth", block: "center" });
    panel.querySelector("input").focus();
  }
});

document.querySelector("#listing-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = new FormData(form);
  const listings = readStoredList(storageKeys.listings);
  listings.unshift({
    kind: data.get("kind"),
    title: String(data.get("title")).trim(),
    quantity: String(data.get("quantity")).trim(),
    price: Number(data.get("price")),
    location: String(data.get("location")).trim(),
    sample: false
  });
  writeStoredList(storageKeys.listings, listings);
  form.reset();
  document.querySelector("#listing-status").textContent = "Saved in this browser; it is not published online.";
  renderListings(document.querySelector("#listing-search").value);
});

document.querySelector("#listing-search").addEventListener("input", (event) => {
  renderListings(event.currentTarget.value.trim());
});

renderFlocks();
renderLogs();
renderListings();
