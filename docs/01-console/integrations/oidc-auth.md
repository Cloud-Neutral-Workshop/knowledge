# OIDC Authentication Configuration Guide

This guide describes how to configure GitHub and Google OAuth login for the Cloud Neutral Toolkit, enabling any user to sign in with their own GitHub or Google account.

## Architecture Overview

```
┌──────────────┐      ┌──────────────────┐      ┌──────────────────┐
│  Browser     │      │   www.svc.plus   │      │accounts.svc.plus │
│  (User)      │      │   (Frontend)     │      │   (Backend)      │
└──────┬───────┘      └────────┬─────────┘      └────────┬─────────┘
       │  1. Click "Login      │                         │
       │     with GitHub"      │                         │
       │──────────────────────>│                         │
       │                       │                         │
       │  2. Redirect to       │                         │
       │     accounts /api/    │                         │
       │     auth/oauth/login/ │                         │
       │     github            │                         │
       │<──────────────────────│                         │
       │                       │                         │
       │  3. accounts redirects to GitHub/Google         │
       │     with client_id & callback URL               │
       │<────────────────────────────────────────────────│
       │                       │                         │
       │  4. User authorizes   │                         │
       │     on GitHub/Google  │                         │
       │                       │                         │
       │  5. GitHub/Google redirects back to             │
       │     accounts /api/auth/oauth/callback/github    │
       │─────────────────────────────────────────────────>
       │                       │                         │
       │  6. accounts exchanges code for token,          │
       │     creates/links user, redirects to console    │
       │<────────────────────────────────────────────────│
       │                       │                         │
```

## Prerequisites

- A GitHub account with access to **Settings > Developer Settings**
- A Google account with access to [Google Cloud Console](https://console.cloud.google.com/)
- Running `accounts.svc.plus` and the frontend served under `www.svc.plus` / `console.svc.plus`

---

## 1. GitHub OAuth App

### 1.1 Create OAuth App

1. Go to [GitHub Developer Settings > OAuth Apps](https://github.com/settings/developers)
2. Click **"OAuth Apps"** tab, then **"New OAuth App"**
3. Fill in the form:

| Field | Value |
|---|---|
| **Application name** | `Cloud Neutral Console` |
| **Homepage URL** | `https://www.svc.plus` |
| **Authorization callback URL** | `https://accounts.svc.plus/api/auth/oauth/callback/github` |
| **Enable Device Flow** | ☐ (unchecked) |

4. Click **"Register application"**

### 1.2 Generate Client Secret

1. On the app detail page, copy the **Client ID** (displayed at the top)
2. Click **"Generate a new client secret"**
3. **Immediately copy the Client Secret** — it will only be shown once

### 1.3 Record Credentials

```
GitHub Client ID:     Ov23li...
GitHub Client Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Callback URL:         https://accounts.svc.plus/api/auth/oauth/callback/github
```

> ⚠️ **Security**: Never commit Client Secret to version control. Store it as an environment variable or in a secret manager.

### 1.4 GitHub OAuth Scopes

The OAuth App requests these scopes by default:
- `user:email` — Read the user's email addresses (used for account binding)

No additional GitHub permissions are required.

---

## 2. Google OAuth Client ID

### 2.1 Configure OAuth Consent Screen

> This step is required before creating credentials. If already configured, skip to 2.2.

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **APIs & Services > OAuth consent screen**
4. Choose **External** user type (allows any Google user to sign in)
5. Fill in the required fields:

| Field | Value |
|---|---|
| **App name** | `Cloud Neutral Console` |
| **User support email** | your email address |
| **Developer contact email** | your email address |

6. Add scopes: `email`, `profile`, `openid`
7. Click **Save and Continue** through the remaining steps
8. Under **Publishing status**, click **"Publish App"** to move out of testing mode
   - In testing mode, only manually added test users can sign in

### 2.2 Create OAuth Client ID

1. Go to **APIs & Services > Credentials**
2. Click **"Create Credentials" > "OAuth client ID"**
3. Fill in the form:

| Field | Value |
|---|---|
| **Application type** | `Web application` |
| **Name** | `Cloud Neutral Console` |
| **Authorized JavaScript origins** | `https://www.svc.plus` |
| **Authorized redirect URIs** | `https://accounts.svc.plus/api/auth/oauth/callback/google` |

4. Click **"Create"**
5. Copy the **Client ID** and **Client Secret** from the popup

### 2.3 Record Credentials

```
Google Client ID:     xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
Google Client Secret: GOCSPX-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Callback URL:         https://accounts.svc.plus/api/auth/oauth/callback/google
```

---

## 3. Backend Configuration (accounts.svc.plus)

Set the following environment variables for **accounts.svc.plus**:

```bash
# ── GitHub OAuth ──
GITHUB_CLIENT_ID=<your_github_client_id>
GITHUB_CLIENT_SECRET=<your_github_client_secret>

# ── Google OAuth ──
GOOGLE_CLIENT_ID=<your_google_client_id>
GOOGLE_CLIENT_SECRET=<your_google_client_secret>

# ── General OAuth ──
OAUTH_REDIRECT_URL=https://accounts.svc.plus/api/auth/oauth/callback
OAUTH_FRONTEND_URL=https://www.svc.plus
```

These variables are referenced in `config/account.yaml`:

```yaml
auth:
  oauth:
    redirectUrl: "${OAUTH_REDIRECT_URL}"
    frontendUrl: "${OAUTH_FRONTEND_URL:-https://www.svc.plus}"
    github:
      clientId: "${GITHUB_CLIENT_ID}"
      clientSecret: "${GITHUB_CLIENT_SECRET}"
    google:
      clientId: "${GOOGLE_CLIENT_ID}"
      clientSecret: "${GOOGLE_CLIENT_SECRET}"
```

> **Note**: The backend automatically appends `/{provider}` to `OAUTH_REDIRECT_URL` (e.g. `.../callback/github`) if a provider-specific redirect URL is not set.

---

## 4. Frontend Configuration (`www.svc.plus` canonical, `console.svc.plus` secondary)

The frontend resolves the accounts service URL **server-side** via `getAccountServiceBaseUrl()`, which reads:

```bash
# Set in accounts.svc.plus deployment environment
ACCOUNT_SERVICE_URL=https://accounts.svc.plus
```

If not set, the function falls back to a runtime default. **No `NEXT_PUBLIC_*` env var is needed** — the OAuth login URLs are constructed server-side and passed to the client components as props.

### OAuth Login URLs (auto-generated)

| Provider | Login URL |
|---|---|
| GitHub | `{accountServiceBaseUrl}/api/auth/oauth/login/github` |
| Google | `{accountServiceBaseUrl}/api/auth/oauth/login/google` |

### OAuth Callback URLs (handled by accounts.svc.plus)

| Provider | Callback URL |
|---|---|
| GitHub | `https://accounts.svc.plus/api/auth/oauth/callback/github` |
| Google | `https://accounts.svc.plus/api/auth/oauth/callback/google` |

---

## 5. Troubleshooting

### `undefined/api/auth/oauth/login/github`

**Cause**: OAuth URLs were using a client-side env var (`NEXT_PUBLIC_ACCOUNTS_SVC_URL`) that was not set.

**Fix** (applied in commit `4ce4147`): OAuth URLs now use the server-resolved `accountServiceBaseUrl` prop.

### OAuth login redirects to wrong domain

Check that `OAUTH_FRONTEND_URL` in accounts.svc.plus matches the canonical public domain where users should be redirected after authentication. The current default is `https://www.svc.plus`.

### Google "Access blocked: This app's request is invalid"

Ensure the **Authorized redirect URI** in Google Cloud Console **exactly** matches:
```
https://accounts.svc.plus/api/auth/oauth/callback/google
```
Trailing slashes or mismatched protocols will cause this error.

### GitHub "The redirect_uri MUST match the registered callback URL"

Ensure the **Authorization callback URL** in GitHub Developer Settings **exactly** matches:
```
https://accounts.svc.plus/api/auth/oauth/callback/github
```

### Google OAuth in "Testing" mode — only test users can sign in

Go to **OAuth consent screen > Publishing status** and click **"Publish App"** to allow any Google user to sign in.

---

## 6. Quick Reference

| Item | Value |
|---|---|
| GitHub OAuth App Settings | https://github.com/settings/developers |
| Google Cloud Credentials | https://console.cloud.google.com/apis/credentials |
| GitHub Callback URL | `https://accounts.svc.plus/api/auth/oauth/callback/github` |
| Google Callback URL | `https://accounts.svc.plus/api/auth/oauth/callback/google` |
| Backend Config File | `accounts.svc.plus/config/account.yaml` |
| Frontend URL Resolution | `getAccountServiceBaseUrl()` in `src/server/serviceConfig.ts` |
