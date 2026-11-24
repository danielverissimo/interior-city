const byId = (id) => document.getElementById(id);
const panel = byId("panel");
const order = byId("order");
const amount = byId("amount");
const status = byId("status");
const progress = byId("progress");
const progressSection = byId("progress-section");
const percentLabel = byId("percent");
const message = byId("message");
const error = byId("error");
const submit = order.querySelector("[type=submit]");
const demo = typeof GetParentResourceName !== "function";
const money = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
const volume = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 });
let price;
let demoTimer;
let progressTimer;

const litersText = (liters) => volume.format(liters) + " L";

function quote() {
  byId("liters").textContent = litersText((Number(amount.value) || 0) / price);
}

function open(data) {
  price = data.price;
  amount.max = data.limit;
  amount.value = demo ? "120" : "";
  byId("limit").textContent = "Até " + money.format(data.limit);
  byId("price").textContent = money.format(price);
  byId("demo-horn").hidden = true;
  message.textContent = "Quanto você quer abastecer?";
  status.hidden = true;
  error.hidden = true;
  order.hidden = false;
  submit.disabled = false;
  panel.hidden = false;
  quote();
  if (!demo) amount.focus();
}

function setProgress(value) {
  const percent = Math.floor(value);
  progress.firstElementChild.style.transform = "scaleX(" + value / 100 + ")";
  if (progress.getAttribute("aria-valuenow") !== String(percent)) {
    progress.setAttribute("aria-valuenow", percent);
    percentLabel.textContent = percent + "%";
  }
}

function startProgress(seconds) {
  const startedAt = performance.now();
  const duration = Math.max(1, seconds) * 1000;
  setProgress(0);
  function tick() {
    const value = Math.min(99, (performance.now() - startedAt) / duration * 100);
    setProgress(value);
    if (value < 99) progressTimer = requestAnimationFrame(tick);
  }
  progressTimer = requestAnimationFrame(tick);
}

function showDelivery(data) {
  const finished = data.action === "finished";
  const approaching = data.action === "approaching";
  cancelAnimationFrame(progressTimer);
  order.hidden = true;
  progressSection.hidden = approaching;
  if (finished) setProgress(100);
  else if (!approaching) startProgress(data.seconds);
  status.hidden = false;
  message.textContent = finished ? "Abastecimento concluído." : approaching ? "Frentista se posicionando." : "Realizando abastecimento";
  byId("total").textContent = money.format(data.amount);
  byId("delivered").textContent = litersText(data.liters);
  byId("status-close").textContent = finished ? "Fechar" : "Cancelar";
}

function hide() {
  panel.hidden = true;
  clearTimeout(demoTimer);
  cancelAnimationFrame(progressTimer);
  if (demo) byId("demo-horn").hidden = false;
}

async function nui(action, payload = {}) {
  const response = await fetch("https://" + GetParentResourceName() + "/" + action, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  return response.json();
}

function close() {
  hide();
  if (!demo) void nui("close").catch(console.error);
}

order.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (!order.reportValidity() || submit.disabled) return;
  const value = Number(amount.value);
  submit.disabled = true;
  error.hidden = true;
  if (demo) {
    const liters = value / price;
    const data = { amount: value, liters, seconds: Math.max(5, Math.ceil(liters / 1.8)) };
    showDelivery({ ...data, action: "approaching" });
    demoTimer = setTimeout(() => {
      showDelivery({ ...data, action: "filling" });
      demoTimer = setTimeout(() => showDelivery({ ...data, action: "finished" }), data.seconds * 1000);
    }, 800);
    return;
  }
  try {
    const result = await nui("order", { amount: value });
    if (!result.ok) throw new Error("Atendimento indisponível.");
  } catch {
    submit.disabled = false;
    error.textContent = "Não foi possível enviar o pedido. Tente novamente.";
    error.hidden = false;
  }
});

amount.addEventListener("input", quote);
byId("dismiss").addEventListener("click", close);
byId("status-close").addEventListener("click", close);
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !panel.hidden) close();
});

if (demo) {
  document.body.classList.add("preview");
  const demoQuote = { price: 6, limit: 240 };
  byId("demo-horn").addEventListener("click", () => open(demoQuote));
  open(demoQuote);
} else {
  window.addEventListener("message", ({ data }) => {
    if (data?.action === "open") open(data);
    else if (data?.action === "close") hide();
    else if (data?.action === "approaching" || data?.action === "filling" || data?.action === "finished") showDelivery(data);
  });
}
