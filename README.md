# madi-madi.github.io

Personal site for Ibrahim Salama Madi — full-stack developer (Laravel · Vue · Elasticsearch).

Two static pages, no build step, no dependencies, no framework.

- `index.html` — an interactive Ubuntu terminal. Type `help`, `skills`,
  `search <arabic>`, `projects`. Clickable command buttons sit underneath so a
  non-technical reader never faces a blank prompt.
- `about.html` — the same story as a readable page. Bilingual English / Arabic
  with a real RTL layout, light + dark themes, a live Arabic search demo and an
  SVG of the ingest pipeline.

Brand logos in `skills` are official Simple Icons paths (CC0), inlined — the
page makes no external request except the Google Fonts stylesheet.

## Publishing

This repo must be named exactly `madi-madi.github.io` for GitHub Pages user sites.

```bash
git remote add origin git@github.com:madi-madi/madi-madi.github.io.git
git add -A && git commit -m "Personal site"
git push -u origin main
```

Then in the repo: **Settings → Pages → Source: Deploy from a branch → `main` / `(root)`**.
Live at https://madi-madi.github.io within a minute or two.

## Before pushing

- Drop the CV PDF in the repo root as `Ibrahim-Madi-CV.pdf` (the rail links to it).
- Replace the placeholder figures in `#intro` with real numbers once you can quote them
  (search latency, assets processed per day, concurrent users).

## Editing

Everything lives in `index.html`. Arabic strings are in the `AR` object at the bottom;
English is the markup itself, keyed by `data-i18n`. Add a key to both to add a line.

## Profile cleanup

`tools/github-cleanup.sh` hides the old learning repositories, fixes the
language GitHub detects on the Laravel projects, writes real descriptions and
pins what's left.

```bash
gh auth login -s repo,delete_repo,read:user
./tools/github-cleanup.sh          # dry run, changes nothing
./tools/github-cleanup.sh --apply  # do it
```

Making a repo private is reversible from its settings page at any time.
Fork deletion is not, so the script asks first.

## Contact and visits

The `contact` command in the terminal and the form on `about.html` both POST to
FormSubmit, which forwards to my inbox and needs no account. **The first message
you send arrives as a confirmation email — click the link in it once and the
endpoint goes live.** Until then submissions are held, not delivered.

Visit counting is GoatCounter: no cookies, no personal data, about 3 KB. Sign up
free at goatcounter.com, then replace `MADI` in the snippet at the bottom of
`index.html` and `about.html` with your own site code. Terminal commands are
counted as events, so the dashboard shows which ones people actually run.
