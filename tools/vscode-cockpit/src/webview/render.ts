export function getHtml(cspSource: string, nonce: string): string {
  return /* html */ `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}';">
<style>
  :root { color-scheme: light dark; }
  body {
    font-family: var(--vscode-font-family);
    font-size: var(--vscode-font-size);
    color: var(--vscode-foreground);
    padding: 0;
    margin: 0;
  }
  .section { border-bottom: 1px solid var(--vscode-sideBarSectionHeader-border, transparent); }
  .section-header {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 6px 8px;
    cursor: pointer;
    user-select: none;
    background: var(--vscode-sideBarSectionHeader-background, transparent);
    font-weight: 600;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.3px;
  }
  .section-header:hover { background: var(--vscode-list-hoverBackground); }
  .caret {
    display: inline-block;
    width: 12px;
    transition: transform 0.1s ease;
    transform: rotate(90deg);
  }
  .section.collapsed .caret { transform: rotate(0deg); }
  .count {
    margin-left: auto;
    opacity: 0.65;
    font-weight: 400;
    font-size: 11px;
  }
  .section-body { padding: 4px 8px 8px; display: flex; flex-direction: column; gap: 6px; }
  .section.collapsed .section-body { display: none; }
  .empty { opacity: 0.6; font-style: italic; padding: 4px 2px 8px; font-size: 12px; }
  .card {
    border: 1px solid var(--vscode-widget-border, var(--vscode-panel-border));
    border-radius: 4px;
    padding: 6px 8px;
    background: var(--vscode-sideBar-background);
  }
  .card-top { display: flex; align-items: flex-start; gap: 6px; flex-wrap: wrap; }
  .card-title { font-weight: 600; overflow-wrap: break-word; word-break: normal; flex: 1 1 140px; min-width: 0; }
  .badge {
    font-size: 10px;
    padding: 1px 6px;
    border-radius: 9px;
    background: var(--vscode-badge-background);
    color: var(--vscode-badge-foreground);
    white-space: nowrap;
    flex: 0 0 auto;
  }
  .copy-btn {
    border: none;
    background: transparent;
    color: var(--vscode-icon-foreground, var(--vscode-foreground));
    cursor: pointer;
    opacity: 0.7;
    padding: 2px 4px;
    border-radius: 3px;
    font-size: 13px;
    flex: 0 0 auto;
    line-height: 1;
  }
  .copy-btn:hover { opacity: 1; background: var(--vscode-toolbar-hoverBackground); }
  .copy-btn.copied { opacity: 1; }
  .meta { margin-top: 3px; font-size: 11px; opacity: 0.75; overflow-wrap: anywhere; }
  .meta div { margin-top: 1px; }
</style>
</head>
<body>
<div id="root"></div>
<script nonce="${nonce}">
(function () {
  const vscode = acquireVsCodeApi();
  const root = document.getElementById('root');
  const priorState = vscode.getState() || { collapsed: {} };
  const collapsed = priorState.collapsed;

  function saveState() {
    vscode.setState({ collapsed });
  }

  function render(sections) {
    root.innerHTML = '';
    for (const section of sections) {
      const el = document.createElement('div');
      el.className = 'section' + (collapsed[section.id] ? ' collapsed' : '');
      el.dataset.sectionId = section.id;

      const header = document.createElement('div');
      header.className = 'section-header';
      header.innerHTML =
        '<span class="caret">▸</span><span>' + section.title + '</span>' +
        '<span class="count">' + section.items.length + '</span>';
      header.addEventListener('click', () => {
        el.classList.toggle('collapsed');
        collapsed[section.id] = el.classList.contains('collapsed');
        saveState();
      });
      el.appendChild(header);

      const body = document.createElement('div');
      body.className = 'section-body';
      if (section.items.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'empty';
        empty.textContent = section.emptyMessage;
        body.appendChild(empty);
      } else {
        for (const item of section.items) {
          body.appendChild(renderCard(item));
        }
      }
      el.appendChild(body);
      root.appendChild(el);
    }
  }

  function renderCard(item) {
    const card = document.createElement('div');
    card.className = 'card';

    const top = document.createElement('div');
    top.className = 'card-top';

    const title = document.createElement('span');
    title.className = 'card-title';
    title.textContent = item.title;
    top.appendChild(title);

    if (item.badge) {
      const badge = document.createElement('span');
      badge.className = 'badge';
      badge.textContent = item.badge;
      top.appendChild(badge);
    }

    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy-btn';
    copyBtn.title = item.copyLabel || 'Copy';
    copyBtn.textContent = '⧉';
    copyBtn.addEventListener('click', () => {
      vscode.postMessage({ command: 'copy', text: item.copyValue });
      copyBtn.textContent = '✓';
      copyBtn.classList.add('copied');
      setTimeout(() => {
        copyBtn.textContent = '⧉';
        copyBtn.classList.remove('copied');
      }, 1200);
    });
    top.appendChild(copyBtn);
    card.appendChild(top);

    if (item.meta && item.meta.length) {
      const meta = document.createElement('div');
      meta.className = 'meta';
      for (const line of item.meta) {
        const d = document.createElement('div');
        d.textContent = line;
        meta.appendChild(d);
      }
      card.appendChild(meta);
    }
    return card;
  }

  window.addEventListener('message', (event) => {
    const message = event.data;
    if (message.command === 'render') {
      render(message.sections);
    }
  });

  vscode.postMessage({ command: 'ready' });
})();
</script>
</body>
</html>`;
}
