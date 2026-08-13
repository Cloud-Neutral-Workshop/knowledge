# Portal website content

This is the file-based CMS source for Portal's build-time marketing content.

- Homepage, product marketing, documentation landing copy, and company copy live here.
- Product documentation is canonical under the repository's top-level `docs/`.
- Product technical blogs are canonical under the repository's top-level
  `content/`.
- Portal's `/docs` and `/blogs` remain proxied to the docs service. The service
  publishes those two canonical trees, so do not duplicate their archives here.
- Never commit passwords, API keys, access tokens, refresh tokens, private keys,
  or production configuration values.

## Publishing

1. Create a Git branch and edit the Markdown/YAML content.
2. Review and merge the content PR.
3. Release the relevant consumer: Portal builds from `content/website`, while
   the docs service publishes `docs/` and `content/`.

The backend is portable: Portal consumes a standard Git URL, not a GitHub API
or browser-based editor.
