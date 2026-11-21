// State contract of next-steps-mod (GH-1240). `claude plugin validate` holds every
// `$.state` key the hooks module names to this file.

/** The next steps parsed from the last main-loop answer. */
export type Steps = {
  /** The one recommended step (the answer's `Next:` line), or null when it had none. */
  next: string | null
  /** Up to two alternatives (the answer's `Also:` lines). */
  also: string[]
  /** The turn the steps came from. */
  turnId: string
}

declare module 'claude-code' {
  interface PluginState {
    'next-steps-mod': { steps: Shaped<Steps | null>; isHidden: boolean }
  }
}
