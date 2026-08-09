import { execFileSync } from 'child_process';
import { CardItem } from '../types';

interface RawEntry {
  path?: string;
  head?: string;
  branch?: string;
  detached?: boolean;
}

function parsePorcelain(output: string): RawEntry[] {
  const entries: RawEntry[] = [];
  let current: RawEntry = {};
  for (const line of output.split('\n')) {
    if (line.trim() === '') {
      if (current.path) {
        entries.push(current);
      }
      current = {};
      continue;
    }
    if (line.startsWith('worktree ')) {
      current.path = line.slice('worktree '.length).trim();
    } else if (line.startsWith('HEAD ')) {
      current.head = line.slice('HEAD '.length).trim();
    } else if (line.startsWith('branch ')) {
      current.branch = line.slice('branch '.length).replace('refs/heads/', '').trim();
    } else if (line.startsWith('detached')) {
      current.detached = true;
    }
  }
  if (current.path) {
    entries.push(current);
  }
  return entries;
}

export function findWorktrees(workspaceRoot: string, folderLabel?: string): CardItem[] {
  let output: string;
  try {
    output = execFileSync('git', ['worktree', 'list', '--porcelain'], {
      cwd: workspaceRoot,
      encoding: 'utf8',
    });
  } catch {
    return [];
  }

  const entries = parsePorcelain(output);
  return entries.map((entry): CardItem => {
    const shortSha = entry.head ? entry.head.slice(0, 7) : '';
    const title = entry.branch ?? `detached @ ${shortSha}`;
    const meta = [entry.path ?? '', shortSha ? `HEAD ${shortSha}` : ''].filter(Boolean);
    return {
      id: `worktree:${folderLabel ?? ''}:${entry.path}`,
      title,
      badge: entry.detached ? 'detached' : undefined,
      meta: folderLabel ? [`(${folderLabel})`, ...meta] : meta,
      copyValue: entry.path ?? '',
      copyLabel: 'Copy path',
    };
  });
}
