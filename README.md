# DeadSimpleCms

DeadSimpleCms is a deliberately minimal Phoenix CMS library.

It provides: - Structured content storage (pages + content areas) -
Admin CRUD UI helpers - Validation and ordering - Zero opinions about layout,
theming, caching, auth, or rendering

Your application owns everything else.

---

## Philosophy

DeadSimpleCms is designed around a few non-negotiable principles:

- Host app owns the database
- Host app owns rendering and layout
- No roles, no auth
- No caching
- No page builders, no themes
- Small surface area, predictable behavior

This makes the library easy to understand, easy to remove, and safe to
extend without fighting hidden abstractions.

---

## What DeadSimpleCms Provides

- `cms_pages`
- `cms_content_areas`
- `cms_images`
- Admin LiveView UI for managing content
- A single baseline content shape (`:text_block`)
- Repo indirection so the host app controls persistence

---

## What DeadSimpleCms Does _Not_ Do

- No automatic migrations
- No database ownership
- No frontend rendering
- No authentication or authorization
- No caching or publishing workflows
- No page builder or layout system

---

## Installation

### 1. Add the dependency

```elixir
def deps do
  [
    {:dead_simple_cms, "~> 0.1.0"}
  ]
end
```

```bash
mix deps.get
```

---

### 2. Configure the Repo

DeadSimpleCms does not define its own Repo.

You must configure which Repo it should use:

```elixir
# config/config.exs
config :dead_simple_cms, repo: MyApp.Repo
```

This is required.

---

### 3. Install migrations (host-owned)

DeadSimpleCms ships migration templates, not migrations.

Run the install task to copy rendered migrations into your app:

```bash
mix dead_simple_cms.install
```

Then run:

```bash
mix ecto.migrate
```

---

### 4. Mount admin routes

```elixir
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_admin]
  DeadSimpleCmsWeb.Router.dead_simple_cms_admin_routes()
end
```

---

## Rendering Content

DeadSimpleCms does not render frontend content.

A baseline component may be copied to:

    lib/my_app_web/cms_components.ex

You own all rendering decisions.

---

## Development

```bash
mix setup
mix phx.server
```

Visit http://localhost:4000.
