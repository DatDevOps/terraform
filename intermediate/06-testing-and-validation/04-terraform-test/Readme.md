<!-- IAC testing with Terraform Test -->

# Testing Infrastructure as Code
A core tenet of software development is the need to develop rigorous tests to validate the functionality of your code. 
Terraform is Infrastructure as Code, and like any code you might write, it needs to be tested. 
However, infrastructure is a different beast than traditional application development, so mapping software development testing onto IaC requires a bit of nuance. 
Let's start by talking about the various tests that exist in software development and see if we can translate those to the IaC context. 
Some of the most simple and basic tests are unit and contract tests. In application development, unit tests are written to verify the functionality of a single function or method. Here are my inputs and my expected outputs. Does the function do what it's supposed to and handle the errors gracefully?

Contract tests serve to validate that two components work properly together. Does method or service A produce the proper outputs that method B is expecting? 
After I make a change to service A, are the outputs still correct? Am I honoring the contract with method B? 

Above unit and contract tests, we have integration tests. Here is where you would deploy components of the actual application and verify that they work properly together. This could be two services that have a relationship or a workflow involving a service, database, and a UI. 

Beyond integration tests are end‑to‑end tests, and as implied by the name, we are now deploying the entire application and testing its full range of capabilities. 
As we move up through the testing types, the time and money required to run each test increases. 
Ideally, you want to catch issues as early in the cycle as possible to minimize the cost and time of running tests.


# Unit and Contract Tests

<!-- Unit test -->
How would you go about mapping unit and contract tests on the Terraform code? We'll start with unit tests. 

- Terraform unit tests should start by verifying that your code is valid and syntactically correct. And also that it can render a successful plan given valid inputs. Two useful commands that can help with this process are: 

    $ terraform fmt 
    
    $ terraform validate. 
    
As a quick refresher, terraform fmt, simply formats your existing code to match the preferred standard from HashiCorp. While this isn't a test per se, it does make comparing different versions of the same code a lot easier. 

Terraform validate will verify the syntax and internal logic of your configuration. At a minimum, you can be confident that even if there are configuration errors, at least the basic syntax references and arguments are correct. 

Beyond those two commands, you can make use of the Terraform testing framework to supply different sets of values for the configuration and verify that the plan is successful with predictable outcomes.

<!-- Contract test -->
Contract tests are there to test what valid even looks like. Three validation check that are usefule here are:
    - Input variable validation blocks describe what valid input looks like, creating a contract between you and the consumer. 
    - Precondition blocks test assumptions about what you expect to be true for a given object inside the code. 
    - Postcondition blocks are a guarantee you make to consumers of an object that certain things about that object are true. 
    
Unit and contract tests typically do not deploy any actual infrastructure. Instead, they are operating at the planned phase of the run. 
For instances where actual resources are required, you can supply mock data using the testing framework.

# Integration Tests
Integration tests in Terraform involve the actual deployment of infrastructure and verification that the deployed resources are configured and functioning correctly. 
A typical integration test would plan and apply a configuration with a predefined variable set to a temporary environment. 
Once the infrastructure is provisioned, tests are executed to validate the functionality of the deployment. 
Once those tests are completed, the temporary environment is torn down. Integration tests are meant to test specific use cases for your configuration or module. 
As your code changes over time, integration tests can verify that the updated code still meets the needs of each use case. 
Due to the ephemeral nature of integration tests, they still aren't testing a full end‑to‑end deployment of an entire environment, only the portion that your terraforming configuration describes. 
That means they can only verify that portion of the environment is still operating correctly, and additional testing will be required as you promote changed code through lower environments and into production.

# Terraform Testing Framework
We now have all these tests that we want to run, and we probably want to do that through an automated system. 
The Terraform testing framework was introduced in Terraform 1.6, and it provides a built‑in way for you to test your Terraform code. 

Each test that Terraform runs is defined inside of a .tftest.hcl or .tftest.json file.
A test is made up of a series of Terraform runs, executed in the order they're defined inside the file
By default, the command looks for test files defined in the current working directory or a tests subdirectory

The terraform test command will run each test in series based on the alphabetical order of the files; however, you can select specific tests to run if you prefer. 
Inside of your test, there needs to be at least one run block; otherwise, the test really wouldn't do anything. The run blocks will be executed in the order that they appear.
A test is made up of a series of Terraform runs, executed in the order they're defined inside the file. 
By default, each run will use the root module of the configuration from which you're running the test. 


Before we jump into the syntax:

    run  "<name_label>" {
        #can be set to either plan or apply. If you omit the command argument, the run will default to apply    
        command = plan | apply

        variables {
            <variable_name> = <variable_value>
        }

        module {
            source = "<local or remote module>"
        }

        assert {
            condition     = true | false
            error_message = "Description of failure."
        }

        expect_failure = [<list of objects with failure>]
    }

But sometimes you need to set up resources for the test to use, or you need to leverage some resources after the configuration is deployed to validate it. 
To that end, you can reference a different module inside of your test run. 
When all of the runs complete, Terraform finishes the test by cleaning up any resources that were deployed during the test runs. 

The final step is to report the results of the test and whether each run passed or failed. There are two kinds of runs, plan and apply. 

Plan does not deploy any resources. It simply generates an execution plan that you can assert conditions against. 
In those assertions, all of the tested values have to be known at apply. You can't have computed values in there. 

Apply runs stand up actual infrastructure during the test and store the state for that infrastructure in a temporary location. 
Subsequent runs in the same test will have access to the outputs of the state data from previous runs. 
When a test completes, all apply runs will execute a destroy action to tear down the temporary infrastructure that was created for the test. 

That's the general workflow, so now let's dig into the syntax. There are several top‑level blocks supported in a testing file. 
The variables block allows you to define variable values to be used by the runs in the test. The block is optional and can be overridden by a variable block inside of a run. 
The provider block lets you define how a provider should be configured for this test. Maybe you want to make sure that your AWS provider is using a particular region or has certain default tags enabled. 
You can specify multiple provider blocks as needed. If you don't specify a provider block, the test will use the provider block defined inside your module. 

 
If you didn't supply a top‑level variables block or want to declare more specific values, you can add a variables block inside of the run block. 
The assert block works just like it did in the check block from earlier. It has condition and error message arguments. If the condition resolves to false, the run is listed as failed in the testing results. Sometimes you may want to test for failure of a validation block, so instead of an assert block, you can add the expect_failures argument and pass it a list of objects that will have failed validations.
That could be variable validation, preconditions, or postconditions. You do not have to specify an assert block or expect failures argument inside of a run block. 
For runs that are simply setting up dependencies or infrastructure to test in a later run block, assert and expect failures wouldn't be all that useful. 
The run block does have a few other arguments, but we've covered the most relevant ones for now.

# Practicals
- Produce a valid Plan
- Check variable validation
- Verify website is available



# Solution

Now run:

    $ cd 06-testing-and-validation/04-terraform-test

    $  cp -R ../03-drift/base_app/ .

    $ cd base_app/

    $ rm -rf m2.tfplan

    $ mkdir test && touch integration_test.tftest.hcl var_test.tftest.hcl

Checkout the content that I added to the files. Comment out the content of integration_test.tftest.hcl and run below:

    $ terraform init [if you have not already done so]

    $ terraform fmt

    $ terraform validate

    $ terraform test

        tests/integration_test.tftest.hcl... in progress
        tests/integration_test.tftest.hcl... pass
        tests/var_test.tftest.hcl... in progress
        run "good_plan"... pass
        run "company_name_regex"... pass
        tests/var_test.tftest.hcl... tearing down
        tests/var_test.tftest.hcl... pass

        Success! 2 passed, 0 failed.    

The variable test passed. Also the integration test passed because the file was present with no/commented out content and hence no failure

Uncomment the integration_test.tftest.hcl 

    $ terraform test

        tests/integration_test.tftest.hcl... in progress
        run "setup"... pass
        run "test_site"... pass
        tests/integration_test.tftest.hcl... tearing down
        tests/integration_test.tftest.hcl... pass
        tests/var_test.tftest.hcl... in progress
        run "good_plan"... pass
        run "company_name_regex"... pass
        tests/var_test.tftest.hcl... tearing down
        tests/var_test.tftest.hcl... pass

        Success! 4 passed, 0 failed.


# Advanced Testing Features
We're going to start with mock data. In software development, you often supply mock data or a mock service when doing your testing. 
That way you don't have to stand up an entire application to perform unit or integration testing, and the testing process goes much faster. 
Terraform has the same thing in the form of mock providers, mock resources, and mock data sources. Let's start by talking about mock providers. 

The mock provider can be used in place of the actual provider. 
This is useful for scenarios where you don't have access to the actual provider environments like an AWS account 
or provisioning the supporting infrastructure would take too much time, like a Kubernetes cluster. 
When you invoke a mock provider, it generates a matching schema based off that provider plug‑in. 
To do that, it has to pretend that the resources and data sources in the configuration were actually provisioned with real values. 

For any computed attributes that don't come from the configuration, the solution is to just make up values of the correct type for each attribute. 
Mock providers have a standard set of values to use for each data type. 
So if we were mocking up an S3 bucket, the ARN that would normally be generated by AWS is set to a random string. If you want a resource or data source attribute to have a specific value, you can change the default value by adding a mock_resource or mock_data source inside of the mock provider block. 
The values included in the mock_data or mock_resource block will be used for all objects of that type. 

What if you wanted to set an attribute value for a specific resource or data source in the configuration, not all instances of it? That's where overrides come in. 
Overrides allow you to change the attribute values for a particular resource, data source, or module output in your configuration. 
Overrides can be defined inside of a mock provider or as a top‑level block in the test. 
An override will take precedence over a mock data source or resource since it is specific to the exact data source or resource in the configuration. 
All of the runs in our tests were executed in series, but what if you wanted to run a bunch in parallel to speed up the execution time? 
It is possible to kick off runs in parallel; however, a few things need to be true. Number one, the runs do not reference outputs from each other. 

Number two, the runs cannot share the same instance of state. That would violate concurrent access to state. 
And number three, all of the applicable runs have to have the parallel attribute set to true. You can set that attribute at the top level of the test block or individually inside of run blocks. 

Parallel testing is extremely useful if you have tons of variable validation tests that you'd like to run in parallel. 
There's even more to the testing framework than what I've included here, however, I think this is a solid start. 
You can use the Taco Wagon configuration and the tests we've already developed to experiment with these advanced features. 
 


