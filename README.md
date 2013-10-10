Manga Fetcher fetches and downloads manga images to your machine!

### Requirements

- Node.js (developed and tested with v0.11.5)
- CoffeeScript

### Installation
`npm install -g mangafetcher`.

Manga Fetcher would store manga in a folder name 'manga' in your current directory.

### Currently supported manga
- [Bleach](http://mangafox.me/manga/bleach/) (episode 256-386)
  - `mangafetcher -m bleach -v 44 -e 386`
- [Shaman King Flowers](http://www.mangahere.com/manga/shaman_king_flowers/) (up to episode 17)
  - `mangafetcher -m sk-f -v 0 -e 1`
  - please keep `-v 0` as no volume is specified in this manga
