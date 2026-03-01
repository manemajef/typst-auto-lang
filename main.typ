#import "auto-lang.typ": *
#show: lang-setup.with(detect-by: "first")

= שלום
זה פסקה שאמורה להיות בעברית

this is ment to be in enlgish

== headings should be auto detecred

== כותרות אמורות להיות מזוהות

$f(x) = x^2$ עברית

- רשימה
- האם
- זה עובד ?

\

= a שלום כלבה

#show: lang-setup.with(detect-by: "freq")

= a שלום כלבה

Here, The algorithm is Smarter --- אם רוב הפסקה תהיה כתובה בעברית, אז הכיוון יהיה `RTL` ,



