// Verify a CSS/JS animation in a REAL browser via the Chrome DevTools Protocol.
// No test framework, no Playwright install — just headless Chrome + a WebSocket.
//
// Why this exists: an animation can pass a code read and still drift, jump, or stall
// on screen. This drives the live page, samples the animated element's transform +
// getBoundingClientRect + opacity across the whole animation window, grabs screenshots,
// and prints a PASS/FAIL verdict. See:
//   lessons/css-scale-property-multiplies-translate.md   (trust getBoundingClientRect
//     over DOMMatrix.m41 — the matrix reflects only `transform`, not separate
//     scale/translate/rotate properties, so a rect/matrix disagreement is REAL drift)
//   Verify on the main-checkout dev server after ff-merge, NOT a worktree server —
//     Vite fs.allow blanks an out-of-tree worktree.
//
// Edit the CONFIG block, then:  node verify-anim.mjs
// Gotchas baked in: navigate + sleep BEFORE touching localStorage (else SecurityError
// on the blank initial document); awaitPromise on Runtime.evaluate; SIGKILL cleanup.

import { spawn } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
import { writeFileSync } from 'node:fs';

const CONFIG = {
  chrome: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  port: 9444,
  url: 'http://localhost:5175/',          // the MAIN-checkout dev server, not a worktree
  window: '1280,360',

  // JS run once after first navigate, BEFORE reload. Seed mock state / localStorage here.
  // Leave '' to skip. (Runs on a real document, so localStorage is allowed.)
  setup: `localStorage.setItem('app:data-source','mock');`,
  reloadAfterSetup: true,

  settleMs: 2600,                          // wait after reload for the scene to settle
  trigger: `document.querySelector('[data-sprite-trigger]')?.click(); 1`,  // start the anim

  // Expression returning a plain object describing the element each frame. Sample BOTH
  // the matrix (m41/m42 = the `transform` property only) and the rect (true on-screen
  // box) — when they disagree, the rect wins.
  probe: `(() => {
    const k = document.querySelector('.sprite');
    if (!k) return null;
    const m = new DOMMatrix(getComputedStyle(k).transform);
    const r = k.getBoundingClientRect();
    return {
      tx: Math.round(m.m41), ty: Math.round(m.m42),
      cx: Math.round(r.left + r.width / 2), cy: Math.round(r.top + r.height / 2),
      op: +(+getComputedStyle(k).opacity).toFixed(2),
    };
  })()`,

  frames: 12,                              // probe samples across the animation
  intervalMs: 55,
  shotsAt: [3, 7],                         // sample indices to screenshot
  shotPath: (i) => `/tmp/anim-${i}.png`,
  tailMs: 400,                             // settle, then one final probe ("ended")
};

let ws, msgId = 0;
const pending = new Map();
const send = (method, params = {}) => {
  const id = ++msgId;
  ws.send(JSON.stringify({ id, method, params }));
  return new Promise((r) => pending.set(id, r));
};
async function ev(expression) {
  const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails));
  return r.result.value;
}
async function shot(path) {
  const s = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(path, Buffer.from(s.data, 'base64'));
}

const chrome = spawn(CONFIG.chrome, [
  `--remote-debugging-port=${CONFIG.port}`, '--headless=new',
  `--user-data-dir=/tmp/cdp-anim-prof-${CONFIG.port}`,
  '--no-first-run', '--no-default-browser-check', `--window-size=${CONFIG.window}`, CONFIG.url,
], { stdio: 'ignore' });

try {
  // Find the page target.
  let target;
  for (let i = 0; i < 50; i++) {
    try {
      const list = await (await fetch(`http://localhost:${CONFIG.port}/json`)).json();
      target = list.find((x) => x.type === 'page' && x.webSocketDebuggerUrl);
      if (target) break;
    } catch {}
    await sleep(200);
  }
  if (!target) throw new Error('no CDP page target — is Chrome at CONFIG.chrome?');

  ws = new globalThis.WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('message', (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
  });
  await new Promise((r) => ws.addEventListener('open', r));
  await send('Runtime.enable');
  await send('Page.enable');

  // Navigate + settle BEFORE localStorage — the blank initial doc throws SecurityError.
  await send('Page.navigate', { url: CONFIG.url });
  await sleep(900);
  if (CONFIG.setup) {
    await ev(`(() => { ${CONFIG.setup} return 1; })()`);
    if (CONFIG.reloadAfterSetup) { await send('Page.reload'); await sleep(1400); }
  }
  await sleep(CONFIG.settleMs);

  const open = await ev(CONFIG.probe);
  if (CONFIG.trigger) await ev(CONFIG.trigger);

  const samples = [];
  for (let i = 0; i < CONFIG.frames; i++) {
    samples.push(await ev(CONFIG.probe));
    if (CONFIG.shotsAt.includes(i)) await shot(CONFIG.shotPath(i));
    await sleep(CONFIG.intervalMs);
  }
  await sleep(CONFIG.tailMs);
  const ended = await ev(CONFIG.probe);

  console.log('OPEN :', JSON.stringify(open));
  for (const s of samples) console.log('  ', JSON.stringify(s));
  console.log('ENDED:', JSON.stringify(ended));

  // ---- VERDICT: edit the assertions for the property under test. -----------------
  // Example (directional exit leap): moved toward the facing side + up, then faded.
  const valid = samples.filter(Boolean);
  const last = valid.at(-1);
  if (open && last) {
    const dx = last.cx - open.cx, dy = last.cy - open.cy;
    const faded = ended && ended.op < 0.05;
    console.log(`\nΔcx=${dx} Δcy=${dy} faded=${faded}`);
    console.log('VERDICT:', faded ? 'check Δ against the intended motion' : 'CHECK — did not fade');
  }
  console.log('shots:', CONFIG.shotsAt.map((i) => CONFIG.shotPath(i)).join(' '));
} catch (e) {
  console.error('ERROR', e);
  process.exitCode = 1;
} finally {
  try { ws?.close(); } catch {}
  chrome.kill('SIGKILL');
}
