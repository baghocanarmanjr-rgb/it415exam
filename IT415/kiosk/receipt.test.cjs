// Run with: node IT415/kiosk/receipt.test.cjs
// Executes the actual inline app script with a minimal DOM and controlled timers.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { webcrypto } = require('node:crypto');
const html = fs.readFileSync(`${__dirname}/index.html`, 'utf8');
const script = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].at(-1)[1];
function kiosk(storage = new Map(), blocked = false) {
  const elements = new Map();
  const timers = new Map();
  let timer = 0;
  const context = vm.createContext({
    crypto: webcrypto,
    localStorage: {
      getItem(key) { if (blocked) throw Error('Unavailable'); return storage.get(key) ?? null; },
      setItem(key, value) { if (blocked) throw Error('Unavailable'); storage.set(key, String(value)); }
    },
    document: { getElementById(id) {
      if (!elements.has(id)) elements.set(id, { innerHTML: '', value: '', hidden: true,
        classList: { add() {}, remove() {} }, focus() {}, setSelectionRange() {} });
      return elements.get(id);
    } },
    window: { scrollTo() {} },
    setTimeout(fn) { timers.set(++timer, fn); return timer; },
    clearTimeout(id) { timers.delete(id); }
  });
  vm.runInContext(script, context);
  return {
    run(code) { return vm.runInContext(code, context); },
    view() { return elements.get('app').innerHTML; },
    flush() { const pending = [...timers.values()]; timers.clear(); pending.forEach(fn => fn()); }
  };
}
const app = kiosk();
app.run("go('receipt')");
assert.equal(app.run('S.screen'), 'order');
app.run("add(1); add(1); add(2); go('cash'); S.paid='100'; payCash()");
assert.equal(app.run('S.txn'), null);
assert.equal(app.run('seq'), 0);
app.run("S.paid='invalid'; payCash()");
assert.equal(app.run('S.txn'), null);
app.run("S.paid='200'; payCash()");
assert.equal(app.run('S.screen'), 'success');
assert.match(app.view(), /Payment Successful!/);
const first = app.run('S.txn.no');
assert.match(first, /^TXN-\d{4}-\d{5}-[\da-f-]{36}$/);
assert.equal(app.run('S.txn.total'), 140);
assert.equal(app.run('S.txn.paid'), 200);
assert.equal(app.run('S.txn.change'), 60);
assert.equal(app.run('S.txn.method'), 'Cash');
app.run("complete('Cash', 200)");
assert.equal(app.run('S.txn.no'), first);
app.run("go('receipt')");
assert.match(app.view(), /Official Digital Receipt/);
assert.match(app.view(), /<td>Coffee<\/td><td>2<\/td><td>₱45.00<\/td><td>₱90.00<\/td>/);
assert.match(app.view(), /<td>Sandwich<\/td><td>1<\/td><td>₱50.00<\/td><td>₱50.00<\/td>/);
for (const value of [first, '₱140.00', '₱200.00', '₱60.00', 'Cash', 'Date/Time', 'Print Receipt', 'New Transaction']) {
  assert.ok(app.view().includes(value), value);
}
app.run("go('order')");
assert.equal(app.run('S.screen'), 'receipt');
app.run('newTxn()');
assert.equal(app.run('S.screen'), 'order');
assert.equal(app.run('count()'), 0);
assert.equal(app.run('total()'), 0);
assert.equal(app.run('S.method'), null);
assert.equal(app.run('S.paid'), '');
assert.equal(app.run('S.txn'), null);
assert.equal(app.run('S.processing'), false);
assert.ok(!app.view().includes(first));
assert.ok(app.view().includes('₱0.00'));
assert.equal(app.run('matchingProducts().length'), 6);
app.run("add(4); go('qr'); complete('QR Payment',total()); go('receipt')");
assert.notEqual(app.run('S.txn.no'), first);
assert.equal(app.run('S.txn.method'), 'QR Payment');
assert.equal(app.run('S.txn.total'), 25);
assert.equal(app.run('S.txn.paid'), 25);
assert.equal(app.run('S.txn.change'), 0);
assert.ok(!app.view().includes('<td>Coffee</td>'));
app.run("newTxn(); add(5); go('card'); cardPay()");
assert.equal(app.run('S.txn'), null);
app.flush();
assert.equal(app.run('S.txn.method'), 'Credit/Debit Card');
assert.equal(app.run('S.txn.total'), 20);
assert.equal(app.run('S.txn.paid'), 20);
assert.equal(app.run('S.txn.change'), 0);
app.run("newTxn(); add(1); go('card'); cardPay(); newTxn()");
app.flush();
assert.equal(app.run('S.txn'), null);
assert.equal(app.run('total()'), 0);
const references = new Set();
for (let i = 0; i < 30; i++) {
  const isolated = kiosk(new Map(), true);
  isolated.run("add(1); complete('Cash',45)");
  references.add(isolated.run('S.txn.no'));
}
assert.equal(references.size, 30);
console.log('PASS: success, receipt items/quantities/totals, cash/QR/card details, failure guards, reset, catalog preservation, reference uniqueness, canceled card timer.');
