#!/bin/bash

# Create the pools
ceph osd pool create my-pool-xyz 100

bundle # This is in case you use a volume locally

bundle exec bin/ceph-ruby
