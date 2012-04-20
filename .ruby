---
source:
- meta
authors:
- name: trans
  email: transfire@gmail.com
copyrights:
- holder: Rubyworks
  year: '2011'
  license: BSD-2-Clause
requirements:
- name: shomen-model
- name: citron
  groups:
  - test
  development: true
- name: detroit
  groups:
  - build
  development: true
dependencies: []
alternatives: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/rdoc-shomen.git
  scm: git
  name: upstream
resources:
- uri: http://rubyworks.github.com/rdoc-shomen
  name: home
  type: home
- uri: http://rubydoc.info/gems/rdoc-shoment
  name: docs
  type: doc
- uri: http://github.com/rubyworks/rdoc-shomen
  name: code
  type: code
- uri: http://github.com/rubyworks/rdoc-shomen/issues
  name: bugs
  type: bugs
- uri: http://groups.google.com/groups/rubyworks-mailinglist
  name: mail
  type: mail
extra: {}
load_path:
- lib
revision: 0
created: '2010-07-01'
summary: RDoc Generator for Shomen Documentation Format
title: RDoc Shomen
version: 0.1.1
name: rdoc-shomen
description: ! 'RDoc-Shomen is an RDoc generator plugin that can be used to generate
  Shomen

  documentation. This is an alternative to the shomen command line tool which

  use the `.rdoc` cache to generate a shomen document. In contrast the rdoc-shomen

  generator operates as a traditional rdoc plugin.'
organization: rubyworks
date: '2012-04-16'
