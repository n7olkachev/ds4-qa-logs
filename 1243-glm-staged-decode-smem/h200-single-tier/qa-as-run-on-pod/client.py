#!/usr/bin/env python3
"""Three-turn greedy chat against ds4-server; turn 2 carries a ~17k-token message so the
GLM MTP window [first draft .. pos] passes 12,033 positions. Writes the full exchange log and
the concatenated greedy texts (for before/after and MTP/no-MTP comparison)."""
import json, sys, time, urllib.request
port, logpath, textpath = sys.argv[1], sys.argv[2], sys.argv[3]
url = f"http://127.0.0.1:{port}/v1/chat/completions"
def chat(messages, max_tokens):
    body = {"model": "ds4", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
    t0 = time.time()
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=3600) as r:
        out = json.loads(r.read())
    dt = time.time() - t0
    msg = out["choices"][0]["message"]
    text = msg.get("content") or ""
    usage = out.get("usage", {})
    return text, usage, dt
# deterministic ~17k-token filler: numbered pseudo-log lines (ASCII, ~3.5 chars/token)
filler = "\n".join(f"record {i:05d}: sensor={i*7919%1000} status={'ok' if i%7 else 'retry'} note=alpha-{i%13}-beta-{i%17}" for i in range(1, 801))
msgs = [{"role": "system", "content": "You are a terse assistant. Answer directly, no thinking."}]
turns = [
    ("Say hello in exactly five words.", 64),
    ("Here is a sensor log. How many records have status=retry? Reply with the number only.\n\n" + filler, 96),
    ("Now state the sensor value of record 00800. Reply with the number only.", 64),
]
log = open(logpath, "w"); texts = open(textpath, "w")
for i, (prompt, mt) in enumerate(turns, 1):
    msgs.append({"role": "user", "content": prompt})
    text, usage, dt = chat(msgs, mt)
    msgs.append({"role": "assistant", "content": text})
    log.write(f"turn {i}: prompt_chars={len(prompt)} max_tokens={mt} usage={json.dumps(usage)} time={dt:.1f}s\n")
    log.write(f"turn {i} text: {json.dumps(text)}\n\n")
    texts.write(f"--- turn {i} ---\n{text}\n")
log.close(); texts.close()
print("client done")
