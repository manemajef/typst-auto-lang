// auto-lang.typ
//
// Per-paragraph automatic language detection.
// Installs a show rule for `par` that inspects the natural-language text of
// each block (recursing into nested bodies, ignoring math equations and
// raw/code blocks) and applies `#set text(lang: "he")` when Hebrew dominates.

// ---------------------------------------------------------------------------
// Internal: recursive plain-text extractor
#let _extract-text(body) = {
  if type(body) != content { return "" }
  let f = body.func()
  // Hard-skip: math and raw/code produce no natural-language signal
  if f == math.equation or f == raw { return "" }
  // Leaf: a real text node
  if body.has("text") { return body.text }
  // Sequence / list / etc. — multiple children
  if body.has("children") {
    return body.children.map(_extract-text).join("")
  }
  // Single-body wrappers: strong, emph, link, par body, heading body, …
  if body.has("body") {
    let inner = body.fields().at("body")
    // Guard: the field might be a closure (e.g. inside a `context` block)
    if type(inner) == content { return _extract-text(inner) }
  }
  ""
}


#let lang-regex = (
  en: regex("\p{Latin}"),
  he: regex("\p{Hebrew}"),
  ar: regex("\p{Arabic}"),
)

// get fonts array with regex match
#let get-fonts-array(fonts, lang) = {
  if type(fonts) == str {
    ((name: fonts, covers: lang-regex.at(lang)),)
  } else if type(fonts) == array {
    fonts.map(f => (name: f, covers: lang-regex.at(lang)))
  } else {
    fonts
  }
}

// State tracking current language — used as fallback in "first" mode
// when a block contains no letter characters.
#let curr-lang = state("curr-lang", "en")

// Internal: walk content and return the script of the FIRST letter found.
// Returns "he", "en", or none (no letter — skips math, raw, numbers, symbols).
#let _first-lang-char(body) = {
  if type(body) != content { return none }
  let f = body.func()
  if f == math.equation or f == raw { return none }
  if body.has("text") {
    for char in body.text.clusters() {
      if char.matches(regex("\p{Hebrew}")).len() > 0 { return "he" }
      if char.matches(regex("\p{Latin}")).len() > 0 { return "en" }
    }
    return none
  }
  if body.has("children") {
    for child in body.children {
      let r = _first-lang-char(child)
      if r != none { return r }
    }
  }
  if body.has("body") {
    let inner = body.fields().at("body")
    if type(inner) == content { return _first-lang-char(inner) }
  }
  none
}

// flatten array to body
#let list2body(ls) = ls.children.map(c => c.body).join()

// ---------------------------------------------------------------------------
// DEFAULT
#let default_fonts = (
  en: ("New Computer Modern", "Latin Modern Roman", "Times New Roman"),
  he: ("David CLM", "Times New Roman", "Libertinus Math"),
)
// ---------------------------------------------------------------------------
// Public API

/// Detect language from a content block.
/// Returns "he" when Hebrew letter count strictly exceeds Latin letter count,
/// "en" otherwise (including when there are no letters at all).
/// Ignores math equations and raw/code blocks.
#let detect-lang(detect-by: "freq", body) = {
  if detect-by == "first" {
    return _first-lang-char(body) // "he", "en", or none
  }
  let s = _extract-text(body)
  let heb = s.matches(regex("\p{Hebrew}")).len()
  let lat = s.matches(regex("\p{Latin}")).len()
  if heb > lat { "he" } else { "en" }
}

/// Force-Hebrew span — bypasses auto-detection for its content.
#let he(body) = [#set text(lang: "he", dir: rtl); #body]

/// Force-English span — bypasses auto-detection for its content.
#let en(body) = [#set text(lang: "en", dir: ltr); #body]

/// Document wrapper.  Apply once at the top of your entry file: \n #show: setup
#let lang-setup(
  english-fonts: default_fonts.en,
  hebrew-fonts: default_fonts.he,
  fallback-font: "New Computer Modern",
  detect-by: "freq",
  body,
) = {
  let fonts = (..get-fonts-array(english-fonts, "en"), ..get-fonts-array(hebrew-fonts, "he"), fallback-font)
  set text(font: fonts)

  // Apply language to `it` based on `detected` ("he", "en", or none).
  // none only arises in "first" mode — falls back to curr-lang state.
  let apply-lang(it, detected) = {
    if detected == "he" [
      #curr-lang.update("he")
      #set text(lang: "he")
      #it
    ] else if detected == "en" [
      #curr-lang.update("en")
      #it
    ] else {
      context if curr-lang.get() == "he" [
        #set text(lang: "he")
        #it
      ] else [#it]
    }
  }

  show par: it => apply-lang(it, detect-lang(detect-by: detect-by, it.body))
  show list: it => apply-lang(it, detect-lang(detect-by: detect-by, list2body(it)))
  show enum: it => apply-lang(it, detect-lang(detect-by: detect-by, list2body(it)))
  show heading: it => apply-lang(it, detect-lang(detect-by: detect-by, it.body))

  body
}
