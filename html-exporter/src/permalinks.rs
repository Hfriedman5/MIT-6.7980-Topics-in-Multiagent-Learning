//! Add shareable URLs without replacing Typst's native cross-reference targets.

use scraper::{ElementRef, Html, Node, Selector};
use std::collections::HashMap;

use crate::{element_text, escape_attr, heading_text_from_html, heading_title_html, slugify};

pub fn add_permalinks(body: &str) -> (String, HashMap<String, String>) {
    let mut dom = Html::parse_fragment(body);
    let targets = Selector::parse(
        ".notes-heading, section.env.statement, figure.rendered-figure, .equation-line:has(> .eqno)",
    )
    .unwrap();
    let all_ids = Selector::parse("[id]").unwrap();
    let mut ids: HashMap<_, _> = dom
        .select(&all_ids)
        .map(|element| (element.value().id().unwrap().to_owned(), element.id()))
        .collect();
    // Reserve authored labels before assigning fallbacks, regardless of order.
    let labels: HashMap<_, _> = dom
        .select(&targets)
        .filter_map(|element| {
            element
                .value()
                .attr("data-label")
                .map(|label| (label_id(label), element.id()))
        })
        .collect();
    let mut heading_ids = HashMap::new();
    let mut changes = Vec::new();
    let mut counts: HashMap<String, usize> = HashMap::new();

    for target in dom.select(&targets) {
        if child(&target, ".permalink").is_some() {
            continue;
        }
        let (kind, description, fallback, host) = if target
            .value()
            .has_class("notes-heading", scraper::CaseSensitivity::CaseSensitive)
        {
            let title = heading_text_from_html(&heading_title_html(&target));
            let description = format!("section: {title}");
            ("section".to_owned(), description, slugify(&title), target)
        } else if target.value().name() == "section" {
            let kind = child(&target, ".env-kind")
                .map(|el| element_text(&el))
                .unwrap_or_else(|| "Statement".to_owned());
            let number = child(&target, ".env-number")
                .map(|el| el.text().collect::<String>())
                .unwrap_or_default();
            let description = format!("{kind} {number}").trim().to_owned();
            (
                slugify(&kind),
                description.clone(),
                slugify(&description),
                target,
            )
        } else if target.value().name() == "figure" {
            let kind = target
                .value()
                .attr("data-figure-kind")
                .unwrap_or("figure")
                .to_owned();
            let count = counts.entry(kind.clone()).or_default();
            *count += 1;
            let number = target
                .value()
                .attr("data-figure-number")
                .filter(|number| !number.is_empty())
                .map(str::to_owned)
                .unwrap_or_else(|| count.to_string());
            let description = format!("{kind} {number}");
            let host = if kind == "algorithm" {
                child(&target, ".algorithm .env-title").unwrap_or(target)
            } else {
                child(&target, ".figcaption-label")
                    .or_else(|| child(&target, "figcaption"))
                    .unwrap_or(target)
            };
            (kind, description.clone(), slugify(&description), host)
        } else {
            let host = child(&target, ".eqno").unwrap();
            let description = format!("equation {}", element_text(&host));
            (
                "equation".to_owned(),
                description.clone(),
                slugify(&description),
                host,
            )
        };

        let base = target
            .value()
            .attr("data-label")
            .filter(|label| !label.is_empty())
            .map(label_id)
            .unwrap_or(fallback);
        let mut id = base.clone();
        let mut suffix = 2;
        loop {
            let existing_here = ids.get(&id).is_none_or(|existing| {
                target.descendants().any(|node| node.id() == *existing)
                    || target.ancestors().any(|node| node.id() == *existing)
            });
            let reserved_here = labels.get(&id).is_none_or(|owner| *owner == target.id());
            if existing_here && reserved_here {
                break;
            }
            id = format!("{base}-{suffix}");
            suffix += 1;
        }

        if kind == "section" {
            if let Some(old_id) = target.value().id() {
                heading_ids.insert(old_id.to_owned(), id.clone());
            }
        }
        // Aligned equation rows use display:contents. Their number provides a
        // real box for scrolling; other aliases sit at the top of the block.
        let anchor_host = if kind == "equation" { host } else { target };
        // Native line anchors are hidden metadata spans. Relocate them to a
        // visible box too, so both old and new URLs work without JavaScript.
        let native_anchors: Vec<_> = if kind == "equation" {
            target
                .select(&Selector::parse(".equation-anchor[id]").unwrap())
                .map(|anchor| (anchor.id(), anchor_element(anchor.value().id().unwrap())))
                .collect()
        } else {
            Vec::new()
        };
        let alias = if ids.contains_key(&id) {
            None
        } else {
            ids.insert(id.clone(), target.id());
            Some(anchor_element(&id))
        };
        let class =
            if kind == "section" || kind == "algorithm" || target.value().name() == "section" {
                "permalink permalink-gutter"
            } else if host.id() == target.id() {
                "permalink permalink-corner"
            } else {
                "permalink"
            };
        let link = empty_element(&format!(
            "<a class=\"{class}\" href=\"#{}\" aria-label=\"Permalink to {}\" title=\"Permalink to {}\"></a>",
            fragment_id(&id), escape_attr(&description), escape_attr(&description)
        ));
        changes.push((host.id(), anchor_host.id(), native_anchors, alias, link));
    }

    for (host, anchor_host, native_anchors, alias, link) in changes {
        for (node_id, element) in native_anchors {
            *dom.tree.get_mut(node_id).unwrap().value() = element;
            dom.tree.get_mut(anchor_host).unwrap().prepend_id(node_id);
        }
        if let Some(alias) = alias {
            dom.tree.get_mut(anchor_host).unwrap().prepend(alias);
        }
        dom.tree.get_mut(host).unwrap().append(link);
    }
    (dom.root_element().inner_html(), heading_ids)
}

fn child<'a>(element: &ElementRef<'a>, selector: &str) -> Option<ElementRef<'a>> {
    element.select(&Selector::parse(selector).unwrap()).next()
}

fn empty_element(html: &str) -> Node {
    Node::Element(
        Html::parse_fragment(html)
            .root_element()
            .child_elements()
            .next()
            .unwrap()
            .value()
            .clone(),
    )
}

fn anchor_element(id: &str) -> Node {
    empty_element(&format!(
        "<span class=\"permalink-anchor\" id=\"{}\"></span>",
        escape_attr(id)
    ))
}

fn label_id(label: &str) -> String {
    // HTML IDs cannot contain whitespace; all other authored characters stay.
    label.split_whitespace().collect::<Vec<_>>().join("-")
}

// Percent-encode UTF-8 labels for an actual URL fragment, not just HTML attrs.
pub(crate) fn fragment_id(id: &str) -> String {
    let mut fragment = String::new();
    for byte in id.bytes() {
        if byte.is_ascii_alphanumeric() || b"-._~:".contains(&byte) {
            fragment.push(byte as char);
        } else {
            use std::fmt::Write;
            write!(fragment, "%{byte:02X}").unwrap();
        }
    }
    fragment
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labeled_targets_keep_native_ids_and_links_and_expose_authored_labels() {
        let body = r##"<h2 class="notes-heading" id="loc-1" data-label="sec:idea" data-number="8.2"><span class="secno">8.2</span>An <em>idea</em> <a href="#loc-2">Theorem 1</a></h2>
<section class="env statement" id="loc-2" data-label="thm:idea"><span id="theorem-l8-1"></span><p class="env-heading"><span class="env-title"><strong class="env-kind">Theorem</strong><strong class="env-number">L8.1</strong></span></p><div class="env-body">Proof.</div></section>
<figure class="rendered-figure" id="loc-3" data-label="tab:notation" data-figure-kind="table" data-figure-number="1"><table><tr><td>A</td></tr></table><figcaption><span class="figcaption-label">Table 1.</span>Notation.</figcaption></figure>
<figure class="rendered-figure" data-label="algo:cfr" data-figure-kind="algorithm" data-figure-number="2"><div class="figure-body"><section class="env algorithm"><p class="env-title">CFR</p></section></div></figure>"##;
        let (html, headings) = add_permalinks(body);
        let dom = Html::parse_fragment(&html);
        let links: Vec<_> = dom
            .select(&Selector::parse("a.permalink").unwrap())
            .collect();
        assert_eq!(links.len(), 4);
        assert_eq!(dom.select(&Selector::parse(".notes-heading > .permalink-gutter, .env.statement > .permalink-gutter, .algorithm .env-title > .permalink-gutter").unwrap()).count(), 3);
        assert_eq!(headings["loc-1"], "sec:idea");
        for id in [
            "loc-1",
            "loc-2",
            "loc-3",
            "theorem-l8-1",
            "sec:idea",
            "thm:idea",
            "tab:notation",
            "algo:cfr",
        ] {
            assert_eq!(
                dom.select(&Selector::parse("[id]").unwrap())
                    .filter(|el| el.value().id() == Some(id))
                    .count(),
                1,
                "{id}"
            );
        }
        assert!(html.contains(r##"href="#loc-2">Theorem 1</a>"##));
        assert!(html.contains("<em>idea</em>"));
        assert_eq!(
            dom.select(
                &Selector::parse(
                    ".figcaption-label > .permalink, .algorithm .env-title > .permalink"
                )
                .unwrap()
            )
            .count(),
            2
        );
        assert!(links
            .iter()
            .all(|link| link.value().attr("aria-label").is_some()));
        assert_eq!(add_permalinks(&html).0, html);
    }

    #[test]
    fn fallback_ids_are_unique_and_do_not_steal_authored_labels() {
        let body = r#"<h2 class="notes-heading">Overview</h2><h2 class="notes-heading">Overview</h2><h2 class="notes-heading" data-label="overview">Other title</h2><figure class="rendered-figure" data-figure-kind="table" data-figure-number="1"></figure><figure class="rendered-figure" data-figure-kind="table" data-figure-number="1"></figure>"#;
        let (html, _) = add_permalinks(body);
        let dom = Html::parse_fragment(&html);
        let links: Vec<_> = dom
            .select(&Selector::parse("a.permalink").unwrap())
            .map(|el| el.value().attr("href").unwrap())
            .collect();
        assert_eq!(
            links,
            [
                "#overview-2",
                "#overview-3",
                "#overview",
                "#table-1",
                "#table-1-2"
            ]
        );
    }

    #[test]
    fn headings_are_stable_when_numbers_change_and_labels_are_url_encoded() {
        let body = r#"<h2 class="notes-heading" id="loc-5" data-number="8.1"><span class="secno">8.1</span>Overview</h2><h2 class="notes-heading" data-label="sec:α&amp;&quot;">Unicode</h2>"#;
        let (html, ids) = add_permalinks(body);
        let (_, renumbered) = add_permalinks(&body.replace("8.1", "9.3"));
        assert_eq!(ids, renumbered);
        assert_eq!(ids["loc-5"], "overview");
        assert!(html.contains("#sec:%CE%B1%26%22"));
        assert!(html.contains("sec:α&amp;&quot;"));
    }

    #[test]
    fn numbered_equations_link_at_the_number_without_altering_math() {
        let body = r#"<figure class="equation equation-aligned"><div class="equation-line" data-label="eq:sum"><span class="equation-align-left" data-typst-math="[a]">a</span><span class="equation-align-right">= b</span><span class="eqno">(1)</span><span class="equation-anchor" id="loc-8" hidden></span></div><div class="equation-line"><span class="eqno">(2)</span></div><div class="equation-line">unnumbered</div></figure>"#;
        let (html, _) = add_permalinks(body);
        let dom = Html::parse_fragment(&html);
        assert_eq!(
            dom.select(&Selector::parse(".eqno > .permalink").unwrap())
                .count(),
            2
        );
        assert_eq!(
            dom.select(&Selector::parse(".eqno > .permalink-anchor").unwrap())
                .count(),
            3
        );
        assert!(html.contains("#eq:sum"));
        assert!(html.contains("#equation-2"));
        assert!(
            html.contains(r#"<span class="equation-align-left" data-typst-math="[a]">a</span>"#)
        );
        assert!(html.contains("loc-8"));
        assert!(!html.contains("hidden"));
    }

    #[test]
    fn whitespace_labels_become_valid_ids_without_colliding() {
        let (html, _) = add_permalinks(
            r#"<h2 class="notes-heading" data-label="sec:an idea">One</h2><h2 class="notes-heading" data-label="sec:an-idea">Two</h2>"#,
        );
        let dom = Html::parse_fragment(&html);
        let ids: Vec<_> = dom
            .select(&Selector::parse("[id]").unwrap())
            .map(|el| el.value().id().unwrap())
            .collect();
        assert_eq!(ids, ["sec:an-idea-2", "sec:an-idea"]);
    }
}
