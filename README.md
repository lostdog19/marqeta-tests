***

# marqeta-tests

A subset of tests of the Marqeta Core API with an automation framework created in Ruby, using Test::Unit.

***

## Execution

To execute the tests from the command line:

> $ruby auto_test.rb

To execute the tests from the command line and save the output in JUnit format (usable in CI environments):

> ruby auto_test.rb --runner=junitxml --junitxml-output-file=test_report.xml

***

## Structure

**marqeta_api_data** - Files containing the API definitions used in the tests

**tests** - Files containing the tests

**auto_test.rb** - entry point to run all tests located in the **./tests** folder

**Bugs.txt** - A collection of bugs located during test creation

**defaults.rb** - A collection of information which is common is most cases, and can be used by most tests

**marqueta_api.rb** - The code to interface with the Marqeta API

**README.md** - This file

**Test Cases.txt** - Plain text file containing the tests created for this exercise

**test_base.rb** - A base class which all the test cases inherit from, in order to ensure common behavior.


