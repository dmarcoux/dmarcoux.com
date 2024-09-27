+++
title = "Easily Upgrade Your Rails Applications With next_rails"
description = """\
                With next_rails, a toolkit to upgrade Rails applications, turn your \
                wish into reality. next_rails makes the whole upgrade process easier \
                to manage by allowing you to gradually change your code.\
              """
date = "2021-08-13"

[extra.meta]
type = "article"
keywords = "Ruby on Rails, Ruby, Rails, next_rails, Update, Upgrade, Toolkit, Dual Boot"
+++

Did you ever wish you could upgrade your *Rails* applications without doing it
all at once? This would make everything much easier, right?

With *next_rails*, a toolkit to upgrade *Rails* applications, turn your wish
into reality. While *Rails* upgrades tend to be manageable in small
applications, many issues are often arising in larger applications due to
upstream changes like the removal of deprecated features. *next_rails* makes the
whole upgrade process easier to manage by allowing you to gradually change your
code. Let's start!

## How *next_rails* Works

*next_rails* is a gem and you should add it in your *Gemfile* under the
*development* group. Do it manually or with this command:

```bash
bundle add next_rails --group=development
```

Once *next_rails* is installed, you set it up with `next --init`. This command
slightly changes your *Gemfile* while also creating *Gemfile.next*, a symlink to
your *Gemfile*. The following lines are added to your *Gemfile*:

```ruby
def next?
  File.basename(__FILE__) == "Gemfile.next"
end
```

The last step to setup *next_rails* is to add a `if...else` statement to your
*Gemfile* under the newly introduced `next?` method. This replaces the usual
`gem 'rails'` line found in every *Gemfile* of a *Rails* application, so don't
forget to delete that line too.

<!-- markdownlint-disable -->
```ruby
if next?
  # This is the next Rails version your application will run
  gem 'rails', '~> 6.1'
else
  # This is the Rails version your application currently runs
  gem 'rails', '~> 6.0'
end
```
<!-- markdownlint-enable -->

To run *Bundler* with the next *Rails* version, you can prefix any *Bundler*
call with `next`. Let's execute `next bundle install`, this will generate
*Gemfile.next.lock* with all gems listed in your *Gemfile*, but unlike
*Gemfile.lock*, it will point to the next *Rails* version as listed in the
`if...else` statement above. Another command example would be `next bundle exec
rails s` to start your Rails application with the next *Rails* version.

## How to Write Code for the Next *Rails* Version

In the directory *lib* located at the root of your *Rails* application, define a
new module `RailsVersion`:

<!-- markdownlint-disable -->
```ruby
# lib/rails_version.rb
module RailsVersion
  def self.is_6_1?
    Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR == 1
  end
end
```
<!-- markdownlint-enable -->

With this module, you can then check if the application is currently running
with the next *Rails* version. It can be in models, controllers, etc...

*This class...*

```ruby
class Bicycle
  def repair
    'The bicycle is all fixed up!'
  end
end
```

*...is adapted for the next Rails version:*

```ruby
class Bicycle
  def repair
    # Code for the next Rails version
    return 'Everything is repaired!' if RailsVersion.is_6_1?

    # Code for the current Rails version
    'The bicycle is all fixed up!'
  end
end
```

Adapting code for the next *Rails* version doesn't have to be complicated. A
guard clause or a `if...else` statement should be enough in most cases. If
needed, you could also write a separate method like this:

```ruby
class Bicycle
  def repair
    # Code for the next Rails version
    return repair_6_1 if RailsVersion.is_6_1?

    # Code for the current Rails version
    'The bicycle is all fixed up!'
  end

  def repair_6_1
    # Do whatever needs to be done for the next Rails version
  end
end
```

## How to Roll Out the Next *Rails* Version

You can safely upgrade the *Rails* version in the *Gemfile* once all issues
arising from the next *Rails* version have been addressed:

<!-- markdownlint-disable -->
```ruby
if next?
  gem 'rails', '~> 6.1'
else
  # Now the same version as above
  gem 'rails', '~> 6.1'
end
```
<!-- markdownlint-enable -->

The code for the newly upgraded *Rails* version is kept and the rest is removed.

*This class...*

```ruby
class Bicycle
  def repair
    # Code for next Rails version
    return 'Everything is repaired!' if RailsVersion.is_6_1?

    # Code for current Rails version
    'The bicycle is all fixed up!'
  end
end
```

*...is changed to:*

```ruby
class Bicycle
  def repair
    'Everything is repaired!'
  end
end
```

## How to Keep *Gemfile.next.lock* Up-to-Date

The version of *Rails* and other gems tracked in *Gemfile.next.lock* have to be
updated from time to time to follow the dependency updates happening on the
default *Gemfile.lock*. This is how you can achieve this:

1. Overwrite *Gemfile.next.lock* with a copy of *Gemfile.lock*:

   ```bash
   cp Gemfile.lock Gemfile.next.lock
   ```

2. Inside your development environment, update the *Rails* version:

   ```bash
   next bundle update rails
   ```

3. Create a pull request with the changes or commit them to a branch, this
   depends on your project.

## How Did It Go For You?

This is it, you're set to use *next_rails* in your *Rails* applications.
