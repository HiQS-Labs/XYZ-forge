import * as child_process from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import { CardItem } from '../types';

interface ReleaseRow {
  version: string;
  codename?: string;
  status?: string;
  target_date?: string;
  milestone?: string;
  description?: string;
}

function findReleasesFromDb(dbPath: string, folderLabel?: string): CardItem[] {
  try {
    const pyCode =
      'import sqlite3, json, sys; conn = sqlite3.connect(sys.argv[1]); conn.row_factory = sqlite3.Row; print(json.dumps([dict(r) for r in conn.execute("SELECT version, codename, status, target_date, milestone, description FROM releases ORDER BY id").fetchall()]))';
    const output = child_process.execFileSync('python3', ['-c', pyCode, dbPath], { encoding: 'utf8' });
    const rows = JSON.parse(output) as ReleaseRow[];
    const items: CardItem[] = [];
    for (const row of rows) {
      const version = row.version;
      if (!version) {
        continue;
      }
      const codename = row.codename;
      const title = codename ? `${codename} (${version})` : version;
      const meta: string[] = [];
      if (row.target_date) {
        meta.push(`target ${row.target_date}`);
      }
      if (row.milestone) {
        meta.push(`milestone ${row.milestone}`);
      }
      if (row.description) {
        const desc = row.description;
        meta.push(desc.length > 140 ? `${desc.slice(0, 140)}…` : desc);
      }

      items.push({
        id: `release:${folderLabel ?? ''}:${version}`,
        title,
        badge: row.status,
        meta: folderLabel ? [`(${folderLabel})`, ...meta] : meta,
        copyValue: codename ?? version,
        copyLabel: `Copy "${codename ?? version}"`,
      });
    }
    return items;
  } catch {
    return [];
  }
}

function parseBlock(block: string): Record<string, string> {
  const fields: Record<string, string> = {};
  for (const line of block.split('\n')) {
    const match = /^([A-Za-z][\w -]*):\s?(.*)$/.exec(line);
    if (match) {
      fields[match[1].trim()] = match[2].trim();
    }
  }
  return fields;
}

export function findReleases(workspaceRoot: string, folderLabel?: string): CardItem[] {
  const dbPath = path.join(workspaceRoot, 'releases.db');
  if (fs.existsSync(dbPath)) {
    return findReleasesFromDb(dbPath, folderLabel);
  }

  const full = path.join(workspaceRoot, 'RELEASES.md');
  let text: string;
  try {
    text = fs.readFileSync(full, 'utf8');
  } catch {
    return [];
  }

  const items: CardItem[] = [];
  const blocks = text.split(/\n{2,}/).filter((b) => /^Release:/m.test(b));
  for (const block of blocks) {
    const fm = parseBlock(block);
    if (!fm['Release']) {
      continue;
    }
    const version = fm['Release'];
    const codename = fm['Codename'];
    const title = codename ? `${codename} (${version})` : version;
    const meta: string[] = [];
    if (fm['Target Date']) {
      meta.push(`target ${fm['Target Date']}`);
    }
    if (fm['Milestone']) {
      meta.push(`milestone ${fm['Milestone']}`);
    }
    if (fm['Description']) {
      const desc = fm['Description'];
      meta.push(desc.length > 140 ? `${desc.slice(0, 140)}…` : desc);
    }

    items.push({
      id: `release:${folderLabel ?? ''}:${version}`,
      title,
      badge: fm['Status'],
      meta: folderLabel ? [`(${folderLabel})`, ...meta] : meta,
      copyValue: codename ?? version,
      copyLabel: `Copy "${codename ?? version}"`,
    });
  }
  return items;
}
