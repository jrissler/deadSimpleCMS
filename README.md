# DeadSimpleCms

DeadSimpleCms is a deliberately minimal Phoenix CMS library.

It is designed to solve a very specific problem: **allow non-technical
users to update structured content without breaking carefully designed
pages**.

It is _not_ a general-purpose CMS.

---

## What It Is

DeadSimpleCms provides:

- Structured content storage (`cms_pages`, `cms_content_areas`, `cms_images`)
- A small, predictable admin UI built with Phoenix LiveView
- Validation, ordering, and visibility flags
- Repo indirection so the host app owns persistence
- A clean boundary between **content** and **rendering**
- External S3-based image uploads via LiveView uploaders

That's it.

---

## Items Optionally Implemented by Parent App

DeadSimpleCms intentionally does **not** include:

- Themes
- Frontend rendering opinions
- Authentication and/or authorization
- Roles and permissions
- Caching layers
- Publishing workflows
- Database ownership

---

## Philosophy

DeadSimpleCms is built around a few non-negotiable principles:

- **The host app owns the database**
- **The host app owns layout and rendering**
- **The CMS owns only content structure and admin CRUD**
- **Small surface area**

This makes the library:

- Easy to reason about
- Easy to remove
- Safe to extend

---

## Data Model Overview

DeadSimpleCms provides three core concepts:

### CMS Pages (`cms_pages`)

- `slug`
- `title`
- `published`
- `published_at`

Public reads should typically filter on `published == true`.

---

### CMS Content Areas (`cms_content_areas`)

- Belong to a page via `page_id`
- Ordered via `position` (integer)
- Optional `name` (scoped per page)
- Optional `visible` flag
- Structured fields (`title`, `subtitle`, `body_md`, etc.)

Admin views allow move up/down and renumber operations.\
No drag-and-drop.

---

### CMS Images (`cms_images`)

- `filename`
- `url`
- `alt`
- `caption`
- `size`
- `content_type`

Images are uploaded directly to S3 using presigned URLs.\
The CMS stores metadata only.

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

### 2. Configure Repo, Endpoint, Layout, and S3

DeadSimpleCms does not define its own Repo or Endpoint.

You must tell it which ones to use:

```elixir
# config/config.exs
config :dead_simple_cms,
  repo: YourApp.Repo,
  endpoint: YourAppWeb.Endpoint,
  admin_layout: {YourAppWeb.Layouts, :app},
  admin_path: "/cms",
  s3: [
    bucket: "your-bucket",
    region: "your-region ie: us-east-1",
    access_key_id: "your-key",
    secret_access_key: "your-secret"
  ]
```

### Required

- `repo`
- `endpoint`
- `s3.bucket`
- `s3.region`
- `s3.access_key_id`
- `s3.secret_access_key`

### Optional

- `admin_layout`
- `admin_path`

---

### 3. Install Migrations and Assets

DeadSimpleCms does **not** run migrations automatically.

Run:

```bash
mix dead_simple_cms.install
mix ecto.migrate
```

This will:

- Copy migration files into your app (`priv/repo/migrations`)
- Copy a baseline `cms_components.ex` file (if not present)
- Copy `assets/js/uploader.js` (if not present)

Your app owns the schema from this point forward.

---

### 4. Wire Uploaders (Manual Step)

Because JavaScript bootstrapping varies per app, DeadSimpleCms does
**not** patch your `app.js` automatically.

In `assets/js/app.js`:

1.  Import the uploader:

```javascript
import Uploaders from "./uploader";
```

2.  Pass it into LiveSocket:

```javascript
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  uploaders: Uploaders,
});
```

This enables direct-to-S3 PUT uploads via presigned URLs.

---

### 5. Mount Admin Routes

```elixir
import DeadSimpleCmsWeb.Router, only: [dead_simple_cms_admin_routes: 0]

scope "/admin", YourAppWeb do
  pipe_through [:browser]

  dead_simple_cms_admin_routes()
end
```

---

## Public Page Rendering Example

DeadSimpleCms does not render frontend pages.

Add a route / module in your host app:

```elixir
live "/pages/:slug", CmsPageLive, :show
```

Minimal LiveView example:

```elixir
def mount(%{"slug" => slug}, _session, socket) do
  page = DeadSimpleCms.Cms.get_published_page_by_slug!(slug)
  areas = DeadSimpleCms.Cms.list_areas_for_page(page.id)

  {:ok, assign(socket, page: page, areas: areas)}
end
```

Render using your own components:

```elixir
<%= for area <- @areas do %>
  <.cms_text_block area={area} />
<% end %>
```

You own layout, styling, sanitization, and markdown rendering.

---

## LiveView Layout Contract (`inner_content` vs `inner_block`)

DeadSimpleCms admin pages are implemented as Phoenix LiveViews.

### Critical distinction

- LiveView layouts receive rendered content via `@inner_content`
- Function components receive content via the `@inner_block` slot

These are not interchangeable.

Your `admin_layout` must support LiveView layout semantics.

If used both manually and by LiveView, support both styles:

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

The host app owns layout contracts.

---

## Post-Install Checklist

After setup, verify:

- `/cms` (or your configured `admin_path`) loads
- You can create a CMS page
- You can add content areas
- Image uploads succeed (confirms S3 + JS wiring)
- Public page route renders published content

---

## Development

```bash
mix setup
mix phx.server
```

Visit:

    http://localhost:4000

---

## Final Notes

DeadSimpleCms is intentionally boring.

It is a **content-backed template system**, not a traditional CMS.

If you need something small, predictable, and safe --- this is exactly
that.
