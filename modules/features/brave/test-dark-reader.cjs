// Run: NODE_PATH=<directory containing playwright-core and darkreader> node
// modules/features/brave/test-dark-reader.cjs <generated Neon Flux CSS> [Brave binary]
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright-core');
const palette = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../themes/neon-flux/palette.json')));
const css = fs.readFileSync(process.argv[2], 'utf8');
const rgb = hex => `rgb(${hex.match(/[a-f\d]{2}/gi).map(x => parseInt(x, 16)).join(', ')})`;

(async () => {
  const browser = await chromium.launch({
    executablePath: process.argv[3] || '/etc/profiles/per-user/miko/bin/brave',
    headless: true,
    args: ['--disable-gpu'],
  });
  try {
    const page = await browser.newPage();
    await page.setContent(`<style>
      body { background: #f6f3ec; color: black; }
      .panel { background: white; border: 1px solid #bababa; }
      :root { --csscol1: #BBBBBB; --csscol2: #DDDDDD; }
      .trainex-header { background: var(--csscol1); }
      .trainex-panel { background: var(--csscol2); }
      .header { background: #dcdcdc; }
      .nested { background: #f8f8f8; }
      .warning { background: #ffcc00; color: #cc0000; }
      .transparent { background: transparent; }
      .gradient { background: linear-gradient(#fff, #dcdcdc); }
    </style>
    <div class="panel">Panel <span class="transparent">transparent text</span></div>
    <div class="trainex-header">Variable header</div><div class="trainex-panel">Variable panel</div>
    <div class="cream" style="background:#F6F3ED">Actual TraineX cream</div>
    <div class="header">Header</div><div class="nested">Nested panel</div>
    <div class="inline" style="background:#f6f3ec">Inline cream background</div>
    <div class="warning">Warning</div><div class="gradient">Gradient</div>
    <svg><rect width="20" height="20" fill="#00ff00" /></svg>`);
    await page.addScriptTag({path: require.resolve('darkreader')});
    const theme = {
      mode: 1, brightness: 100, contrast: 100, sepia: 0, grayscale: 0,
      darkSchemeBackgroundColor: palette.canvas, darkSchemeTextColor: palette.text,
    };
    await page.evaluate(theme => DarkReader.enable(theme), theme);
    await page.waitForTimeout(300);
    const inspect = () => page.evaluate(() => Object.fromEntries(
      ['body', '.panel', '.header', '.nested', '.inline', '.warning', '.transparent', '.gradient', 'rect'].map(s => {
        const c = getComputedStyle(document.querySelector(s));
        return [s, {background: c.backgroundColor, border: c.borderTopColor, color: c.color, image: c.backgroundImage, fill: c.fill}];
      })
    ));
    const before = await inspect();
    // Same seam as the extension's global Dynamic Theme Editor CSS fixes.
    await page.evaluate(({theme, css}) => DarkReader.enable(theme, {css}), {theme, css});
    await page.waitForTimeout(300);
    const after = await inspect();
    assert.equal(after['.panel'].background, rgb(palette.surface), 'white panels must use Neon Flux surface, not a generated gray');
    assert.equal(after['.header'].background, rgb(palette.raised), 'gray headers must use raised navy');
    assert.equal(after['.nested'].background, rgb(palette.surface), 'off-white panels must use surface navy');
    assert.equal(after['.inline'].background, rgb(palette.surface), 'inline cream backgrounds must not become brown');
    assert.equal(await page.locator('.cream').evaluate(el => getComputedStyle(el).backgroundColor), rgb(palette.surface), 'actual TraineX cream must not remain brown');
    assert.equal(await page.locator('.trainex-header').evaluate(el => getComputedStyle(el).backgroundColor), rgb(palette.raised), 'CSS-variable headers must use raised navy');
    assert.equal(await page.locator('.trainex-panel').evaluate(el => getComputedStyle(el).backgroundColor), rgb(palette.raised), 'mid-gray CSS-variable panels must use raised navy');
    assert.equal(after.body.background, rgb(palette.canvas));
    assert.equal(after['.panel'].border, rgb(palette.border));
    assert.equal(after['.transparent'].background, 'rgba(0, 0, 0, 0)', 'transparent children must remain transparent');
    assert.deepEqual(after['.warning'], before['.warning'], 'semantic warning colors must remain Dark Reader-managed');
    assert.equal(after.rect.fill, before.rect.fill, 'do not repaint SVG artwork');
    assert.notEqual(after['.gradient'].image, 'none', 'do not strip background images');
    // Dark Reader adds palette variables on demand; overrides must still win.
    await page.evaluate(() => {
      const node = document.createElement('div');
      node.id = 'late-panel'; node.style.background = '#eeeeee'; document.body.append(node);
    });
    await page.waitForTimeout(200);
    assert.equal(await page.locator('#late-panel').evaluate(el => getComputedStyle(el).backgroundColor), rgb(palette.surface));
    console.log('PASS: panels, headers, nested/inline/late backgrounds, borders, canvas, transparency, warning colors, SVG, gradients');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
