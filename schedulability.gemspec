# -*- encoding: utf-8 -*-
# stub: schedulability 0.5.0.pre.20200304103926 ruby lib

Gem::Specification.new do |s|
  s.name = "schedulability".freeze
  s.version = "0.5.0.pre.20200304103926"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/Schedulability", "changelog_uri" => "https://deveiate.org/code/schedulability/History_md.html", "documentation_uri" => "https://deveiate.org/code/schedulability", "homepage_uri" => "https://hg.sr.ht/~ged/Schedulability", "source_uri" => "https://hg.sr.ht/~ged/Schedulability" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.date = "2020-03-04"
  s.description = "Schedulability is a library for describing scheduled time. You can specify one or more periods of time using a simple syntax, then combine them to describe more-complex schedules.".freeze
  s.email = ["ged@faeriemud.org".freeze, "mahlon@martini.nu".freeze]
  s.files = ["History.md".freeze, "README.md".freeze, "lib/schedulability.rb".freeze, "lib/schedulability/exceptions.rb".freeze, "lib/schedulability/parser.rb".freeze, "lib/schedulability/schedule.rb".freeze, "spec/helpers.rb".freeze, "spec/schedulability/parser_spec.rb".freeze, "spec/schedulability/schedule_spec.rb".freeze, "spec/schedulability_spec.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Schedulability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Schedulability is a library for describing scheduled time.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_development_dependency(%q<timecop>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.18"])
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.8"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.8"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.18"])
  end
end
