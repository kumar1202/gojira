FROM ruby:3.3.1

RUN curl -sL https://github.com/Kong/deck/releases/download/v1.39.4/deck_1.39.4_linux_arm64.tar.gz -o deck.tar.gz
RUN tar -xf deck.tar.gz -C /tmp
RUN cp /tmp/deck /usr/local/bin/

COPY . /app

WORKDIR /app

RUN bundle install
RUN gem build gojira.gemspec
RUN gem install *.gem
