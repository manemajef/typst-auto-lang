#let _with-lang(it, lang) = [
  #set text(lang: lang)
  #it
]

#let force-lang(body, lang) = {
  show par: it => _with-lang(it, lang)
  show heading: it => _with-lang(it, lang)
  show list: it => _with-lang(it, lang)
  show enum: it => _with-lang(it, lang)
  _with-lang(body, lang)
}

#let rl(body, lang: "he") = force-lang(body, lang)
#let lr(body, lang: "en") = force-lang(body, lang)

#let _detect-by = state("auto-dir.detect-by", "auto")

#let auto-dir(
  hebrew-font: ("David CLM", "Libertinus Math"),
  english-font: ("New Computer Modern", "Libertinus Serif"),
  arab-font: "Libertinus Serif",
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
    "New Computer Modern",
  ))

  let plain(c) = {
    if type(c) == str { return c }
    let f = c.func()
    if f == math.equation or f == raw { return "" }
    let fields = c.fields()
    if "children" in fields { return fields.children.map(plain).join("") }
    if "body" in fields { return plain(fields.body) }
    if "text" in fields { return plain(fields.text) }
    ""
  }

  let detect-char(ch) = {
    if ch.matches(heb).len() > 0 { "he" }
    else if ch.matches(ara).len() > 0 { "ar" }
    else if ch.matches(lat).len() > 0 { "en" }
    else { none }
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
    if nh + na + nl == 0 { default-lang }
    else if nh + na > nl { if nh >= na { "he" } else { "ar" } }
    else { "en" }
  }

  let apply(it, source) = context {
    let by = _detect-by.get()
    let lang = if by == "first" { detect-first(source) } else { detect-auto(source) }
    _with-lang(it, lang)
  }

  show par: it => apply(it, it.body)
  show heading: it => apply(it, it.body)
  show list: it => apply(it, it)
  show enum: it => apply(it, it)

  [#_detect-by.update(_ => detect-by) #doc]
}
