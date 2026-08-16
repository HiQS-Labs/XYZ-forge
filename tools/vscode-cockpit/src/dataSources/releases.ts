import * as fs from 'fs';
import * as path from 'path';
import { CardItem } from '../types';

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
