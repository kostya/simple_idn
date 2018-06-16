require "./spec_helper"

describe "SimpleIdn" do
  describe "to_unicode" do
    TESTCASES_JOSEFSSON.each do |testcase, vector|
      it "from `#{vector[1]}` to `#{vector[0]}`" do
        SimpleIdn.to_unicode(vector[1]).should eq vector[0]
      end
    end

    it "should respect * and not try to decode it" do
      SimpleIdn.to_unicode("*.xn--mllerriis-l8a.com").should eq("*.møllerriis.com")
    end

    it "should respect leading _ and not try to encode it" do
      SimpleIdn.to_unicode("_something.xn--mllerriis-l8a.com").should eq "_something.møllerriis.com"
    end

    it "empty string" do
      SimpleIdn.to_unicode("").should eq ""
    end

    it "should return . if only . given" do
      SimpleIdn.to_unicode(".").should eq "."
      SimpleIdn.to_unicode("..").should eq ".."
    end

    it "raises when the input is an invalid ACE" do
      expect_raises(Exception) do
        SimpleIdn.to_unicode("xn---")
      end
    end
  end
  describe "to_ascii" do
    TESTCASES_JOSEFSSON.each do |testcase, vector|
      it "from `#{vector[0]}` to `#{vector[1]}`" do
        SimpleIdn.to_ascii(vector[0]).should eq vector[1].downcase
      end
    end

    it "should respect * and not try to encode it" do
      SimpleIdn.to_ascii("*.hello.com").should eq "*.hello.com"
    end

    it "should respect leading _ and not try to encode it" do
      SimpleIdn.to_ascii("_something.example.org").should eq "_something.example.org"
    end
    it "should respect @ and not try to encode it" do
      SimpleIdn.to_ascii("@.hello.com").should eq("@.hello.com")
    end

    it "should return empty" do
      SimpleIdn.to_ascii("").should eq("")
    end

    it "should return . if only . given" do
      SimpleIdn.to_ascii(".").should eq "."
      SimpleIdn.to_ascii("..").should eq ".."
    end
  end
end
