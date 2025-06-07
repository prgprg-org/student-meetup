---
marp: true
paginate: true
---

<!-- Build: marp index.md -o index.html --html=true
     Watch: marp index.md -o index.html --html=true -w
-->

# Everything you didn't want to know about TeX

Michal Vlasák, 2025

---

### Goals of the talk

 - Explain what TeX is, where it is coming from.

 - Show how TeX works (on the low level), in order to:

     - Increase understanding of inner workings of commonly used and misunderstood system.

     - Show how _not_ to do things. 🙂

---

### What is TeX?

TeX is a typestting system that translates TeX language input source:


```tex
\section First section

My text, using \macros!

\bye
```

to printable file formats (e.g. DVI, PDF).

---

### History of TeX

 - In the beginning, there was Knuth.

 - Known for e.g. Knuth-Morris-Pratt, Knuth shuffle, etc.

 - Writing _The Art of Computer Programming_ since 1960s.

 - [TeX is the ultimate Yak shave](https://yakshav.es/the-patron-saint-of-yakshaves/):

> Any apparently useless activity which, by allowing one to overcome intermediate difficulties, allows one to solve a larger problem.

![bg right w:50%](https://upload.wikimedia.org/wikipedia/commons/a/a5/Donald_Ervin_Knuth_%28cropped%29.jpg)

---

#### Yak shave

 - Write a book about compilers (1962)
 - Write a book about computer science fundamentals
 - Write a typesetting system (TeX)
 - Invent custom programming language and paradigm (WEB + literate programming)

 - Invent layout algorithm (Knuth-Plass Line Wrapping Algorithm)
 - Design fonts (Computer Modern)
 - Invent language for describing fonts (METAFONT)
 - Custom format for printable documents (DVI)
 - Invent custom license ("modifications must have different name")

---

### About TeX

 - Everything is published for free:

   - https://ctan.org/tex-archive/systems/knuth/dist/

 - Five books from Knuth about TeX and friends
   - TeXbook
     - for users
   - [TeX the program](https://mirrors.ctan.org/info/knuth-pdf/tex/tex.pdf)
     - source code and documentation of TeX

 - Developed 1977-1990, three major versions. Since 1990, [bug fixes only](https://mirrors.ctan.org/systems/knuth/dist/errata/tex82.bug).

 - Surprisingly little is "core TeX".

---

### Product of its time

<style scoped>
* {
  font-size: 0.8rem;
}
</style>

Extremely portable
 - change files
 - limited subset of Pascal, custom macro language (WEB) on top
 - has little system dependencies (file I/O)
 - almost doesn't use floating point, only integers
 - almost no recursion
 - almost no use of floating point operations

But also very limited. Extensions added:

 - new primitives,
 - language support (etc. right-to-left, Indian scripts),
 - support for finding files on file system,
 - interopability with standards (Unicode, UTF, PostScript, PDF, TrueType, OpenType).

---

## Inner workings of TeX

![bg w:90%](figures/tex.drawio.svg)

<div style = "height: 50em;"></div>

<!--
Input processor (transforms input text to tokens)

Expansion processor (expand macros, conditionals, etc.)

Execution processor (perform commands, i.e. change state, assignments, add to horizontal/vertical list)

Visual processor (kerning, ligatures, line break, page break)

Backend
-->

---

### Boxes and glue model

- TeX's model is called _boxes and glue_.

- TeX in it's core just puts "boxes" after each another horizontally or vertically, optionally separated by "glue".

- Boxes can be anything with fixed 2D dimensions:

  - characters (_glyphs_, e.g. "a"),
  - blackspace (_rules_, i.e. black rectangles, e.g. ■),
  - container of other material ("horizontal list", "vertical list", `\hbox{a■}`).

- Glue is the whitespace between boxes.

  - Usually starts as "stretchable", but gets fixed size during typesetting.

---

### Interchangeable terms

 - Box = "list with known size" (e.g. `\vbox` and `\hbox` are vertical and horizontal lists respectively)

 - Skip = glue

 - Character ~ glyph (character = Unicode character, glyph = drawing in font)

---

### Boxes and glue in the backend

 - Backend takes inner representation of typeset page and "_ships it out_" to output file.

 - Like many things: Structural recursion and case analysis.

 - After TeX finishes a page, all dimension are fixed, `shipout` means:

   1. Receive a box (list) as an argument.
   2. (Recursively) process the lists, laying all the elements horizontally or vertically:
      - For glyph, emit reference to the glyph in its font.
      - For rule, emit a rectangle of black ink.
      - For glue and space left blank in boxes, adjust current position.

---

## Output deep dive

 - Demo: [`shipout1.tex`](examples/shipout/shipout1.tex), [`shipout2.tex`](examples/shipout/shipout2.tex), [`visualizers.pdf`](examples/context/visualizers.pdf)

 - Tracing:

   - `\tracingoutput=1`
   - [`nodetree`](https://www.ctan.org/pkg/nodetree)
   - [`viznodelist.lua`](https://gist.github.com/pgundlach/556247)

 - Code references:

    - [`ship_out`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/pdf/pdfshipout.c?plain=1#L34-L290)
    - [`hlist_out`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/pdf/pdflistout.c?plain=1#L302-L834)
    - [`vlist_out`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/pdf/pdflistout.c?plain=1#L836-L1203)

---

## Execution processor

 - The core of TeX. It is the main loop of TeX.

 - An interpreter receiving a sequence of commands, and executing them in order.

 - The commands are the non-expandable tokens left after expansion.

 - Most commands either manipulate the global state (assignments) or append new material to the current list.

 - TeX is always building some (nested) horizontal or vertical list.

 - Commands themselves often read tokens from input.


---

### Main loop of TeX

```c
struct Token {
    int cmd; // opcode, "command"
    int chr; // operand, "character"
}

while (!should_exit) {
    Token current = get_next_expanded_token();
    switch (current_mode + current.chr) {
    ANY_MODE(assign_dimen_cmd): // \hoffset, \voffset, \pagewidth, \pageheight
        scan_optional_equals();
        assign_internal_value(currrent.chr, scan_normal_dimen());
	break;
    case HORIZONTAL_MODE + letter_cmd: // e.g. `a`
    case HORIZONTNAL_MODE + other_cmd: // e.g. `1`
    	tail_append(new_char(current_font, current.chr));
	break;
    case HORIZONTAL_MODE + char_num_cmd: // e.g. `\char42`
        tail_append(new_char(current_font, scan_int()));
    	break;
    ANY_MODE(vrule_cmd): // `\vrule`
    ANY_MODE(hrule_cmd): // `\hrule`
    	tail_append(scan_rule_spec()); // <width X> <height X> <depth X>
	break;
    // [...]
    }
}
```

---

### Main loop deep dive

 - Tracing:

   - `\tracingcommands=1`
   - `\tracingassigns=1`

 - Code references:

   - [`main_control`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/maincontrol.c?plain=1#L1001-L1035)

   - [`scan_rule_spec`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/scanning.c?plain=1#L1874-L1912)

---

#### Semantic nest

 - Processing commands like `\hbox{a\hbox{b}c}` requires nested/recursive processing.

 - TeX doesn't nest the main loop, it uses a "semantic stack".

 - For each new local/nested context pushes information on the stack.

 - When the nested context ends (usually on `}`, right brace), it pops the stack and performs additional processing (restore local assignments, finish box, etc.).

---

#### Semantic nest deep dive

 - Demo: [`assignments.tex`](examples/assignments.tex)

 - Tracing:

   - `\tracingassigns=1`
   - `\tracinggroups=1`

 - Code references:

    - [`push_nest`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/nesting.c?plain=1#L293-L312)

    - [`handle_right_brace`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/maincontrol.c?plain=1#L1458-L1641)

    - [`unsave`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/equivalents.c?plain=1#L750-L829)

    - [`eq_define`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/equivalents.c?plain=1#L643-L663)

---

## Visual processor

TeX provides automatic means for tasks for:

- line breaking,
- page breaking,
- alignment (tables),
- math.

---

### Line breaking

 - Line breaking is specific to unrestricted (outer) horizontal mode (started implicitly from vertical mode).

 - After a horizontal list in this mode is built, it is subject to line breaking.

 - The best breakpoints are chosen in order to achieve width of exactly `\hsize`.

   - [Knuth-Plass algorithm](https://en.wikipedia.org/wiki/Knuth%E2%80%93Plass_line-breaking_algorithm).

 - Global optimum is found.

 - Multiple horizontal boxes are created, and separated by `\baselineskip` (baseline glue).

---

### Line breaking II

 - Multiple attempts:

    1. First pass tries to find good linebreaks without hyphenation.
    2. Second pass hyphenates and tries to find good linebreaks.
    3. Third pass allows `\emergencystretch` and attempts again.

---

### Nodes for breaking

 - In order to deprioritize/prioritize line breaks at certain positions there is `\penalty`:

   - `\penalty⟨number⟩`

      - positive discourages break,
      - negative encourages break.

 - If different things should be typeset depending on whether line break happens:

    - `\discretionary{⟨pre-break⟩}{⟨post-break⟩}{⟨no-break⟩}`

      - Most typically: `\discretionary{-}{}{}`, a.k.a. `\-`.

---

## Page breaking

 - The main loop of TeX is in unrestricted vertical mode building a long vertical list.

 - After each addition to the list, the page breaker tries to decide whether it has a good position for page break. It tries to achieve height of `\vsize`.

 - If it decides to break, it puts what it considers a page to `\box255` and calls user defined _output routine_ (`\output` token list).

 - User macros can decide whether to `\shipout\box255`, or to modify it first, and to return some content to the page breaker.

---

### Glue elasticity

 - Glue elasticity is what allows many different options during breaks.

 - Glue is like a spring with a nominal dimension, shrinkability and expandability.

 - Best choice stays close to nominal dimensions, elasticity allows tolerance.

 - Breaking exactly at glue is possible, and removes the glue completely.

 - Many kinds of glue are inserted implicitly by TeX:

   - `\spaceskip`, `\topskip`, `\leftskip`, `\rightskip`, `\parskip`, ...

 - E.g. `\rightskip=0pt plus 1fil` achieves "left justified" text.

 - `\kern` is also a spacer, but fixed size and _non-breakable_.
   - Used for fine tuning, e.g. _kerning_.

---

## Getting tokens

 - TeX main loop keeps getting next expanded (unexpandable) token and executes it.

 - There are two main kinds of tokens:

    1. Character token (e.g. `a`$_{11}$, `␣`$_{10}$, `1`$_{12}$)
       - the command (`cmd`) is the _category code_ (_catcode_).
       - the operand (`chr`) is the character itself (i.e. ASCII code)

    2. Control sequence token  (e.g. `hbox`, `hsize`)
       - The command and operand are looked up in _table of equivalents_, based on the string of the control sequence.

---

### Category codes

https://en.wikibooks.org/wiki/TeX/catcode

```
    0 = Escape character, normally \
    1 = Begin grouping, normally {
    2 = End grouping, normally }
    3 = Math shift, normally $
    4 = Alignment tab, normally &
    5 = End of line, normally <return>
    6 = Parameter, normally #
    7 = Superscript, normally ^
    8 = Subscript, normally _
    9 = Ignored character, normally <null>
    10 = Space, normally <space> and <tab>
    11 = Letter, normally only contains the letters a,...,z and A,...,Z.
    12 = Other, normally everything else not listed in the other categories
    13 = Active character, for example ~
    14 = Comment character, normally %
    15 = Invalid character, normally <delete>
```

---

## Input processor

 - In first stage of input processing, TeX applies system dependent conversion to internal representation of ASCII (Unicode) and consistent line breaks.

 - Line breaks are mostly converted to spaces, but empty line emits `\par` (end of paragraph).

 - In second stage, in a simplified view either TeX sees `\` (escape character)
and scans a control sequence (letter characters followed by spaces as
delimiter), e.g. `\hbox`, or reads a character token of some category, e.g. `a`$_{11}$.

 - Code reference: [`scan_control_sequence`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/textoken.c?plain=1#L1638-L1687)

---

## Expandable commands

 - There is limited amount of unexpandable commands (up to `max_command`,
~100-140) that can go to main loop.

 - The remaining of commands are either _expandable primitive commands_, or _macros_ ("call commands").

Expandable primitive examples:

 - `\expandafter`, `\noexpand`

 - `\if`, `\else`, `\fi`

 - `\csname`, `\string`

---

## Macros

 - Macros are defined with `\def`:

   - `\def\cs{<tokens>}`

 - Definition of a macros is stored as a _token list_ (linked list of tokens). Example:

    - `\def\a{A}` - `\a` stores one token
    - `\def\a{\B\C}` - `\b` stores two tokens


 - Expanding a macro involves pushing the contents of the stored token list to the top of the input stack.

 - In any momement, TeX may be reading input tokens from any token list (e.g. macro) or from some input file.

---

## Macros II

 - Macros can have parameters:

   - `\def\greet#1{Hello #1!}` - scans one parameter, and stores 8 tokens

 - Actually, macro definition provides a _matching template_:

```tex
\def\mac a#1#2 \b {#1\−a ##1#2 #2}
```

 - There are:

   1. Delimited arguments (scanned until delimiter)
   2. Undelimited arguments (either single token or content between `{` `}`).

---

## Macros deep dive

 - Tracing:

   - `\tracingmacros=1`

 - Code references:

    - [`expand`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/expand.c?plain=1#L64-L381)
    - [`macro_call`](https://github.com/TeX-Live/texlive-source/blob/77ea78f6ffb3c2f132d9ef13799f3b6fe8fcf39a/texk/web2c/luatexdir/tex/expand.c?plain=1#L621-L968)

---


## Beware

1. Spaces not consumed on the input processor and expansion level are
   interpreted as spacer commands that insert glue in horizontal mode or are
   ignored in vertical mode.

2. Beware TeX scanning for numbers or dimensions (e.g. `plus`) further than you
   wanted:

```tex
\def\a{\penalty200} vs \def\a{\penalty200\relax}

... \a 0 ...
```

---

## TeX examples

---

### Check if macro argument is empty

```tex
\def\isempty#1{%
  \ifx\end#1\end
    % empty
  \else
    % not empty
  \fi
}
```

<!--

\isempty scans one argument, and we want to do different things based on whether it is empty or not.

TeX has on the expansion level a few `\if` primitives, but they mostly compare two consecutive tokens for equality.

But we can still use it with a trick:

`\ifx` checks whether two tokens are equal. We can check `\ifx\something<maybe empty>\something`.

If the argument turns out to be empty, \ifx will see \something \something as the two following tokens, and we go to the "true branch".

(Going to the true branch means that when TeX will encounter \else, it will keep reading tokens, but ignore everything until \fi, we are still on expansion level, not in a true programming language.)

If the argument is not empty (e.g. it is Hello), it will see `\ifx\something Hello\something`, then `\something` is not the same token as `H`, so TeX will ignore everything up to `\else` and "execute" the else branch.

This conveniently also means that we don't care whether the argument has single token or not, even though we only have a single token comparison.

-->

---

### Macro arguments

```tex
\def\frac#1#2{{#1 \over #2}}

$\frac{11}{5}$
$\frac12$
```

<!--
You probably have used `\frac` macro for typesetting fractions in LaTeX before.

Actually on the primitive level in TeX it uses `\over` primitive, which expects numerator to precede it and denominator to follow it.

Weirdly enough, Knuth actually made a lot of the math internals much more complicated (there is an extra pass to figure out the sizes), just to be able to say `\over`, which is more natural, but we get `\frac`, which removes that benefit.

As the `\frac` macro takes two undelimited arguments, they will capture contents wrapped in `{}` or just one token. This means that if we have a simple fraction with single digit numbers, we can just omit the braces.
-->

---

### Dynamic control sequences

```tex
\def\skip{\csname \ifhmode h\else v\fi skip\endcsname}
```

<!--
There is `\vskip` primitive for inserting glue to current vertical list, or `\hskip` to insert glue to current horizontal list.

If we wanted to have a single macro called `\skip`, which would expand to `\hskip` or `\vskip` depending on the current mode, we need to dynamically construct a control sequence name (`\hskip`, `\vskip`).

We can do this by checking the current mode (`\ifhmode`), and based on it emitting `h` or `v`.

Finally to get a dynamic control sequence, we use `\csname` and `\endcsname`. Everything written between the pair is expanded, and the remaining "ASCII" codes (ignoring category codes) are used as the control sequence name.
-->

---

### Copy current meaning of another token:

```tex
\let\bgroup={
\let\egroup=}
\let\endgraf=\par
```

<!--
Every control sequence has its meaning stored in table of equivalents. We can
copy the meaning with `\let` This allows us to create true copy of primitives,
macros, and but also other tokens.

For example `\bgroup` and `\egroup` commands are just copies of `{`, `}` which are the more primitive ways to start a group.

(Disclaimer: it's actually more involved, `{` and `}` are special syntactically - they always need to be scanned in balanced way, `\bgroup` and `\egroup` bypass that, as they have begin group and end group meaning semantically, but don't need to be balanced syntactically. Also, there is `\begingroup` and `\endgroup`, but they only start/end group, they can't be used e.g. with `\hbox\bgroup\egroup`.
-->

---

### Hash tables

```tex
\setkv{a}{b}
\getkv{a}
```

```tex
\def\setkv#1#2{%
    \expandafter\def\csname kv:#1\endcsname{#2}%
}

\def\getkv#1{%
    \csname kv:#1\endcsname
}

```

<div data-marpit-fragment>

```tex
% more elegant, but has problem
\def\setkv#1{%
    \expandafter\def\csname kv:#1\endcsname
}
\setkv{a}b % doesn't work
```

<!--
Hash tables which allow mapping of keys to values are a very important data structure.

We often want them also in TeX, and we can emulate them with dynamicly constructed control sequences.

We can define macros `\setkv` and `\getkv` that will allow us to store and retrieve arbitrary things.

To store the values we define a control sequence named `kv:key`, which stores the `value`. As the name includes a character which normally can't be part of macro name (i.e. `:`), it is unlikely to collide with anything user writes.

To generate the dynamic control sequence name, we of course use `\csname`.

But we have a problem, we want to say `\def\dynamiccontrolsequence{something}`. But `\def` is a command which in the main loop of TeX just says "give me next token, assert that it is a control sequence, then scan matching template and text in braces (`{}`).

If we write `\def\csname...`, TeX will just redefine `\csname`. We need to first construct the dynamic control sequence name, so that `\def` already sees it.

For this we want to change the expansion order. Most important primitive in that regard is `\expandafter`.

`\expandafter` reads a token temporarily, leaves it unexpanded, but reads a second token which it expands.

So in this case, `\expandafter\def\csname` first creates the dynamic control sequence name, and only then `\def` runs and already sees the right thing.
-->

---

### Append to macro

```tex
\def\a{}
\addto\a{hello}  % hello
\addto\a{ world} % hello world
\addto\a{!}      % hello world!
```

<div data-marpit-fragment>

```tex
\def\a{}
\def\a{\a hello} % WRONG: \a recursively refers to itself, we want to expand it first
```

<div data-marpit-fragment>

```tex
\def\a{}
\expandafter\def\expandafter\a\expandafter{\a hello}
% \def\a{hello}
\expandafter\def\expandafter\a\expandafter{\a world!}
% \def\a{helloworld!}
```

<div data-marpit-fragment>

```tex
\def\addto#1#2{\expandafter\def\expandafter#1\expandafter{#1#2}}

\def\addto#1#2{\def#1{#1#2}} % WRONG
```

<!--
Another case where we need to be careful with expansion is if we want to for example define a macro that appends some tokens to an existing macro.

Let's break it down on a simpler example, where we just want to add to macro \a some text. First thing we might try is `\def\a{\a hello}` -- define `\a` to be `\a` followed by something.

But this doesn't really work - we will define `\a` to mean token `\a` followed by a few letter tokens. We just got a recursive definition of a macro that will cause stack overflow on expansion.

What we really want to do, is to define `\a` to be _expanded value_ of `\a` followed by what we want to add.

But `\def` when it scans meaning of macro doesn't expand. We can use `\expandafter` to solve this. Just before `\def` we will start a chain of `\expandafter`s that will reach the `\a` that we want to expand.

Thanks to this, by the time `\def` runs, it will already see the expanded meaning of `\a` followed by what we want to add.

To create the generic `\addto` macro that we wanted initially, we can just make `\a` and the text to add into parameters of `\addto`.
-->

---

### Ending ifs

```tex
\def\bold#1{{\bf #1}}
\def\italic#1{{\it #1}}
```

```tex
\ifnum1>0 \bold \else \italic \fi {word} % bad
```

<div data-marpit-fragment>

```tex
\ifnum1>0 \expandafter \bold \else \expandafter \italic \fi {word} % good
```

<!--
Say we have a macro called `\bold` that receives an arguments and typesets it in bold, and `\italoc` macro that typesets argument in italic.

Say that based on some condition, we want to make a text between braces either bold or italic.

First thing that we may come up with is to just use `\bold` and `\italic` in each respective branch. But the problem is, that both just scan the next token, which will be `\else` or `\fi` respectively, completely confusing TeX.

Before `\bold` and `\italic` execute, we want them to just see `{word}` after them, so they scan the correct thing as argument.

We will use the fact that `\if` `\else` and `\fi` work on expansion level. Expansion of `\else` just keeps ignoring tokens until it reaches `\fi`. Expansion of `\fi` just pops the `\if` from stack. If we use `\expandafter` to expand `\else` and `\fi` before we `\bold` and `\italic` take effect, the condition first disappears from the input completely, and `\bold` and `\italic` will correctly scan the text following the condition as argument.
-->

---

### `\afterfi` and `\let\next` tricks

```tex
\def\afterfi#1#2\fi{\fi#1}

\ifnum1>0 \afterfi \bold \else \afterfi \italic \fi {word} % good
```

<div data-marpit-fragment>

```tex
\ifnum1>0 \let\next=\bold \else \let\next=\italic \fi \next{word}
```


<!--
Another trick to achieve a similar thing (insert macro only after `\fi`) is to introduce a macro, which will eat everything up to the `\fi`, ignore it, execute the `\fi` to get rid of the condition on the stack, and then to insert the thing that we wanted to carry out of the condition.

And finally, yet another thing to carry out something out of the condition is to just define a temporary macro, and use it after the condition.
-->

---

### Parsing comma separated input

```tex
\cite[a,b,c]

\def\cite[#1]{\citeimpl#1,,}

\def\citeimpl#1,{%
  \ifx\end#1\end
    % terminating condition reached
  \else
    [#1]% print citation
    \expandafter\citeimpl % loop and continue
  \fi
}
```

<!--
Say we want to implement a macro called `\cite`, which gets a list of references, and we want to resolve them and print a nice label for them.

We don't care much about the typesetting part, but only about how to parse a comma separated list in square brackets.

Unlike `{` `}`, square brackets are not special to TeX. So we can just define a macro which will match an opnening square brace, and then an argument delimited by ending square brace.

We won't use any predefined loop macros, we will just handcode recursion ourselves.

A single step of recursion will process one argument. To get one argument from input, we will can define a macro that reads an argument delimited by comma.

As we need all elements to be delimited by comma, before even calling this recursive processing we must add a comma to after our initial `\cite` argument.

But as always with recursion, we must come up with the base case. For that we will actually add another comma after the initial argument. This will mean that our recursive macro will read one extra element which will be empty. As we already know how to check for empty string, it will serve nicely as our terminating condition.

In the recursive step, we just need to print the citation somehow (not really important for us here), and invoke recursively. But again we have a problem, `\citeimpl` immediately tries to read until first comma. But the `\fi` macro is in the way, and we need to get rid of it. We already know how to do that, in this case `\expandafter` works nicely.

The nice thing about our macro is that it is _tail recursive_. Because the `\expandafter` gets rid of the `\fi` from input stack, our recursive macro actually calls itself as the very last thing. It doesn't need any extra stack space and is quite efficient.

Most similar loop macros in TeX actually are tail recursive, usually for the same purpose ours is - we need to read past `\fi`.
-->

---

### Parsing comma separated input - ignoring leading whitespace

```tex
\cite[a, b, c]

\def\cite[#1]{\citeimpl#1,,,}

\def\citeimpl#1#2,{
  \ifx#1,
    % terminating condition reached
  \else
    [#1#2]
    \expandafter\citeimpl
  \fi
}
```

<!--
We can define a more user friendly variant of the `\cite` macro. The problem with the previous version is, that it scan all arguments as just everything until the next comma. So if some elements start with leading whitespace, we will treat them as part of the citation name.

This is not nice, and we can get rid of the leading whitespace with a trick.

The trick is that reading undelimited arguments (i.e. single token or text surrounded with braces) ignores whitespace until it finds the argument. So if we read the input with undelimited argument, we will get rid of leading whitespace automatically. But that means that we will not read until the next comma, but only one letter.

To solve the problem, we can scan both undelimited argument and the delimited argument. The first will ignore leading whitespace and scan the first letter. The second will read the rest of the argument until the comma.

The only thing we have to be careful about is to reconstruct the argument we must combine `#1` and `#2`. And also, our terminating condition has to change slightly -- now our macro scanning will not read empty argument, but will read into first argument whatever next token is, and it will read one of our extra commas that we insert. So in this case, we need to insert another one into input, and check the base case by comparing the first argument to comma.
-->

---

### Plain TeX generic loop

```tex
\loop
  \message{\number\MyCount}
  \advance\MyCount by 1
\ifnum\MyCount<100 \repeat
```

<div data-marpit-fragment>

```tex
\def\loop#1\repeat{\def\body{#1}\iterate}
\def\iterate{%
    \body
    \let\next=\iterate
  \else
    \let\next=\relax
  \fi
  \next
}
```

<!--
In plain TeX loops are implemented with a macro called `\loop`. It scans body
of the loop - everything up until `\repeat`, which needs to end with `\if`
condition.

It looks like a special syntax, but it really isn't. Under the hood, it just defines `\body` as the body of the loop including the condition at the end, and recursively calls itself until the condition terminates by using the `\next` trick.
-->

---

### Plain TeX generic loop - alternatives

```tex
\loop
  \message{\number\MyCount}
  \advance\MyCount by 1
\ifnum\MyCount<100 \repeat

\def\loop#1\repeat{\def\body{#1}\iterate}
```

```tex
\def\iterate{\body \iterate\fi}
```

```tex
\def\iterate{\body \expandafter\iterate\fi}
```

<!--
In this case however, we could leave out the `\next` trick and just have simple recursion. But it isn't tail recursion -- there will be `\fi` left on the input stack for each iteration. The `\next` variant is tail recursive, as would be the `\expandafter` variant.
-->


---

## Demo

 - [`document.tex`](examples/document/document.tex) = plain TeX with:
   - section macros,
   - marks,
   - footnotes,
   - inserts,
   - leaders,
   - I/O,
   - table of contents.

 - [`plain.tex`](https://mirrors.ctan.org/systems/knuth/dist/lib/plain.tex)

<!--

The demo document shows some features that we didn't have time to cover:

1. Some example of typesetting commands like `\section`. There we want to handle numbering of sections, setting up penalties to encourage break before section, forbid page break between section title and first paragraph, and.

2. Marks = notes about what is the current capture, which can be used to typeset name of the current chapture on a page.

3. Footnotes and figures which are "inserts" - floating elements for which TeX tries to reserve space on the page, and ultimately the output routine chooses where to place them. Simplest example is `\topinsert` which is placed either in the current location or at the top of next page, and `\footnote` which typesets a footnote at the bottom of the current page.

4. Writing to and readin from files. For reading a file in full, we can just use `\input` with the file name. But writes with `\write` are surprisingly not performed where they are executed by TeX's main loop. Instead, they are added as a node which executes the write as part of `\shipout`. This means that writes happen on finalized pages, and e.g. page number is usually known at that time.

5. The "at shipout" property of writes is important for implementing features like table of contents. As TeX ships out pages sequentially, and in a single pass, it can't really typeset table of contents at the beginning of the document, as it doesn't yet know what are the chapters. Writes provide a solution - write the information about the chapters to a helper file in the first pass, and read that information in the second pass, which will be able to typeset table of contents. The write with section information has to be very careful with expansion, as it needs some part expanded (like section number register, since it can change multiple times in a page), but some registers need to be read only when the read happens (like the page number, which is correct only at that point). A typical problem with these writes to files is also special characters (control sequences and e.g. `~`) that could otherwise be expanded, but we don't want that, for that we escape with `\detokenize` which makes all characters into "other" tokens (catcode 11), except spaces which are left as spacer, catcode 10.

6. Leaders - repeated elements, used to typeset "leading" dots in table of contents, but also the header lines. Internally, they are represented like glue, but instead of being just whitespace, they are realized by repeating their contents.


-->

---

## Verbatim

```tex
\verbatim
Text printed verbatim
\endverbatim
```

<div data-marpit-fragment>

```tex
\def\verbatim#1\endverbatim{...}
```

<div data-marpit-fragment>

```tex
\expandafter\def\expandafter\verbatim\expandafter#\expandafter1\string\endverbatim{...}
```

<!--
Another interesting thing to implement in TeX is a verbatime environment, which allows to print a piece of text verbatim as it appears in source code. Usually in a monospace font. While TeX normally ignores duplicate spaces, and line breaks in source code are more or less treated just like spaces, in verbatime environment we need each space and end line character to have their desired effect.

Verbatim environment thus often boils down to setting character codes of everything to 12, except for space and newline which have to have a bit of special handling, as they are not only semantically, but syntactically significant for TeX.

But the challenge is, that when we set all category codes of all ASCII codes to 12, then how can we scan until `\endverbatim`? Our definition tries to match up to single token which is `endverbatim` control seqeunce. But since we set category code of backslash to 12, then it will not create control sequences. So we actually need to define `\verbatim` to not be delimited by control sequence `\endverbatim`, but by the twelve category code 12 tokens `\`, `e` `n`, etc.

For this we can use `\string` to get the control sequence `endverbatim` expanded into just category 12 tokens. But of course, to have them there at the right time, we need a `\expandafter` sequence.
-->

---

### LaTeXisms

<div style = "height: 3em;"></div>

```latex
% plain TeX
\parindent=1em

% LaTeX
\def\setlength#1#2{#1#2\relax}
\setlength{\parindent}{1em}
```

<!--
In plain TeX assignments to registers are done directly, more often with the optional equals sign that increases readability.

In LaTeX there is for example a macro called `\setlength` that just receives the register and dimension as two parameters, and expands to putting them after each other, which executes the assignment. Finally the `\relax` makes sure there are no additional things scanned as part of the dimension.
-->

---

```latex
% plain TeX
{\bf bold text}

% LaTeX
\def\textbf#1{{\bf #1}}
\textbf{bold text}
```

<!--
In plain TeX, temporary change of font to bold would be achieved with a local group. The font would be set to bold, and the assignment undone at the end of the group, and all the text in between would be typeset in bold.

LaTeX hides the underlying concept of the group, and just exposes a command that makes it's argument bold. It's also a bit less efficient, as it needs to scan it's argument.
-->

---

```latex
\begin{environment}
\end{environment}

\def\begin#1{%
  \csname#1\endcsname
}
\def\end#1{%
  \csname end#1\endcsname
}

\environment
\endenvironment
```

<!--
LaTeX environments are marked with `\begin` and `\end`. Behind the scenes, these just translate to the control sequence without begin for the start, and control sequence starting with end for the end.

Usually the definitions envrionments internally also start a group, so all assignments are local.
-->

---

```latex
% LaTeX
\rule{1cm}{0.4pt}

% TeX
\hrule height 0.4pt width 1cm
```

<!--
Instead of using primitive `\hrule` or `\vrule` with key word arguments, LaTeX instead uses `\rule` with two macro arguments.
-->

---

```latex
\def\makatletter{\catcode`\@=11\relax}
\def\makatother{\catcode`\@=12\relax}
```

<!--
The famous `\makatletter` and `\makatother` macros from LaTeX just change the category of the at sign (`@`), making it either scan part of  control sequences or not. Usually these macros are used to temporarily be able to access "internal" definitions which are using the `@` to avoid accidental redefinitions.
-->

---

## Resources

1. [TeX by topic](https://mirrors.ctan.org/info/texbytopic/TeXbyTopic.pdf)
2. [TeXbook naruby](https://petr.olsak.net/tbn.html)
3. [TeXbook](https://www.ctan.org/pkg/texbook)
4. [LuaTeX manual](http://mirrors.ctan.org/systems/doc/luatex/luatex.pdf)
5. [LuaTeX source code](https://github.com/TeX-Live/texlive-source/tree/trunk/texk/web2c/luatexdir)
6. [TeX without TeX](https://wiki.luatex.org/index.php/TeX_without_TeX)
8. [`nodetree`](https://www.ctan.org/pkg/nodetree)
7. [`viznodelist.lua`](https://gist.github.com/pgundlach/556247)
