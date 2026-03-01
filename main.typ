#import "lib.typ": *
#show: auto-dir.with(detect-by: "auto")


= Auto--dir
== Overview
This is a simple lib that auto detects language, and ment for _Arabic_ and _Hebrew_ scripts which requires manual lang decleration for _RTL_ direction.

== דוגמא
אם כותבים פסקה בעברית, אז אוטומטית זה נהיה RTL

also, $f(x) = x^2$  גם אם מתחילים באנגלית, אבל הרוב עברית -- זה עדיין עובד.



== `detect-by: "first"`
#show: auto-dir.with(detect-by: "first")
If you want the detection algorithm to work like in apple notes etc (detected by first char), you can set: `show: auto-dir.with(detect-by = "first")`

= A הרבה עברית
