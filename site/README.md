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

## Enable App Links (open links in the app, no chooser)

Android only hands `https://lunara.ankitak.com.np/...` links straight to Lunara when
`.well-known/assetlinks.json` lists your **release signing certificate's SHA-256 fingerprint**.

1. Get the fingerprint from your release keystore:

   ```bash
   keytool -list -v -keystore path/to/lunara-release.jks -alias lunara \
     | grep -A1 "SHA256:"
   ```

   (For a Play App Signing build, copy the **App Signing** SHA-256 from the Play Console instead.)

2. Replace `REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT` in `assetlinks.json` with it
   (keep the `package_name` as `com.lunara.app`; use `com.lunara.app` for the FOSS/GMS release build).

3. Verify it is reachable:

   ```bash
   curl https://lunara.ankitak.com.np/.well-known/assetlinks.json
   ```

Until this is set, links still work — the site's `Lunara://` fallback opens the app after a tap,
and Android may show an "Open with" chooser.

## Automatic deploys

`.github/workflows/site.yml` redeploys `site/` to Vercel on every published GitHub Release (and can
be run manually). It needs three repository secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

(Find the org/project ids with `npx vercel` locally, or in the Vercel project settings. If you prefer,
connect the repo in the Vercel dashboard for Git-based deploys and delete `site.yml`.)
