const LOTTERY_GROUPS = new Set([
  'Nacional',
  'Leidsa',
  'Loteria Real',
  'Loteka',
  'Americanas',
  'La Primera',
  'La Suerte',
  'LoteDom',
  'Anguila',
  'King Lottery',
]);

const IGNORED_LINES = new Set([
  '¿Ganaste?',
  'Gracias, Resultados Pronto',
  'Resultados Anteriores',
  'Open Menu',
  'Loterias Dominicanas',
  'GRATIS -',
]);

export function parseLotteryResults(html) {
  const visibleText = stripHtml(html);
  const lines = normalizeLines(visibleText).filter((line) => !ignoredLine(line));
  const results = [];
  let currentLottery = 'Loterias Dominicanas';

  for (let i = 0; i < lines.length - 2; i += 1) {
    const line = lines[i];

    if (LOTTERY_GROUPS.has(line)) {
      currentLottery = line;
      continue;
    }

    if (!looksLikeDate(line)) continue;

    const drawName = nextMeaningfulLine(lines, i + 1);
    if (!drawName || LOTTERY_GROUPS.has(drawName)) continue;

    const numberLineIndex = nextNumberLineIndex(lines, i + 2);
    if (numberLineIndex == null) continue;

    const numbers = extractNumbers(lines[numberLineIndex]);
    if (numbers.length < 2) continue;

    results.push({
      lotteryName: currentLottery,
      drawName,
      drawDate: line,
      numbers,
      prize: extractPrize(lines, numberLineIndex + 1),
      isVerified: true,
    });

    i = numberLineIndex;
  }

  return deduplicate(results);
}

function stripHtml(html) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>|<\/div>|<\/h\d>|<\/li>|<\/a>|<\/section>|<\/article>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#x27;|&#39;/g, "'")
    .replace(/&quot;/g, '"');
}

function normalizeLines(text) {
  return text
    .split(/\n+/)
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter(Boolean);
}

function ignoredLine(line) {
  return IGNORED_LINES.has(line) || line.startsWith('Image:');
}

function nextMeaningfulLine(lines, start) {
  for (let i = start; i < lines.length && i < start + 6; i += 1) {
    const line = lines[i];
    if (ignoredLine(line) || looksLikeDate(line)) continue;
    if (extractNumbers(line).length > 1) continue;
    return line;
  }
  return null;
}

function nextNumberLineIndex(lines, start) {
  for (let i = start; i < lines.length && i < start + 8; i += 1) {
    if (extractNumbers(lines[i]).length >= 2) return i;
  }
  return null;
}

function extractNumbers(text) {
  return [...text.matchAll(/\b\d{1,3}(?:X)?\b/g)]
    .map((match) => match[0])
    .filter((value) => value.length <= 3 || value.endsWith('X'));
}

function looksLikeDate(value) {
  return /^\d{1,2}-\d{1,2}$/.test(value) || /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function extractPrize(lines, start) {
  if (start >= lines.length) return null;
  const candidate = lines[start];
  return /^\d{1,3}(,\d{3})+$/.test(candidate) ? candidate : null;
}

function deduplicate(results) {
  const seen = new Set();
  return results.filter((result) => {
    const key = `${result.lotteryName}|${result.drawName}|${result.drawDate}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}
