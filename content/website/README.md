# Portal website content

This is the file-based CMS source for Portal's build-time marketing content.

- Homepage, product marketing, documentation landing copy, and company copy live here.
- Portal's `/docs` and `/blogs` remain proxied to the docs service; do not copy
  service documentation or blog archives into this directory.
- Never commit passwords, API keys, access tokens, refresh tokens, private keys,
  or production configuration values.

## Publishing

1. Create a Git branch and edit the Markdown/YAML content.
2. Review and merge the content PR.
3. Build Portal. The workflow clones `content/website` and validates
   `content-manifest.yaml` before generating the static content artifacts.

The backend is portable: Portal consumes a standard Git URL, not a GitHub API
or browser-based editor.
