# Puppet Library

A private Puppet Forge. Compatible with [librarian-puppet](http://librarian-puppet.com).

[![Build Status](https://api.travis-ci.org/drrb/puppet-library.svg)](https://travis-ci.org/drrb/puppet-library)
[![Coverage Status](https://img.shields.io/coveralls/drrb/puppet-library.svg)](https://coveralls.io/r/drrb/puppet-library)
[![Code Climate](https://img.shields.io/codeclimate/github/drrb/puppet-library.svg)](https://codeclimate.com/github/drrb/puppet-library)

[![Gem Version](https://badge.fury.io/rb/puppet-library.svg)](http://badge.fury.io/rb/puppet-library)
[![Dependency Status](https://gemnasium.com/drrb/puppet-library.svg)](https://gemnasium.com/drrb/puppet-library)

Puppet Library serves Puppet modules in the same format as [the Puppet Forge](http://forge.puppetlabs.com). This allows you to create a private Puppet Forge and manage all the modules you use completely within your infrastructure.

Plugins can be created to serve modules from arbitrary sources. Puppet Library contains built-in support for:
 - serving packaged (`.tar.gz`) modules from a directory (or directories) of your choosing
 - proxying a remote forge (or forges)
 - caching proxied forges to disk
 - serving modules from source on disk
 - serving modules from Git repositories using tags as version numbers!

## Demo

Puppet Library has a web UI to browse the modules. A demo is available [here](http://puppet-library.herokuapp.com).

## Installation

Install the server as a Gem:

    $ gem install puppet-library

Or, to get the latest, you can install from source

    $ git clone https://github.com/drrb/puppet-library.git
    $ cd puppet-library
    $ rake install

## Getting Started

Create a module directory and add the modules to it

    $ mkdir modules
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-apache-0.9.0.tar.gz
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-concat-1.0.0.tar.gz
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-stdlib-2.4.0.tar.gz

Start the server

    $ puppet-library --port 9292 --module-dir ./modules

Point librarian-puppet to the server

    $ cat > Puppetfile <<EOF
    forge 'http://localhost:9292'

    mod 'puppetlabs/apache', '0.9.0'
    EOF

Resolve and download the modules

    $ librarian-puppet install

## Usage

Run the server (proxies the Puppet Forge by default)

    $ puppet-library

Serve modules from a specific directory

    $ puppet-library --module-dir /var/puppet-modules

Serve modules from a remote forge as a proxy

    $ puppet-library --proxy http://forge.puppetlabs.com

Proxy a remote forge, caching downloaded modules on disk

    $ puppet-library --proxy http://forge.puppetlabs.com --cache-basedir

Serve a module from source

    $ puppet-library --source-dir ~/code/puppetlabs-apache

Serve modules on a specific port

    $ puppet-library --port 8888

See all options

    $ puppet-library --help

## Back-Ends

Puppet Library contains built-in support for:
 - serving packaged (`.tar.gz`) modules from a directory (or directories) of your choosing
 - proxying a remote forge (or forges)
 - serving modules from source on disk
 - serving modules from Git repositories using tags as version numbers!
 - serving modules from a combination of the above

## Compatibility with other tools

### Dependency Resolution/Installation

Puppet Library currently supports:
- search with Puppet (`puppet module search apache`)
- dependency resolution and installation with Puppet (`puppet module install puppetlabs/apache`)
- dependency resolution and installation with [librarian-puppet](http://librarian-puppet.com)
- installation with [r10k](https://github.com/adrienthebo/r10k)

### Ruby

Puppet Library is tested against Ruby versions:
- 1.8.7
- 1.9.3
- 2.0.0
- 2.1.0

### Puppet

Puppet Library implements version 1 of the Forge API, and supports reading
module metadata from modules' Modulefiles. This means that Puppet Library
can currently only work with Puppet < 3.6, which uses the new Forge API (v3)
and has switched to using `metadata.json` instead of `Modulefile`. Progress
can be tracked [here](https://github.com/drrb/puppet-library/issues?milestone=1).

## Config file (EXPERIMENTAL)

Instead of specifying command-line options, you can configure Puppet Library with a configuration file.
To use a configuration file, point to it on the command line:

```sh
puppet-library --config-file my-puppet-library-config.yml
```

A configuration file looks like this:

```yaml
port: 4567
server: thin
daemonize: true
pidfile: /var/run/puppetlibrary.pid
forges:
    - Directory: /var/lib/modules
    - Directory: /var/lib/other-modules
    - Source: /var/code/puppetlabs-apache
    - Proxy: http://forge.puppetlabs.com
```

## Running with Phusion Passenger (EXPERIMENTAL)

To run Puppet Library with [Phusion Passenger](https://www.phusionpassenger.com):

```sh
# Install Puppet Library
sudo gem install puppet-library

# Create a Passenger-compatible directory structure
mkdir -p /webapps/puppet-library/{public,tmp}

# Create a Rack config file to point Puppet Library to your modules
cat > /webapps/puppet-library/config.ru <<EOF
require "rubygems"
require "puppet_library"

# NB: this config API is not yet stable, and may change without notice.
# The format shown is valid from Puppet Library v0.11.0
server = PuppetLibrary::Server.configure do
    # Serve our private modules out of a directory on disk
    forge :directory do
        path = "/var/lib/modules"
    end

    # Serve the latest versions from GitHub
    forge :git_repository do
        source "http://github.com/example/puppetlabs-apache-fork.git"
        include_tags /[0-9.]+/
    end

    # Download all other modules from the Puppet Forge
    forge :proxy do
        url "http://forge.puppetlabs.com"
    end
end

run server
EOF

# Create an Apache virtual host pointing at Puppet Library
cat > /etc/httpd/conf.d/puppetlibrary.conf <<EOF
<VirtualHost *:80>
    ServerName privateforge.example.com
    DocumentRoot /webapps/puppet-library/public
    <Directory /webapps/puppet-library/public>
        Allow from all
        Options -MultiViews
    </Directory>
</VirtualHost>
EOF
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes, and add tests for them
4. Test your changes (`rake`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create new Pull Request

## Acknowledgements

This project was inspired by [dalen/simple-puppet-forge](https://github.com/dalen/simple-puppet-forge).

## License

Puppet Library
Copyright (C) 2014 drrb

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
