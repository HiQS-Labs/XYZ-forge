'use strict';

const { parse, parseLine } = require('./parse');
const { validate } = require('./validate');

function summarize(entries) {
  const byAccount = new Map();
  for (const e of entries) {
    const k = `${e.account} ${e.currency}`;
    byAccount.set(k, (byAccount.get(k) || 0) + e.amount);
  }
  return [...byAccount.entries()]
    .map(([k, total]) => {
      const [account, currency] = k.split(' ');
      return { account, currency, total };
    })
    .sort((a, b) => a.account.localeCompare(b.account) || a.currency.localeCompare(b.currency));
}

module.exports = { parse, parseLine, validate, summarize };
