// /xyz-status — read-only XYZ status with no model turn (GH-964).
// Runs three existing readers and prints their output; it never approves,
// blocks or rewrites anything, so it registers no tool or prompt hooks.
import type { Register } from 'claude-code'

const TIMEOUT_MS = 15_000

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'xyz-status',
      description: 'XYZ: recent hosted runs, tick claims, marathon/relay drivers (no model turn)',
      immediate: true,
    })
    return next(e)
  })

  on('command.run', { command: 'xyz-status' }, async $ => {
    const top = await $.process.run(['git', 'rev-parse', '--show-toplevel'], { timeoutMs: TIMEOUT_MS })
      .catch(() => undefined)
    const root = top?.exitCode === 0 ? top.stdout.trim() : ''
    if (!root) return { text: 'xyz-status: not inside a git repository — start the session in an XYZ-forge clone.' }

    // Repo-local readers run by absolute path; gh comes from PATH. All run in the root,
    // with TICK_REPO_ROOT pinned so tick cannot follow an inherited root elsewhere.
    const readers: [string, string[]][] = [
      ['Hosted runs on development (recent 8)', ['gh', 'run', 'list', '--branch', 'development', '--limit', '8']],
      ['tick claims', [`${root}/bin/tick`, 'claims']],
      ['Marathon / relay drivers', ['bash', `${root}/relay-automation/marathon-ls.sh`]],
    ]

    const sections = await Promise.all(readers.map(async ([title, argv]) => {
      try {
        const r = await $.process.run(argv, { cwd: root, env: { TICK_REPO_ROOT: root }, timeoutMs: TIMEOUT_MS })
        const out = r.stdout.trim()
        if (r.exitCode === 0 && out) return `## ${title}\n${out}`
        const why = r.stderr.trim().split('\n')[0] || (out ? out.split('\n')[0] : 'empty output')
        return `## ${title}\nERROR (exit ${r.exitCode}): ${why}`
      } catch (err) {
        return `## ${title}\nERROR (${err instanceof Error ? err.message : String(err)})`
      }
    }))

    return { text: [`root: ${root}`, ...sections].join('\n\n') }
  })
}
