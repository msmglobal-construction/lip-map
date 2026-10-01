# GitHub Pages — privacy policy URL

Goal: a stable Privacy Policy URL for App Store Connect:

`https://msmglobal-construction.github.io/lip-map/privacy.html`

Source file in this repo: `docs/privacy.html` (served from the `/docs` folder on `master`).

## Preferred setup (API / CLI)

If you have `repo` + Pages admin on the GitHub account that owns the repo:

```bash
gh api -X POST repos/msmglobal-construction/lip-map/pages \
  --input - <<'EOF'
{
  "build_type": "legacy",
  "source": {
    "branch": "master",
    "path": "/docs"
  }
}
EOF
```

Check status:

```bash
gh api repos/msmglobal-construction/lip-map/pages
```

Wait until `status` is `built` or `building` completes, then open:

https://msmglobal-construction.github.io/lip-map/privacy.html

Update the site later (already enabled):

```bash
gh api -X PUT repos/msmglobal-construction/lip-map/pages \
  --input - <<'EOF'
{
  "build_type": "legacy",
  "source": {
    "branch": "master",
    "path": "/docs"
  }
}
EOF
```

## Manual clicks (if API fails)

1. Open https://github.com/msmglobal-construction/lip-map/settings/pages  
2. Under **Build and deployment** → **Source**, choose **Deploy from a branch**.  
3. Branch: **master**. Folder: **/docs**.  
4. Save.  
5. Wait 1–2 minutes, then verify https://msmglobal-construction.github.io/lip-map/privacy.html  

## Interim URL (works before Pages is live)

Paste into App Store Connect temporarily if needed:

`https://raw.githubusercontent.com/msmglobal-construction/lip-map/master/docs/privacy.html`

Prefer switching to the `github.io` URL once Pages builds successfully (raw URLs are harder to brand and may not render as a full HTML page in every browser context).

## App Store Connect field

**App Privacy Policy URL** → `https://msmglobal-construction.github.io/lip-map/privacy.html`
