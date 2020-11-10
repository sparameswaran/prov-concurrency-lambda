## Testing Provisioned Concurrency in Lambda

The sample provided is aimed at demonstrating the benefit of [provisioned concurrency](https://docs.aws.amazon.com/lambda/latest/dg/configuration-concurrency.html#configuration-concurrency-provisioned) vs just using reserved concurrency in Lambda function. A [SAM (Serverless Application Model)](https://github.com/aws/serverless-application-model) template is used to quickly build and deploy a set of Lambda functions and associated Step functions that can be executed to demonstrate reserved concurrency vs provisioned concurrency. For more info on Provisioned concurrency, please refer to this [blog post](https://aws.amazon.com/blogs/aws/new-provisioned-concurrency-for-lambda-functions/)

### Components:
* Sample Lambda function [concurrencytest.py](functions/concurrencytest.py) under functions folder (in Python 3) that  mimics cold start using an environment variable to control sleep duration on initialization.
  * Cold start delay set to 5 seconds and normal function execution is set to 3 seconds.
* Two Lambda functions that refer to previously mentioned python code to expose with reserved vs provisioned concurrency
	* The total reserved concurrency should be greater than provisioned concurrency while ensuring the remaining unreserved concurrency is minimum 100. So, use something like 200 for reserved concurrency and 150 for provisioned concurrency so one does not hit limits (default total concurrency is 1000 for Lambda functions).
  * These can be configured in the sam template file:
  ```
  ...
  ReservedConcurrentExecutions: 300
  ...

  Name: ProvisionedConcurrencyPROD
  ProvisionedConcurrencyConfig:
    ProvisionedConcurrentExecutions: 150  #Lower it from 150 -> 1 for quick deployment
  ```
* Step function template [concurrency_test_state_machine.asl.json](statemachine/concurrency_test_state_machine.asl.json) under statemachine folder, that uses iterator function to go through a list of objects and invoke target lambda function in parallel for each payload item.
	* There would be two separate step functions one to invoke reserved and other to invoke provisioned concurrency.
  * The step function acts as a load generator to test multiple parallel invocations of the same lambda function to test concurrency.
* All of these are specified in a single SAM Template, [template.yaml](template.yaml).
* Use the sample test payload [sample-test-input.json](sample-test-input.json) for testing the Step functions

### Steps:
* Setup latest SAM tooling in local environment (or use AWS Cloud9 env). Refer to [SAM install documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
* Download the template and files from this Repo into a new folder
* Create a new S3 bucket to store SAM artifacts or reuse an existing SAM bucket. For Serverless projects, this bucket would be used by Lambda service to pick them.
* Change into the directory/folder which contains the SAM template.yaml
* We will be bypassing `sam build` as the code is very much simple and no local testing is required.
* Run `sam-package.sh` script providing the path to the template.yaml file, a new SAM output template file and S3 SAM bucket name.
	* Sample: `./sam-package.sh template.yaml sam-template-output.yaml aws-sam-cli-managed-default-samclisourcebucket-xyz`
	* This should create a new `sam-template-output.yaml` if SAM cli is correctly installed and S3 bucket is accessible.
* Next run the `sam-deploy.sh` script providing a stack name (for CloudFormation to deploy as stack) along with path to the SAM output template.yaml generated from the package step.
	* Sample: `./sam-deploy.sh test-concurrency sam-template-output.yaml`
		* This should generate output similar to following:
```
	Deploying with following values
	===============================
	Stack name                 : test-my-concurrency
	Region                     : None
	Confirm changeset          : False
	Deployment s3 bucket       : None
	Capabilities               : ["CAPABILITY_NAMED_IAM"]
	Parameter overrides        : {}

Initiating deployment
=====================

Waiting for changeset to be created..

CloudFormation stack changeset
---------------------------------------------------------------------------------------------------------------------------------------------------------
Operation                              LogicalResourceId                      ResourceType                           Replacement
---------------------------------------------------------------------------------------------------------------------------------------------------------
+ Add                                  BaseConcurrencyTestFunctionAlias       AWS::Lambda::Alias                     N/A
+ Add                                  BaseConcurrencyTestFunctionVersion     AWS::Lambda::Version                   N/A
+ Add                                  BaseConcurrencyTestFunction            AWS::Lambda::Function                  N/A
+ Add                                  BaseConcurrencyTestStateMachineRole    AWS::IAM::Role                         N/A
+ Add                                  BaseConcurrencyTestStateMachine        AWS::StepFunctions::StateMachine       N/A
+ Add                                  LambdaExecutionRole                    AWS::IAM::Role                         N/A
+ Add                                  ProvisionedConcurrencyTestFunctionAl   AWS::Lambda::Alias                     N/A
                                       ias
+ Add                                  ProvisionedConcurrencyTestFunctionVe   AWS::Lambda::Version                   N/A
                                       rsion
+ Add                                  ProvisionedConcurrencyTestFunction     AWS::Lambda::Function                  N/A
+ Add                                  ProvisionedConcurrencyTestStateMachi   AWS::IAM::Role                         N/A
                                       neRole
+ Add                                  ProvisionedConcurrencyTestStateMachi   AWS::StepFunctions::StateMachine       N/A
                                       ne
---------------------------------------------------------------------------------------------------------------------------------------------------------

Changeset created successfully. arn:aws:cloudformation:us-west-2:xxxx:changeSet/samcli-deploy1604945820/55a7586b-8d0b-4606-ad45-b63f3e8e336a


2020-11-09 10:17:11 - Waiting for stack create/update to complete

CloudFormation events from changeset
---------------------------------------------------------------------------------------------------------------------------------------------------------
ResourceStatus                         ResourceType                           LogicalResourceId                      ResourceStatusReason
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE_IN_PROGRESS                     AWS::IAM::Role                         LambdaExecutionRole                    -
CREATE_IN_PROGRESS                     AWS::IAM::Role                         LambdaExecutionRole                    Resource creation Initiated
CREATE_COMPLETE                        AWS::IAM::Role                         LambdaExecutionRole                    -
CREATE_IN_PROGRESS                     AWS::Lambda::Function                  BaseConcurrencyTestFunction            -
CREATE_IN_PROGRESS                     AWS::Lambda::Function                  BaseConcurrencyTestFunction            Resource creation Initiated
CREATE_IN_PROGRESS                     AWS::Lambda::Function                  ProvisionedConcurrencyTestFunction     -
CREATE_COMPLETE                        AWS::Lambda::Function                  ProvisionedConcurrencyTestFunction     -
CREATE_COMPLETE                        AWS::Lambda::Function                  BaseConcurrencyTestFunction            -
CREATE_IN_PROGRESS                     AWS::Lambda::Function                  ProvisionedConcurrencyTestFunction     Resource creation Initiated
CREATE_IN_PROGRESS                     AWS::IAM::Role                         BaseConcurrencyTestStateMachineRole    -
CREATE_IN_PROGRESS                     AWS::IAM::Role                         ProvisionedConcurrencyTestStateMachi   -
                                                                              neRole
CREATE_IN_PROGRESS                     AWS::Lambda::Version                   BaseConcurrencyTestFunctionVersion     -
CREATE_COMPLETE                        AWS::Lambda::Version                   BaseConcurrencyTestFunctionVersion     -
CREATE_IN_PROGRESS                     AWS::Lambda::Version                   ProvisionedConcurrencyTestFunctionVe   Resource creation Initiated
                                                                              rsion
CREATE_IN_PROGRESS                     AWS::Lambda::Version                   BaseConcurrencyTestFunctionVersion     Resource creation Initiated
CREATE_IN_PROGRESS                     AWS::IAM::Role                         BaseConcurrencyTestStateMachineRole    Resource creation Initiated
CREATE_IN_PROGRESS                     AWS::IAM::Role                         ProvisionedConcurrencyTestStateMachi   Resource creation Initiated
                                                                              neRole
CREATE_IN_PROGRESS                     AWS::Lambda::Version                   ProvisionedConcurrencyTestFunctionVe   -
                                                                              rsion
CREATE_COMPLETE                        AWS::Lambda::Version                   ProvisionedConcurrencyTestFunctionVe   -
                                                                              rsion
...

CREATE_COMPLETE                        AWS::StepFunctions::StateMachine       BaseConcurrencyTestStateMachine        -
CREATE_COMPLETE                        AWS::StepFunctions::StateMachine       ProvisionedConcurrencyTestStateMachi   -
                                                                              ne
CREATE_IN_PROGRESS                     AWS::StepFunctions::StateMachine       BaseConcurrencyTestStateMachine        Resource creation Initiated
CREATE_COMPLETE                        AWS::Lambda::Alias                     ProvisionedConcurrencyTestFunctionAl   -
                                                                              ias
CREATE_COMPLETE                        AWS::CloudFormation::Stack             test-my-concurrency                    -
---------------------------------------------------------------------------------------------------------------------------------------------------------

CloudFormation outputs from deployed stack
-----------------------------------------------------------------------------------------------------------------------------------------------------------
Outputs
-----------------------------------------------------------------------------------------------------------------------------------------------------------
Key                 BaseConcurrencyTestStateMachine
Description         Base Concurrency Test State machine ARN
Value               arn:aws:states:us-west-2:xxxx:stateMachine:BaseConcurrencyTestStateMachine-nOVLiJyCMPBS

Key                 ProvisionedConcurrencyTestStateMachine
Description         Provisioned Concurrency Test State machine ARN
Value               arn:aws:states:us-west-2:xxxx:stateMachine:ProvisionedConcurrencyTestStateMachine-Wc4LX2CHVmlG
-----------------------------------------------------------------------------------------------------------------------------------------------------------

Successfully created/updated stack - test-my-concurrency in None
```
* One will note there is some time delay in finishing the configuration as the lambda functions are being instantiated in case of provisioned concurrency.
* Now one should be able to see the new lambda and associated step functions deployed. use the outputs to go to the related step machine definitions.
* Test first against the BaseConcurrencyTestStateMachine with the [sample payload](sample-test-input.json).
* Use CloudWatch to check the execution and invocations.
* The lambda function are  also X-Ray enabled. So, go to the x-ray services and check for invocations and one should be able to see delay in invocation due to cold start delay in initialization.
* In X-Ray, search by the stack name and step function service name. Sample:
`service("test-my-concurrency-BaseConcurrencyTestStateMachine-nOVLiJyCMPBS")` . This should show some invocations take 8 seconds (due to additional cold start delay of 5 seconds on top of 3 second invocation time) while warmed up ones take 3 seconds.
* Give some time before starting the Provisioned Concurrency Step function with same sample payload.
* This time the run would show all invocations are within the 3 second limit as the Lambda function instances were pre-provisioned and incur no more associated cold start delay.  
