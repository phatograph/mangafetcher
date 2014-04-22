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

- Eyeshield 21
  - `mangafetcher -m eyeshield21 -e 1`

- Shaman King
  - `mangafetcher -m sk -v 33 -e 292`

- Shaman King Flowers
  - `mangafetcher -m sk-f -e 1`

- Denpa Kyoushi
  - `mangafetcher -m denpa-kyoushi -e 1`

- Trinity Seven
  - `mangafetcher -m trinity-seven -e 1`

- And [many more](https://github.com/phatograph/mangafetcher/blob/master/database.coffee)!

### Modes

##### List mode

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

##### Episode List mode

Some mangas must have both volume and episode specified. And some of their
volume/episode combination is quite hard to remember. Using this mode
would quickly display this information. For example this displays a
list of Tsubasa episodes.

```
$ mangafetcher -x -m tsubasa
Captain Tsubasa 114 | Vol 37 | Nov 19, 2007
Captain Tsubasa 113 | Vol 37 | Nov 19, 2007
Captain Tsubasa 112 | Vol 37 | Nov 19, 2007
Captain Tsubasa 111 | Vol 37 | Nov 19, 2007
Captain Tsubasa 110 | Vol 37 | Nov 19, 2007
Captain Tsubasa 109 | Vol 36 | Nov 19, 2007
Captain Tsubasa 108 | Vol 36 | Nov 19, 2007
...

$ mf -m tsubasa -v 37 -e 114
```

##### Multiple episodes mode

For convenient, since v.1.4 Manga Fetcher is able to queue and download
multiple episodes at once. Using `-e` option with `x..y` range
would download from episode x to y.

``` bash
$ mangefetcher -m eyeshield21 -e 201..210
```


All manga credits to [mangahere.com](http://mangahere.com) and [mangafox.me](http://mangafox.me)!
