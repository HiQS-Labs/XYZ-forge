# Example run: current non-deprecated Gemini API model IDs

Worked example of the `/browserbase` research flow. Retrieved 2026-09-04.

## Method

1. `browse cloud search "Gemini API models list model variants ai.google.dev"` located the docs.
2. `browse cloud fetch https://ai.google.dev/gemini-api/docs/models` returned HTTP 302 to a
   silent Google sign-in redirect, so per SKILL.md §3 step 3 the run escalated to a browser.
3. `browse open <url> --remote -s gemini --wait networkidle` then `browse get markdown` on the
   models page and the deprecations page. Session replay:
   https://www.browserbase.com/sessions/012e73b5-4071-4077-8ba5-48a810c2caec
4. IDs taken from the `Endpoint` column of the models page and cross-checked against the
   `Shutdown date` column of the deprecations page.

Rule used: **non-deprecated = listed on the models page and shown as "No shutdown date
announced" on the deprecations page.** Anything with a shutdown date, or labelled
"(Shut down)" / "(Deprecated)", is excluded even if it still answers requests today.

## Gemini text / multimodal (stable)

```
gemini-3.8-flash
gemini-3.7-flash
gemini-3.6-flash
gemini-3.5-flash
gemini-3.5-flash-lite
gemini-2.5-flash
gemini-2.5-flash-lite
gemini-2.5-pro
```

## Gemini text / multimodal (preview)

```
gemini-3.1-pro-preview
gemini-3-flash-preview
```

## Gemini image generation

```
gemini-3.1-flash-image          (Nano Banana 2)
gemini-3.1-flash-lite-image     (Nano Banana 2 Lite)
gemini-3-pro-image              (Nano Banana Pro)
```

## Gemini audio, live, transcription, TTS

```
gemini-3.1-flash-live-preview
gemini-3.5-live-translate-preview
gemini-3.5-transcribe
gemini-3.5-transcribe-live
gemini-3.1-flash-tts-preview
gemini-2.5-flash-native-audio-preview-12-2025
gemini-2.5-flash-preview-tts
gemini-2.5-pro-preview-tts
```

## Gemini video

```
gemini-omni-1.1-flash           (Gemini Omni Flash)
```

## Gemini agents, tools, embeddings, robotics

```
gemini-2.5-computer-use-preview-10-2025
deep-research-preview-04-2026
deep-research-max-preview-04-2026
antigravity-preview-05-2026
gemini-embedding-2-preview      (models page ID; deprecations page lists it as gemini-embedding-2)
gemini-robotics-er-2-preview
```

## Alias

```
gemini-flash-latest             (floating alias, documented under "Model version name patterns")
```

## Non-Gemini families on the same API, also current

```
veo-3.1-generate-preview
veo-3.1-lite-generate-preview
lyria-3.5
lyria-3-clip-preview
lyria-3-pro-preview
lyria-realtime-exp
```

## Excluded as deprecated or shut down (shutdown date on the deprecations page)

| ID | Shutdown | Replacement |
|---|---|---|
| gemini-3.1-flash-lite | May 7, 2027 | gemini-3.5-flash-lite |
| gemini-2.5-flash-image | October 2, 2026 | gemini-3.1-flash-image |
| gemini-embedding-001 | May 14, 2028 | gemini-embedding-2 |
| gemini-robotics-er-1.6-preview | August 31, 2026 | gemini-robotics-er-2-preview |
| gemini-omni-flash-preview | September 30, 2026 | gemini-omni-1.1-flash |
| imagen-4.0-* (all) | August 17, 2026 | gemini-3.1-flash-image |
| gemini-2.0-flash, gemini-2.0-flash-lite (+ -001) | June 1, 2026 | gemini-3.6-flash / gemini-3.1-flash-lite |
| gemini-3-pro-preview | March 9, 2026 | gemini-3.1-pro-preview |
| gemini-3.1-flash-lite-preview | May 25, 2026 | gemini-3.1-flash-lite |
| veo-3.0-*, veo-2.0-* | June 30, 2026 | veo-3.1-* |

## Caveats

- The models page renders the transcription row as one merged string
  (`gemini-3.5-transcribegemini-3.5-transcribe-live`); the deprecations page lists them as two IDs.
- Shutdown dates on Google's page are "earliest possible" dates, not guaranteed.
- Verify live with `GET https://generativelanguage.googleapis.com/v1beta/models` before hardcoding.

## Sources

- https://ai.google.dev/gemini-api/docs/models
- https://ai.google.dev/gemini-api/docs/deprecations
