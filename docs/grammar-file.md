---
title: "The Citron Grammar File"
permalink: /grammar-file/
---

# The Citron Grammar File

The Citron Grammar File contains:

  - Rules of the input grammar in a [BNF]-like format
  - Type declarations for the symbols used in the grammar
  - Code blocks associated with the rules
  - Other Citron directives

[BNF]: https://en.wikipedia.org/wiki/Backus–Naur_form

The grammar file should be in ASCII encoding.

  - [Grammar](#grammar)
    - [Symbols](#symbols)
    - [Rules](#rules)
    - [An example](#an-example)
  - [Types](#types)
  - [Code blocks](#code-blocks)
  - [Directives](#directives)
    - [Type specification](#type-specification)
      - [%token_type](#token_type)
      - [%nonterminal_type](#nonterminal_type)
      - [%default_nonterminal_type](#default_nonterminal_type)
    - [Naming](#naming)
      - [%class_name](#class_name)
      - [%tokencode_prefix](#tokencode_prefix)
    - [Code insertion](#code-insertion)
      - [%preface](#preface)
      - [%epilogue](#epilogue)
      - [%extra_class_members](#extra_class_members)
    - [Precedence and associativity](#precedence-and-associativity)
      - [%left_associative](#left_associative)
      - [%right_associative](#right_associative)
      - [%nonassociative](#nonassociative)
    - [Grammar-controls](#grammar-controls)
      - [%start_symbol](#start_symbol)
      - [%token](#token)
      - [%fallback](#fallback)
      - [%wildcard](#wildcard)
      - [%token_set](#token_set)


## Grammar

### Symbols

A grammar for a language or format is composed of production rules. The
rules make use of [terminal and non-terminal symbols][term-non-term].
In a Citron grammar, both terminals and non-terminals should be named
using alphabets, digits and underscores only. Terminals should start
with an uppercase letter and non-terminals should start with a lowercase
letter. Typically, terminal names are all-uppercase and non-terminal
names are all-lowercase.

Some parser generators ([Bison][bison_literal_token] for example) allow
literal characters and strings to be directly used in a grammar rule,
but Citron does not. In Citron, all terminals should be named.

We also call terminals as tokens. Citron directives
use the term "token" to denote a terminal symbol.

[term-non-term]: https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols
[cfg]: https://en.wikipedia.org/wiki/Context-free_grammar

### Rules

Citron can work with only [context-free grammars][cfg], where there must
be exactly one non-terminal symbol on the left hand side (LHS) of the
rule, and zero or more terminal or non-terminal symbols on the right
hand side (RHS) of the rule.

[bison_literal_token]: https://www.gnu.org/software/bison/manual/html_node/Symbols.html

An arrow string ("::=") should be used as the separator between the LHS
and the RHS of a rule.  A period (".") should be used to mark the end of
the rule. The rule can be completely in one line, or can be broken up
into multiple lines, but either way, it has to end with a period.

The RHS of a rule should contain only terminal or non-terminal symbols,
so you can't specify alternativity (either this sequence of symbols or
this other sequence of symbols) or optionality (this symbol may or may
not come here) directly in a rule. Rather, you have to break that out
into separate rules.

### An example

Consider the following grammar for a Swift function header
(the part before the body of a function), a simplified version of [the
function declaration grammar][func_decl] from the [Swift Language Reference]:

> _function-header_ → <code><b>func</b></code> _function-name function-signature_<br/>
> _function-name_ → _identifier_<br/>
>
> _function-signature_ → _parameter-clause_ <code><b>throws</b></code>_<sub>opt</sub> function-result<sub>opt</sub>_<br/>
> _function-signature_ → _parameter-clause_ <code><b>rethrows</b></code> _function-result<sub>opt</sub>_<br/>
> _function-result_ → <code><b>-></b></code> _type_<br/>
>
> _parameter-clause_ → <code><b>(</b></code> <code><b>)</b></code> | <code><b>(</b></code> _parameter-list_ <code><b>)</b></code><br/>
> _parameter-list_ → _parameter_ | _parameter_ <code><b>,</b></code> _parameter-list_<br/>
> _parameter_ → _external-parameter-name<sub>opt</sub> local-parameter-name type-annotation_<br/>
> _external-parameter-name_ → _identifier_<br/>
> _local-parameter-name_ → _identifier_<br/>
>
> _type-annotation_ → <code><b>:</b></code> <code><b>inout</b></code><sub>opt</sub> _type_<br/>
> _type_ → _identifier_<br/>

[func_decl]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Declarations.html#//apple_ref/swift/grammar/function-declaration
[Swift Language Reference]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AboutTheLanguageReference.html

The literal words and punctuation in the grammar are tokens that should
get recognized in the previous tokenization stage. We should also
recognize identifiers during tokenization. The other symbols should be
treated as non-terminals.

We can rewrite the above grammar as an input for Citron as follows:

~~~ Text
func_header ::= FUNC func_name func_signature.
func_name ::= IDENTIFIER.

func_signature ::= param_clause.
func_signature ::= param_clause func_result.
func_signature ::= param_clause throws_clause func_result.
func_signature ::= param_clause throws_clause.
throws_clause ::= THROWS.
throws_clause ::= RETHROWS.
func_result ::= FUNC_ARROW type.

param_clause ::= L_BR R_BR.
param_clause ::= L_BR param_list R_BR.
param_list ::= param.
param_list ::= param COMMA param_list.
param ::= local_param_name type_annotation.
param ::= external_param_name local_param_name type_annotation.

external_param_name ::= IDENTIFIER.
local_param_name ::= IDENTIFIER.

type_annotation ::= COLON type.
type_annotation ::= COLON INOUT type.
type ::= IDENTIFIER.
~~~

Alternatives are handled by creating a separate rule for each
alternative (see rules for `param_clause` and `param_list`).

Optional symbols in a rule are handled by breaking the rule into two
rules, one excluding the symbol and one including it (see rules for `param` and
`type_annotation`). If there are multiple optional symbols, we have to
create rules for each combination of possible symbols (see rules for
`func_signature`).

Now we have a complete grammar that Citron can understand. But a grammar
is not sufficient to generate a parser. For that, we also need to
declare the types for the grammar's symbols and provide code blocks for
our grammar's rules.

However, if required, you can still run Citron on just the grammar to
check for any grammar-related errors like conflicts and unreachable
rules.

## Types

Citron requires that we specify the semantic type of each symbol
used in the grammar. That's the type we use to represent that symbol in
our code.

All terminal symbols are assumed to have the same semantic type.
Different non-terminal symbols can have different semantic types.

For example, we could represent the terminals in the above grammar with
an enum like this:

~~~ Swift
enum Token {
    case keyword // for FUNC, THROWS, INOUT, etc.
    case punctuation // for (, ), ->, etc.
    case identifier(String) // for IDENTIFIER
}
~~~

We can specify that the semantic type for all terminals is
`FunctionToken` by using the [%token_type](#token_type) directive in the
grammar file, like this:

~~~ Text
%token_type FunctionToken
~~~

The non-terminal `param` in the above grammar represents a function
paramater. We could represent that in our code with a struct defined
like this:

~~~ Swift
struct FunctionParameter {
    let localName: String
    let externalName: String?
    let type: String
    let isInout: Bool
}
~~~

We can specify that the semantic type for the non-terminal `param` is
`FunctionParameter` by using the [%nonterminal_type](#nonterminal_type)
directive in the grammar file, like this:

~~~ Text
%nonterminal_type param FunctionParameter
~~~

We can use arrays and tuples to build intermediate types. For example,
the non-terminal `type_annotation` can be represented by a tuple, like
this:

~~~ Text
%nonterminal_type type_annotation "(type: String, isInout: Bool)"
~~~

The sematic type for all terminals, and the semantic type for each
non-terminal should be specified in the Citron grammar file.

It's a good practice to keep the type specifications of non-terminals
closer to the rules that use these non-terminals, so that the code blocks
for the rules are easier to read.

We can place the type definitions anywhere in our project, and should
just make it available when compiling the generated parser code, either
by including it in the same module, or by importing the defining module.

## Code blocks

Citron requires that each grammar rule be followed by a code block
associated with that rule. The code block is invoked every time that
rule is used during parsing.

Conceptually, the code block for a rule takes its RHS symbols as input
and returns its LHS symbol as output.

Consider the following rule:

~~~ Text
param ::= local_param_name type_annotation.
~~~

The code block for this rule should take the local parameter name and
the type annotation as inputs, and should return the function
parameter.

We can choose which inputs we want to work with and by what name by
adding aliases to the required symbols. For example, we could modify the
rule as:

~~~ Text
param ::= local_param_name(lpn) type_annotation(ta).
~~~

Then we'd be able to access `lpn` and `ta` inside the code block for
this rule. The type of `lpn` would be the semantic type specified for
`local_param_name` (let's assume that's `String`). The type of `ta`
would be `(type: String, isInout: Bool)`, which is the semantic type we
declared for `type_annotation`.  The code block should return a value of
type `FunctionParameter`, which is the semantic type we declared for
`param`.

We can write a code block for this rule as follows:

~~~ Text
param ::= local_param_name(lpn) type_annotation(ta). {
    return FunctionParameter(localName: lpn,
            externalName: nil, type: ta.type, isInout: ta.isInout)
}
~~~

Likewise, we should write a code block for each rule in our grammar.

Each code block becomes the body of a member function in the generated
parser class. The above code block would look something like this in the
generated code:

~~~ Swift
func codeBlockForRule13(lpn: String, ta: (type: String, isInout: Bool)) throws -> FunctionParameter {
    return FunctionParameter(localName: lpn,
            externalName: nil, type: ta.type, isInout: ta.isInout)
}
~~~

Since the code block is placed in a function with stricty typed
parameters, any type mismatches would be caught when the generated
parser is compiled.

The code blocks are a great way to build a data structure (usually a
parse tree) representing the parsed data. Typically, the code block for
a rule builds the data structure representing the LHS symbol of the
rule. This data structure will eventually get passed as input to a code
block of a rule that uses this rule's LHS symbol in the RHS, and thereby
get incorporated into a higher level data structure (in case of a
parse-tree, a higher level node i.e. a node closer to the root of the
tree). Finally, a start symbol rule's code block shall return the
complete data structure representing the whole input data.

Once we have the grammar rules, type specifications and code blocks, we
can ask Citron to [generate a parser](/citron/generating-the-parser/)
for us.

## Directives

### Type specification

Citron requires that the [semantic types](#types) of all symbols used in
the grammar be declared in the grammar file using these directives:

#### token_type

Specifies the [semantic type](#types) for all terminals. If the type is a
compound type with use of special characters, it should be enclosed in
"quotes" or {brackets}.

Example:

~~~ Text
%token_type String
~~~

#### nonterminal_type

Specifies the [semantic type](#types) for a particular non-terminal. If
the type is a compound type, it should be enclosed in "quotes" or
{brackets}.

Example:

~~~ Text
%nonterminal_type type_annotation "(type: String, isInout: Bool)"
~~~

#### default_nonterminal_type

Specifies the [semantic type](#types) for all non-terminals that don't
have types specified with [%nonterminal_type](#nonterminal_type). If the
type is a compound type, it should be enclosed in "quotes" or
{brackets}.

Example:

~~~ Text
%default_nonterminal_type String
~~~

### Naming

#### class_name

Specifies the name of the parser class generated by Citron. If this
directive is not present, the class is named `Parser`.

Example:

~~~ Text
%class_name ConfigFileParser
~~~

#### tokencode_prefix

By default, the token code enum values are the same as the token names
used in the grammar. For example, the above grammar uses the token names
`FUNC` and `INDENTIFIER`, so the token code enum will include the values
`.FUNC` and `.IDENTIFIER`.

Specifying a token code prefix directive will cause the enum values to be
generated with the specified prefix.

For example:

~~~ Text
%tokencode_prefix t_
~~~

will cause the enum to be generated with values `.t_FUNC` and
`.t_IDENTIFIER`.

In case you want to have Swifty-looking enum values for the token codes,
you can name the tokens with CamelCase and use an all-lowercase token
code prefix, so the enum values can look something like `.tokenFunc`.

### Code insertion

#### preface

Specifying a preface will include the contents of the preface _before_
the parser class in the output file. This can be used to import modules
or define types that are required for the code in the code blocks.

Example:

~~~ Text
%preface {
    import Foundation
}
~~~

#### epilogue

Specifying an epilogue will include the contents of the preface _after_
the parser class in the output file. One use for this would be to extend
the parser class to add additional functionality.

Example:

~~~ Text
%epilogue {
    extension Parser: MyProtocol {
        func conformingFunction() {
            doSomething()
        }
    }
}
~~~

#### extra_class_members

Using this directive, we can add extra class members to the parser
class. Since code blocks are also member functions, any extra members we
add become accessible from inside the code blocks. This is a great way
to make the parser configurable.

For example, if you specify %extra_class_members like this:

~~~ Text
%extra_class_members {
    let shouldGenerateParseTree: Bool
    init(shouldGenerateParseTree: Bool) {
        self.shouldGenerateParseTree = shouldGenerateParseTree
    }
}
~~~

We can access the `shouldGenerateParseTree` as an instance variable
in all our code blocks. The code blocks can then conditionally
generate the parse tree. Creating the parser as
`Parser(shouldGenerateParseTree: false)` would suspend parse tree
generation.

### Precedence and associativity

A grammar rule with multiple recursions can cause the grammar to become
ambiguous, resulting in shift-reduce conflicts. One way to fix these
conflicts is to specify associativity. When there are multiple such
rules, we might also need to specify the relative precedence between
them.

For example:

~~~ Text
%left_associative PLUS MINUS.
%left_associative MULT DIV.
%right_associative POW.
~~~

specifies that:

  - `PLUS` and `MINUS` are left associative and equal in precedence
    compared to each other
  - `MULT` and `DIV` are left associative and equal in precedence
    compared to each other
  - `POW` is right associative
  - `POW` has higher precedence than `MULT` and `DIV`
  - `MULT` and `DIV` have higher precedence than `PLUS` and `MINUS`

Citron handles precedence and associativity in the same way as Lemon, so
the "Precedence Rules" section in the [Lemon documentation][lemon_doc]
applies to Citron as well. Lemon's %left, %right and %nonassoc
correspond to Citron's %left_associative, %right_associative and
%nonassociative respectively.

[lemon_doc]: https://www.hwaci.com/sw/lemon/lemon.html

#### left_associative

Specifies that a token is left asscociative.

#### right_associative

Specifies that a token is right asscociative.

#### nonassociative

Specifies that a token is non-asscociative.

### Grammar controls

#### start_symbol

Specifies the nonterminal to be used as the start symbol of the grammar.

If this directive is not specified, the LHS of the first rule in the
grammar is considered to be start symbol.

For example:

~~~ Text
%start_symbol func_header
~~~

#### token

The order of tokens in the `CitronTokenCode` enumeration is determined
by the order in which the tokens appear in the grammar. In case you'd
like a token to appear earlier in the enumeration, you can tell Citron
about the token before it appears in the grammar with this directive.

For example:

~~~ Text
%token COMMA
~~~

#### fallback

Specifies that a token can, if required, be treated as another token.

For example, in the above grammar, the keywords `throws` and `rethrows`
would be identified as the tokens `THROWS` and `RETHROWS`. So an input
like `func fn(throws: Bool)` would result in a syntax error, because the
`THROWS` token is not allowed inside the parameters clause. If you'd
like to allow the use of `throws` and `rethrows` as identifiers, you can
say:

~~~ Text
%fallback IDENTIFIER THROWS RETHROWS.
~~~

This specifies that the tokens `THROWS` and `RETHROWS` can be treated
as `IDENTIFIER` if that would help avoid a syntax error.

#### wildcard

Specifies a catch-all [fallback](#fallback) token.

For example:

~~~ Text
%wildcard IDENTIFIER.
~~~

specifies that `IDENTIFIER` is a fallback for _every other_ token in the
grammar.

#### token_set

Specifies that a nonterminal should be treated as a set of tokens.

For example, in the above grammar, the `throws_clause` nonterminal might
get defined like this, along with type specifications and code
blocks:

~~~ Text
%nonterminal_type throws_clause FunctionToken // same as %token_type

throws_clause ::= THROWS(t). { return t }
throws_clause ::= RETHROWS(t). { return t }
~~~

You can replace all those lines with a token set specification like
this:

~~~ Text
%token_set throws_clause THROWS | RETHROWS.
~~~

