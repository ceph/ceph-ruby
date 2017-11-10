# Ceph::Ruby

Easy management of Ceph Distributed Storage System (rbd, images, rados objects) using ruby.

## Development



## Installation

Add this line to your application's Gemfile:

    gem 'ceph-ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ceph-ruby

## Usage

    require "ceph-ruby"

    # version information
    puts CephRuby::Lib::Rados.version_string
    puts CephRuby::Lib::Rbd.version_string

    # connect to cluster and open a pool
    cluster = CephRuby::Cluster.new
    pool = cluster.pool("my-pool-xyz")
    pool.open

    # simple example for using rados objects
    object = pool.rados_object("my-object-xyz")
    object.write(0, "This is a Test!")
    puts object.size

    # simple example for using rbd images
    image = pool.rados_block_device("my-image-xyz")
    puts image.exists?
    image.create(10.gigabytes)
    puts image.exists?
    puts image.size
    image.write(0, "This is a Test!")
    pp image.stat
    image.close

    # clean up
    pool.close
    cluster.shutdown


## Known bugs

* Many features provided by ceph are not implemented yet. Please contribute!


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Copyright

Copyright (c) 2012 - 2013 [Netskin GmbH](http://www.netskin.com). Released unter the MIT license.
