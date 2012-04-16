config :rubytest do |test|
  test.run :default do |r|
    r.files < 'test/case_*.rb'
  end
end

