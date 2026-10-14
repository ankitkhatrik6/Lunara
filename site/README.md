# Lunara landing site

The static site served at **lunara.ankitak.com.np**. It is the page a shared link lands on when
Lunara is not installed, and the marketing home for the app otherwise.

- `index.html` — the landing page (premium theme matching the app). Also handles
  `/song/<id>`, `/album/<id>`, `/playlist/<id>`, `/artist/<id>` by attempting to open the app.
- `.well-known/assetlinks.json` — Android App Links verification (opens links straight in the app).
- `vercel.json` — Vercel routing/headers.
- `assets/` — the app icon and favicon.

## Deploy to Vercel

1. Push this repo to GitHub (the `site/` folder is part of it).
2. In [vercel.com](https://vercel.com): **Add New → Project → Import** this repository.
3. Set **Root Directory** to `site`.
4. Framework preset: **Other**. Build command: *(none)*. Output directory: *(none / root)*.
5. Deploy. You get a `*.vercel.app` URL first.

## Point the domain (DNS)

In **Vercel → Project → Settings → Domains**, add `lunara.ankitak.com.np`, then at your DNS provider
for `ankitak.com.np` add the record Vercel shows:

| Type  | Name  | Value                          |
|-------|-------|--------------------------------|
| CNAME | lunara| `cname.vercel-dns.com`         |

(If your registrar only supports apex/ALIAS and you want the bare domain, use an `A` record to
`76.76.21.21` instead — but for a subdomain like `lunara`, a CNAME is correct.)

Wait for DNS to propagate (minutes to an hour). Vercel issues the TLS certificate automatically.

## Enable App Links (open links in the app, no chooser) — done

Android only hands `https://lunara.ankitak.com.np/...` links straight to Lunara when
`.well-known/assetlinks.json` lists the release signing certificate's SHA-256 fingerprint. This
is already filled in: the permanent release key `keystore/lunara-release.jks` (created 2026-10-14,
30-year RSA-4096, kept out of git) has fingerprint

```
27:AD:CB:35:11:34:AC:33:58:4C:4A:AD:6F:F5:48:9B:ED:42:3E:F0:D5:F5:D5:17:D9:E3:38:A7:F5:25:C5:75
```

which is what `assetlinks.json` serves. Nothing left to fill in here — just verify after the
domain points at Vercel:

```bash
curl https://lunara.ankitak.com.np/.well-known/assetlinks.json
```

## Signing the release (permanent key)

- The key is `keystore/lunara-release.jks` (alias `lunara`), generated once and never committed —
  `.gitignore` excludes it. **Back it up somewhere safe (USB drive, password manager): losing it
  means updates can never install over the existing app.**
- CI signs with it via the `RELEASE_KEYSTORE_BASE64` repository secret (base64 of the `.jks`
  file), plus `RELEASE_KEYSTORE_PASSWORD` and `RELEASE_KEY_PASSWORD` (same value). If that secret
  is missing the release workflow **fails loudly** instead of shipping a debug-signed build.
- Local builds read the same passwords from `keystore/keystore.properties`, which is committed.

## Automatic deploys

`.github/workflows/site.yml` redeploys `site/` to Vercel on every published GitHub Release (and can
be run manually). It needs three repository secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

(Find the org/project ids with `npx vercel` locally, or in the Vercel project settings. If you prefer,
connect the repo in the Vercel dashboard for Git-based deploys and delete `site.yml`.)
