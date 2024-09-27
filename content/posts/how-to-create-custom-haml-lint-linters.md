+++
title = "How to Create Custom haml_lint Linters"
description = """\
                haml_lint provides a lot of useful linters, but you might have rules specific \
                to your Rails application. In this case, you'll have to create a custom linter \
                to enforce those rules.\
              """
date = "2021-09-27"

[extra.meta]
type = "article"
keywords = "haml_lint, custom linters, lint, Haml, Ruby on Rails, Ruby, Rails"
+++

The majority of software engineering teams have rules, guidelines or standards
for the code they write. While enforcing those manually can definitely work on
small teams, it doesn't scale for medium to large teams. By automating this
process, linters come to the rescue with their built-in rules. If this isn't
enough for your team, custom linters allow you to codify anything not already
covered by their default rules.

Today, you will learn how to create custom *haml_lint* linters for your *Haml*
view templates in your *Rails* application.

## What Are Linters?

In all kinds of projects, software engineers use linters to analyze source code
to catch programming errors and bugs, detect coding style inconsistencies,
enforce guidelines, measure code quality and much more. Web applications built
with *Rails* aren't different! Every day, thousands of *Rails* applications rely
on *RuboCop* to lint *Ruby* code. Same for *JavaScript* code with *ESLint*.
Linting view templates is possible with *erb_lint* for *ERB* templates,
*haml_lint* for *Haml* templates and *slim_lint*, you guessed it... for *Slim*!

So whenever linters find a potential issue in source code, they will report an
offense and you need to either fix the issue or in rare cases, discard it as a
false positive.

## Why and How Would You Create a Custom Linter?

*haml_lint* provides a lot of useful linters, but you might have rules specific
to your *Rails* application. In this case, you'll have to create a custom linter
to enforce those rules.

To begin, add the gem *haml_lint* in your *Gemfile* under the *development* and
*test* groups. Do it manually or with this command:

```bash
bundle add haml_lint --group=development,test
```

Let's now start with a simple example. In your *Rails* application, create the file
*my_first_linter.rb* under the *lib/haml_lint/* directory. Here's the code:

<!-- markdownlint-disable -->
```ruby
module HamlLint
  # MyFirstLinter is the name of the linter in this example, but it can be anything
  class Linter::MyFirstLinter < Linter
    include LinterRegistry

    # Report an offense if a `div` tag is used.
    #
    # @param [HamlLint::Tree::TagNode] a tag node in a Haml document
    def visit_tag(node)
      return unless node.tag_name == 'div'

      record_lint(node, "You're not allowed divs!")
    end
  end
end
```
<!-- markdownlint-enable -->

To use this linter, you need to enable it in your *haml_lint* configuration.  If
you haven't already configured *haml_lint*, create the file *.haml_lint.yml* at
the root of your *Rails* application. Those are the lines to add in your
*haml_lint* configuration:

<!-- markdownlint-disable -->
```yaml
require:
  - './lib/haml_lint/my_first_linter.rb'

linters:
  MyFirstLinter:
    enabled: true
```
<!-- markdownlint-enable -->

So from now on, whenever running *haml_lint*, this linter will report an
offense for every `<div>` defined in a *Haml* view template. This isn't the most
useful linter, but it's only the beginning!

## A Second Example

Let's have a look at another linter which reports an offense if the instance
variable `@pagetitle` is not set in a *Haml* view template. Again, same
procedure as with the first linter. Under the *lib/haml_lint/* directory, create
a file *set_pagetitle_in_view_linter.rb* with the following code:

```ruby
module HamlLint
  class Linter::SetPagetitleInView < Linter
    include LinterRegistry

    # Report an offense if the instance variable @pagetitle is not set in a
    # Haml view. Partials are ignored by this linter.
    #
    # @param [HamlLint::Tree::RootNode] the root of a syntax tree
    def visit_root(root_node)
      # Do not proceed if the view isn't under the directory 'app/views/'
      # and doesn't end with the extension '.html.haml'
      return unless root_node.file.match?(%r{^app/views/.*\.html\.haml$})

      # Do not proceed if the view is a partial.
      # Only partials start with an underscore.
      return if File.basename(root_node.file).start_with?('_')

      # Do not proceed if the view defines the instance variable @pagetitle,
      # then this rule is respected. Yay!
      return if instance_variable_pagetitle_is_defined?(document)

      record_lint(root_node, 'Set the instance variable @pagetitle to have a ' \
                             'page title when the view is rendered.')
    end

    private

    # @param [HamlLint::Document] a parsed Haml document and its associated metadata
    def instance_variable_pagetitle_is_defined?(document)
      ruby_source = HamlLint::RubyExtractor.new.extract(document).source
      parsed_ruby = HamlLint::RubyParser.new.parse(ruby_source)

      parsed_ruby.each_descendant.find do |descendant_node|
        # Details on Abstract Syntax Tree from Parser gem:
        # https://github.com/whitequark/parser/blob/11c7644365fe554217bb4670a4cbc905ab8504cd/doc/AST_FORMAT.md#to-instance-variable
        # Are we assigning an instance variable? Is it called @pagetitle?
        descendant_node.ivasgn_type? && descendant_node.children.first == :@pagetitle
      end
    end
  end
end
```

Enable this linter in your *haml_lint* configuration file. This should be the
content of *.haml_lint.yml*:

<!-- markdownlint-disable -->
```yaml
require:
  - './lib/haml_lint/my_first_linter.rb'
  - './lib/haml_lint/set_pagetitle_in_view_linter.rb'

linters:
  MyFirstLinter:
    enabled: true

  SetPagetitleInView:
    enabled: true
```
<!-- markdownlint-enable -->

With this example of a project-specific rule codified in a linter, it's now
impossible to forget assigning a value to `@pagetitle` in a view template. Gone
are the *"You forgot to set `@pagetitle` in view_123.html.haml."* reviews in a
pull request since running *haml_lint* will catch this issue. This is the power
of automation!

## A Deeper Look Into How *haml_lint* Linters Work

To really understand how *haml_lint* linters work, you need to learn a few
things. Nothing complicated, but without this knowledge, you won't be able to
create your own linters.

Different linters will analyze code in different ways by processing different
nodes. In *haml_lint*'s world, this is called visiting a node and it is defined
in the various `visit_*` methods like `visit_tag` or `visit_root`.

Going back to the two custom linters you've seen so far, the first visits HTML
tag nodes and checks if they are a `<div>`. The second linter is visiting root
nodes, those are complete *Haml* view templates, and verify if the instance
variable `@pagetitle` is set. Have a look at [*haml_lint*'s
code](https://github.com/sds/haml-lint/tree/78a551cd1ae239b8c6ac8686d8f219571c62ac66/lib/haml_lint/tree)
for a list of all nodes. Every node has its `visit_NODE_NAME` method. So
`visit_root` is for root nodes as you've already seen, `visit_script` is for
script nodes and so on.

To evaluate any *Ruby* code included in *Haml* view templates, *haml_lint*
relies on the [*parser*](https://github.com/whitequark/parser) gem to build an
[abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree). With
this, analyzing *Ruby* code is also possible in custom linters. It's exactly
what the second linter `SetPagetitleInView` does when verifying if `@pagetitle`
is set. While most linters probably won't need to go this deep, it's definitely
useful to know how.

For more linter examples, have a look at the
[linters](https://github.com/sds/haml-lint/tree/78a551cd1ae239b8c6ac8686d8f219571c62ac66/lib/haml_lint/linter)
included in *haml_lint*. This will definitely help you understand even better
how linters are built.

## Lint All The Things!

It's now time for you to create custom *haml_lint* linters for *Haml* view
templates in your *Rails* applications.
