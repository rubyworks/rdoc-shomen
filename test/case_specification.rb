require 'citron'
#require 'ae'

testcase "Document conforms to specificaiton" do

  # IMPORTANT! For now we need to hand create this document.
  fixture_document = 'test/fixture/doc/doc.json'

  before :all do
    @doc = JSON.load(File.new(fixture_document))
  end

  test "(metadata)" do
    assert @doc['(metadata)']
  end

end
