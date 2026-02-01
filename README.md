# DeadSimpleCms

DeadSimpleCms is a deliberately minimal Phoenix CMS library.

It is designed to solve a very specific problem: **allow non-technical users to update structured content without breaking carefully designed pages**.

It is _not_ a general-purpose CMS.

---

## What It Is

DeadSimpleCms provides:

- Structured content storage (`cms_pages`, `cms_content_areas`, `cms_images`)
- A small, predictable admin UI built with Phoenix LiveView
- Validation, ordering, and visibility flags
- Repo indirection so the host app owns persistence
- A clean boundary between **content** and **rendering**

That’s it.

---

## What It Is _Not_

DeadSimpleCms intentionally does **not** include:

- Page builders
- Themes
- Frontend rendering opinions
- Authentication or authorization
- Roles or permissions
- Caching layers
- Publishing workflows
- Database ownership

If you want those things, this library is not for you.

---

## Philosophy

DeadSimpleCms is built around a few non-negotiable principles:

- **The host app owns the database**
- **The host app owns layout and rendering**
- **The CMS owns only content structure and admin CRUD**
- **Small surface area beats flexibility**
- **Predictability beats power**

This makes the library:

- Easy to reason about
- Easy to remove
- Safe to extend
- Resistant to scope creep

---

## Data Model Overview

DeadSimpleCms provides three core concepts:

- **CMS Pages** (`cms_pages`)
  - `slug`
  - `title`
  - `published`
  - `published_at`

- **CMS Content Areas** (`cms_content_areas`)
  - Belong to a page
  - Ordered via `position`
  - Optional `name`
  - Optional `visible` flag
  - Structured fields (`title`, `subtitle`, `body_md`, etc.)

- **CMS Images** (`cms_images`)
  - Simple image records for admin usage

The CMS does **not** dictate how these are rendered.

---

## Installation

### 1. Add the Dependency

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

### 2. Configure the Repo and Endpoint

DeadSimpleCms does not define its own Repo or Endpoint.

You must tell it which ones to use:

```elixir
# config/config.exs
config :dead_simple_cms,
  repo: YourApp.Repo,
  endpoint: YourAppWeb.Endpoint,
  admin_layout: {YourAppWeb.Layouts, :app},
  admin_path: "/cms"
```

- `repo` **required**
- `endpoint` **required**
- `admin_layout` optional (defaults to the CMS layout)
- `admin_path` optional

---

### 3. Install Migrations (Host-Owned)

DeadSimpleCms does **not** run migrations automatically.

Copy them into your app:

```bash
mix dead_simple_cms.install
```

Then run:

```bash
mix ecto.migrate
```

Your app owns the schema from this point forward.

---

### 4. Mount Admin Routes

```elixir
import DeadSimpleCmsWeb.Router, only: [dead_simple_cms_admin_routes: 0]

scope "/admin", YourAppWeb do
  pipe_through [:browser]

  dead_simple_cms_admin_routes()
end
```

Authentication is the host app’s responsibility.

---

## Rendering Content

DeadSimpleCms **does not render frontend content**.

A simple baseline component will be copied into your app, for example:

```
lib/your_app_web/cms_components.ex
```

From there:

- You decide layout
- You decide styling
- You decide sanitization
- You decide markdown handling

The CMS only provides validated content.

---

## LiveView Layout Contract (`inner_content` vs `inner_block`)

DeadSimpleCms admin pages are implemented as **Phoenix LiveViews**.

This means layout behavior follows Phoenix LiveView rules — not component rules.

### Critical distinction

- **LiveView layouts** receive rendered content via `@inner_content`
- **Function components** receive content via the `@inner_block` slot

These two mechanisms are **not interchangeable**.

DeadSimpleCms:

- Does **not** wrap layouts manually
- Applies layouts via:

```elixir
use Phoenix.LiveView, layout: {YourAppWeb.Layouts, :app}
```

Because of this, any layout used as `admin_layout` must be compatible with LiveView layouts.

---

### Layout Used _Only_ as a LiveView Layout

If your layout is only used by LiveView:

```heex
{@inner_content}
```

---

### Layout Used Both Manually and by LiveView (Recommended)

If your app already uses the layout as a function component:

```heex
<Layouts.app>
  ...
</Layouts.app>
```

Then the layout should support **both** call styles:

```elixir
slot :inner_block

def app(assigns) do
  ~H"""
  <main>
    <%= if assigns[:inner_block] do %>
      {render_slot(@inner_block)}
    <% else %>
      {@inner_content}
    <% end %>
  </main>
  """
end
```

This allows:

- Existing LiveViews to continue working
- DeadSimpleCms to integrate cleanly
- No layout duplication
- No forced refactors

---

### Why DeadSimpleCms Works This Way

This behavior is dictated by **Phoenix LiveView**, not by the CMS.

DeadSimpleCms intentionally:

- Does not mutate layout assigns
- Does not wrap layouts conditionally
- Does not inject compatibility layers

The host app owns layout contracts.

---

## Development

```bash
mix setup
mix phx.server
```

Visit:

```
http://localhost:4000
```

---

## Final Notes

DeadSimpleCms is intentionally boring.

If you need power, flexibility, or abstraction — look elsewhere.

If you need something small, predictable, and easy to reason about — this is exactly that.
