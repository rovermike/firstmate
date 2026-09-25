#!/usr/bin/env python3
"""Resolve the quiet skill's cross-references into the afk skill.

The skills are the delivered agent-facing artifact; a cited section name that
resolves to no heading is a dangling reference an agent cannot follow, which is
the defect the prompt audit reported. Both documents are parsed into their
heading model, then every `afk` skill section the quiet skill cites, and every
numbered step it cites inside that section, is resolved against that model.
"""
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
quiet = (root / ".agents/skills/quiet/SKILL.md").read_text()
afk = (root / ".agents/skills/afk/SKILL.md").read_text()

def headings(text):
    out = []
    for line in text.splitlines():
        m = re.match(r"^(#{1,6})\s+(.*?)\s*$", line)
        if m:
            out.append((len(m.group(1)), m.group(2)))
    return out

afk_headings = headings(afk)
afk_titles = [t for _, t in afk_headings]

def section_body(title):
    lines = afk.splitlines()
    idx = [i for i, l in enumerate(lines) if re.match(r"^#{1,6}\s+" + re.escape(title) + r"\s*$", l)]
    if not idx:
        return None
    start = idx[0]
    level = len(re.match(r"^(#+)", lines[start]).group(1))
    body = []
    for l in lines[start + 1:]:
        m = re.match(r"^(#{1,6})\s", l)
        if m and len(m.group(1)) <= level:
            break
        body.append(l)
    return "\n".join(body)

# References of the form: the `afk` skill's "<Section>"  (optionally "... step N")
refs = re.findall(r"`afk` skill'?s \"([^\"]+)\"(\s+step (\d+))?", quiet)
# References of the form: "<Section>" section  (audit's other cited form)
refs += [(t, "", "") for t in re.findall(r"\"([^\"]+)\" section", quiet)]

print(f"afk skill headings: {afk_titles}")
print(f"quiet skill cites {len(refs)} afk section reference(s)")
bad = 0
for title, _, step in refs:
    if title in afk_titles:
        status = "RESOLVES"
    else:
        status = "DANGLING (no such section in the afk skill)"
        bad += 1
    line = f'  - "{title}"'
    if step:
        body = section_body(title)
        steps = re.findall(r"^(\d+)\.\s", body or "", re.M)
        if step in steps:
            line += f" step {step} -> step exists (steps present: {steps})"
        else:
            line += f" step {step} -> MISSING STEP (steps present: {steps})"
            bad += 1
    print(f"{line}: {status}")
print("RESULT:", "all cited sections and steps resolve" if bad == 0 else f"{bad} dangling reference(s)")
sys.exit(1 if bad else 0)
