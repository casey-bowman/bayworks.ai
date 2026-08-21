use leptos::prelude::*;
use leptos_meta::{provide_meta_context, MetaTags, Stylesheet, Title};
use leptos_router::{
    components::{Route, Router, Routes, A},
    StaticSegment,
};

pub fn shell(options: LeptosOptions) -> impl IntoView {
    view! {
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="utf-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <meta name="description" content="BayWorks — software engineering where Bitcoin meets distributed agents. A dba of Pacific Bay LLC."/>
                <link rel="icon" type="image/svg+xml" href="/images/favicon.svg"/>
                <AutoReload options=options.clone() />
                <HydrationScripts options/>
                <MetaTags/>
            </head>
            <body>
                <App/>
            </body>
        </html>
    }
}

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/bayworks.css"/>
        <Title text="BayWorks — Software Engineering"/>
        <Router>
            <SiteHeader/>
            <main>
                <Routes fallback=|| NotFound().into_view()>
                    <Route path=StaticSegment("") view=HomePage/>
                    <Route path=StaticSegment("projects") view=ProjectsPage/>
                    <Route path=StaticSegment("about") view=AboutPage/>
                    <Route path=StaticSegment("contact") view=ContactPage/>
                </Routes>
            </main>
            <SiteFooter/>
        </Router>
    }
}

#[component]
fn SiteHeader() -> impl IntoView {
    let (menu_open, set_menu_open) = signal(false);

    view! {
        <header class="site-header">
            <div class="container header-inner">
                <button
                    class="menu-toggle"
                    aria-label="Toggle navigation"
                    aria-expanded=move || menu_open.get().to_string()
                    on:click=move |_| set_menu_open.update(|open| *open = !*open)
                >
                    <span></span><span></span><span></span>
                </button>
                <nav class="site-nav" class:open=move || menu_open.get() on:click=move |_| set_menu_open.set(false)>
                    <A href="/">"Home"</A>
                    <A href="/projects">"Projects"</A>
                    <A href="/about">"About"</A>
                    <A href="/contact">"Contact"</A>
                </nav>
            </div>
        </header>
    }
}

#[component]
fn SiteFooter() -> impl IntoView {
    view! {
        <footer class="site-footer">
            <div class="container footer-inner">
                <p>"BayWorks is a dba of Pacific Bay LLC."</p>
                <p class="footer-fine">"© 2026 Pacific Bay LLC. All rights reserved."</p>
            </div>
        </footer>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    view! {
        <Title text="BayWorks — Software Engineering"/>
        <section class="hero">
            <div class="container">
                <div class="hero-lockup">
                    <img src="/images/bayworks-logo.png" alt="BayWorks" class="hero-logo"/>
                    <h1>"Software engineering where "<span class="accent-btc">"Bitcoin"</span>" meets "<span class="accent-ai">"distributed agents"</span></h1>
                </div>
                <p class="lede">
                    "BayWorks builds open, peer-to-peer infrastructure in Rust"
                </p>
                <div class="hero-actions">
                    <A href="/projects" attr:class="btn btn-primary">"See our projects"</A>
                    <A href="/contact" attr:class="btn btn-ghost">"Get in touch"</A>
                </div>
            </div>
        </section>

        <section class="section">
            <div class="container">
                <h2 class="section-title">"Featured project"</h2>
                <div class="card project-card kamiroh">
                    <div class="project-card-head">
                        <img src="/images/kamiroh-logo.png" alt="kamiroh" class="project-logo"/>
                        <span class="badge">"Active spike"</span>
                    </div>
                    <p>
                        "Peer actors, addressable by name and endpoint, that message each other — locally
                        or across the network — to drive agents. Built on Kameo actors and Iroh's QUIC
                        networking, with no central server required."
                    </p>
                    <div class="card-actions">
                        <a href="https://kamiroh.com" target="_blank" rel="noopener" class="btn btn-small">"kamiroh.com"</a>
                        <A href="/projects" attr:class="btn btn-small btn-ghost">"Learn more"</A>
                    </div>
                </div>
            </div>
        </section>
    }
}

#[component]
fn ProjectsPage() -> impl IntoView {
    view! {
        <Title text="Projects — BayWorks"/>
        <section class="section page-head">
            <div class="container">
                <h1>"Projects"</h1>
                <p class="lede">"Work in progress at BayWorks, developed in the open."</p>
            </div>
        </section>
        <section class="section">
            <div class="container">
                <article class="card project-card kamiroh">
                    <div class="project-card-head">
                        <img src="/images/kamiroh-logo.png" alt="kamiroh" class="project-logo"/>
                        <span class="badge">"Spike 2 in progress"</span>
                    </div>
                    <p>
                        "kamiroh enables peer-to-peer, actor-based communication across the internet —
                        without a central server. Named actors live at Iroh endpoints and hold
                        turn-taking conversations over QUIC, with deny-by-default, allowlist-based
                        security and cryptographic endpoint verification."
                    </p>
                    <h3>"How it's built"</h3>
                    <p>
                        "A workspace-based modular monolith in Rust, using a ports-and-adapters
                        architecture that separates core domain logic from the network. Three
                        interchangeable transports — in-memory, the Kameo actor runtime, and an Iroh
                        QUIC adapter — with hermetic and N0 network profiles, including NAT traversal
                        with hole-punched direct paths using only endpoint IDs."
                    </p>
                    <h3>"Developed through workshop spikes"</h3>
                    <p>
                        "kamiroh is evolving through a series of architectural spikes. The current
                        iteration, spike 2, makes timeouts and disconnects first-class: every
                        conversation surface takes finite, mandatory deadlines, a hung exchange fails
                        loudly on both sides' own clocks, and transports report peer death as concrete
                        evidence that immediately fails active exchanges while preserving the
                        underlying conversation."
                    </p>
                    <div class="card-actions">
                        <a href="https://kamiroh.com" target="_blank" rel="noopener" class="btn btn-small">"kamiroh.com"</a>
                        <a href="https://github.com/kamiroh-workshop-2/kamiroh" target="_blank" rel="noopener" class="btn btn-small btn-ghost">"Spike 2 workshop repo"</a>
                    </div>
                </article>

                <div class="card placeholder-card">
                    <h3>"More to come"</h3>
                    <p>"Further projects exploring the Bitcoin × AI nexus will appear here."</p>
                </div>
            </div>
        </section>
    }
}

#[component]
fn AboutPage() -> impl IntoView {
    view! {
        <Title text="About — BayWorks"/>
        <section class="section page-head">
            <div class="container">
                <h1>"About BayWorks"</h1>
            </div>
        </section>
        <section class="section">
            <div class="container prose">
                <p>
                    "BayWorks is the software engineering practice of Pacific Bay LLC. We build
                    systems software in Rust, with particular interest in peer-to-peer networking,
                    actor systems, and the ground where Bitcoin meets distributed agents — agents
                    need open protocols, verifiable identity, and money native to the internet."
                </p>
                <p>
                    "We develop in the open: our projects grow through public, testable architectural
                    spikes rather than big-bang releases, so the design rationale stays visible and
                    the code stays honest."
                </p>
            </div>
        </section>
    }
}

#[component]
fn ContactPage() -> impl IntoView {
    view! {
        <Title text="Contact — BayWorks"/>
        <section class="section page-head">
            <div class="container">
                <h1>"Contact"</h1>
                <p class="lede">"Interested in working together, or curious about a project? Say hello."</p>
            </div>
        </section>
        <section class="section">
            <div class="container">
                <div class="card contact-card">
                    <p>"Email is the best way to reach us:"</p>
                    <a class="btn btn-primary" href="mailto:casey@bayworks.ai">"casey@bayworks.ai"</a>
                </div>
            </div>
        </section>
    }
}

#[component]
fn NotFound() -> impl IntoView {
    view! {
        <Title text="Not found — BayWorks"/>
        <section class="section page-head">
            <div class="container">
                <h1>"Page not found"</h1>
                <p class="lede">"That page doesn't exist. "<A href="/">"Head back home."</A></p>
            </div>
        </section>
    }
}
