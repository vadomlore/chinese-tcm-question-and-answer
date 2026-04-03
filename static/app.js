const DATA_INDEX_PATH = "./data/index.json";
const QUESTION_SECTION = "## Daily Questions (AI Generated)";

function setText(id, value) {
    const element = document.getElementById(id);
    if (element) {
        element.textContent = value;
    }
}

function showEmpty(message, reviewDate, sourceFile = "暂无") {
    setText("review-date", reviewDate);
    setText("source-file", sourceFile);
    setText("card-count", "0");
    setText("empty-message", message);
    document.getElementById("empty-state").hidden = false;
    document.getElementById("card-list").hidden = true;
}

function splitCardBlocks(sectionText) {
    return sectionText
        .split(/^###\s+\d+\s*$/m)
        .map((part) => part.trim())
        .filter((part) => part && !part.includes("Waiting for generation"));
}

function extractField(block, labels) {
    for (const label of labels) {
        const regex = new RegExp(`^-\\s*${label}\\s*[:：]\\s*(.+)$`, "m");
        const match = block.match(regex);
        if (match) {
            return match[1].trim();
        }
    }
    return "";
}

function parseCards(markdown) {
    if (!markdown.includes(QUESTION_SECTION)) {
        return [];
    }

    const section = markdown.split(QUESTION_SECTION)[1].split("## Notes")[0];
    const blocks = splitCardBlocks(section);

    return blocks.map((block, index) => ({
        index: index + 1,
        question: extractField(block, ["问题", "Question"]),
        answer: extractField(block, ["答案", "Answer"]) || "未填写答案",
        keywords: extractField(block, ["关键词", "Keywords"]) || "待补充",
        hint: extractField(block, ["复习提示", "Review Hint"]) || "适合短时复习",
    })).filter((card) => card.question);
}

function renderCards(cards) {
    const list = document.getElementById("card-list");
    list.innerHTML = "";

    cards.forEach((card) => {
        const article = document.createElement("article");
        article.className = "flashcard";
        article.innerHTML = `
            <p class="card-index">第 ${card.index} 题</p>
            <h2>${card.question}</h2>
            <details>
                <summary>显示答案</summary>
                <p><strong>答案：</strong>${card.answer}</p>
                <p><strong>关键词：</strong>${card.keywords}</p>
                <p><strong>复习提示：</strong>${card.hint}</p>
            </details>
        `;
        list.appendChild(article);
    });

    document.getElementById("empty-state").hidden = true;
    list.hidden = false;
}

function todayIso() {
    return new Date().toISOString().slice(0, 10);
}

function pickCandidateFile(indexData, reviewDate) {
    const datedFiles = (indexData.dailyFiles || []).filter((item) => item.hasQuestions);
    if (!datedFiles.length) {
        return null;
    }

    const previous = datedFiles.filter((item) => item.date < reviewDate);
    return (previous.at(-1) || datedFiles.at(-1));
}

async function fetchText(path) {
    const response = await fetch(path, { cache: "no-store" });
    if (!response.ok) {
        throw new Error(`Failed to fetch ${path}`);
    }
    return response.text();
}

async function fetchJson(path) {
    const response = await fetch(path, { cache: "no-store" });
    if (!response.ok) {
        throw new Error(`Failed to fetch ${path}`);
    }
    return response.json();
}

async function boot() {
    const params = new URLSearchParams(window.location.search);
    const reviewDate = params.get("date") || todayIso();

    try {
        const indexData = await fetchJson(DATA_INDEX_PATH);
        const candidate = pickCandidateFile(indexData, reviewDate);

        if (!candidate) {
            showEmpty("还没有任何已生成题目的日卡文件。先生成并发布一份题库。", reviewDate);
            return;
        }

        const markdown = await fetchText(`./${candidate.path}`);
        const cards = parseCards(markdown);

        if (!cards.length) {
            showEmpty("已经找到题库文件，但其中还没有可练习的问题。请先执行一次 /生成中医问答题。", reviewDate, candidate.fileName);
            return;
        }

        setText("review-date", reviewDate);
        setText("source-file", candidate.fileName);
        setText("card-count", String(cards.length));
        renderCards(cards);
    } catch (error) {
        showEmpty("页面加载失败。请确认 data/index.json 和每日题库文件已经推送到仓库。", reviewDate);
        console.error(error);
    }
}

boot();
