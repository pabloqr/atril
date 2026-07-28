# Changelog

## [0.2.2](https://github.com/pabloqr/atril/compare/v0.2.1...v0.2.2) (2026-07-28)


### Features

* **editor:** add selection-aware source synchronization ([2cad707](https://github.com/pabloqr/atril/commit/2cad707cd80653a3032780d10858eed9743b7634))
* **editor:** add song editor functionality ([367c127](https://github.com/pabloqr/atril/commit/367c127c7440118f2debe8a3ef5b3d704c128306))
* **editor:** expose source edit rejection reasons ([4a8e52e](https://github.com/pabloqr/atril/commit/4a8e52eaee82ffa3f7058a439749528c1e797887))
* **editor:** navigate through song issues from toolbar ([ffa3faf](https://github.com/pabloqr/atril/commit/ffa3fafc68fb195d06f3352171f5db751022fcc5))
* **editor:** show active issue feedback in status bar ([db6771f](https://github.com/pabloqr/atril/commit/db6771fde486a1841e093ade4d540f9d502401a9))
* **repository:** add logger service in song repository ([151da00](https://github.com/pabloqr/atril/commit/151da00910abcbabf74d8a8fbda9032f6e642647))
* **routing:** add application route observer ([2b45fc9](https://github.com/pabloqr/atril/commit/2b45fc9bae41d5bfdae35282ae10c097e129f22b))
* **routing:** add typed app routes and song workspace navigation ([1de1b7a](https://github.com/pabloqr/atril/commit/1de1b7af5965aad796971da362cf53cc290cdd59))
* **workspace:** adapt toolbar layout to screen width ([80f3568](https://github.com/pabloqr/atril/commit/80f35684b69739418bcc9275f7e36408b7dbbaec))
* **workspace:** add animated transpose controls ([bd7acd5](https://github.com/pabloqr/atril/commit/bd7acd52f3a263c5e8686c2ecb709348fb90a996))
* **workspace:** add directive picker to action menus ([8c28ddd](https://github.com/pabloqr/atril/commit/8c28ddda34941df54fe9768d3b2cbda4e632ba52))
* **workspace:** add editor and preview workspace shell ([3da1192](https://github.com/pabloqr/atril/commit/3da11929ad57316bf13c0170281183e93c3cefcb))
* **workspace:** add editor interface and expandable FAB menu ([6a91ca3](https://github.com/pabloqr/atril/commit/6a91ca35dfad68a6773cacc8bdc5b5c335783177))
* **workspace:** add shared editor and preview state ([15183ac](https://github.com/pabloqr/atril/commit/15183acbbec59c42a7a8ede3b6c1dae45d445dae))
* **workspace:** add toolbar menu anchor for medium, expanded and extra-large screens ([7a9ba4c](https://github.com/pabloqr/atril/commit/7a9ba4c9dc5757c70a54455b21c621716f12584b))
* **workspace:** enable chord insertion from action menus ([7185fa2](https://github.com/pabloqr/atril/commit/7185fa23c2543bf836af0a1f748d6fc07e73613e))
* **workspace:** implement undo and redo actions in toolbar ([b7e354a](https://github.com/pabloqr/atril/commit/b7e354ab30f2211ad85e8e7a6e0d1e04238273df))
* **workspace:** show live issue count in toolbar ([fd052e5](https://github.com/pabloqr/atril/commit/fd052e5f3f89a2f2063df1c8199e89cdf348b9ef))


### Bug Fixes

* **editor:** update input text color to be visible with light/dark theme ([fa5e542](https://github.com/pabloqr/atril/commit/fa5e5423448505b3e5198ca03d1ef08b92b79783))
* **ui:** animate bottom toolbar FAB visibility ([02ca082](https://github.com/pabloqr/atril/commit/02ca082dfa420758b197b3873fdceaef39f03370))
* **ui:** animate toolbar size changes ([c365723](https://github.com/pabloqr/atril/commit/c365723c323af4198c95302de47dc3eab06bc363))
* **ui:** restore toolbar padded tap targets ([2c2dc06](https://github.com/pabloqr/atril/commit/2c2dc06cd13abbaeaf36faf858037cb2a1eeeb8d))
* **view-model:** dispose command resources ([412af87](https://github.com/pabloqr/atril/commit/412af8703e65c00023f79122beb31728b47bde8d))
* **workspace:** align app bar actions across visual densities ([d108377](https://github.com/pabloqr/atril/commit/d10837784685c3e9436916d5929cf79e57cf23a8))
* **workspace:** lock orientation while editing songs ([c6b64fa](https://github.com/pabloqr/atril/commit/c6b64faf99f801e6d853aa756f69e01ed6f0a72c))
* **workspace:** modify router tree and loading screen to remove parameters from branch paths ([1f6a697](https://github.com/pabloqr/atril/commit/1f6a6976076bbbfadd71e49cc10211bbde60b526))
* **workspace:** preserve undo history across view changes ([6059795](https://github.com/pabloqr/atril/commit/6059795d587190d49df8211208551ac71b9805f1))
* **workspace:** restore editor focus after chord actions ([c7675a5](https://github.com/pabloqr/atril/commit/c7675a59a1d63a15703d129e714dcd5842c70689))


### Refactors

* **editor:** improve bottom banner readability ([7dda835](https://github.com/pabloqr/atril/commit/7dda8354d066c55d473a181680231ff1e77aa1d4))
* **editor:** validate source selection offsets and improve performance ([5e94516](https://github.com/pabloqr/atril/commit/5e94516b47cac93d64389b270e401197ef343077))
* **exceptions:** make exception classes final ([c497ffb](https://github.com/pabloqr/atril/commit/c497ffb3d75e0d0f0fd824f00fe51325292a06e2))
* **persistence:** remove unnecesary awaits ([5cef580](https://github.com/pabloqr/atril/commit/5cef58067eff3f92d66f8d0026ef319d0ba2931e))
* **ui:** extract method to show custom dialog ([5cf299f](https://github.com/pabloqr/atril/commit/5cf299f7b5f18d064e06dc3a6c8db2a03868c9eb))
* **ui:** major overhaul of responsive reusable toolbar ([28c3a9b](https://github.com/pabloqr/atril/commit/28c3a9b50b7a334fd48c06ddef607c97231c2489))
* **ui:** move SongListTile to widgets folder ([5f141c5](https://github.com/pabloqr/atril/commit/5f141c59dfec97e24f30a0698f9d735b723a48a5))
* **ui:** polish library icons and action menus ([ab626e0](https://github.com/pabloqr/atril/commit/ab626e09969a3932cd494aea60fe0b2d0abd7352))
* **ui:** refine directive picker item layout ([9ed021a](https://github.com/pabloqr/atril/commit/9ed021aaa2b127d6349aaf15ef1118d932c342e8))
* **ui:** update tap behaviour for MenuAnchors ([3cbf2e8](https://github.com/pabloqr/atril/commit/3cbf2e8fe6761289a44cc85be4654f95f23b7aea))
* **view-model:** make command fields final ([23b8336](https://github.com/pabloqr/atril/commit/23b83365e0ecf165b071364aecbf7ab23385fd06))
* **view-model:** remove unnecessary fields in LoadingViewModel ([aad7b95](https://github.com/pabloqr/atril/commit/aad7b95c305473fcceda42b48dca0556a8f6c6c9))
* **view-model:** rename song file name fields to filename ([ac92119](https://github.com/pabloqr/atril/commit/ac92119498c0b9a7d1085046869e8db930bf3d57))
* **workspace:** provide view model to workspace scaffold ([34998ae](https://github.com/pabloqr/atril/commit/34998aefcfdce7e925e5b11741c3da312c49e80f))


### CI/CD

* add to Release Please configuration missing changelog sections ([e18b4a0](https://github.com/pabloqr/atril/commit/e18b4a045d2f85c2c648f2e6cc61ec45f731b3a9))

## [0.2.1](https://github.com/pabloqr/atril/compare/v0.2.0...v0.2.1) (2026-06-30)


### Refactors

* rename song file name field to filename ([7a48fb7](https://github.com/pabloqr/atril/commit/7a48fb7e2fe3ad6ea5777dc55145d8f82e4fb829))


### Tests

* add coverage for song library behavior ([be0c714](https://github.com/pabloqr/atril/commit/be0c71423bd682021f7e3f47d75a402f392c9b22))

## [0.2.0](https://github.com/pabloqr/atril/compare/v0.1.0...v0.2.0) (2026-06-18)


### ⚠ BREAKING CHANGES

* **transposer:** Add interval-based transposition
* **editor:** Add song parsing and source editing

### feat

* **editor:** Add song parsing and source editing ([7cd520f](https://github.com/pabloqr/atril/commit/7cd520f5dd62323a8025b57dd4021d62f7fe6952))
* **transposer:** Add interval-based transposition ([227400c](https://github.com/pabloqr/atril/commit/227400ce5a52c94b20768f113ff96917d7e063bc))


### Refactors

* **domain:** Add barrel exports for chord and song models ([93c1c76](https://github.com/pabloqr/atril/commit/93c1c76755ff296e66ed670dbcf1b89f983fb79b))


### Documentation

* **chordpro:** Document architecture and supported syntax ([290fc39](https://github.com/pabloqr/atril/commit/290fc39179ffb70a6fcdbe09fbc98b0d356111e3))
* **persistence:** document file storage boundaries ([2212855](https://github.com/pabloqr/atril/commit/22128551be6ebefb720012438f74a5b33ce7f572))
* **song:** complete and improve models documentation ([14b9a4f](https://github.com/pabloqr/atril/commit/14b9a4ffc66fc21a20066ea116e2e0709d08647a))


### CI/CD

* add release automation ([f4b40a8](https://github.com/pabloqr/atril/commit/f4b40a8d7c7e9f18d41194925a4e4f33b87155f5))
