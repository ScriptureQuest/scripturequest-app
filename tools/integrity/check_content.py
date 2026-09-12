"""Read-only structural and game-text regressions; not full KJV certification."""
import json
import re
from pathlib import Path

books = json.loads(Path('assets/bible/kjv.json').read_text())['books']
assert len(books) == 66
assert len({b['name'] for b in books}) == 66
refs = {}
for book in books:
    assert [c['chapter'] for c in book['chapters']] == list(range(1, len(book['chapters']) + 1))
    for ch in book['chapters']:
        assert [v['verse'] for v in ch['verses']] == list(range(1, len(ch['verses']) + 1))
        for verse in ch['verses']:
            assert verse['text'].strip()
            refs[f"{book['name']} {ch['chapter']}:{verse['verse']}"] = verse['text'].strip()
assert sum(len(b['chapters']) for b in books) == 1189
assert len(refs) == 31102
for name, field in [('core_verses.json', 'snippet'), ('scramble_verses.json', 'text')]:
    rows = json.loads(Path('assets/verses', name).read_text())
    for row in rows:
        ref = row['reference'].replace('Psalm ', 'Psalms ')
        assert row[field] == refs[ref], ref
        if 'missing' in row:
            tokens = set(re.findall(r"[A-Za-z']+", row[field].lower()))
            assert all(word.lower() in tokens for word in row['missing']), ref
            assert not set(w.lower() for w in row['missing']) & set(w.lower() for w in row['distractors']), ref
    print(f'{name}: {len(rows)} exact KJV matches')
print('PASS: 66 books, 1189 sequential chapters, 31102 nonempty sequential verses; 14 game texts')
