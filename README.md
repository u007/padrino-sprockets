# Padrino::Sprockets

Sprockets, also known as "the asset pipeline", is a system for pre-processing, compressing and serving up of javascript, css and image assets. `Padrino::Sprockets` provides integration with the Padrino web framework.

## Installation

Install from RubyGems:

```sh
$ gem install padrino-sprockets
```

Or include it in your project's `Gemfile` with Bundler:

```ruby
gem 'padrino-sprockets', :require => "padrino/sprockets"
```


## Usage

Inside config/apps.rb

```ruby
if RACK_ENV == 'production'
  set :assets_url, 'assets'
  set :assets_debug, false
  # set :show_exceptions, false
else
  set :assets_url, 'dev-assets'
  set :assets_debug, false
  # set :show_exceptions, true
end
```

Place your assets under these paths:

```
app/assets/javascripts
app/assets/images
app/assets/stylesheets
```

Register sprockets in your application:

```ruby
class Redstore < Padrino::Application
  register Padrino::Sprockets
  sprockets
end
```

Now when requesting a path like `/assets/application.js` it will look for a source file in one of these locations :

* `app/assets/javascripts/application.js`
* `app/assets/javascripts/application.js.coffee`
* `app/assets/javascripts/application.js.erb`

To minify javascripts in production do the following:

In your Gemfile:

```ruby
# enable js minification
gem 'uglifier'
# enable css compression
gem 'yui-compressor'
```

In your app:

```ruby
class Redstore < Padrino::Application
  register Padrino::Sprockets
  sprockets :minify => (Padrino.env == :production)
end
```

For more documentation about sprockets, have a look at the [Sprockets](https://github.com/sstephenson/sprockets/) gem.

## Helpers Usage

### sprockets

```ruby
:minify => true / false
```

## Contributors

* [@matthias-guenther](https://github.com/matthias-guenther)
* [@swistak](https://github.com/swistak)
* [@dommmel](https://github.com/dommmel)
* [@charlesvallieres](https://github.com/charlesvallieres)
* [@jfcixmedia](https://github.com/jfcixmedia)
* [@stefl](https://github.com/stefl)
* [@mikesten](https://github.com/mikesten)
