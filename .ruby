---
source:
- meta
authors:
- name: trans
  email: transfire@gmail.com
copyrights: []
requirements:
- name: rdoc
  version: 3+
- name: qed
  groups:
  - test
  development: true
- name: ae
  groups:
  - test
  development: true
- name: detroit
  groups:
  - build
  development: true
- name: reap
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
  home: http://rubyworks.github.com/rdoc-shomen
  docs: http://rubydoc.info/gems/rdoc-shoment
  code: http://github.com/rubyworks/rdoc-shomen
  bugs: http://github.com/rubyworks/rdoc-shomen/issues
  mail: http://groups.google.com/groups/rubyworks-mailinglist
extra: {}
load_path:
- lib
revision: 0
created: '2010-07-01'
summary: RDoc Generator for Shomen Documentation Format
title: RDoc Shomen
version: 0.1.0
name: rdoc-shomen
description: ! 'RDoc-Shomen is an RDoc generator plugin that can be used to generate
  Shomen

  documentation. This is an alternative to the shomen command line tool which

  use the `.rdoc` cache to generate a shomen document. In contrast the rdoc-shomen

  generator operates as a traditional rdoc plugin.'
organization: rubyworks
date: '2012-03-31'
