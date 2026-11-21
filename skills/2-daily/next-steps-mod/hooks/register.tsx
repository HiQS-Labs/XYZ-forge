// next-steps-mod — Claude names the next steps every turn; nobody asks "what's next?" (GH-1240).
//
// Three parts, one aim:
//   1. prompt.compose  — appends a session-scope section that makes every main-loop answer end
//                        with a `Next:` line (the one recommended step) and up to two `Also:` lines.
//   2. turn.complete   — parses those lines from the answer, keeps them in $.state, and offers the
//                        top one as the dim Tab-to-take prompt suggestion.
//   3. ui.render       — draws the steps as buttons above the prompt (terminal and Desktop); a press
//                        submits that step as the operator's own prompt. `/next-steps` asks for a
//                        ranked list without typing it.
//
// Boundary: no tool.call, tool.check, prompt.submit or session.append hook. The mod never approves,
// blocks or rewrites a tool call or an operator prompt. Every prompt it submits is a button press or
// the slash command, never a timer or an answer (GH-967: no auto-submit).
import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Steps } from '../types'

const PLUGIN = 'next-steps-mod'
const COMMAND = 'next-steps'
const SECTION_ID = `${PLUGIN}:policy`

// Change the tag when Steps' fields change: a reload then reads an older value as absent.
const steps = atom({ plugin: 'next-steps-mod', key: 'steps' } as const, null, { shape: 'steps-1' })
const isHidden = atom({ plugin: 'next-steps-mod', key: 'isHidden' } as const, false)

const POLICY = `# Next steps (next-steps-mod)

The operator never wants to ask "what's next?". Keep thinking one step ahead while you work, and end
every answer on the main conversation with this block, after your normal closing:

Next: <the one step you recommend, as an imperative sentence the operator could send back as their
next prompt, under 120 characters>
Also: <an alternative or the second step> (zero to two Also: lines)

Rules:
- The Next: line names the most valuable concrete action now: finish the piece left open, verify
  what was not verified, commit, open or merge the PR, deploy, close the issue, or the follow-up you
  noticed. Never "let me know", never a question back to the operator.
- When the task is done and nothing is pending, still name the most valuable follow-up, or write
  "Next: nothing pending; <what to watch for>".
- A reversible step inside the request is done, not listed. List what needs the operator's decision,
  what lies outside the request, and what comes after this turn.
- The block is parsed by a mod: each line starts with exactly "Next:" or "Also:" (no bold, no bullet),
  one step per line, the Next: line first and last in the answer's final lines.`

const ASK = 'What are the next steps? Rank the three most valuable, the one you recommend first, with one line each on why. End with the Next:/Also: block.'

// `Next:` / `Also:` lines, tolerant of a leading bullet or bold marks the model adds anyway.
const LINE = /^\s*(?:[-*]\s*)?\**\s*(Next|Also)\s*\**\s*:\s*\**\s*(.+?)\s*\**\s*$/i

const parse = (answer: string, turnId: string): Steps => {
  const found: Steps = { next: null, also: [], turnId }
  for (const raw of answer.split('\n')) {
    const m = LINE.exec(raw)
    if (!m) continue
    const text = (m[2] ?? '').replace(/`/g, '').trim()
    if (!text) continue
    if (m[1]!.toLowerCase() === 'next') {
      if (found.next === null) found.next = text
      else if (found.also.length < 2 && !found.also.includes(text)) found.also.push(text)
    } else if (found.also.length < 2 && text !== found.next && !found.also.includes(text)) {
      found.also.push(text)
    }
  }
  return found
}

// A step fits the band on one row; a longer one is cut with an ellipsis for the label only.
const label = (text: string, width: number) =>
  text.length <= width ? text : `${text.slice(0, Math.max(8, width - 1)).trimEnd()}…`

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: COMMAND,
      description: 'Ask for ranked next steps without typing it (next-steps-mod)',
      immediate: true,
    })
    return next(e)
  })

  on('command.run', { command: COMMAND }, async $ => {
    void $.prompt.submit({ text: ASK, asUser: true })
    return { text: 'next-steps: asked for ranked next steps (runs once the session is idle).' }
  }).catch(() => ({ text: 'next-steps: could not submit the ask; type it instead.' }))

  on('prompt.compose', async ($, e, next) => {
    const { sections } = await next(e)
    if (sections.some(s => s.id === SECTION_ID)) return { sections }
    return { sections: [...sections, { id: SECTION_ID, text: POLICY, scope: 'session' }] }
  })

  on('turn.complete', async ($, e, next) => {
    // Main loop only: a subagent's report is not the operator's answer.
    if (e.agentId !== undefined || e.reason !== 'answer' || e.isAborted) return next(e)
    const found = parse(e.answer, e.turnId)
    await update($, steps, () => found)
    if (found.next) void $.prompt.suggest({ text: found.next })
    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const found = await read($, steps)
    const quiet = e.props.hasSurvey || e.props.isWorking || found === null || (await read($, isHidden))
    if (quiet) return next(e)

    const { Box, Button, Text } = $.ui.resolve(e)
    const width = Math.max(24, Math.floor((e.props.bodyColumns - 24) / 3))
    const submit = (text: string) => () => {
      void $.prompt.submit({ text, asUser: true })
    }
    const hide = () => {
      void update($, isHidden, () => true)
    }

    if (found.next === null) {
      return (
        <Box>
          <Text dimColor>No Next: line in the last answer. </Text>
          <Button key="ask" hotkey="1" variant="primary" onPress={submit(ASK)}>
            Ask what's next
          </Button>
          <Text> </Text>
          <Button key="hide" role="dismiss" dimColor onPress={hide}>
            Hide
          </Button>
        </Box>
      )
    }

    return (
      <Box>
        <Text dimColor>Next </Text>
        <Button key="next" hotkey="1" variant="primary" onPress={submit(found.next)}>
          {label(found.next, width)}
        </Button>
        {found.also.map((text, i) => (
          <Button key={`also-${i}`} hotkey={String(i + 2)} onPress={submit(text)}>
            {label(text, width)}
          </Button>
        ))}
        <Text> </Text>
        <Button key="hide" role="dismiss" dimColor onPress={hide}>
          Hide
        </Button>
      </Box>
    )
  })
}
