const storageKeys = {
  logs: "livestock-farm-logs",
  eggCollections: "livestock-egg-collections",
  listings: "livestock-market-listings",
  supplierQuotes: "livestock-supplier-price-quotes"
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

const sampleSupplierQuotes = [
  { ingredient: "Maize", supplier: "Example supplier A", price: 420, bagKg: 50, location: "Kumasi", date: dateInputValue, sample: true },
  { ingredient: "Maize", supplier: "Example supplier B", price: 445, bagKg: 50, location: "Accra", date: dateInputValue, sample: true },
  { ingredient: "Soybean meal", supplier: "Example supplier A", price: 720, bagKg: 50, location: "Kumasi", date: dateInputValue, sample: true },
  { ingredient: "Soybean meal", supplier: "Example supplier B", price: 760, bagKg: 50, location: "Accra", date: dateInputValue, sample: true },
  { ingredient: "Fishmeal", supplier: "Example supplier A", price: 600, bagKg: 25, location: "Tema", date: dateInputValue, sample: true },
  { ingredient: "Fishmeal", supplier: "Example supplier B", price: 650, bagKg: 25, location: "Accra", date: dateInputValue, sample: true },
  { ingredient: "Wheat bran", supplier: "Example supplier A", price: 300, bagKg: 50, location: "Tamale", date: dateInputValue, sample: true },
  { ingredient: "Wheat bran", supplier: "Example supplier B", price: 330, bagKg: 50, location: "Kumasi", date: dateInputValue, sample: true },
  { ingredient: "Premixes", supplier: "Example supplier A", price: 540, bagKg: 25, location: "Accra", date: dateInputValue, sample: true },
  { ingredient: "Premixes", supplier: "Example supplier B", price: 575, bagKg: 25, location: "Kumasi", date: dateInputValue, sample: true }
];

const feedIngredients = [
  "Maize", "Soybean meal", "Fishmeal", "Wheat bran", "Premixes", "Limestone",
  "Dicalcium phosphate", "Vegetable oil", "Salt", "Lysine", "Methionine"
];

let healthPhotos = [];
let healthPhotoUrls = [];
const maxHealthPhotos = 5;
const maxHealthPhotoSize = 10 * 1024 * 1024;

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

function getEggCollections() {
  return readStoredList(storageKeys.eggCollections);
}

function renderFlocks() {
  for (const container of [document.querySelector("#dashboard-flocks"), document.querySelector("#all-flocks")]) {
    container.replaceChildren(...flocks.map(createFlockCard));
  }
  document.querySelector("#active-birds").textContent = flocks.reduce((sum, flock) => sum + flock.birds, 0).toLocaleString("en-GH");
  document.querySelector("#flock-count").textContent = String(flocks.length);
  for (const select of [document.querySelector("#log-flock"), document.querySelector("#health-flock"), document.querySelector("#egg-flock")]) {
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

function renderEggCollections() {
  const collections = getEggCollections();
  const weekStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  weekStart.setDate(weekStart.getDate() - ((weekStart.getDay() + 6) % 7));
  const weekStartKey = [
    weekStart.getFullYear(),
    String(weekStart.getMonth() + 1).padStart(2, "0"),
    String(weekStart.getDate()).padStart(2, "0")
  ].join("-");
  const traysThisWeek = collections
    .filter((entry) => entry.date >= weekStartKey && entry.date <= dateInputValue)
    .reduce((total, entry) => total + Number(entry.trays), 0);
  document.querySelector("#eggs-this-week").textContent = traysThisWeek.toLocaleString("en-GH", { maximumFractionDigits: 1 });

  const table = document.querySelector("#egg-table");
  table.replaceChildren();
  if (!collections.length) {
    const row = element("tr");
    const cell = element("td", "", "No egg collections recorded yet.");
    cell.colSpan = 4;
    row.append(cell);
    table.append(row);
    return;
  }

  for (const entry of [...collections].sort((a, b) => b.date.localeCompare(a.date))) {
    const row = document.createElement("tr");
    for (const value of [
      formatDate(entry.date, { year: "numeric", month: "short", day: "numeric" }),
      flockName(entry.flock),
      Number(entry.trays).toLocaleString("en-GH", { maximumFractionDigits: 1 }),
      entry.notes || ""
    ]) {
      row.append(element("td", "", value));
    }
    table.append(row);
  }
}

function flockName(id) {
  return flocks.find((flock) => flock.id === id)?.name ?? "Unknown flock";
}

function activitySymbol(type) {
  return ({ Feed: "◌", Water: "◌", Weight: "↗", Vaccination: "＋", Treatment: "＋", Mortality: "!", "General note": "✎" })[type] ?? "✎";
}

function renderListings(search = "", filter = "all") {
  const ownListings = readStoredList(storageKeys.listings);
  const listings = [...ownListings, ...sampleListings].filter((listing) => {
    const text = `${listing.kind} ${listing.feedType ?? ""} ${listing.title} ${listing.location}`.toLocaleLowerCase();
    const matchesFilter = filter === "all"
      || (filter === "feed-sale" && listing.kind === "Feed for sale")
      || (filter === "feed-wanted" && listing.kind === "Feed wanted (buy order)");
    return matchesFilter && text.includes(search.toLocaleLowerCase());
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
    const isFeedSale = listing.kind === "Feed for sale";
    const isFeedWanted = listing.kind === "Feed wanted (buy order)";
    if (isFeedWanted) card.classList.add("listing-buy-order");
    card.append(element("div", "listing-art", listing.kind === "Eggs" ? "◉" : listing.kind === "Live birds" ? "🐔" : "▤"));
    const body = element("div", "listing-body");
    const listingLabel = isFeedWanted ? "FEED BUY ORDER" : isFeedSale ? "FEED FOR SALE" : listing.kind;
    body.append(element("span", "listing-kind", listing.sample ? `SAMPLE · ${listing.kind}` : listingLabel));
    body.append(element("h3", "", listing.title));
    if (listing.feedType) body.append(element("div", "listing-feed-type", listing.feedType));
    const details = element("div", "listing-detail");
    details.append(element("span", "", listing.quantity), element("span", "", listing.location));
    const priceLabel = isFeedWanted ? "Budget" : "Price";
    body.append(details, element("div", "listing-price", `${priceLabel}: ₵ ${Number(listing.price).toLocaleString("en-GH")}`), element("div", "listing-location", listing.sample ? "Illustrative example, not a live offer" : "Saved in this browser · not visible to other farmers"));
    card.append(body);
    grid.append(card);
  }
}

function renderSupplierQuotes() {
  const ingredientFilter = document.querySelector("#supplier-ingredient-filter").value;
  const locationSearch = document.querySelector("#supplier-location-search").value.trim().toLocaleLowerCase();
  const quotes = [...readStoredList(storageKeys.supplierQuotes), ...sampleSupplierQuotes]
    .filter((quote) => (ingredientFilter === "all" || quote.ingredient === ingredientFilter)
      && quote.location.toLocaleLowerCase().includes(locationSearch))
    .sort((a, b) => a.ingredient.localeCompare(b.ingredient) || (a.price / a.bagKg) - (b.price / b.bagKg));
  const table = document.querySelector("#supplier-quote-table");
  table.replaceChildren();
  document.querySelector("#supplier-quote-count").textContent = `${quotes.length} quotes · sorted by ingredient, lowest price per kg first`;
  if (!quotes.length) {
    const row = element("tr");
    const cell = element("td", "", "No supplier quotes match these filters.");
    cell.colSpan = 7;
    row.append(cell);
    table.append(row);
    return;
  }

  for (const quote of quotes) {
    const row = element("tr", quote.sample ? "example-quote" : "");
    const supplierCell = document.createElement("td");
    supplierCell.append(element("strong", "", quote.supplier), element("small", "quote-origin", quote.sample ? "Example data" : "Your quote"));
    row.append(
      element("td", "", quote.ingredient),
      supplierCell,
      element("td", "", quote.location),
      element("td", "", `${Number(quote.bagKg).toLocaleString("en-GH")} kg`),
      element("td", "", `₵ ${Number(quote.price).toLocaleString("en-GH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`),
      element("td", "unit-price", `₵ ${(Number(quote.price) / Number(quote.bagKg)).toLocaleString("en-GH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`),
      element("td", "", formatDate(quote.date, { year: "numeric", month: "short", day: "numeric" }))
    );
    table.append(row);
  }
}

function renderFeedIngredients() {
  const rows = document.querySelector("#feed-ingredient-rows");
  rows.replaceChildren();
  for (const ingredient of feedIngredients) {
    const row = document.createElement("tr");
    const availableCell = document.createElement("td");
    const available = document.createElement("input");
    available.type = "checkbox";
    available.className = "feed-ingredient-available";
    available.setAttribute("aria-label", `${ingredient} available`);
    availableCell.append(available);
    row.append(availableCell, element("td", "", ingredient));

    for (const [className, label, min, step] of [
      ["feed-ingredient-price", `${ingredient} price per kg`, "0.01", "0.01"],
      ["feed-ingredient-inclusion", `${ingredient} inclusion percentage`, "0", "0.1"]
    ]) {
      const cell = document.createElement("td");
      const input = document.createElement("input");
      input.type = "number";
      input.className = className;
      input.min = min;
      input.step = step;
      input.disabled = true;
      input.setAttribute("aria-label", label);
      input.placeholder = className === "feed-ingredient-price" ? "0.00" : "0";
      cell.append(input);
      row.append(cell);
    }
    rows.append(row);
  }
}

function getFeedStage(birdType, ageWeeks) {
  if (birdType === "broiler") {
    if (ageWeeks < 3) return { name: "Broiler starter", dailyIntake: 50 };
    if (ageWeeks < 6) return { name: "Broiler grower", dailyIntake: 100 };
    return { name: "Broiler finisher", dailyIntake: 150 };
  }
  if (ageWeeks < 8) return { name: "Layer chick starter", dailyIntake: 40 };
  if (ageWeeks < 18) return { name: "Layer grower/developer", dailyIntake: 70 };
  return { name: "Layer ration", dailyIntake: 110 };
}

function updateFeedStage() {
  const birdType = document.querySelector("#feed-bird-type").value;
  const ageWeeks = Number(document.querySelector("#feed-bird-age").value);
  const stage = getFeedStage(birdType, ageWeeks);
  document.querySelector("#feed-stage-hint").textContent = `Estimated stage: ${stage.name}. The ${stage.dailyIntake} g/bird/day starting estimate is adjustable; actual intake varies by bird strain, environment, and management.`;
  document.querySelector("#feed-daily-intake").value = stage.dailyIntake;
}

function formatGhs(value) {
  return `₵ ${Number(value).toLocaleString("en-GH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function calculateFeedCost(event) {
  event.preventDefault();
  const status = document.querySelector("#feed-calc-status");
  const result = document.querySelector("#feed-calc-result");
  status.textContent = "";
  result.hidden = true;

  const availableRows = [...document.querySelectorAll("#feed-ingredient-rows tr")]
    .filter((row) => row.querySelector(".feed-ingredient-available").checked);
  if (!availableRows.length) {
    status.textContent = "Select at least one available ingredient.";
    return;
  }

  const recipe = availableRows.map((row) => ({
    ingredient: row.cells[1].textContent,
    price: Number(row.querySelector(".feed-ingredient-price").value),
    inclusion: Number(row.querySelector(".feed-ingredient-inclusion").value)
  }));
  const totalInclusion = recipe.reduce((total, item) => total + item.inclusion, 0);
  if (Math.abs(totalInclusion - 100) > 0.05) {
    status.textContent = `Ingredient inclusion must total 100%. Current total: ${totalInclusion.toLocaleString("en-GH", { maximumFractionDigits: 1 })}%.`;
    return;
  }
  if (recipe.some((item) => item.inclusion > 0 && (!Number.isFinite(item.price) || item.price <= 0))) {
    status.textContent = "Enter a valid price per kg for every ingredient used in the mix.";
    return;
  }

  const birds = Number(document.querySelector("#feed-bird-count").value);
  const days = Number(document.querySelector("#feed-days").value);
  const dailyIntake = Number(document.querySelector("#feed-daily-intake").value);
  const budget = Number(document.querySelector("#feed-budget").value);
  const batchKg = birds * days * dailyIntake / 1000;
  const totalCost = recipe.reduce((total, item) => total + batchKg * item.inclusion / 100 * item.price, 0);
  const costPerKg = totalCost / batchKg;

  document.querySelector("#feed-result-summary").textContent = `${batchKg.toLocaleString("en-GH", { maximumFractionDigits: 2 })} kg for ${birds.toLocaleString("en-GH")} birds over ${days} day${days === 1 ? "" : "s"}.`;
  document.querySelector("#feed-total-cost").textContent = formatGhs(totalCost);
  document.querySelector("#feed-cost-per-kg").textContent = formatGhs(costPerKg);
  document.querySelector("#feed-budget-result").textContent = formatGhs(budget);

  const costRows = document.querySelector("#feed-cost-rows");
  costRows.replaceChildren();
  for (const item of recipe.filter((ingredient) => ingredient.inclusion > 0)) {
    const amountKg = batchKg * item.inclusion / 100;
    const row = document.createElement("tr");
    for (const value of [item.ingredient, `${item.inclusion.toLocaleString("en-GH", { maximumFractionDigits: 1 })}%`, `${amountKg.toLocaleString("en-GH", { maximumFractionDigits: 2 })} kg`, formatGhs(amountKg * item.price)]) {
      row.append(element("td", "", value));
    }
    costRows.append(row);
  }
  const budgetStatus = document.querySelector("#feed-budget-status");
  const difference = Math.abs(budget - totalCost);
  budgetStatus.classList.toggle("over-budget", totalCost > budget);
  budgetStatus.textContent = totalCost > budget
    ? `Over budget by ${formatGhs(difference)}.`
    : `Within budget by ${formatGhs(difference)}.`;
  result.hidden = false;
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

renderFeedIngredients();
updateFeedStage();
document.querySelector("#feed-bird-type").addEventListener("change", updateFeedStage);
document.querySelector("#feed-bird-age").addEventListener("input", updateFeedStage);
document.querySelector("#feed-ingredient-rows").addEventListener("change", (event) => {
  if (!event.target.classList.contains("feed-ingredient-available")) return;
  const row = event.target.closest("tr");
  row.querySelectorAll(".feed-ingredient-price, .feed-ingredient-inclusion").forEach((input) => {
    input.disabled = !event.target.checked;
    if (!event.target.checked) input.value = "";
  });
});
document.querySelector("#feed-calc-form").addEventListener("input", () => {
  document.querySelector("#feed-calc-status").textContent = "";
  document.querySelector("#feed-calc-result").hidden = true;
});
document.querySelector("#feed-calc-form").addEventListener("submit", calculateFeedCost);

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

document.querySelector("#egg-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = new FormData(form);
  const collections = getEggCollections();
  collections.push({
    flock: data.get("flock"),
    trays: Number(data.get("trays")),
    date: data.get("date"),
    notes: String(data.get("notes")).trim()
  });
  writeStoredList(storageKeys.eggCollections, collections);
  form.reset();
  form.elements.date.value = dateInputValue;
  document.querySelector("#egg-status").textContent = "Collection saved on this device.";
  renderEggCollections();
});

document.querySelector("#egg-form").elements.date.value = dateInputValue;

function renderHealthPhotoPreviews() {
  healthPhotoUrls.forEach((url) => URL.revokeObjectURL(url));
  healthPhotoUrls = [];
  const previews = document.querySelector("#health-photo-previews");
  previews.replaceChildren();
  healthPhotos.forEach((photo, index) => {
    const url = URL.createObjectURL(photo);
    healthPhotoUrls.push(url);
    const preview = element("article", "photo-preview");
    const image = document.createElement("img");
    image.src = url;
    image.alt = `Selected photo ${index + 1}: ${photo.name}`;
    const footer = element("div", "photo-preview-footer");
    const download = element("a", "photo-download", "Download");
    download.href = url;
    download.download = photo.name;
    const remove = element("button", "photo-remove", "×");
    remove.type = "button";
    remove.title = `Remove ${photo.name}`;
    remove.setAttribute("aria-label", `Remove ${photo.name}`);
    remove.addEventListener("click", () => {
      healthPhotos.splice(index, 1);
      renderHealthPhotoPreviews();
    });
    footer.append(download, remove);
    preview.append(image, footer);
    previews.append(preview);
  });
  document.querySelector("#health-share-actions").hidden = healthPhotos.length === 0;
}

document.querySelector("#health-photos").addEventListener("change", (event) => {
  const input = event.currentTarget;
  const selected = Array.from(input.files);
  let added = 0;
  let skipped = 0;
  for (const photo of selected) {
    if (!photo.type.startsWith("image/") || photo.size > maxHealthPhotoSize || healthPhotos.length >= maxHealthPhotos) {
      skipped += 1;
      continue;
    }
    healthPhotos.push(photo);
    added += 1;
  }
  input.value = "";
  document.querySelector("#health-photo-status").textContent = added
    ? `${added} photo${added === 1 ? "" : "s"} added.${skipped ? ` ${skipped} skipped; use images under 10 MB, up to 5 total.` : ""}`
    : skipped ? "No photos added. Use images under 10 MB, up to 5 total." : "";
  renderHealthPhotoPreviews();
});

document.querySelector("#share-health-report").addEventListener("click", async () => {
  const status = document.querySelector("#health-share-status");
  const shareData = {
    title: "Poultry health concern",
    text: [
      `Flock: ${document.querySelector("#health-flock").selectedOptions[0].textContent}`,
      `Urgent signs marked: ${document.querySelector("#urgent-signs").checked ? "Yes" : "No"}`,
      `Observations: ${document.querySelector("#symptoms").value.trim() || "Not provided"}`
    ].join("\n"),
    files: healthPhotos
  };
  try {
    if (typeof navigator.share !== "function" || typeof navigator.canShare !== "function" || !navigator.canShare({ files: healthPhotos })) {
      status.textContent = "This browser cannot share photo attachments. Download each photo above and attach it to a message to your vet.";
      return;
    }
    await navigator.share(shareData);
    status.textContent = "Share options opened. Choose a trusted contact or app to send these photos.";
  } catch (error) {
    if (error.name !== "AbortError") status.textContent = "Could not open sharing. Download the photos and attach them to a message to your vet.";
  }
});

window.addEventListener("beforeunload", () => {
  healthPhotoUrls.forEach((url) => URL.revokeObjectURL(url));
});

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

document.querySelector("#show-supplier-quote-form").addEventListener("click", () => {
  const panel = document.querySelector("#supplier-quote-panel");
  panel.hidden = !panel.hidden;
  if (!panel.hidden) {
    panel.scrollIntoView({ behavior: "smooth", block: "center" });
    panel.querySelector("input").focus();
  }
});

document.querySelector("#supplier-quote-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = new FormData(form);
  const quotes = readStoredList(storageKeys.supplierQuotes);
  quotes.push({
    supplier: String(data.get("supplier")).trim(),
    ingredient: data.get("ingredient"),
    price: Number(data.get("price")),
    bagKg: Number(data.get("bagKg")),
    location: String(data.get("location")).trim(),
    date: data.get("date"),
    sample: false
  });
  writeStoredList(storageKeys.supplierQuotes, quotes);
  form.reset();
  form.elements.date.value = dateInputValue;
  document.querySelector("#supplier-quote-status").textContent = "Quote saved in this browser.";
  renderSupplierQuotes();
});

document.querySelector("#supplier-quote-form").elements.date.value = dateInputValue;
document.querySelector("#supplier-ingredient-filter").addEventListener("change", renderSupplierQuotes);
document.querySelector("#supplier-location-search").addEventListener("input", renderSupplierQuotes);

document.querySelector("#listing-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = new FormData(form);
  const listings = readStoredList(storageKeys.listings);
  listings.unshift({
    kind: data.get("kind"),
    feedType: data.get("feedType") || "",
    title: String(data.get("title")).trim(),
    quantity: String(data.get("quantity")).trim(),
    price: Number(data.get("price")),
    location: String(data.get("location")).trim(),
    sample: false
  });
  writeStoredList(storageKeys.listings, listings);
  form.reset();
  updateListingForm();
  const isBuyOrder = data.get("kind") === "Feed wanted (buy order)";
  document.querySelector("#listing-status").textContent = isBuyOrder
    ? "Buy order saved in this browser; other farmers cannot see it yet."
    : "Saved in this browser; other farmers cannot see it yet.";
  renderListings(document.querySelector("#listing-search").value, document.querySelector("#listing-filter").value);
});

function updateListingForm() {
  const form = document.querySelector("#listing-form");
  const kind = form.elements.kind.value;
  const isFeed = kind === "Feed for sale" || kind === "Feed wanted (buy order)";
  const isBuyOrder = kind === "Feed wanted (buy order)";
  const feedTypeField = document.querySelector("#feed-type-field");
  feedTypeField.hidden = !isFeed;
  form.elements.feedType.disabled = !isFeed;
  form.elements.feedType.required = isFeed;
  form.elements.title.placeholder = isFeed
    ? isBuyOrder ? "e.g. Looking for layer mash" : "e.g. Surplus layer feed"
    : kind === "Eggs" ? "e.g. Fresh layers’ eggs" : kind === "Live birds" ? "e.g. Market-ready broilers" : "e.g. Poultry supplies";
  form.elements.quantity.placeholder = isFeed ? "e.g. 10 bags, 50 kg each" : kind === "Eggs" ? "e.g. 20 trays" : "e.g. 50 birds";
  document.querySelector("#quantity-label").textContent = isBuyOrder ? "Quantity wanted" : "Quantity";
  document.querySelector("#listing-price-label").textContent = isBuyOrder ? "Budget (GHS)" : "Price (GHS)";
}

document.querySelector("#listing-form").elements.kind.addEventListener("change", updateListingForm);
updateListingForm();

document.querySelector("#listing-search").addEventListener("input", (event) => {
  renderListings(event.currentTarget.value.trim(), document.querySelector("#listing-filter").value);
});

document.querySelector("#listing-filter").addEventListener("change", (event) => {
  renderListings(document.querySelector("#listing-search").value.trim(), event.currentTarget.value);
});

renderFlocks();
renderLogs();
renderEggCollections();
renderSupplierQuotes();
renderListings();
