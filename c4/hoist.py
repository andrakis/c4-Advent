#!/usr/bin/env python3
# hoist.py dungeon.c: c4lc has no compound literals at file scope, and
# make_dungeon.py writes hundreds, as (const char* []) {...} inside locations[]
# and objects[]. Give each a name of its own in front of the declaration that
# uses it. The dungeon is the same; only where its strings are spelled moves.
import re, sys
path = sys.argv[1]
t = open(path).read()
lit = re.compile(r'\(\s*(const\s+[\w ]+?\s*\*?)\s*\[\]\s*\)\s*\{')

def skip_string(i):
    q = t[i]
    i += 1
    while t[i] != q:
        if t[i] == chr(92):
            i += 1
        i += 1
    return i + 1

def skip_comment(i):
    if t.startswith('//', i):
        return t.index('\n', i) + 1
    if t.startswith('/*', i):
        return t.index('*/', i) + 2
    return i

def close_brace(i):
    depth = 0
    while True:
        j = skip_comment(i)
        if j != i:
            i = j
            continue
        c = t[i]
        if c == '"' or c == "'":
            i = skip_string(i)
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i
        i += 1

out, hoisted = [], []
decl = []          # this top-level declaration so far
i = last = depth = n = 0
while i < len(t):
    j = skip_comment(i)
    if j != i:
        i = j
        continue
    c = t[i]
    if c == '#' and (i == 0 or t[i - 1] == '\n'):
        i = t.index('\n', i) + 1
        continue
    if c == '"' or c == "'":
        i = skip_string(i)
        continue
    if c == '(' and depth > 0:
        m = lit.match(t, i)
        if m:
            b = m.end() - 1
            e = close_brace(b)
            n += 1
            hoisted.append('static %s adv_cl%d[] = %s;\n' % (m.group(1), n, t[b:e + 1]))
            decl.append(t[last:i])
            decl.append('adv_cl%d' % n)
            i = last = e + 1
            continue
    if c == '{':
        depth += 1
    elif c == '}':
        depth -= 1
    elif c == ';' and depth == 0:
        decl.append(t[last:i + 1])
        last = i + 1
        out.extend(hoisted)
        out.extend(decl)
        hoisted, decl = [], []
    i += 1
decl.append(t[last:])
out.extend(hoisted)
out.extend(decl)
t = ''.join(out)
if lit.search(t):
    sys.exit('hoist.py: a literal inside a literal is left in ' + path)
open(path, 'w').write(t)
print('hoist.py: %d literals' % n)
