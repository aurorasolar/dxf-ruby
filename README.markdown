# DXF

[![Build Status](https://travis-ci.org/bfoz/dxf-ruby.png)](https://travis-ci.org/bfoz/dxf-ruby)

Tools for working with the popular DXF file format

## Installation

Add this line to your application's Gemfile:

    gem 'DXF'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dxf

## Usage

```ruby
require 'dxf'

# To export the my_sketch object in inches
DXF.write('filename.dxf', my_sketch, :inches)
```

### I want to push new dxf-ruby and backend code. What do I do?

1. Visit <https://github.com/aurorasolar/dxf-ruby/releases> and see what is the latest release available. Your tag will be the latest release +1. For example, if the latest tag is `0.6.07`, yours will be `0.6.08`.
    - Alternatively, if you have a full (**not** shallow) repo, you can do:
        ```
        git pull
        git tag -l --format '%(taggerdate:short) | %(refname:strip=2) %(objectname:short) %(authoremail) %(contents:lines=1)' | tail -n5`
        # tip: add above tag format as a git alias (git config --global alias.tl 'tag -l ...'; git tl)
        ```
2. Update the file `dxf-in-ruby.gemspec` with the new version
3. Commit your changes: `git commit -m 'feat/cool-feature: made it fly to space'`
4. Tag your latest commit with an annotated (**not light**) git tag as following:
    - `git tag -m 'Station docking procedure attempt 7' TAG_VERSION`
5. Push your branch and its tags to GitHub: `git push --follow-tags` Note: do not `git push --tags` as this will push tags from all your branches. If a tag has changed upstream, you may be prompted to force-push over it, do **not** do that unless you are over-writing your own tag or fixing a previous mistake
6. (Backend) Now go into your backend repo and change the `Gemfile` line `gem 'aurorasolar/dxf-ruby', :git => 'http://...long-url.../dxf-ruby.git', tag: 'OLD_TAG'` to use the new `$TAG_VERSION` that you just pushed to github
7. (Backend) Run `bundle install` to pull the new dxf-ruby version.
8. (Backend) Please run tests on the backend repo just to make sure everything is working


### How to make staging fixes and hotfixes
The following steps outline how to make staging fixes and hotfixes for dxf-ruby. However, if you have any doubts or questions, please consult a backend engineer first.
- Checkout the dxf-ruby version tagged on [`staging` for backend](https://github.com/aurorasolar/backend/blob/staging/Gemfile) (or [`master` for a hotfix](https://github.com/aurorasolar/backend/blob/master/Gemfile))
- Branch off of that release
- Make a `git tag` with your changes
- Create a dxf-ruby PR into development
- Make a backend staging-fix (or hotfix) PR set `development`/`staging`(/`master`) using the new tag
- When dxf-ruby code changes are approved, merge backend `staging` (or `master`)
- (For a hotfix, the following steps must be done on `staging` as well)
- Update your dxf-ruby branch off `development` (`staging`)
- Create a new `git tag`
- On backend, for your `development` (or `staging`) PR, reference the new version
- Merge

License
-------

Copyright 2012-2013 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.
