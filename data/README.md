# How to update the CV

Everything on the CV page (and in the PDF) comes from the four files in this
folder. **You never need to edit `cv.qmd`** — just change a spreadsheet and
render the site again:

```bash
quarto render cv.qmd
```

You can open these files in Excel, Numbers, Google Sheets or RStudio. Save them
again as **CSV (comma separated), UTF-8**.

Two rules that apply everywhere:

* Inside any cell you can use markdown: `**bold**`, `*italic*`,
  `[text](https://link)`. A plain `https://...` address is turned into a link
  automatically.
* In the **details** column, separate several bullet points with a vertical
  bar `|`.
* **The order of the rows is the order on the page.** To put a new publication
  at the top of the list, insert its row at the top of its group.

---

## events.csv — entries with a date on the right

Used for jobs, education, stays abroad, training, skills…

| column | what it is |
|---|---|
| `section` | which part of the CV the row belongs to (see the list below) |
| `what` | the bold first line (job title, degree, tool name…) |
| `where` | the italic second line (institution, level…) |
| `when` | the date, shown on the right |
| `details` | bullet points under the entry, separated by `|` |
| `icon` | optional emoji shown before `what` (used for the language flags); it is left out of the PDF |

`section` must be one of:
`current-position`, `research`, `education`, `abroad`, `third-mission`,
`research-groups`, `collaborations`, `training`, `societies`, `languages`,
`programming`, `skills`, `systems`.

---

## publications.csv — papers, preprints, preregistrations, abstracts

One row per publication. They are printed as:

> **authors** (year). *title*. *journal*, volume. **label:** link. note

| column | what it is |
|---|---|
| `status` | `Published`, `Under Review`, `Preregistration`, `In Preparation` or `Published Abstract` |
| `authors` | the author list — write your own name as `**Calderan, M.**` so it comes out in bold |
| `year` | leave empty for work that is not published yet |
| `title` | the title, without the final full stop |
| `journal` | the journal name (printed in italics); leave empty if there is none |
| `volume` | volume / issue / pages, e.g. `47, e148` |
| `url` | the DOI or link |
| `url_label` | optional word before the link, e.g. `Preprint` |
| `note` | anything extra at the end |

**To add a publication:** add one row, choose the `status`, done. The numbered
list renumbers itself.

---

## conferences.csv — talks and posters

They are printed as:

> **authors** *title*. **type** verb event, location, date.

| column | what it is |
|---|---|
| `authors` | the author list (`**Calderan, M.**` for your name) |
| `title` | the title of the talk or poster |
| `type` | `Poster`, `Talk`, `Mini-Talk`, `Video-Poster`, `Symposium`… (printed in bold) |
| `verb` | `presented at the`, `accepted at the`, `at the`, `at`… |
| `event` | the name of the conference |
| `location` | e.g. `Brixen (Italy)` |
| `date` | e.g. `Feb. 2025` |
| `url` | optional link |

---

## bullets.csv — plain lists

Used for teaching, awards, invited talks, academic roles, organizational
activities and the R packages.

| column | what it is |
|---|---|
| `section` | which part of the CV (see below) |
| `subsection` | optional sub-heading; a new sub-heading starts wherever this text changes |
| `kind` | leave empty for a bullet point, or write `text` for a normal paragraph |
| `text` | the content of the bullet point or paragraph |
| `details` | sub-bullets, separated by `|` |

`section` must be one of:
`preconf-workshops`, `invited-talks`, `awards`, `peer-reviews`, `teaching`,
`academic-roles`, `organizational`, `involvement`, `r-packages`.

---

## Adding a whole new section

1. Add the rows to the right file, with a new `section` name.
2. Open `cv.qmd` and add, where you want it to appear:

````markdown
## Title of the new section

```{r}
#| output: asis
#| echo: false
cv_events("my-new-section")     # or cv_bullets("my-new-section")
```
````

If you mistype a section name, rendering stops with a message listing the
names that do exist.
