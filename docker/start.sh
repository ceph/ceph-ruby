#!/bin/bash

# Create the pools
ceph osd pool create my-pool-xyz 100

bin/ceph-ruby
