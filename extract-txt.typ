#lorem(20) $f(x)$ and #lorem(10)

שלום עולם מה קורה? #lorem(20)

#let get-text(b) = {
  if type(b) != content { return " " }
  let f = b.func()
  if f == math.equation or f == raw { return " " }
  if b.has("text") { return b.text }
  if b.has("children") { return b.children.map(get-text).join(" ") }
}



#show par: set text(blue)
