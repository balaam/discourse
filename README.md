# Discourse

Discourse is a markup language for defining conversation in video games. The default extension for discourse files is `.ds`.

You can read more about it [here](http://howtomakeanrpg.com/a/rpg-dialog-language-discourse.html).

## Parser

Running

`./parser.lua ./examples/example_1.txt`

will transform a discourse script into a lua table.

Note: Currently it will also spew out a load of debug information before that table.

## Work

The discourse parser is functional and for me that's probably enough but here are some thoughts about language extensions and different approaches to writing the parser.

### Whitespace

Whitespace in discourse is fluid, it can change; lines can be combined, space can be trimmed. This means the tags are hard to correctly position as an offset, that offset can change when the whitespace changes. A better solution might be an non-whitespace offset. In this way the tags will stick to the words.

### Comments

It would be nice to have comments. C style // would be enough.
