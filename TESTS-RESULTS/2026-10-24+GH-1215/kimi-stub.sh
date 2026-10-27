#!/usr/bin/env bash
echo "$@" > "${TMPDIR:-/tmp}/kimi-stub-args.txt"
echo '{"role":"meta","type":"system.version","version":"2.3.1"}'
echo 'kimi: some non-json chatter'
echo '{"role":"assistant","content":"   "}'
echo '{"role":"meta","type":"session.resume_hint","session_id":"s","content":"To resume this session: kimi -r s"}'
exit 0
