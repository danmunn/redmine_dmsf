# Dav4rack - Web Authoring for Rack[![Build Status](https://travis-ci.org/planio-gmbh/dav4rack.svg?branch=master)](https://travis-ci.org/planio-gmbh/dav4rack)

Dav4rack is a framework for providing WebDAV via Rack allowing content
authoring over HTTP. It is based off the [original RackDAV
framework](http://github.com/georgi/rack_dav) adding some useful new features:

- Better resource support for building fully virtualized resource structures
- Generic locking as well as Resource level specific locking
- Interceptor middleware to provide virtual mapping to resources
- Mapped resource paths
- Authentication support
- Resource callbacks
- Remote file proxying (including sendfile support for remote files)
- Nokogiri based document parsing
- Ox based XML document building (for performance reasons)

If you find issues, please create a new issue on github. If you have fixes,
please fork the repo and send me a pull request with your modifications. If you
are just here to use the library, enjoy!


## About this fork

This is the [Planio](https://plan.io/redmine-hosting) fork of Dav4rack. The
master branch includes improvements and fixes done by @djgraham and
@tim-vandecasteele in their respective forks on Github.

It also incorporates various fixes that were made as part of the redmine\_dmsf
plugin, as well as improvements done by ourselves during development of an
upcoming redmine document management plugin.

Several core APIs were changed in the process so it will not be a straight
upgrade for applications that were developed with Dav4rack 0.3 (the last
released Gem version).

## Install

### Bundler

To use this fork, include in your Gemfile:

    gem 'dav4rack', git: 'https://github.com/planio-gmbh/dav4rack.git', branch: 'master'


### Via RubyGems

    gem install dav4rack

This will give you the last officially released version, which is *very* old.


## Documentation

- [Dav4rack documentation](http://chrisroberts.github.com/dav4rack)

## Quickstart

If you just want to share a folder over WebDAV, you can just start a
simple server with:

    dav4rack

This will start a Unicorn, Mongrel or WEBrick server on port 3000, which you
can connect to without authentication. Unicorn and Mongrel will be much more
responsive than WEBrick, so if you are having slowness issues, install one of
them and restart the dav4rack process.  The simple file resource allows very
basic authentication which is used for an example. To enable it:

    dav4rack --username=user --password=pass


## Rack Handler

Using Dav4rack within a rack application is pretty simple. A very slim
rackup script would look something like this:


```ruby
  require 'rubygems'
  require 'dav4rack'

  use Rack::CommonRails.logger
  run Dav4rack::Handler.new(root: '/path/to/public/fileshare')
```

This will use the included FileResource and set the share path. However,
Dav4rack has some nifty little extras that can be enabled in the rackup script.
First, an example of how to use a custom resource:

```ruby
  run Dav4rack::Handler.new(resource_class: CustomResource,
                            custom: 'options',
                            passed: 'to resource')
```

Next, lets venture into mapping a path for our WebDAV access. In this example,
we will use default FileResource like in the first example, but instead of the
WebDAV content being available at the root directory, we will map it to a
specific directory: `/webdav/share/`

```ruby
  require 'rubygems'
  require 'dav4rack'

  use Rack::CommonRails.logger

  app = Rack::Builder.new{
    map '/webdav/share/' do
      run Dav4rack::Handler.new(root: '/path/to/public/fileshare')
    end
  }.to_app
  run app
```

Aside from the `Builder#map` block, notice the new option passed to the Handler's
initialization, `:root_uri_path`. When Dav4rack receives a request, it will
automatically convert the request to the proper path and pass it to the
resource.

Another tool available when building the rackup script is the Interceptor. The
Interceptor's job is to simply intercept WebDAV requests received up the path
hierarchy where no resources are currently mapped. For example, lets continue
with the last example but this time include the interceptor:


```ruby
  require 'rubygems'
  require 'dav4rack'

  use Rack::CommonRails.logger
  app = Rack::Builder.new{
    map '/webdav/share/' do
      run Dav4rack::Handler.new(root: '/path/to/public/fileshare')
    end
    map '/webdav/share2/' do
      run Dav4rack::Handler.new(resource_class: CustomResource)
    end
    map '/' do
      use Dav4rack::Interceptor, mappings: {
        '/webdav/share/' => {resource_class: FileResource, custom: 'option'},
        '/webdav/share2/' => {resource_class: CustomResource}
      }
      use Rails::Rack::Static
      run ActionController::Dispatcher.new
    end
  }.to_app
  run app
```

In this example we have two WebDAV resources restricted by path. This means
those resources will handle requests to `/webdav/share/* and /webdav/share2/*`
but nothing above that. To allow webdav to respond, we provide the Interceptor.
The Interceptor does not provide any authentication support. It simply creates
a virtual file system view to the provided mapped paths. Once the actual
resources have been reached, authentication will be enforced based on the
requirements defined by the individual resource. Also note in the root map you
can see we are running a Rails application. This is how you can easily enable
Dav4rack with your Rails application.


## Custom Middleware

This is an alternative way to integrate one or more webdav handlers into a
Rails app. It uses a custom middleware dispatching to any number of mounted
Dav4Rack handlers, handles OPTIONS requests outside the webdav namespaces for
interoperability with microsoft windows and lastly dispatches any remaining
requests to the main (Rails) application.

```ruby

class CustomMiddleware

  def initialize(app)
    @rails_app = app

    @dav_app = Rack::Builder.new{
      map '/dav/' do
        run Dav4rack::Handler.new(resource_class: CustomResource)
      end

      map '/other/dav' do
        run CustomDavHandler.new
      end
    }.to_app
  end

  def call(env)
    status, headers, body = @dav_app.call env

    # If the URL map generated by Rack::Builder did not find a matching path,
    # it will return a 404 along with the X-Cascade header set to 'pass'.
    if status == 404 and headers['X-Cascade'] == 'pass'

      # The MS web redirector webdav client likes to go up a level and try
      # OPTIONS there. We catch that here and respond telling it that just
      # plain HTTP is going on.
      if 'OPTIONS'.casecmp(env['REQUEST_METHOD'].to_s) == 0
        [ '200', { 'Allow' => 'OPTIONS,HEAD,GET,PUT,POST,DELETE' }, [''] ]
      else
        # let Rails handle the request
        @rails_app.call env
      end

    else
      [status, headers, body]
    end
  end

end
```

You can add this middleware to your Rails app using

```ruby
Rails.configuration.middleware.insert_before ActionDispatch::Cookies, CustomMiddleware
```

## Logging

Dav4rack provides some simple logging in a Rails style format (simply for
consistency) so the output should look somewhat familiar.

    Dav4rack::Handler.new(resource_class: CustomResource, log_to: '/my/log/file')

You can even specify the level of logging:

    Dav4rack::Handler.new(resource_class: CustomResource, log_to: ['/my/log/file', Rails.logger::DEBUG])

In order to use the Rails Rails.logger, just specify `log_to: Rails.logger`.

## Custom Resources

Creating your own resource is easy. Simply inherit the Dav4rack::Resource
class, and start redefining all the methods you want to customize. The
Dav4rack::Resource class only has implementations for methods that can be
provided extremely generically. This means that most things will require at
least some sort of implementation. However, because the Resource is defined so
generically, and the Controller simply passes the request on to the Resource,
it is easy to create fully virtualized resources.

## Helpers

There are some helpers worth mentioning that make things a little easier.

First of all, take note that the `request` object will be an instance of `Dav4rack::Request`, which extends `Rack::Request` with some useful helpers.

### Redirects and sending remote files

If `request.client_allows_redirect?` is true, the currently connected client
will accept and properly use a 302 redirect for a GET request. Most clients do
not properly support this, which can be a real pain when working with
virtualized files that may be located some where else, like S3. To deal with
those clients that don't support redirects, a helper has been provided so
resources don't have to deal with proxying themselves. The Dav4rack::RemoteFile
is a modified Rack::File that can do some interesting things. First, lets look
at its most basic use:

  class MyResource < Dav4rack::Resource
    def setup
      @item = method_to_fill_this_properly
    end

    def get
      if(request.client_allows_redirect?)
        response.redirect item[:url]
      else
        response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type)
        OK
      end
    end
  end

This is a simple proxy. When Rack receives the RemoteFile, it will pull a chunk of data from object, which in turn pulls it from the socket, and
sends it to the user over and over again until the EOF is reached. This much the same method that Rack::File uses but instead we are pulling
from a socket rather than an actual file. Now, instead of proxying these files from a remote server every time, lets cache them:

    response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type, :cache_directory => '/tmp')

Providing the `:cache_directory` will let RemoteFile cache the items locally,
and then search for them on subsequent requests before heading out to the
network. The cached file name is based off the SHA1 hash of the file path, size
and last modified time. It is important to note that for services like S3, the
path will often change, making this cache pretty worthless. To combat this, we
can provide a reference to use instead:

    response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type, :cache_directory => '/tmp', :cache_ref => item[:static_url])

These methods will work just fine, but it would be really nice to just let
someone else deal with the proxying and let the process get back to dealing
with actual requests. RemoteFile will happily do that as long as the frontend
server is setup correctly. Using the sendfile approach will tell the RemoteFile
to simply pass the headers on and let the server deal with doing the actual
proxying. First, lets look at an implementation using all the features, and
then degrade that down to the bare minimum. These examples are NGINX specific,
but are based off the Rack::Sendfile implementation and as such should be
applicable to other servers. First, a simplified NGINX server block:

    server {
      listen 80;
      location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Sendfile-Type X-Accel-Redirect;
        proxy_set_header X-Accel-Remote-Mapping webdav_redirect
        proxy_pass http://my_app_server;
      }

      location ~* /webdav_redirect {
        internal;
        resolver 127.0.0.1;
        set $r_host $upstream_http_redirect_host;
        set $r_url $upstream_http_redirect_url;
        proxy_set_header Authorization '';
        proxy_set_header Host $r_host;
        proxy_max_temp_file_size 0;
        proxy_pass $r_url;
      }
    }

With this in place, the parameters for the RemoteFile change slightly:

    response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type, :sendfile => true)

The RemoteFile will automatically take care of building out the correct path and sending the proper headers. If the X-Accel-Remote-Mapping header
is not available, you can simply pass the value:

    response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type, :sendfile => true, :sendfile_prefix => 'webdav_redirect')

And if you don't have the X-Sendfile-Type header set, you can fix that by changing the value of :sendfile:

    response.body = Dav4rack::RemoteFile.new(item[:url], :size => content_length, :mime_type => content_type, :sendfile => 'X-Accel-Redirect', :sendfile_prefix => 'webdav_redirect')

And if you have none of the above because your server hasn't been configured for sendfile support, you're out of luck until it's configured.

## Authentication

Authentication is performed on a per Resource basis. The Controller object will
call `#authenticate` on any Resources it handles requests for.  Basic
Authentication information from the request will be passed to the method.
Depending on the result, the Controller will either continue on with the
request, or send a 401 Unauthorized response.

Override `Resource#authentication_realm` and `Resource#authentication_error_msg` to customize the realm name and response content for authentication failures.

Authentication can also be implemented using callbacks, as discussed below.

## Callbacks

*Deprecated*. This feature will most probably be removed in the future.

If you want to implement general before/after logic for every request, use a
custom controller class and override `#process`.


Resources can make use of callbacks to easily apply permissions, authentication or any other action that needs to be performed before or after any or all
actions. Callbacks are applied to all publicly available methods. This is important for methods used internally within the resource. Methods not meant
to be called by the Controller, or anyone else, should be scoped protected or private to reduce the interaction with callbacks.

Callbacks can be called before or after a method call. For example:

  class MyResource < Dav4rack::Resource
    before do |resource, method_name|
      resource.send(:my_authentication_method)
    end

    after do |resource, method_name|
      puts "#{Time.now} -> Completed: #{resource}##{method_name}"
    end

    private

    def my_authentication_method
      true
    end
  end

In this example MyResource#my_authentication_method will be called before any public method is called. After any method has been called a status
line will be printed to STDOUT. Running callbacks before/after every method call is a bit much in most cases, so callbacks can be applied to specific
methods:

  class MyResource < Dav4rack::Resource
    before_get do |resource|
      puts "#{Time.now} -> Received GET request from resource: #{resource}"
    end
  end

In this example, a simple status line will be printed to STDOUT before the MyResource#get method is called. The current resource object is always
provided to callbacks. The method name is only provided to the generic before/after callbacks.

Something very handy for dealing with the mess of files OS X leaves on the system:

  class MyResource < Dav4rack::Resource
    after_unlock do |resource|
      resource.delete if resource.name[0,1] == '.'
    end
  end

Because OS X implements locking correctly, we can wait until it releases the lock on the file, and remove it if it's a hidden file.

Callbacks are called in the order they are defined, so you can easily build callbacks off each other. Like this example:

  class MyResource < Dav4rack::Resource
    before do |resource, method_name|
      resource.DAV_authenticate unless resource.user.is_a?(User)
      raise Unauthorized unless resource.user.is_a?(User)
    end
    before do |resource, method_name|
      resource.user.allowed?(method_name)
    end
  end

In this example, the second block checking User#allowed? can count on Resource#user being defined because the blocks are called in
order, and if the Resource#user is not a User type, an exception is raised.

### Avoiding callbacks

Something special to notice in the last example is the DAV_ prefix on authenticate. Providing the DAV_ prefix will prevent
any callbacks being applied to the given method. This allows us to provide a public method that the callback can access on the resource
without getting stuck in a loop.

## Software using Dav4rack!

* {meishi}[https://github.com/inferiorhumanorgans/meishi] - Lightweight CardDAV implementation in Rails
* {dav4rack_ext}[https://github.com/schmurfy/dav4rack_ext] - CardDAV extension. (CalDAV planned)

## Issues/Bugs/Questions

### Known Issues

- OS X Finder PUT fails when using NGINX (this is due to NGINX's lack of
  chunked transfer encoding in earlier versions). Use a recent version of
  NGINX.
- Windows WebDAV mini-redirector - this client is very broken. Windows from
  version 7 onwards however should work fine with the `OPTIONS` handling
  addition demonstrated above.
- Lots of unimplemented parts of the webdav spec (patches always welcome). Run
  `test/litmus_all.sh` to see what works and what doesnt.


### Unknown Issues

Please report issues at github: http://github.com/planio-gmbh/dav4rack/issues
Include as much information about the environment as possible (especially client OS / software).

## Contributors

A big thanks to everyone contributing to help make this project better.

* [clyfe](http://github.com/clyfe)
* [antiloopgmbh](http://github.com/antiloopgmbh)
* [krug](http://github.com/krug)
* [teefax](http://github.com/teefax)
* [buffym](https://github.com/buffym)
* [jbangert](https://github.com/jbangert)
* [doxavore](https://github.com/doxavore)
* [spicyj](https://github.com/spicyj)
* [TurchenkoAlex](https://github.com/TurchenkoAlex)
* [exabugs](https://github.com/exabugs)
* [inferiorhumanorgans](https://github.com/inferiorhumanorgans)
* [schmurfy](https://github.com/schmurfy)
* [pifleo](https://github.com/pifleo)
* [mlmorg](https://github.com/mlmorg)

## License

Just like RackDAV before it, this software is distributed under the MIT license.
