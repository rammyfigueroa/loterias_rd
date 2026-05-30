import assert from 'node:assert/strict';
import test from 'node:test';

import { parseLotteryResults } from '../src/parser.js';

test('parsea resultados desde HTML similar a la fuente', () => {
  const html = `
    <main>
      <h2>Nacional</h2>
      <p>29-05</p>
      <a>Juega + Pega +</a>
      <p>13 16 19 26 25</p>
      <h2>Leidsa</h2>
      <p>28-05</p>
      <a>Quiniela Leidsa</a>
      <p>44 56 97</p>
    </main>
  `;

  const results = parseLotteryResults(html);

  assert.equal(results.length, 2);
  assert.equal(results[0].lotteryName, 'Nacional');
  assert.equal(results[0].drawName, 'Juega + Pega +');
  assert.deepEqual(results[0].numbers, ['13', '16', '19', '26', '25']);
  assert.equal(results[1].lotteryName, 'Leidsa');
});
