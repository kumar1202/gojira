# Gojira

**Maintaining order within the Kong realm** [[ref](https://en.wikipedia.org/wiki/Gojira)]

<img src="docs/gojira.png" alt="drawing" width="500"/>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gojira'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gojira

## Usage

## Commands

### Env

* Lint: 
  * Searches through env directory 
  * get list of all products/services
  * checks if their upstream info is available across all clusters of that env 
  * service level validations(PCI/NPCI service tags, no route with tags)
  * Gives out errors of each validation level in JSON

* Generate: 
  * Merge product services files into one config
  * Substitute kong upstreams for respective compliance type and DC
  * Merge all product configs into one file
  * Not to interfere and merge global conf and certs, they will be passed with -s
  * Can include local config here later