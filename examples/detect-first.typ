#import "../lib.typ": *
#show: auto-dir.with(detect-by: "first")

= detect-by: "first"

With `detect-by: "first"`, the *first* recognised script character sets the
direction — like Apple Notes, WhatsApp, and Obsidian.

Use the `#enchar`, `#archar` or `#hechar` to add invisble lang char. for example:



#archar this paragraph starts with english,

= A הרבה עברית כתובה פה

Starts with "A" (Latin) → LTR, even though most characters are Hebrew.

= הרבה עברית כתובה פה with some English

Starts with "ה" (Hebrew) → RTL, even though it ends in English.

= العنوان يبدأ بالعربية ثم some English

Starts with Arabic → RTL.

#show: auto-dir.with(detect-by: "auto")

= Switch back to majority detection

= A הרבה עברית כתובה פה

Now this is RTL — Hebrew characters outnumber Latin ones.

