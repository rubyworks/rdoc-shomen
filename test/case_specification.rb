require 'citron'
require 'brass'
require 'json'

testcase "Document conforms to specificaiton" do

  # IMPORTANT! For now we need to hand create this document.
  FIXTURE_DOCUMENT = 'test/fixture/doc/doc.json'

  def initialize(*a,&b)
    super(*a,&b)

    @doc = JSON.load(File.new(FIXTURE_DOCUMENT))
  end

  test "(metadata)" do
    assert @doc['(metadata)']
  end

end
