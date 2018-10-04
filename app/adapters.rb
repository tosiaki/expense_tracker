class XMLAdapter
  def generate(obj)
    Ox.dump(obj)
  end

  def parse(response)
    Ox.parse_obj(response)
  end
end
