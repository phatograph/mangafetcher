Manga Fetcher fetches and downloads manga images to your machine!

### Requirements

- Node.js (developed and tested with v0.10.21 and v0.11.5)
- CoffeeScript

### Installation

``` bash
npm install -g mangafetcher
```

### Currently supported manga

Note that Manga Fetcher stores manga in a folder name 'manga' in your current directory.
If the folder doesn't exist, it would be automatically created.

- One Piece (Experimental)
  - `mangafetcher -m one-piece -v 1 -e 1`
  - `mangefetcher -m one-piece -v TBD -e 713` for TBD volumes

- Naruto (Experimental)
  - `mangafetcjer -m naruto -v 1 -e 1`

- Bleach
  - `mangafetcher -m bleach -v 44 -e 386`

- Shaman
  - `mangafetcher -m sk -v 33 -e 292`

- Shaman King Flowers
  - `mangafetcher -m sk-f -e 1`

- Denpa Kyoushi
  - `mangafetcher -m denpa-kyoushi -e 1`

- Trinity Seven
  - `mangafetcher -m trinity-seven -e 1`

### List mode

If you already downloaded some manga and want to check for updates.
You could run `mangafetcher -l` to check them.

``` bash
$ mangafetcher -l
Shaman King Flowers 17 (local: 17/17)
Trinity Seven 32 (local: 4/32)
Nisekoi (KOMI Naoshi) 95 (local: 95/95)
Denpa Kyoushi 92 (local: 59/92)
Bleach 553 (local: 259/553)
```

All manga credits to [mangahere.com](http://mangahere.com) and [mangafox.me](http://mangafox.me)!
