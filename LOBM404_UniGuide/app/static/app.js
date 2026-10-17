"use strict";
const articlesBox = document.querySelector("#article-list");
const resultCount = document.querySelector("#result-count");
const searchInput = document.querySelector("#search");
const categoryInput = document.querySelector("#category");
const dialog = document.querySelector("#article-dialog");
let feedbackMaxLength = 500;
const icons = {"Ta’lim": "▤", "Xizmatlar": "↗", "Xavfsizlik": "◇", "Kampus": "✦"};
function node(tag, text, className) {
  const el = document.createElement(tag);
  if (text !== undefined) el.textContent = text;
  if (className) el.className = className;
  return el;
}
function openArticle(article) {
  const detail = document.querySelector("#article-detail");
  detail.replaceChildren(node("div", article.category, "eyebrow"), node("h2", article.title), node("p", article.body));
  detail.append(node("h3", "Uchta oddiy qadam"));
  const list = node("ol");
  for (const item of article.checklist || []) list.append(node("li", item));
  detail.append(list, node("p", "O‘quv namunasi. Haqiqiy tartibni universitetning rasmiy manbasidan tekshiring.", "detail-note"));
  dialog.showModal();
}
let requestNumber = 0;
async function showArticles() {
  const current = ++requestNumber;
  const params = new URLSearchParams({q: searchInput.value, category: categoryInput.value});
  try {
    const response = await fetch(`/api/articles?${params}`);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Ma’lumotni olib bo‘lmadi.");
    if (current !== requestNumber) return;
    if (categoryInput.options.length === 1) {
      for (const category of data.categories) categoryInput.append(new Option(category, category));
    }
    resultCount.textContent = `${data.total} ta yo‘riqnoma topildi`;
    articlesBox.replaceChildren();
    for (const [index, article] of data.articles.entries()) {
      const card = node("article", undefined, `article-card card-${index % 3}`);
      const top = node("div", undefined, "article-top");
      top.append(node("span", icons[article.category] || "▤", "article-icon"), node("span", article.category, "category-badge"));
      const button = node("button", "Yo‘riqnomani o‘qish  ↗", "text-button");
      button.addEventListener("click", () => openArticle(article));
      card.append(top, node("h3", article.title), node("p", article.summary), button);
      articlesBox.append(card);
    }
    if (!data.total) articlesBox.append(node("p", "Mos yo‘riqnoma topilmadi. Qisqaroq so‘z bilan yoki boshqa turkumda qayta izlang.", "empty-state"));
  } catch (error) {
    if (current !== requestNumber) return;
    articlesBox.replaceChildren(node("p", `Xatolik: ${error.message} Server ishlayotganini tekshiring.`, "error-state"));
    resultCount.textContent = "Yuklash amalga oshmadi";
  }
}
document.querySelector("#search-form").addEventListener("submit", event => { event.preventDefault(); showArticles(); });
categoryInput.addEventListener("change", showArticles);
document.querySelector(".close-dialog").addEventListener("click", () => dialog.close());
dialog.addEventListener("click", event => { if (event.target === dialog) dialog.close(); });
const feedbackMessage = document.querySelector("#message");
function countFeedback() {
  const length = Array.from(feedbackMessage.value.trim()).length;
  document.querySelector("#character-count").textContent = `${length} / ${feedbackMaxLength} belgi`;
  feedbackMessage.setCustomValidity(length > feedbackMaxLength ? `Fikr ${feedbackMaxLength} belgidan oshmasin.` : "");
}
feedbackMessage.removeAttribute("maxlength"); // Python len bilan bir xil Unicode kod nuqtalarini sanaymiz.
feedbackMessage.addEventListener("input", countFeedback);
fetch("/api/health").then(response => response.json()).then(data => {
  if (Number.isInteger(data.feedback_max_length) && data.feedback_max_length > 0) feedbackMaxLength = data.feedback_max_length;
  countFeedback();
}).catch(() => { /* Server xatosi API amali paytida ko‘rsatiladi. */ });
document.querySelector("#feedback-form").addEventListener("submit", async event => {
  event.preventDefault();
  const result = document.querySelector("#feedback-result");
  const button = event.target.querySelector("button");
  button.disabled = true;
  result.textContent = "Tekshirilmoqda…";
  try {
    const response = await fetch("/api/feedback", {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({message: feedbackMessage.value})});
    const data = await response.json();
    result.className = response.ok ? "success-text" : "error-text";
    result.textContent = data.message || data.error;
  } catch {
    result.className = "error-text";
    result.textContent = "Server bilan aloqa yo‘q. Server ishlayotganini tekshiring.";
  } finally { button.disabled = false; }
});
showArticles();
