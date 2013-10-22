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

- Shaman King Flowers
  - `mangafetcher -m sk-f -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga

- Denpa Kyoushi
  - `mangafetcher -m denpa-kyoushi -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga

- Trinity Seven
  - `mangafetcher -m trinity-seven -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga

All manga credits to [mangahere.com](http://mangahere.com) and [mangafox.me](http://mangafox.me)!
