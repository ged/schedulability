# -*- encoding: utf-8 -*-
# stub: schedulability 0.2.0.pre20160717085928 ruby lib

Gem::Specification.new do |s|
  s.name = "schedulability"
  s.version = "0.2.0.pre20160717085928"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger", "Mahlon E. Smith"]
  s.date = "2016-07-17"
  s.description = "Schedulability is a library for describing scheduled time. You can specify one\nor more periods of time using a simple syntax, then combine them to describe\nmore-complex schedules."
  s.email = ["ged@FaerieMUD.org", "mahlon@martini.nu"]
  s.extra_rdoc_files = ["History.md", "Manifest.txt", "README.md", "History.md", "README.md"]
  s.files = [".editorconfig", ".simplecov", "ChangeLog", "History.md", "Manifest.txt", "README.md", "Rakefile", "lib/schedulability.rb", "lib/schedulability/exceptions.rb", "lib/schedulability/mixins.rb", "lib/schedulability/parser.rb", "lib/schedulability/schedule.rb", "spec/helpers.rb", "spec/schedulability/mixins_spec.rb", "spec/schedulability/parser_spec.rb", "spec/schedulability/schedule_spec.rb", "spec/schedulability_spec.rb"]
  s.homepage = "http://deveiate.org/projects/schedulability"
  s.licenses = ["BSD-3-Clause"]
  s.rdoc_options = ["--main", "README.md"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0")
  s.rubygems_version = "2.5.1"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "Schedulability is a library for describing scheduled time"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<timecop>, ["~> 0.8"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.12"])
      s.add_development_dependency(%q<hoe>, ["~> 3.15"])
    else
      s.add_dependency(%q<loggability>, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.8"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<timecop>, ["~> 0.8"])
      s.add_dependency(%q<simplecov>, ["~> 0.12"])
      s.add_dependency(%q<hoe>, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<loggability>, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.8"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<timecop>, ["~> 0.8"])
    s.add_dependency(%q<simplecov>, ["~> 0.12"])
    s.add_dependency(%q<hoe>, ["~> 3.15"])
  end
end
