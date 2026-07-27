#!/usr/bin/env node
/**
 * Extract the Divan's ghazals from the Ganjoor MySQL dump into the counted
 * JSON that `prisma/seed.ts` imports (docs/hafez-dataset-sourcing.md).
 *
 *   node scripts/extract-hafez-ghazals.mjs <path-to-dump.sql> [outPath]
 *
 * Source: github.com/ganjoor/ganjoor-db (MIT) — data/dump.sql.gz, decompressed.
 * Zero dependencies, node >= 20. The script refuses to emit anything unless
 * every assertion below holds; a corpus that fails an assertion is a corpus
 * we do not ship.
 *
 * Dump schema (verified against the real 2017-11-09 dump):
 *   categories(id, poetId, name, parentId, hierarchyLevel, url)
 *   poems(id, categoryId, title, url)
 *   verses(id, poemId, order, position, text)
 */

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const [dumpPath, outPathArg] = process.argv.slice(2);
if (!dumpPath) {
  console.error('usage: node scripts/extract-hafez-ghazals.mjs <path-to-dump.sql> [outPath]');
  process.exit(1);
}
const outPath = outPathArg ?? 'apps/api/prisma/data/hafez-ghazals.json';

/** Hard-stop helper: an extraction that cannot prove itself must not emit. */
function ensure(condition, message) {
  if (!condition) {
    console.error(`extraction failed: ${message}`);
    process.exit(1);
  }
}

/**
 * Parse every row of every `INSERT INTO \`table\` VALUES (...),(...);`
 * statement in the dump. A character-level scanner, because row text contains
 * commas, parentheses and quotes that no regex split survives.
 */
function parseRows(sql, table) {
  const marker = `INSERT INTO \`${table}\` VALUES `;
  const rows = [];
  let from = 0;
  for (;;) {
    const at = sql.indexOf(marker, from);
    if (at === -1) break;
    let i = at + marker.length;
    statement: for (;;) {
      ensure(sql[i] === '(', `${table}: expected '(' at offset ${i}`);
      i += 1;
      const row = [];
      let value = '';
      let inString = false;
      let done = false;
      while (!done) {
        const ch = sql[i];
        ensure(ch !== undefined, `${table}: unterminated row at offset ${i}`);
        if (inString) {
          if (ch === '\\') {
            const next = sql[i + 1];
            const map = { n: '\n', r: '\r', t: '\t', 0: '\0', b: '\b', Z: '' };
            value += map[next] ?? next;
            i += 2;
            continue;
          }
          if (ch === "'") {
            if (sql[i + 1] === "'") {
              value += "'";
              i += 2;
              continue;
            }
            inString = false;
            i += 1;
            continue;
          }
          value += ch;
          i += 1;
          continue;
        }
        if (ch === "'") {
          inString = true;
          value = '';
          i += 1;
          continue;
        }
        if (ch === ',' || ch === ')') {
          row.push(value);
          value = '';
          if (ch === ')') {
            rows.push(row);
            done = true;
          }
          i += 1;
          continue;
        }
        value += ch;
        i += 1;
      }
      if (sql[i] === ',') {
        i += 1;
        continue;
      }
      ensure(sql[i] === ';', `${table}: expected ';' after row at offset ${i}`);
      break statement;
    }
    from = i;
  }
  return rows;
}

const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const toPersianNumber = (n) =>
  String(n)
    .split('')
    .map((d) => persianDigits[Number(d)])
    .join('');

console.log(`reading ${dumpPath} …`);
const sql = readFileSync(dumpPath, 'utf8');

// 1. The category: Hafez's غزلیات, located by content, not by remembered ids.
const categories = parseRows(sql, 'categories');
const hafezRoots = categories.filter((c) => c[1] === '2' && c[4] === '1' && c[2] === 'حافظ');
ensure(hafezRoots.length === 1, `expected one Hafez root category, found ${hafezRoots.length}`);
const ghazalCats = categories.filter((c) => c[3] === hafezRoots[0][0] && c[2] === 'غزلیات');
ensure(ghazalCats.length === 1, `expected one غزلیات category, found ${ghazalCats.length}`);
const ghazalCat = ghazalCats[0];
ensure(ghazalCat[5].endsWith('/hafez/ghazal'), `غزلیات category url looks wrong: ${ghazalCat[5]}`);

// 2. The poems of that category; the number read from the url and re-proved
//    against the Persian numeral in the title.
const poems = parseRows(sql, 'poems').filter((p) => p[1] === ghazalCat[0]);
ensure(poems.length > 0, 'no poems found in the غزلیات category');
const byPoemId = new Map();
for (const [id, , title, url] of poems) {
  const match = url.match(/\/sh(\d+)$/);
  ensure(match, `poem ${id}: url carries no /sh<N> number: ${url}`);
  const number = Number(match[1]);
  const expectedTitle = `غزل شمارهٔ ${toPersianNumber(number)}`;
  ensure(title === expectedTitle, `poem ${id}: title «${title}» ≠ «${expectedTitle}»`);
  ensure(!byPoemId.has(id), `poem ${id} appears twice`);
  byPoemId.set(id, { number });
}

// 3. Verses, paired into couplets. Positions must alternate 0,1,0,1 … — a
//    ghazal that does not scan as couplets is a parsing error, not a poem.
for (const row of parseRows(sql, 'verses')) {
  const [, poemId, order, position, text] = row;
  const poem = byPoemId.get(poemId);
  if (!poem) continue;
  (poem.verses ??= []).push({ order: Number(order), position: Number(position), text });
}
const ghazals = [];
for (const [poemId, poem] of byPoemId) {
  ensure(poem.verses && poem.verses.length >= 2, `poem ${poemId}: fewer than two hemistichs`);
  poem.verses.sort((a, b) => a.order - b.order);
  ensure(poem.verses.length % 2 === 0, `poem ${poemId}: odd hemistich count`);
  const couplets = [];
  for (let i = 0; i < poem.verses.length; i += 2) {
    const first = poem.verses[i];
    const second = poem.verses[i + 1];
    ensure(
      first.position === 0 && second.position === 1,
      `poem ${poemId}: positions do not alternate at order ${first.order}`,
    );
    const m1 = first.text.trim();
    const m2 = second.text.trim();
    ensure(m1.length > 0 && m2.length > 0, `poem ${poemId}: empty hemistich`);
    couplets.push([m1, m2]);
  }
  ghazals.push({ number: poem.number, openingLine: couplets[0][0], verses: couplets });
}

// 4. Numbering must cover 1..count with no gaps and no repeats — the exact
//    range the seed re-asserts and selection will draw from.
ghazals.sort((a, b) => a.number - b.number);
const count = ghazals.length;
ghazals.forEach((ghazal, index) => {
  ensure(ghazal.number === index + 1, `numbering gap at ${index + 1} (found ${ghazal.number})`);
});

const corpus = {
  edition: 'ganjoor-db-2017',
  count,
  source: {
    repository: 'https://github.com/ganjoor/ganjoor-db',
    commit: '7ce93971bc028e1c4a9cddeb293a05a637c670da',
    dumpFile: 'data/dump.sql.gz (dated 2017-11-09)',
    license: 'MIT — Copyright (c) 2017 Ganjoor',
    note:
      'Poem text is public domain; the compilation (numbering, structure, corrections) ' +
      'is Ganjoor’s work under MIT and must be credited where this data ships.',
  },
  ghazals,
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(corpus, null, 2) + '\n', 'utf8');

const couplets = ghazals.reduce((sum, g) => sum + g.verses.length, 0);
console.log(
  `wrote ${outPath}: ${count} ghazals (cat ${ghazalCat[0]}), ${couplets} couplets, ` +
    `numbers ${ghazals[0].number}..${ghazals[count - 1].number}`,
);
