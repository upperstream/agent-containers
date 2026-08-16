---
name: document-standards
description: Standards to follow when writing a documentation text file.
---

Here is the list of standards for documentation text files:

* Use two spaces after a full stop, except for source files of manual
  pages.  Since documentation text files are intended to be printed
  using monospace font, "double spaces are no longer necessary in
  computer era" rule cannot be applied.
* Prefer British spelling over American spelling, except for proper
  nouns and commonly used spellings: "license" as a noun in a licence
  text body ("the purpose of this license") and in its file name
  ("LICENSE.txt") is allowed.
* Lines should be wrapped at 72 characters: never exceed 72 characters
  unless the line is preformatted or contains a long URL.  Trailing
  punctuations may appear after the 72-character limit when necessary.
* For Markdown files, human readability as a plain text file takes
  precedence over visual appearance as a rendered HTML.  Respect the
  "Philosophy" section in the _Markdown Syntax_ documentation on
  [Daring Fireball][].
* Use underscores (`_`) as a Markdown indicator for italicisation rather
  than asterisks (`*`) when citing a title of a work.
* Use Markdown indicator for emphasis (asterisks or underscores) only
  when it is semantically necessary.  Avoid overuse of emphasis such as:

      **Example 1**: This is an example of **too much emphasising**.

  This is preferred:

      Example 2: This is an example of fair tone expression.

[Daring Fireball]: https://daringfireball.net/projects/markdown/syntax#philosophy
  "Daring Fireball: Markdown Syntax Documentation"
