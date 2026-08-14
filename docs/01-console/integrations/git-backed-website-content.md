# Git-backed website content

Portal uses a file-based Git backend for website copy. The backend is a normal
Git repository and directory; it does not require a GitHub API, a browser
editor, or a runtime CMS dependency.

The default backend layout is:

```text
content/website/
├── content-manifest.yaml
├── homepage/
├── product/
├── docs/
├── doc/
├── blogs/
└── about/
```

The default backend is `https://github.com/haitaopanhq/knowledge.git`, under
`content/website`. Portal creates `src/content` only as a disposable
build-workspace mirror, validates the contract, then generates the typed
content artifacts consumed by the homepage. No `src/content` source file is
tracked by Portal.

`knowledge.git` is the canonical content source for the product surface:

- `content/website/` supplies the homepage and static product marketing copy
  embedded into the Portal build.
- `docs/` supplies product documentation through the docs service.
- `content/` supplies product technical blogs through the docs service.

Portal's `/docs` and `/blogs` routes remain proxied to the existing docs
service. This keeps the web application thin while every content change still
follows the same Git PR and release workflow in `knowledge.git`.

## Local workflow

Point Portal at any local path or Git URL. The Git host is not part of the
contract.

```bash
export WEBSITE_CONTENT_REPOSITORY=https://github.com/haitaopanhq/knowledge.git
export WEBSITE_CONTENT_REF=main
export WEBSITE_CONTENT_SUBDIR=content/website

yarn content:pull
yarn content:validate
yarn build
```

For a content-only branch, set `WEBSITE_CONTENT_REF` to that branch before
running the same commands. `content:pull` mirrors the backend directory into
an ignored `src/content` build directory, so all website copy belongs in the
backend repository, not the Portal checkout. Portal intentionally has no
command that pushes content back to the backend.

`yarn build` intentionally fails if the content manifest has not been synced.
This prevents an image from being built with an accidental or stale local
content snapshot.

## CI contract

The Portal workflow defaults to the repository above. Any CI runner can
override it with the following environment variables before building the image:

| Variable | Meaning |
| --- | --- |
| `WEBSITE_CONTENT_REPOSITORY` | Reachable Git URL or checked-out local path for the CMS backend. |
| `WEBSITE_CONTENT_REF` | Immutable commit, tag, or reviewed branch to build. |
| `WEBSITE_CONTENT_SUBDIR` | Content root inside the backend; normally `content/website`. |

The current pipeline sets `REQUIRE_EXTERNAL_WEBSITE_CONTENT=true`, so a build
fails rather than silently falling back to a stale Portal snapshot. This is the
guard that keeps local and CI-generated homepage copy aligned.

## Publishing model

1. Update content in the backend on a Git branch.
2. Review and merge the content change.
3. Trigger the Portal build with the merged content ref.
4. The image embeds that exact content snapshot; deploy the image normally.

This is intentionally build-time content. A later content commit requires a
new image build, which keeps release provenance, review, and rollback in Git.
