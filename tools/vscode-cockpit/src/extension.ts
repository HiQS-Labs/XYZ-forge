import * as vscode from 'vscode';
import { findMarathons } from './dataSources/marathons';
import { findReleases } from './dataSources/releases';
import { findWorktrees } from './dataSources/worktrees';
import { getHtml } from './webview/render';
import { Section } from './types';

function randomNonce(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let out = '';
  for (let i = 0; i < 32; i++) {
    out += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return out;
}

function gatherSections(): Section[] {
  const folders = vscode.workspace.workspaceFolders ?? [];
  const multi = folders.length > 1;

  const marathons = folders.flatMap((f) => findMarathons(f.uri.fsPath, multi ? f.name : undefined));
  const releases = folders.flatMap((f) => findReleases(f.uri.fsPath, multi ? f.name : undefined));
  const worktrees = folders.flatMap((f) => findWorktrees(f.uri.fsPath, multi ? f.name : undefined));

  return [
    {
      id: 'marathons',
      title: 'Marathons',
      items: marathons,
      emptyMessage: 'No PROJECT/2-WORKING/MARATHON-PLAN-*.md files in this workspace.',
    },
    {
      id: 'releases',
      title: 'Releases',
      items: releases,
      emptyMessage: 'No RELEASES.md entries — this file is optional and often empty.',
    },
    {
      id: 'worktrees',
      title: 'Git Worktrees',
      items: worktrees,
      emptyMessage: 'No git worktrees found for this workspace.',
    },
  ];
}

class CockpitViewProvider implements vscode.WebviewViewProvider {
  private view?: vscode.WebviewView;

  resolveWebviewView(webviewView: vscode.WebviewView): void {
    this.view = webviewView;
    webviewView.webview.options = { enableScripts: true };
    webviewView.webview.html = getHtml(webviewView.webview.cspSource, randomNonce());

    webviewView.webview.onDidReceiveMessage((message) => {
      if (message.command === 'ready') {
        this.refresh();
      } else if (message.command === 'copy') {
        vscode.env.clipboard.writeText(message.text);
        vscode.window.setStatusBarMessage(`Copied "${message.text}"`, 2000);
      }
    });

    webviewView.onDidChangeVisibility(() => {
      if (webviewView.visible) {
        this.refresh();
      }
    });
  }

  refresh(): void {
    if (!this.view) {
      return;
    }
    this.view.webview.postMessage({ command: 'render', sections: gatherSections() });
  }
}

export function activate(context: vscode.ExtensionContext): void {
  const provider = new CockpitViewProvider();

  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider('xyzCockpit.view', provider),
    vscode.commands.registerCommand('xyzCockpit.refresh', () => provider.refresh()),
  );

  const watcher = vscode.workspace.createFileSystemWatcher(
    '**/{RELEASES.md,PROJECT/2-WORKING/MARATHON-PLAN-*.md,.git/worktrees/**}',
  );
  context.subscriptions.push(
    watcher,
    watcher.onDidChange(() => provider.refresh()),
    watcher.onDidCreate(() => provider.refresh()),
    watcher.onDidDelete(() => provider.refresh()),
    vscode.workspace.onDidChangeWorkspaceFolders(() => provider.refresh()),
  );
}

export function deactivate(): void {}
