require "suture/tests_patient"
require "suture/value/observation"
require "suture/value/test_plan"

module Suture
  class TestsPatientTest < Minitest::Test
    def setup
      @subject = TestsPatient.new
    end

    def test_single_successful_call
      dictaphone = gimme_next(Suture::Adapter::Dictaphone)
      observation = Value::Observation.new(1, :multiply, [1,2,3], 6)
      give(dictaphone).play { [observation] }
      test_plan = Value::TestPlan.new(
        :name => :multiply,
        :subject => lambda {|a,b,c| a * b * c }
      )

      result = @subject.test(test_plan)

      verify!(dictaphone).initialize(test_plan)
      assert_equal false, result.failed?
      assert_equal true, result.ran_all_tests?
      assert_equal 1, result.total_count
      assert_equal 1, result.passed_count
      assert_equal 0, result.failed_count
      assert_equal 0, result.skipped_count
      assert_equal 0, result.errored_count
      assert_equal({
        :observation => observation,
        :passed => true,
        :ran => true
      }, result.results.first)
    end

    def test_single_failing_call
      dictaphone = gimme_next(Suture::Adapter::Dictaphone)
      observation = Value::Observation.new(1, :multiply, [1,2,3], "this isn't 6 at all!!!")
      give(dictaphone).play { [observation] }
      test_plan = Value::TestPlan.new(
        :name => :multiply,
        :subject => lambda {|a,b,c| a * b * c }
      )

      result = @subject.test(test_plan)

      verify!(dictaphone).initialize(test_plan)
      assert_equal true, result.failed?
      assert_equal true, result.ran_all_tests?
      assert_equal 1, result.total_count
      assert_equal 0, result.passed_count
      assert_equal 1, result.failed_count
      assert_equal 0, result.skipped_count
      assert_equal 0, result.errored_count
      assert_equal({
        :observation => observation,
        :passed => false,
        :ran => true
      }, result.results.first)
    end

    def test_fail_fast
      dictaphone = gimme_next(Suture::Adapter::Dictaphone)
      call1 = Value::Observation.new(1, :multiply, [1,2,3], "this isn't 6 at all!!!")
      call2 = Value::Observation.new(1, :multiply, [1,2,3], 6)
      give(dictaphone).play { [call1, call2] }
      test_plan = Value::TestPlan.new(
        :name => :multiply,
        :subject => lambda {|a,b,c| a * b * c },
        :fail_fast => true
      )

      result = @subject.test(test_plan)

      verify!(dictaphone).initialize(test_plan)
      assert_equal true, result.failed?
      assert_equal false, result.ran_all_tests?
      assert_equal 2, result.total_count
      assert_equal 0, result.passed_count
      assert_equal 1, result.failed_count
      assert_equal 1, result.skipped_count
      assert_equal 0, result.errored_count
      assert_equal({
        :observation => call1,
        :passed => false,
        :ran => true
      }, result.results.first)
      assert_equal({
        :observation => call2,
        :passed => nil,
        :ran => false
      }, result.results.last)
    end

    def test_with_errors
      dictaphone = gimme_next(Suture::Adapter::Dictaphone)
      some_error = StandardError.new
      call1 = Value::Observation.new(1, :multiply, [2,3,4], 24)
      call2 = Value::Observation.new(1, :multiply, [1,2,3], 6)
      give(dictaphone).play { [call1, call2] }
      test_plan = Value::TestPlan.new(
        :name => :multiply,
        :subject => lambda {|a,b,c|
          if a == 2
            raise some_error
          else
            a * b * c
          end
        }
      )

      result = @subject.test(test_plan)

      verify!(dictaphone).initialize(test_plan)
      assert_equal true, result.failed?
      assert_equal true, result.ran_all_tests?
      assert_equal 2, result.total_count
      assert_equal 1, result.passed_count
      assert_equal 1, result.failed_count
      assert_equal 0, result.skipped_count
      assert_equal 1, result.errored_count
      assert_equal({
        :observation => call1,
        :passed => false,
        :error => some_error,
        :ran => true
      }, result.results.first)
      assert_equal({
        :observation => call2,
        :passed => true,
        :ran => true
      }, result.results.last)
    end
  end
end
