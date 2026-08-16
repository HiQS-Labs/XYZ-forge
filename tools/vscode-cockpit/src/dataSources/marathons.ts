import * as fs from 'fs';
import * as path from 'path';
import { CardItem } from '../types';

function parseFrontmatter(text: string): Record<string, string> {
  const fields: Record<string, string> = {};
  if (!text.startsWith('---')) {
    return fields;
  }
  const end = text.indexOf('\n---', 3);
  if (end === -1) {
    return fields;
  }
  const block = text.slice(3, end);
  for (const line of block.split('\n')) {
    const match = /^([A-Za-z_][\w-]*):\s?(.*)$/.exec(line);
    if (match && match[2] && match[2] !== '>' && match[2] !== '|') {
      fields[match[1]] = match[2].trim();
    }
  }
  return fields;
}

function firstHeading(text: string): string | undefined {
  const match = /^#\s+(.+)$/m.exec(text);
  return match ? match[1].trim() : undefined;
}

export function findMarathons(workspaceRoot: string, folderLabel?: string): CardItem[] {
  const dir = path.join(workspaceRoot, 'PROJECT', '2-WORKING');
  let entries: string[] = [];
  try {
    entries = fs.readdirSync(dir).filter((f) => /^MARATHON-PLAN-.*\.md$/.test(f));
  } catch {
    return [];
  }

  const items: CardItem[] = [];
  for (const file of entries.sort().reverse()) {
    const full = path.join(dir, file);
    let text: string;
    try {
      text = fs.readFileSync(full, 'utf8');
    } catch {
      continue;
    }
    const fm = parseFrontmatter(text);
    const stem = file.replace(/\.md$/, '');
    const meta: string[] = [];
    if (fm.updated) {
      meta.push(`updated ${fm.updated}`);
    } else if (fm.created) {
      meta.push(`created ${fm.created}`);
    }
    if (fm.owner) {
      meta.push(`owner ${fm.owner}`);
    }
    meta.push(path.join('PROJECT', '2-WORKING', file));

    items.push({
      id: `marathon:${folderLabel ?? ''}:${stem}`,
      title: fm.title ? fm.title.replace(/^Marathon Plan\s*—?\s*/i, '') || stem : firstHeading(text) ?? stem,
      badge: fm.status,
      meta: folderLabel ? [`(${folderLabel})`, ...meta] : meta,
      copyValue: stem,
      copyLabel: `Copy "${stem}"`,
    });
  }
  return items;
}
