# DeadSimpleCms

DeadSimpleCms is a deliberately minimal Phoenix CMS library.

It is designed to solve a very specific problem: **allow non-technical
users to update structured content without breaking carefully designed
pages**.

It is _not_ a general-purpose CMS.

---

## What It Is

DeadSimpleCms provides:

- Structured content storage (`cms_pages`, `cms_content_areas`, `cms_images`, `cms_slots`, `cms_page_templates`)
- Per-page SEO metadata (meta title/description, noindex, social share image) and a sitemap query
- Reusable special content: staff bios (`cms_bios`) and testimonials (`cms_testimonials`)
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

### CMS Pages (`cms_pages`)

- `slug` (normalized: lowercase, hyphenated)
- `title`
- `published`
- `published_at`
- `cms_page_template_id` (optional)

SEO fields (all optional):

- `meta_title`: falls back to `title` when blank (aim for 60 characters or fewer)
- `meta_description`: up to 320 characters (aim for 150–160)
- `noindex`: hides the page from search engines and from `list_sitemap_cms_pages/0`
- `og_image_id`: a `cms_images` record used as the social share image

Public reads should go through `get_published_page_by_slug/1`, which only
returns published pages. A host's full-page preview route (behind its own
authentication) can use `get_preview_page_by_slug/1`, which has the same
preloads but includes unpublished pages.

---

### CMS Content Areas (`cms_content_areas`)

- Belong to **either** a page (`cms_page_id`) **or** a page template
  (`cms_page_template_id`), enforced by a database check constraint
- Belong to a slot (`cms_slot_id`, required)
- Ordered via `position` (integer)
- `name` (scoped per page)
- Optional `visible` flag
- `shared` flag, for template areas: render on every page using the
  template instead of being copied into new pages
- Structured fields (`title`, `subtitle`, `body_md`)
- Optional image (`cms_image_id`)

Editors work on sections inside the page and template editors, which share
one section editor (`DeadSimpleCmsWeb.ContentAreasEditor`): each section has
a live preview, its type's help text, an image upload with its description
(alt text), Move up / Move down and Delete, and saves on its own.
`Cms.move_cms_content_area/2` renumbers positions 0, 1, 2...; there's no
drag-and-drop.

---

### CMS Slots (`cms_slots`)

- `key`, `name`, `description`

A slot tells the host app **which component renders a content area**.
The host matches on `area.cms_slot.key` (for example `"hero"`, `"faq"`,
`"standard_content"`). The install migrations seed a `standard_content` slot.

The slot's `description` is shown as help text under the slot picker in
the page editor, so use it to tell editors what the slot needs (for
example, "One fact per line: 15,000+ | nautical miles").

---

### CMS Page Templates (`cms_page_templates`)

- `key`, `name`, `description`

A template groups content areas that define a page's shape. Pages may
optionally reference a template. Template content areas do two jobs:

- **Starter sections** (`shared` unchecked). A page created in the admin
  with a template gets a copy of these (`copy_template_areas_to_page/1`).
  The copies are the page's own and are edited independently.
- **Shared blocks** (`shared` checked). Not copied. Instead,
  `get_published_page_by_slug/1` preloads the template with its visible
  shared areas, so the host can render them on every page that uses the
  template (a closing call to action, for example). Edit the block once on
  the template and every page shows the change.

Upgrading: run `mix dead_simple_cms.install` again to copy the new
`add_shared_to_cms_content_areas` migration, then `mix ecto.migrate`.

The host can also match on `page.cms_page_template.key` to choose a page
layout.

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

### Special Content (`cms_bios`, `cms_testimonials`)

- **Bios:** name, job title, tag line, description, contact and social links,
  `slug` (generated from the name when blank), `visible`, optional image
- **Testimonials:** name, title, company, source, quote, `stars` (1–5), `visible`

Managed through `DeadSimpleCms.SpecialContent`.

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
  s3: [bucket: "your-bucket"]
```

### Required

- `repo`
- `endpoint`
- `s3.bucket`

### Optional

- `s3.region`, `s3.access_key_id`, `s3.secret_access_key`: when omitted,
  your app's existing `config :ex_aws` settings are used. When given, they
  are written into the `:ex_aws` config (and so apply app-wide).
- `admin_layout`: read at compile time. After changing it, run
  `mix deps.compile dead_simple_cms --force`.
- `admin_path`: the prefix you mount the admin routes under (for example
  `"/admin"`), used to build links between admin pages.
- `preview_components`: a module exporting `cms_content_slot/1`. When set,
  the page editor renders a live preview of each content area using your
  own components.
- `page_preview_url`: a URL template for your app's full-page preview, such
  as `"/preview/:slug"` (`:slug` and `:id` are filled in). When set, the page
  editor and page screens show a "Preview Page" button that opens it in a new
  tab. The route is yours: render the page with your public layout, include
  unpublished pages, and put it behind your own authentication. The preview
  shows saved content, so save before previewing.

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
- Copy `assets/js/uploaders.js` (if not present)
- Copy the EasyMDE markdown editor (`assets/js/easymde.min.js`,
  `assets/js/easymde_hook.js`, `assets/css/easymde.min.css`) (if not present)

Your app owns the schema from this point forward.

#### Umbrella apps

Run the installer from the app that owns the Repo, so migrations land in its
`priv/repo/migrations`, and point `--components-path` at your web app:

```bash
cd apps/my_app
mix dead_simple_cms.install --components-path ../my_app_web/lib/my_app_web/components/cms_components.ex
```

Then move the copied `assets/js/*` and `assets/css/*` files into the web
app's `assets/` directory.

#### Upgrading

Re-run the installer after upgrading DeadSimpleCms. Migrations that are
already installed are skipped (matched by name, ignoring the timestamp), so
only new ones, such as `add_seo_to_cms_pages`, are copied:

```bash
mix dead_simple_cms.install
mix ecto.migrate
```

---

### 4. Wire Uploaders and the Markdown Editor (Manual Step)

Because JavaScript bootstrapping varies per app, DeadSimpleCms does
**not** patch your `app.js` automatically.

In `assets/js/app.js`:

```javascript
import Uploaders from "./uploaders";
import EasyMDEHook from "./easymde_hook";

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  uploaders: Uploaders,
  hooks: { ...yourHooks, EasyMDE: EasyMDEHook },
});
```

`Uploaders` enables direct-to-S3 PUT uploads via presigned URLs. The
`EasyMDE` hook powers the markdown editor on content areas.

In `assets/css/app.css`, import the editor styles:

```css
@import "./easymde.min.css";
```

### Styling the Admin UI

The admin views use Tailwind utility classes plus a handful of
[daisyUI](https://daisyui.com/) component classes (`btn`, `btn-primary`,
`btn-ghost`, `btn-soft`, `fieldset`, `label`, `input`, `select`,
`textarea`, `checkbox`). Phoenix 1.8 apps include daisyUI by default. If
yours doesn't, define those classes yourself.

Either way, add the library to your Tailwind sources so its utility
classes are generated:

```javascript
// Tailwind v3: tailwind.config.js
content: [..., "../../deps/dead_simple_cms/lib/**/*.*ex"]
```

```css
/* Tailwind v4: app.css */
@source "../../deps/dead_simple_cms/lib";
```

### Overriding Admin Components

To change more than styles, replace the admin UI's building blocks with your
own components:

```elixir
# config/config.exs
config :dead_simple_cms, admin_components: YourAppWeb.CmsAdminComponents
```

These can be overridden:

| Component | Used for | Assigns / slots |
| --- | --- | --- |
| `content_header/1` | The header card at the top of every admin page | `main_title`, `sub_title`, `description`, `sub_description`, `icon_class`; slots `:action`, `:tab` |
| `admin_table/1` | Index tables | `id`, `rows`, `row_id`, `row_click`, `row_item`; slots `:col` (`label`, `extra_th_class`, `extra_td_class`), `:tab`, `:action` |
| `non_list_table/1` | Field/value tables on show pages | `object_name`, `headers`; slot `:row` |
| `button/1` | Form buttons | `type`, `variant`, `navigate`, `patch`, `href`, `class`, `rest`; slot `:inner_block` |

Define only the ones you want to change. The rest keep the built-in markup.
Overrides receive the same assigns and slots as the built-in version, and
the built-ins are available as `default_content_header/1`,
`default_admin_table/1`, `default_non_list_table/1`, and `default_button/1`,
so an override can wrap one instead of rewriting it:

```elixir
defmodule YourAppWeb.CmsAdminComponents do
  use Phoenix.Component

  alias DeadSimpleCmsWeb.CoreComponents

  # Replace the header entirely
  def content_header(assigns) do
    ~H"""
    <header class="flex items-center justify-between border-b pb-4">
      <div>
        <h1 class="text-xl font-semibold">{@main_title}</h1>
        <p class="text-sm text-gray-500">{@description}</p>
      </div>
      <div :for={action <- @action}>{render_slot(action)}</div>
    </header>
    """
  end

  # Keep the built-in button, add your own classes
  def button(assigns) do
    CoreComponents.default_button(Map.update!(assigns, :class, &"my-button #{&1}"))
  end
end
```

The setting is read at runtime, so no recompile is needed. Most header
actions (such as "Add CMS Page") are links passed into `content_header`'s
`:action` slot, so they're styled with CSS or the header override rather
than `button/1`.

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
  case DeadSimpleCms.Cms.get_published_page_by_slug(slug) do
    nil ->
      # Handle not found however your app does (404 page, redirect, etc.)
      {:ok, push_navigate(socket, to: "/")}

    page ->
      seo = DeadSimpleCms.Cms.page_seo(page)

      {:ok,
       socket
       |> assign(:page, page)
       |> assign(:areas, page.cms_content_areas)
       |> assign(:page_title, seo.title)
       |> assign(:canonical_url, url(~p"/pages/#{page.slug}"))
       |> assign(:seo, seo)}
  end
end
```

`page.cms_content_areas` contains only visible areas, ordered by
`position`, with `cms_image` and `cms_slot` preloaded.

Render using your own components, choosing one per slot:

```elixir
<%= for area <- @areas do %>
  <.cms_text_block area={area} />
<% end %>
```

You own layout, styling, sanitization, and markdown rendering.

---

## SEO

DeadSimpleCms stores SEO metadata and resolves fallbacks. Your root layout
renders the tags.

`DeadSimpleCms.Cms.page_seo/1` returns:

```elixir
%{
  title: "Yacht Charter Marketing",        # meta_title, or the page title
  description: "Marketing for charter…",   # nil when blank
  og_image_url: "https://…/hero.jpg",       # nil without og_image
  og_image_alt: "Charter yacht at anchor",  # nil without alt text
  robots: "index, follow"                   # "noindex, follow" when noindex
}
```

`og_image` must be preloaded. `get_published_page_by_slug/1` and
`get_cms_page!/1` both preload it.

Example `<head>` (in your root layout):

```heex
<%= if seo = assigns[:seo] do %>
  <meta :if={seo.description} name="description" content={seo.description} />
  <meta name="robots" content={seo.robots} />
  <meta property="og:title" content={seo.title} />
  <meta :if={seo.description} property="og:description" content={seo.description} />
  <meta :if={seo.og_image_url} property="og:image" content={seo.og_image_url} />
  <meta :if={seo.og_image_alt} property="og:image:alt" content={seo.og_image_alt} />
  <meta name="twitter:card" content={if seo.og_image_url, do: "summary_large_image", else: "summary"} />
<% end %>
<link :if={assigns[:canonical_url]} rel="canonical" href={@canonical_url} />
```

### Canonical URLs

DeadSimpleCms does not store canonical URLs. Only the host app knows its
domain and route structure, so it builds them, usually pointing each page
at itself:

```elixir
|> assign(:canonical_url, url(~p"/pages/#{page.slug}"))
```

Build it from the slug, not the incoming request URL, so query strings and
alternate hosts don't create duplicate canonicals.

Social platforms fetch `og:image` anonymously. If your S3 bucket is private,
use a public bucket or CDN for share images.

### Sitemap

`DeadSimpleCms.Cms.list_sitemap_cms_pages/0` returns published pages that
are not `noindex`, ordered by slug. The host app owns the route and URLs:

```elixir
# router.ex
get "/sitemap.xml", SitemapController, :index

# sitemap_controller.ex
def index(conn, _params) do
  urls =
    for page <- DeadSimpleCms.Cms.list_sitemap_cms_pages() do
      ~s(<url><loc>#{url(~p"/pages/#{page.slug}")}</loc><lastmod>#{Date.to_iso8601(page.updated_at)}</lastmod></url>)
    end

  conn
  |> put_resp_content_type("application/xml")
  |> send_resp(200, ~s(<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">#{urls}</urlset>))
end
```

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
- Page `<head>` includes the SEO tags you set, and `/sitemap.xml` lists the page

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
