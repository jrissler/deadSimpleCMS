defmodule DeadSimpleCmsWeb.AboutLive do
  @moduledoc """
  What DeadSimpleCMS is, in plain language, and what's coming next: building
  and editing pages by talking to Claude or ChatGPT. Rendered inside the host
  app's admin like every other CMS screen.

  The page carries its own stylesheet, scoped to `#about-dscms`, because it
  renders inside every host app and can't rely on the host's Tailwind build
  including its colors and layout utilities.
  """
  use DeadSimpleCmsWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      #about-dscms { --ink: #0f172a; --muted: #52525b; --line: #e4e4e7; --brand: #4f46e5; max-width: 64rem; margin: 0 auto; padding: 0 1rem 4rem; color: var(--ink); font-size: 1rem; line-height: 1.6; }
      #about-dscms * { box-sizing: border-box; }
      #about-dscms .ab-stack > * + * { margin-top: 3rem; }
      #about-dscms h1, #about-dscms h2, #about-dscms h3 { margin: 0; letter-spacing: -0.02em; line-height: 1.15; }
      #about-dscms p { margin: 0; }
      #about-dscms .ab-eyebrow { font-size: 0.72rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.22em; }
      #about-dscms .ab-panel-dark { position: relative; overflow: hidden; border-radius: 1.5rem; padding: 3rem 1.5rem; color: #fff; box-shadow: 0 25px 60px rgba(15, 23, 42, 0.25); }
      #about-dscms .ab-hero { background: radial-gradient(circle at 85% 10%, rgba(99, 102, 241, 0.4), transparent 42%), radial-gradient(circle at 8% 100%, rgba(52, 211, 153, 0.25), transparent 45%), #020617; }
      #about-dscms .ab-soon { background: radial-gradient(circle at 90% 15%, rgba(232, 121, 249, 0.25), transparent 40%), linear-gradient(135deg, #4f46e5, #4338ca 45%, #0f172a); }
      #about-dscms .ab-hero h1 { margin-top: 1rem; font-size: clamp(2.2rem, 5vw, 3.25rem); font-weight: 800; color: #fff; }
      #about-dscms .ab-soon h2 { margin-top: 1.25rem; font-size: clamp(1.8rem, 4vw, 2.5rem); font-weight: 800; color: #fff; max-width: 46rem; }
      #about-dscms .ab-lede { margin-top: 1.5rem; max-width: 46rem; font-size: 1.125rem; line-height: 1.75; }
      #about-dscms .ab-hero .ab-lede { color: #e2e8f0; }
      #about-dscms .ab-soon .ab-lede { color: #e0e7ff; }
      #about-dscms .ab-actions { margin-top: 2rem; display: flex; flex-wrap: wrap; gap: 0.75rem; }
      #about-dscms .ab-btn { display: inline-flex; align-items: center; gap: 0.5rem; border-radius: 0.6rem; padding: 0.65rem 1rem; font-size: 0.875rem; font-weight: 600; text-decoration: none; }
      #about-dscms .ab-btn-light { background: #fff; color: var(--ink); }
      #about-dscms .ab-btn-light:hover { background: #eef2ff; }
      #about-dscms .ab-btn-outline { color: #fff; box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.35); }
      #about-dscms .ab-btn-outline:hover { background: rgba(255, 255, 255, 0.1); }
      #about-dscms .ab-btn-dark { background: var(--ink); color: #fff; }
      #about-dscms .ab-btn-dark:hover { background: #1e293b; }
      #about-dscms .ab-icon { width: 1rem; height: 1rem; }
      #about-dscms .ab-section-title { font-size: 1.6rem; font-weight: 800; }
      #about-dscms .ab-section-intro { margin-top: 0.75rem; max-width: 48rem; color: var(--muted); }
      #about-dscms .ab-grid { display: grid; gap: 1rem; margin-top: 1.5rem; }
      #about-dscms .ab-card { border: 1px solid var(--line); border-radius: 1.1rem; background: #fff; padding: 1.5rem; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04); }
      #about-dscms .ab-card h3 { margin-top: 1rem; font-size: 1rem; font-weight: 700; }
      #about-dscms .ab-card p { margin-top: 0.5rem; font-size: 0.9rem; line-height: 1.6; color: var(--muted); }
      #about-dscms .ab-tile { display: flex; width: 2.5rem; height: 2.5rem; align-items: center; justify-content: center; border-radius: 0.75rem; background: #eef2ff; color: var(--brand); }
      #about-dscms .ab-tile .ab-icon { width: 1.25rem; height: 1.25rem; }
      #about-dscms .ab-num { display: flex; width: 2.25rem; height: 2.25rem; align-items: center; justify-content: center; border-radius: 999px; background: var(--ink); color: #fff; font-size: 0.875rem; font-weight: 700; }
      #about-dscms .ab-wide-card { border: 1px solid var(--line); border-radius: 1.5rem; background: #fff; padding: 2rem 1.5rem; }
      #about-dscms .ab-two-col { display: grid; gap: 1.5rem; margin-top: 1rem; }
      #about-dscms .ab-two-col p { color: var(--muted); }
      #about-dscms .ab-pill { display: inline-flex; align-items: center; gap: 0.5rem; border-radius: 999px; padding: 0.3rem 0.75rem; background: rgba(255, 255, 255, 0.15); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.25); color: #fff; }
      #about-dscms .ab-dot { width: 0.5rem; height: 0.5rem; border-radius: 999px; background: #6ee7b7; animation: dscms-pulse 1.8s ease-in-out infinite; }
      @keyframes dscms-pulse { 50% { opacity: 0.35; } }
      #about-dscms .ab-soon-grid { display: grid; gap: 2rem; margin-top: 2.5rem; }
      #about-dscms .ab-label-light { color: #c7d2fe; }
      #about-dscms .ab-bubbles { display: flex; flex-direction: column; align-items: flex-start; gap: 0.75rem; margin-top: 0.75rem; }
      #about-dscms .ab-bubble { max-width: 28rem; border-radius: 1rem 1rem 1rem 0.35rem; background: #fff; color: var(--ink); padding: 0.75rem 1rem; font-size: 0.9rem; line-height: 1.55; box-shadow: 0 10px 25px rgba(15, 23, 42, 0.2); }
      #about-dscms .ab-will { border-radius: 1rem; padding: 1.5rem; background: rgba(255, 255, 255, 0.1); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.2); }
      #about-dscms .ab-will ul { list-style: none; margin: 1rem 0 0; padding: 0; display: grid; gap: 0.75rem; }
      #about-dscms .ab-will li { display: flex; gap: 0.75rem; font-size: 0.9rem; line-height: 1.55; color: #fff; }
      #about-dscms .ab-will li .ab-icon { flex-shrink: 0; width: 1.25rem; height: 1.25rem; margin-top: 0.1rem; color: #6ee7b7; }
      #about-dscms .ab-charge { display: grid; gap: 1.5rem; border: 1px solid #a7f3d0; border-radius: 1.5rem; background: #f0fdf4; padding: 2rem 1.5rem; }
      #about-dscms .ab-charge .ab-tile { background: #059669; color: #fff; }
      #about-dscms .ab-charge h2 { margin-top: 1rem; font-size: 1.6rem; font-weight: 800; }
      #about-dscms .ab-charge ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 1.25rem; }
      #about-dscms .ab-charge li p:first-child { font-weight: 700; }
      #about-dscms .ab-charge li p + p { margin-top: 0.25rem; font-size: 0.9rem; color: var(--muted); }
      #about-dscms .ab-closing { text-align: center; }
      #about-dscms .ab-closing p { margin: 0 auto; max-width: 40rem; font-size: 1.1rem; color: #3f3f46; }
      #about-dscms .ab-closing .ab-actions { justify-content: center; }
      #about-dscms ol.ab-grid { list-style: none; padding: 0; }
      @media (min-width: 640px) {
        #about-dscms .ab-panel-dark { padding: 4rem 3rem; }
        #about-dscms .ab-grid-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
        #about-dscms .ab-charge ul { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        #about-dscms .ab-wide-card, #about-dscms .ab-charge { padding: 2.5rem; }
      }
      @media (min-width: 1024px) {
        #about-dscms .ab-two-col, #about-dscms .ab-soon-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        #about-dscms .ab-charge { grid-template-columns: 15rem minmax(0, 1fr); }
      }
    </style>

    <main id="about-dscms">
      <div class="ab-stack">
        <section class="ab-panel-dark ab-hero">
          <p class="ab-eyebrow ab-label-light">DeadSimpleCMS</p>
          <h1>Your website, without the busywork.</h1>
          <p class="ab-lede">
            DeadSimpleCMS keeps your site's words and photos in one tidy place, so you can change them without touching code.
            And very soon you won't need to fill in the forms yourself: you'll tell your AI assistant what you want, and it will do the work.
          </p>
          <div class="ab-actions">
            <a href="#coming-soon" class="ab-btn ab-btn-light"><.icon name="hero-sparkles" class="ab-icon" /> See what's coming</a>
            <.link navigate={DeadSimpleCms.path("/cms_pages")} class="ab-btn ab-btn-outline">Go to your pages <.icon name="hero-arrow-right" class="ab-icon" /></.link>
          </div>
        </section>

        <section aria-labelledby="what-it-is">
          <h2 id="what-it-is" class="ab-section-title">What it is, in plain words</h2>
          <p class="ab-section-intro">
            Every page on your site is a stack of sections, top to bottom: a big photo with a headline, a story, a few numbers, a quote, a button at the end.
            You fill each one in with a title, some text and maybe a photo. The website decides how it looks, so nothing you type can break the design.
          </p>
          <div class="ab-grid ab-grid-3">
            <div :for={{icon, title, text} <- @building_blocks} class="ab-card">
              <span class="ab-tile"><.icon name={icon} class="ab-icon" /></span>
              <h3>{title}</h3>
              <p>{text}</p>
            </div>
          </div>
        </section>

        <section aria-labelledby="why-simple" class="ab-wide-card">
          <h2 id="why-simple" class="ab-section-title">Why it's so simple on purpose</h2>
          <div class="ab-two-col">
            <p>
              Most website builders give you a thousand buttons, and most of them are ways to make a page look worse.
              DeadSimpleCMS gives you a small, predictable set: pages, sections in order, and the fields each section needs.
            </p>
            <p>
              That same simplicity is what makes the next step possible. A page made of clear, labeled sections is easy for a person to understand,
              and just as easy for an AI assistant to read, write and improve, without ever touching the parts that make your site look the way it does.
            </p>
          </div>
        </section>

        <section id="coming-soon" aria-labelledby="coming-soon-heading" class="ab-panel-dark ab-soon">
          <span class="ab-pill ab-eyebrow"><span class="ab-dot"></span> Coming in the next few weeks</span>
          <h2 id="coming-soon-heading">Build your pages by talking to Claude or ChatGPT.</h2>
          <p class="ab-lede">
            Nobody really wants to fill in forms, pick section types and write search descriptions. Soon you'll connect DeadSimpleCMS to the AI assistant you already use,
            say what you want in your own words, and it will draft the whole thing for you.
          </p>

          <div class="ab-soon-grid">
            <div aria-label="Examples of what you could ask">
              <p class="ab-eyebrow ab-label-light">You could say things like</p>
              <div class="ab-bubbles">
                <p :for={request <- @example_requests} class="ab-bubble">"{request}"</p>
              </div>
            </div>

            <div class="ab-will">
              <p class="ab-eyebrow ab-label-light">And your assistant will</p>
              <ul>
                <li :for={item <- @assistant_does}><.icon name="hero-check-circle" class="ab-icon" /> {item}</li>
              </ul>
            </div>
          </div>
        </section>

        <section aria-labelledby="how-it-works">
          <h2 id="how-it-works" class="ab-section-title">How it will work</h2>
          <ol class="ab-grid ab-grid-3">
            <li :for={{{title, text}, index} <- Enum.with_index(@steps, 1)} class="ab-card">
              <span class="ab-num">{index}</span>
              <h3>{title}</h3>
              <p>{text}</p>
            </li>
          </ol>
        </section>

        <section aria-labelledby="in-charge" class="ab-charge">
          <div>
            <span class="ab-tile"><.icon name="hero-shield-check" class="ab-icon" /></span>
            <h2 id="in-charge">You stay in charge</h2>
          </div>
          <ul>
            <li :for={{title, text} <- @safeguards}>
              <p>{title}</p>
              <p>{text}</p>
            </li>
          </ul>
        </section>

        <section class="ab-closing">
          <p>Until then, everything works just as it does today. Your pages, sections and images are ready for your assistant the moment it arrives.</p>
          <div class="ab-actions">
            <.link navigate={DeadSimpleCms.path("/cms_pages")} class="ab-btn ab-btn-dark">Go to your pages <.icon name="hero-arrow-right" class="ab-icon" /></.link>
          </div>
        </section>
      </div>
    </main>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "About DeadSimpleCMS",
       building_blocks: [
         {"hero-document-text", "Pages", "Each page has a title, an address, and a stack of sections. Drafts stay hidden until you publish."},
         {"hero-squares-2x2", "Sections", "A hero photo, a story, a quote, a timeline. Each type asks only for what it needs and shows a live preview as you type."},
         {"hero-photo", "Images", "One library for every photo on the site, with a description for each so screen readers and search engines understand it."}
       ],
       example_requests: [
         "Write an About page for us. Here are our notes and a few photos.",
         "Add a timeline of how we got started, after the story section.",
         "Make the Space Coast page shorter and friendlier, and give it a better search description."
       ],
       assistant_does: [
         "Draft the page and every section in your voice",
         "Choose the right section types and put them in a sensible order",
         "Write the search title, the search description and a description for each photo",
         "Suggest what's missing, like a call to action or a better headline",
         "Make changes across many pages at once, like a new phone number everywhere"
       ],
       steps: [
         {"Connect it once", "Link your site to Claude or ChatGPT. After that, your assistant can see your pages and section types."},
         {"Ask for what you want", "Describe the page or the change in everyday words, paste in notes, or point it at an existing page to improve."},
         {"Review and publish", "Your assistant saves its work as a draft. Preview the whole page, tweak anything you like, then publish."}
       ],
       safeguards: [
         {"Drafts first", "Nothing your assistant writes goes live until you publish it."},
         {"Preview everything", "See the whole page exactly as visitors will before anyone else can."},
         {"Edit by hand anytime", "This admin isn't going anywhere. Change a word or swap a photo yourself whenever you like."},
         {"The design stays safe", "Your assistant fills in sections. How the site looks stays in your developer's hands."}
       ]
     )}
  end
end
