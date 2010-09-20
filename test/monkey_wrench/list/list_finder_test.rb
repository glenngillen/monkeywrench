$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class MonkeyWrench::ListFinderTest < Test::Unit::TestCase
  context "finding a list" do
    setup do
      setup_config
    end
    context "finding a list by id" do
      should "find a list by id" do
        mock_chimp_post(:lists)
        list = MonkeyWrench::List.find("my-list-id")
        expected = MonkeyWrench::List.new(:id => "my-list-id")
        assert_equal expected, list
      end
      should "return nil if the list doesn't exist" do
        mock_chimp_post(:lists)
        list = MonkeyWrench::List.find("imaginary-list-id")
        assert_equal nil, list
      end
    end
    context "finding a list by name" do
      should "find a single list by name" do
        mock_chimp_post(:lists)
        list = MonkeyWrench::List.find_by_name("A test list")
        assert_equal MonkeyWrench::List.new(:id => "my-list-id"), list
      end
      should "return nil if the list doesn't exist" do
        mock_chimp_post(:lists)
        list = MonkeyWrench::List.find_by_name("An imaginary list")
        assert_equal nil, list
      end
    end
  end
  context "finding all lists" do
    setup do
      setup_config
    end
    should "return an empty array if no lists exist" do
      mock_chimp_post(:lists, {}, true, "listsEmpty")
      lists = MonkeyWrench::List.find_all
      assert_equal [], lists
    end
    should "return an array of lists" do
      mock_chimp_post(:lists)
      lists = MonkeyWrench::List.find_all
      expected = [MonkeyWrench::List.new(:id => "my-list-id")]
      assert_equal expected, lists
    end
  end
  context "caching" do
    setup do
      setup_config
    end
    should "be cleared when #clear! is called" do
      mock_chimp_post(:lists)
      MonkeyWrench::List.find_all
      MonkeyWrench::List.clear!
      mock_chimp_post(:lists, {}, true, "listsEmpty")
      lists = MonkeyWrench::List.find_all
      assert_equal [], lists
    end
    should "cache the list of lists" do
      mock_chimp_post(:lists)
      MonkeyWrench::List.find_all
      mock_chimp_post(:lists, {}, true, "listsEmpty")
      lists = MonkeyWrench::List.find_all
      expected = [MonkeyWrench::List.new(:id => "my-list-id")]
      assert_equal expected, lists
    end
  end
end
