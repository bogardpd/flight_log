require "spec_helper"

describe "should start_with" do
  context "with a string" do
    it "passes if it matches the start of the actual string" do
      "this string".should start_with "this str"
    end

    it "fails if it does not match the start of the actual string" do
      expect {
        "this string".should start_with "that str"
      }.to fail_with("expected \"this string\" to start with \"that str\"")
    end
  end

  context "with an array" do
    it "passes if it is the first element of the array" do
      [0, 1, 2].should start_with 0
    end

    it "passes if the first elements of the array match" do
      [0, 1, 2].should start_with 0, 1
    end

    it "fails if it does not match the first element of the array" do
      expect {
        [0, 1, 2].should start_with 2
      }.to fail_with("expected [0, 1, 2] to start with 2")
    end

    it "fails if it the first elements of the array do not match" do
      expect {
        [0, 1, 2].should start_with 1, 2
      }.to fail_with("expected [0, 1, 2] to start with [1, 2]")
    end
  end

  context "with an object that does not respond to :[]" do
    it "raises an ArgumentError" do
      expect { Object.new.should start_with 0 }.to raise_error(ArgumentError, /does not respond to :\[\]/)
    end
  end

  context "with a hash" do
    it "raises an ArgumentError if trying to match more than one element" do
      expect{
        {:a => 'b', :b => 'b', :c => 'c'}.should start_with({:a => 'b', :b => 'b'})
      }.to raise_error(ArgumentError, /does not have ordered elements/)
    end
  end
end

describe "should_not start_with" do
  context "with a string" do
    it "passes if it does not match the start of the actual string" do
      "this string".should_not start_with "that str"
    end

    it "fails if it does match the start of the actual string" do
      expect {
        "this string".should_not start_with "this str"
      }.to fail_with("expected \"this string\" not to start with \"this str\"")
    end
  end

  context "with an array" do
    it "passes if it is not the first element of the array" do
      [0, 1, 2].should_not start_with 2
    end

    it "passes if the first elements of the array do not match" do
      [0, 1, 2].should_not start_with 1, 2
    end

    it "fails if it matches the first element of the array" do
      expect {
        [0, 1, 2].should_not start_with 0
      }.to fail_with("expected [0, 1, 2] not to start with 0")
    end

    it "fails if it the first elements of the array match" do
      expect {
        [0, 1, 2].should_not start_with 0, 1
      }.to fail_with("expected [0, 1, 2] not to start with [0, 1]")
    end
  end
end

describe "should end_with" do
  context "with a string" do
    it "passes if it matches the end of the actual string" do
      "this string".should end_with "is string"
    end

    it "fails if it does not match the end of the actual string" do
      expect {
        "this string".should end_with "is stringy"
      }.to fail_with("expected \"this string\" to end with \"is stringy\"")
    end
  end

  context "with an array" do
    it "passes if it is the last element of the array" do
      [0, 1, 2].should end_with 2
    end

    it "passes if the last elements of the array match" do
      [0, 1, 2].should end_with [1, 2]
    end

    it "fails if it does not match the last element of the array" do
      expect {
        [0, 1, 2].should end_with 1
      }.to fail_with("expected [0, 1, 2] to end with 1")
    end

    it "fails if it the last elements of the array do not match" do
      expect {
        [0, 1, 2].should end_with [0, 1]
      }.to fail_with("expected [0, 1, 2] to end with [0, 1]")
    end
  end

  context "with an object that does not respond to :[]" do
    it "should raise an error if expected value can't be indexed'" do
      expect { Object.new.should end_with 0 }.to raise_error(ArgumentError, /does not respond to :\[\]/)
    end
  end

  context "with a hash" do
    it "raises an ArgumentError if trying to match more than one element" do
      expect{
        {:a => 'b', :b => 'b', :c => 'c'}.should end_with({:a => 'b', :b =>'b'})
      }.to raise_error(ArgumentError, /does not have ordered elements/)
    end
  end

end

describe "should_not end_with" do
  context "with a sting" do
    it "passes if it does not match the end of the actual string" do
      "this string".should_not end_with "stringy"
    end

    it "fails if it matches the end of the actual string" do
      expect {
        "this string".should_not end_with "string"
      }.to fail_with("expected \"this string\" not to end with \"string\"")
    end
  end

  context "an array" do
    it "passes if it is not the last element of the array" do
      [0, 1, 2].should_not end_with 1
    end

    it "passes if the last elements of the array do not match" do
      [0, 1, 2].should_not end_with [0, 1]
    end

    it "fails if it matches the last element of the array" do
      expect {
        [0, 1, 2].should_not end_with 2
      }.to fail_with("expected [0, 1, 2] not to end with 2")
    end

    it "fails if it the last elements of the array match" do
      expect {
        [0, 1, 2].should_not end_with [1, 2]
      }.to fail_with("expected [0, 1, 2] not to end with [1, 2]")
    end
  end
end
