/// State controlling the detection algorithm mid-document.
/// Values: `"auto"` (majority wins) or `"first"` (first script char wins).
#let detect-by-state = state("auto-dir.detect-by", "auto")

/// State for section-level language override.
/// `none` means auto-detect; `"he"`, `"ar"`, or `"en"` forces that language.
#let lang-state = state("auto-dir.lang", none)

/// Force all subsequent blocks to Hebrew until `#setauto`.
#let sethebrew = lang-state.update(_ => "he")

/// Force all subsequent blocks to Arabic until `#setauto`.
#let setarabic = lang-state.update(_ => "ar")

/// Force all subsequent blocks to English until `#setauto`.
#let setenglish = lang-state.update(_ => "en")

/// Return to automatic language detection.
#let setauto = lang-state.update(_ => none)

/// Force a specific language on a content block, overriding auto-detection.
/// Affects paragraphs, headings, lists, and enums within `body`.
///
/// - lang (string): A BCP 47 language code, e.g. `"he"`, `"ar"`, `"fa"`, `"en"`.
/// - body (content): The content to apply the language to.
/// -> content
#let force-lang(lang, body) = {
  let dir = if lang == "en" { ltr } else { rtl }
  show par: it => [#set text(lang: lang, dir: dir); #it]
  show heading: it => [#set text(lang: lang, dir: dir); #it]
  show list: it => [#set text(lang: lang, dir: dir); #it]
  show enum: it => [#set text(lang: lang, dir: dir); #it]
  [#set text(lang: lang, dir: dir); #body]
}

/// Force right-to-left language on a content block.
///
/// - body (content): The content to render RTL.
/// - lang (string): Language code, defaults to `"he"` (Hebrew).
/// -> content
#let rl(body, lang: "he") = force-lang(lang, body)

/// Force left-to-right language on a content block.
///
/// - body (content): The content to render LTR.
/// - lang (string): Language code, defaults to `"en"` (English).
/// -> content
#let lr(body, lang: "en") = force-lang(lang, body)

/// Invisible hebrew/english/arabic character — use to bias detection toward lang
#let hechar = hide[א]
#let archar = hide[ا]
#let enchar = hide[a]

/// Apply automatic language and direction detection to the document.
///
/// Wraps the document with show rules that detect the dominant script in each
/// paragraph, heading, list, and enum, then sets `text(lang:)` accordingly so
/// Typst can apply correct directionality, shaping, and hyphenation.
///
/// - hebrew-font (string, array): Font(s) used for Hebrew text.
/// - english-font (string, array): Font(s) used for English text.
/// - arab-font (string, array): Font(s) used for Arabic text.
/// - detect-by (string): Detection algorithm — `"auto"` (majority of chars)
///   or `"first"` (first recognised script char, like Apple Notes).
/// - default-lang (string): Fallback language when no script is detected.
/// - doc (content): The document body (passed automatically via `show:`).
/// -> content
#let auto-dir(
  hebrew-font: ("David CLM", "Libertinus Math"),
  english-font: ("New Computer Modern", "Libertinus Serif"),
  arab-font: "Libertinus Serif",
  base-font: "New Computer Modern",
  detect-by: "auto",
  default-lang: "en",
  doc,
) = {
  let heb = regex("\p{Hebrew}")
  let ara = regex("\p{Arabic}")
  let lat = regex("\p{Latin}")

  let with-covers(fonts, rgx) = if type(fonts) == str {
    ((name: fonts, covers: rgx),)
  } else {
    fonts.map(f => (name: f, covers: rgx))
  }

  set text(font: (
    ..with-covers(arab-font, ara),
    ..with-covers(hebrew-font, heb),
    ..with-covers(english-font, lat),
    base-font,
  ))

  let plain(c) = {
    if type(c) == str { return c }
    let f = c.func()
    if f == math.equation or f == raw { return "" }
    let fields = c.fields()
    if "children" in fields { return fields.children.map(plain).join("") }
    if "child" in fields { return plain(fields.child) }
    if "body" in fields { return plain(fields.body) }
    if "text" in fields { return plain(fields.text) }
    ""
  }

  let detect-char(ch) = {
    if ch.matches(heb).len() > 0 { "he" } else if ch.matches(ara).len() > 0 { "ar" } else if ch.matches(lat).len() > 0 {
      "en"
    } else { none }
  }

  let detect-first(c) = {
    for ch in plain(c).clusters() {
      let lang = detect-char(ch)
      if lang != none { return lang }
    }
    default-lang
  }

  let detect-auto(c) = {
    let txt = plain(c)
    let nh = txt.matches(heb).len()
    let na = txt.matches(ara).len()
    let nl = txt.matches(lat).len()
    if nh + na + nl == 0 { default-lang } else if nh + na > nl { if nh >= na { "he" } else { "ar" } } else { "en" }
  }

  let apply(it, source) = context {
    let lang = if lang-state.get() != none {
      lang-state.get()
    } else if detect-by-state.get() == "first" {
      detect-first(source)
    } else {
      detect-auto(source)
    }
    let dir = if lang == "en" { ltr } else { rtl }
    [#set text(lang: lang, dir: dir); #it]
  }

  show par: it => apply(it, it.body)
  show heading: it => apply(it, it.body)
  show list: it => apply(it, it)
  show enum: it => apply(it, it)

  [#detect-by-state.update(_ => detect-by) #doc]
}
