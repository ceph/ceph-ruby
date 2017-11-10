FROM docker-registry.nine.ch/ninech/ruby:trusty
MAINTAINER development@nine.ch

RUN apt-get -qq update && apt-get -qq install -y wget && \
    rm -rf /var/lib/apt/lists/*

# Install the latest version of Ceph to get the latest librbd and the like (required by the tool).
RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add - && \
      echo "deb http://download.ceph.com/debian-jewel/ trusty main" | tee /etc/apt/sources.list.d/ceph-jewel.list && \
      apt-get update && apt-get install -y --force-yes ceph radosgw && \
      apt-get autoremove -y && \
      rm -rf /var/lib/apt/lists/*

COPY lib/ceph-ruby/version.rb /app/lib/ceph-ruby/version.rb
COPY Gemfile ceph-ruby.gemspec ./

RUN bundle install -j2

COPY . /app

CMD ["docker/start.sh"]
