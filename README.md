Manga Fetcher fetches and downloads manga images to your machine!

### Requirements

- Node.js (developed and tested with v0.11.5)
- CoffeeScript

### Installation
`npm install -g mangafetcher`

### Currently supported manga

Note that Manga Fetcher stores manga in a folder name 'manga' in your current directory.
If the folder doesn't exist, it would be automatically created.

- Bleach (tested on episode 256-386)
  - `mangafetcher -m bleach -v 44 -e 386`

- Shaman King (tested on episode 293-300)
  - `mangafetcher -m sk -v 33 -e 292`
  - some episode has more than 30 pages,
    you can adjust page amount by passing amount param,
    e.g. `mangafetcher -m sk -v 33 -e 299 -n 80`

- Shaman King Flowers
  - `mangafetcher -m sk-f -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga

- Nisekoi (KOMI Naoshi)
  - `mangafetcher -m nisekoi -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga
