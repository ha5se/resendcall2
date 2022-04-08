# RE-SENDING UPDATED CALL IN THE "TU" VERIFICATION

In "run" mode, when we are responding somebody to our CQ contest call, we
are the first to send a report to the one calling us (e.g. __W1XYZ 599001__ ).
In case no correction is needed, we would like to simply acknowledge the QSO
with a pure __TU__.
However, in case we incorrectly copied his call for the first time,
we usually want to acknowledge the updated (corrected) call as well, like
__W1XYZ TU__.

While it is quite obvious to resend the full updated (corrected) call as
verification, still most contesters prefer to only send the changed part,
prefix or suffix or something obvious verification. However, to select
what part to repeat, is the very point where tastes very much differ.

Note that known "stupid" pseudo-suffixes as __/QRP__, __/SOTA__, __/YOTA__
that are not part of the official call sign, will just be ignored by this
routine. Instead, only the official callsign will be checked for correction.

Also note that it is very difficult to define an algorhytm what to re-send
when the updated call is shorter than the previous estimation. Examples are
__WE5AA__ --> __W5AA__, __EA1AB__ --> __A1AB__, or __W1CDE__ --> __W1CD__.
The simplest idea is to send the surrounding matched characters on both ends,
e.g. __W5__ in the first example, or __D__ for the last if __SEND_SHORTEST__.



## Terms used within this chapter

Instead of using the natural terms "prefix" or "suffix", rather using the term
"segment" here, to allow to similarly categorize appended parts using "/".

| HA5/W1AW/P	| full call			|
|---------------|-------------------------------|
| HA5/		| full segment			|
| HA5		| base segment, truncated segm.	|
| /		| truncated segment		|
|		|				|
| W1		| full segment, base segment	|
| W		| truncated segment		|
| 1		| truncated segment		|
|		|				|
| AW		| full segment, base segment,	|
|		| truncated segment		|
| /P		| full segment			|
| /		| truncated segment		|
| P		| base segment			|
|---------------|-------------------------------|
| S521PMC	| full call			|
|---------------|-------------------------------|
| S521		| full segment, base segment	|
| S5		| truncated segment		|
| 21		| truncated segment		|
|		|				|
| PMC		| full segment, base segment,	|
|		| truncated segment		|
|---------------|-------------------------------|

When splitting the prefix into truncated segments (country and a numerical
district/area), no DXCC table will be used. Instead, to make the logic
simple, a single character country will only be allowed for __F, G, I, K, M,
N, R, U__ and __W__. All other countries should be at least two character
long. In most cases this is true. while for few special rare countries,
like __CE0X, CE0Y, CE0Z__ etc.  this is not true, but it would not be a big
deal, anyway.

## Configuration parameter syntax

__TU_RESEND_UPDATED_CALL__=function[,modifiers...]

  Specifies what you expect to send in the final "TU" message in case of
  updated (corrected) call.



## Configuration Parameter options, main function



#### { NONE | SEND_FULL | SEND_SHORTEST | SEND_FULL_SEGMENTS |
####   | SEND_BASE_SEGMENTS | SEND_TRUNCATED_SEGMENTS }

  Specifies the main behaviour (function).
  These are mutually exclusive options.



#### { AVANTGARDE | DINOSAUR | CONSERVATIVE | RELAXED }

  These are intuitive (friendly, shorthand, alias) names for the above
  main behaviour with some additional optional modifiers, still mutually
  exclusive with the above main function keywords.



__NONE__

  This is a main function definition, \
  No automatic full or partial repeat for updated call. You probably want to
  resend using an external keyer device, or perhaps using the Ctrl+K window.



__FULL__

  This is a main function definition.
  In case of updated (corrected) call, repeat the full callsign. Probably
  this used to be the normal (natural) verification at some ancient time.



__SEND_MANUAL_POPUP__

  This is a main function definition.
  In case of updated (corrected) call, automatically display the ctrl+k
  pop-up window, allowing full manual control on the final TU message.
  You are expected to type in the changed part of the call according
  to your liking.



__SEND_SHORTEST__

  This is a main function definition, ignoring "natural" segment boundaries,
  only re-send the changed part, from the first through the last changed
  characters or numbers. \
  This perhaps is a somewhat less useful function... \



__SEND_FULL_SEGMENTS__

  This is a main function definition. \
  Using segments as defined above, try to only re-send changed
  full segments, still obeying to additional modifiers. \
  Remember that the base is to re-send the full callsign, that we try to
  occasionally shorten upon these well-defined rules.

  This is a rather strict function, meaning that the full updated segment(s),
  including eventual leading and trailing __"/"__ characters will be sent in
  the final message. \
  E.g. __HA5/__ or __/MM__.



__SEND_BASE_SEGMENTS__

  This is a main function definition. \
  Using segments as defined above, try to only re-send changed
  base segments, still obeying to additional modifiers. \
  Remember that the base is to re-send the full callsign, that we try to
  occasionally shorten upon these well-defined rules. \
  This function means that instead of the changed full segment(s), it is
  enough to just send the base segment(s), without leading or trailing
  __"/"__ in the final "TU" message,
  e.g. __HA5__  instead of the default full segment __HA5/__. \
  However, still __W/__ will be repeated e.g. for ` REQ_GT1_CHARS_SENT`.



__SEND_TRUNCATED_SEGMENTS__

  This is a main function definition. \
  Using segments as the above definitions, try to only re-send changed
  truncated (partial) segments, still obeying to additional modifiers. \
  E.g. when  correcting, in contrast to the default full or the base segment,
  correcting __WD6A__ to __WB6A__, it is then enough to re-send __WB__
  instead of the full/base segment __WB6__. \
  However, still __W/__ or __W1__ will be sent e.g. for ` REQ_GT1_CHARS_SENT`.



__AVANTGARDE__

  This is a main function definition, using an intuitive (friendly, shorthand,
  alias) name for the following parameter combination:
  ```
  SEND_SHORTEST,REQ_GT1_CHARS_SENT
  ```



__DINOSAUR__

  This is a main function definition, using an intuitive (friendly, shorthand,
  alias) name for the following parameter combination:
  ```
  SEND_FULL_SEGMENTS,REQ_GT1_CHARS_SENT,REQ_GT1_CHARS_SPARED,REQ_MATCHED_CHAR
  ```



__CONSERVATIVE__

  This is a main function definition, using an intuitive (friendly, shorthand,
  alias) name for the following parameter combination:
  ```
  SEND_BASE_SEGMENTS,REQ_GT1_CHARS_SENT,REQ_GT1_CHARS_SPARED,REQ_MATCHED_CHAR
  ```



__MODERATE__

  This is a main function definition, using an intuitive (friendly, shorthand,
  alias) name for the following parameter combination:
  ```
  SEND_TRUNCATED_SEGMENTS,REQ_GT1_CHARS_SENT,REQ_MATCHED_CHAR
  ```



__RELAXED__

- This is a main function definition, using an intuitive (friendly, shorthand,
  alias) name for the following parameter combination:
  ```
  SEND_TRUNCATED_SEGMENTS,REQ_GT1_CHARS_SENT
  ```



## Configuration Parameter options



The following options may be combined. Note, however, that not each
combination will be meaningful for every function... Some options may
implicitly also imply others, while some other options may have inconsistent
counterparts. For example, some options would not have practical use with
` SEND_SHORTEST`.



__FULL_FOR_GT1_CHAR_UPD__

  This is an optional, however very strict modifier. This means to always
  re-send full call in the final "TU" message when more than one characters
  updated.



__FULL_FOR_GT1_SEGM_UPD__

  This is an optional, strict while somewhat milder modifier than
  ` FULL_FOR_GT1_CHAR_UPD`. This means to always re-send full call in the
  final "TU" message when more than one segment updated. This is meant to
  help when first you only received a partial call while listening to many,
  e.g. first only copying __HA4C__, then the full call __HA5CQZ__ should be
  re-sent instead of partial __5CQZ__, although only updated two characters.



__FULL_FOR_SLASH__

  This is an optional, strict however rarely hit modifier. This means
  to always re-send the full call in the "final TU" message when a slash
  __"/"__ is present, in order  to spare ambigousity in segments, since
  no simple and bullet-proof prefix/suffix logic can be implemented if
  slash is present.



__REQ_GT1_CHARS_SENT__

  This is an optional, however probably one of the most useful modifiers.
  In case an updated segment is a single character long, e.g. correcting
  __G6C__ to __G6R__, then I only expect few fellows want to acknowledge
  the correction with a single __"R"__. Instead, depending on other
  modifiers, at least __6R__ or __G6R__ should be sent in the "TU" message.

  For ` SEND_SHORTEST `, this means that if only updating a single
  character, then it must be expanded to two characters. Since segments are
  irrelevant in this function, the rules are as follows, respective to the
  only changed character: (first hit wins):
  - use adjacent slash __"/"__ to the right, or to the left
  - use adjacent number __[0-9]__ to the right, or to the left
  - use the character to the right, or to the left.

  For ` SEND_*_SEGMENTS ` functions, in case when the truncated remaining
  changed segment contains only a single-character, then lesser truncated
  combined segment(s) should be used, or even an additional non-changed
  adjacent truncated segment must be included as well. \
  For such  expansion, the following rules apply (first hit wins):
  - expand the truncated segment towards full segment,
  - include an adjacent (partial) segment, the shorter one if available on
    both to the left and to the right end.

  Of course, other modifiers still apply.



__REQ_MATCHED_CHAR__

  This is an optional modifier, meaning that the final returned part should
  contain at least one character that is also present in the corresponig
  part of the previously received call. Otherwise, a longer string should
  be re-sent, using the same expanding logic as for ` REQ_GT1_CHARS_SENT `. \
  Using this option, when correcting __HA5__ or __HA5XY__ to __HA5SE__, then
  __5SE__ will be resent in place of __SE__. On the other side, when
  correcting __HA5S__ to __HA5SE__, then the shortest __SE__ will be re-sent,
  independent of this option.



__REQ_GT1_CHARS_SPARED__

  This is an optional modifier. This means that the intended returned partial
  call should not be used if only sparing a single character, instead, the
  full updated call must be sent. \
  That is, for ` SEND_TRUNCATED_SEGMENTS ` with this option, when correcting
  __W1VYZ__ to __W2XYZ__, truncated __2XYZ__ is not enough here because only
  sparing the single __W__ comparing to the full call, thus finally still
  send full __W2XYZ__.



__USE_CW_WEIGHT__

  This is an optional modifier. In order to satisfy other options, like
  ` REQ_GT1_CHARS_SENT ` or ` REQ_MATCHED_CHAR `, it may be required to add
  an unchanged adjacent extra segment or character to the changed part,
  either on the left or on the right side.

  If adjacent unchanged parts are available on both sides, then the default
  preference is upon character signifance (__/__ over   numeric over
  alphabetic).

  However, when using this option, then instead of selecting the more
  significant character (__/__ over numeric over alphabetic),  rather use
  the shorter CW keying length.

  For example, without this option, when correcting __9A2XY__ to __9K2XY__,
  then both __9K__ and __K2__ would be a valid default selection.
  for both ` RELAXED ` and ` AVANTGARDE `. However, using this option,
  __K2__ will be preferred since it needs less CW keying time to send.

  Another example, for ` AVANTGARDE `, when correcting __HA5SI/P__ to
  __HA5SE/P__, when expanding to two characters, the default answer would be
  __E/__ since __/__ is more meaningful than __S__, while using CW weights
  the answer will be __SE__ since __S__ needs less CW keying time to send.
  Note that in this example, for ` RELAXED `, __SE__ will always be selected
  due to segment oriented logic.



## Examples

In the following table, instead of the long options, we use here the
following shortened options (only for this example!!!):
- opt1C  ` REQ_GT1_CHARS_SENT `
- optMA  ` REQ_MATCHED_CHAR `
- optSP  ` REQ_GT1_CHARS_SPARED `

For ` SEND_TRUNCATED_SEGMENTS `, the difference between some options is:

| wrong	| updat	| opt1C	| optMA	| optSP	| send	|
|-------|-------|-------|-------|-------|-------|
| G6N	| G6R	|	|	|	| R	|
|	|	| X	|	|	| 6R	|
|	|	|	| X	|	| 6R	|
|	|	|	|	| X	| R	|
|	|	| X	| X	|	| 6R	|
|	|	| X	| X	| X	| G6R	|
| HA5IE	| HA5SE	|	|	|	| SE	|
|	|	| X	|	|	| SE	|
|	|	|	| X	|	| SE	|
|	|	|	|	| X	| SE	|
|	|	| X	| X	|	| SE	|
|	|	| X	| X	| X	| SE	|
| HA5II	| HA5SE	|	|	|	| SE	|
|	|	| X	|	|	| SE	|
|	|	|	| X	|	| 5SE	|
|	|	|	|	| X	| SE	|
|	|	| X	| X	|	| 5SE	|
|	|	| X	| X	| X	| 5SE	|
|W1UBC	| W1ABC	|	|	|	| ABC	|
|	|	| X	|	|	| ABC	|
|	|	|	| X	|	| ABC	|
|	|	|	|	| X	| ABC	|
|	|	| X	| X	|	| ABC	|
|	|	| X	| X	| X	| ABC	|
|W1UBC	| W2ABC	|	|	|	| 2ABC	|
|	|	| X	|	|	| 2ABC	|
|	|	|	| X	|	| 2ABC	|
|	|	|	|	| X	| W2ABC	|
|	|	| X	| X	|	| ABC	|
|	|	| X	| X	| X	| WABC	|


For more examples, please try the demo script in the test subdirectory, in
one of the following formats:
```
CONFIG_TU_RESENDUPDATEDCALL_demo.sh
```
(with no arguments), you will repeatedly get prompted for options and
callsigns, or, add the options as well:
```
CONFIG_TU_RESENDUPDATEDCALL_demo.sh  <wrong call>  <updated call>  options,...
```
