# Puppet Library

A server for your Puppet modules. Compatible with [librarian-puppet](http://librarian-puppet.com).

[![Build Status](https://travis-ci.org/drrb/puppet-library.png?branch=master)](https://travis-ci.org/drrb/puppet-library)
[![Coverage Status](https://coveralls.io/repos/drrb/puppet-library/badge.png)](https://coveralls.io/r/drrb/puppet-library)

Puppet library serves packaged (`tar.gz`) modules from a directory of your choosing in the same format as [the Puppet Forge](http://forge.puppetlabs.com).

## Installation

Install the server as a Gem:

    $ gem install puppet-library

## Getting Started

Create a module directory and add the modules to it

    $ mkdir modules
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-apache-0.9.0.tar.gz
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-concat-1.0.0.tar.gz
    $ wget -P modules/ forge.puppetlabs.com/system/releases/p/puppetlabs/puppetlabs-stdlib-2.4.0.tar.gz

Start the server

    $ puppet-library

Point librarian-puppet to the server

    $ cat > Puppetfile <<EOF
    forge 'http://localhost:9292'

    mod 'puppetlabs/apache', '0.9.0'
    EOF

Resolve and download the modules

    $ librarian-puppet install

## Usage

Run the server

    $ puppet-library

Serve modules from a specific directory

    $ puppet-library --module-dir /var/puppet-modules

Serve modules on a specific port

    $ puppet-library --port 8888

See all options

    $ puppet-library --help

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
Copyright (C) 2013 drrb

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
