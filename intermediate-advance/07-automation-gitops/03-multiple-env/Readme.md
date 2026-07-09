<!-- Planning for Multiple Environments -->
One of the primary benefits of Infrastructure as Code is reusability. 
Once you've created a bit of code to deploy some infrastructure, you can reuse it across your organization. 
This often takes the form of modules, but you can also use the same root module to support multiple environments. 
That's what we're going to dig into in this module. You might have several development environments to work on a new feature, like: 
    - QA or staging environment to test features
    - training environment to teach your new employees
    - production environment where your customers interact with your application. 

Each of these environments has different requirements, but they can all be based on the same code. That's the power of Infrastructure as Code. 
There are several possible approaches to accomplishing this goal, including:
    - Using Terraform community workspaces
    - Directories and tfvars files
    - Seperate long lived code branches
    - Release tags and pipelines

We're going to explore some of these approaches and the pros and cons of each. 
Our ultimate goal with the Taco Wagon application is to use our Infrastructure as Code to support multiple networking environments. 
We want our code to be reusable, tested, and consistent. When we make a change to the code, it should be tested in lower environments 
and then go through a promotion process to get to production. Ultimately, we want to avoid making changes directly in prod, except in a break glass scenario. 

We'll start by looking at workspaces, but first we need to define what workspaces are in Terraform Community and how HashiCorp recommends using them.

# Terraform Community Workspaces
Terraform workspaces in Terraform Community Edition let you support multiple environments by using a common Terraform root module and separate instances of state data. The Community Edition version of workspaces are different in several regards from workspaces in HCP Terraform and Terraform Enterprise. 
Each workspace maps to one instance of state data, but all of them will use the same state backend for storing the data. 

When you initialize a Terraform root module, you are essentially creating a default workspace. 
You can create additional workspaces by using the terraform workspace command, but you cannot delete or rename the default workspace. 
Terraform is aware of the currently selected workspace, and you can reference that value in your code by using the expression terraform.workspace. 
This actually works for both Terraform Community Edition and HCP Terraform. 
The intended purpose behind workspaces is to create short‑lived environments for testing code changes and not for long‑term environments. 
That's because of some of the shortcomings of Terraform Community Edition workspaces. 

The first problem is that all workspaces share the same state data backend. That means anyone working on the code can see and potentially alter the state data for all of the environments. 
A developer working on the development environment could, at least in theory, see sensitive data from the production environment and, at worst, accidentally delete or alter the production environment.
Community Edition workspaces lack native access controls. 

The second issue has to do with code maintenance. How do you test out changes for one environment without accidentally applying them to other environments? 
You could handle that through something like code branches or release tags, but open‑source workspaces don't know about version control. 
So again, you could make a change in the development branch and accidentally apply it to production if you're not careful about which workspace is currently selected. 

Finally, there's the challenge of managing variable values. 
You can try and make use of the workspace expression Terraform.workspace to determine which values to use in your tfars. But that can get messy quickly, and it doesn't scale well with the number of environments. 
The key takeaway is that Community Edition workspaces are great for testing out a change in a temporary environment without affecting your existing deployment, but they aren't great for long‑term management. 
So let's look at some other approaches.

# Challenges with Multiple Environments
While workspaces are one potential option for managing multiple environments, they aren't the recommended approach. 
So what's left? Broadly speaking, I've seen three different approaches, folders, branches, and pipelines. 

# Folder Approach
We'll start with the folder‑based approach. In a folder‑based approach, you create a copy of the root module of your code for each environment and place it in its own directory. 
Each folder includes its own tfvars file and configuration for a backend. 

Taking the directory approach allows you to maintain separate state backends for each environment. 
Credentials for each environment will be stored on the CI/CD pipeline platform, further providing a separation of concerns. 
The advantage of folder‑based separation is that you can clearly see from the file structure how many environments are being supported, 
and there's clear separation of the root module, variable values, and backend for each environment. 

        |----environments
        |      |----development
        |      |        main.tf
        |      |        development.tfvars
        |      |        backend.tf
        |      |
        |      |----production
        |      |        main.tf
        |      |
        |      |----staging
        |      |        main.tf
        |      |
        |----modules
                    |----network
                    |
                    |----security


There are some downsides though. Having multiple copies of the root module means you have to make sure you copy your changes over accurately, and it can be easy for your environments to become inconsistent. 
Also, all your environments live in the same branch, making updates tricky, especially if you're storing your child modules locally. 
The last problem is that of scale. This approach doesn't scale beyond a handful of environments very well. Once you get to 10 or 100 environments, 
which I've seen several times, trying to manage all these folders and settings becomes overwhelming and code promotion is a nightmare. 

# Branch Approach
Rather than use separate directories for each environment, you can instead have each environment represented by a branch in your repository. 
This approach is similar to the directory approach, but it allows you to have all your environments using the exact same root module. 
Each branch can have its own state data backend, but they're all going to use the same backend type. 
By using a partial configuration, you can supply additional details at runtime to complete the configuration. 
Configuration values can be stored in tfvars files, but you'll need to be careful about how you manage them. 
You could create a tfvars file for each environment and reference it at runtime, or you could store the environment‑specific values in your CI/CD platform. 
Since all environments are using the same root module, they should be nearly identical with any differences expressed through input variable values or internal logic in the code. 

Operationally, using separate branches requires a certain level of operational maturity. 
You'll need to be able to manage code changes and promotions between branches, and you'll need to be able to manage the state data backends for each environment. 
Like the folder‑based approach, you get the benefit of consistent code across all your environments, 
but you need to manage your code promotions carefully, and you'll need to balance that benefit against the cost of complexity. 
Like the folder‑based approach, using branches also doesn't scale especially well. Once you have more than a handful of environments, 
it becomes significantly more difficult to maintain consistency across all the branches. 

# Pipeline Approach

The third option is to use your pipeline to define and manage environments. In this case, you have a single root module that all the environments use, all on the same default branch. When a commit is made to the main branch, it kicks off your CI/CD pipeline. This will start a deployment to the development environment using the tfvars files and CI/CD values you have stored for that environment. After a successful deployment, you'll test and validate the development environment to make sure it's working properly. Then you'll continue the pipeline, deploying to the staging environment, and then running through the same testing and validation for the staging environment. After the change has been promoted through the lower environments and accepted, a release tag is added, and that kicks off the production deployment pipeline. The pipeline can handle the details of sequencing and orchestration for the production environment deployments. Using the pipeline approach follows the idea of trunk‑based development where all branches are short‑lived and merged back into the default branch as soon as possible. This helps to limit inconsistencies cropping up between different branches. However, there will be some delay between the merge and when the code is deployed to each environment through the pipeline. During that time, each environment may be on a slightly different version of the code, and that difference needs to be managed and accounted for. I'm going to be honest. Managing multiple environments in Terraform is a wildly complicated topic with a lot of decision points. There's no one best solution for everyone. You need to select what works best for your team, your organization, and your infrastructure code.

# Practicals
<!-- NOTE THAT THIS MODULE IS A CONITNUATION OF THE PREVIOUS WITH SAME REPO CODE MODIFIED HERE -->
Globomantics is going to follow the pipeline‑based approach for their environments. The overall workflow should be like this:
- When a PR is created, the CI pipeline will run and perform the checks we already had in the previous module. 
- Generate a plan for all the environments, including staging, prodeast, and prodwest. 
- If everything passes and looks good, the change can be merged. 
- When the PR is merged to the default branch, the change should be applied in sequence to dev, staging, and possibly other environments in the future. 
- If something goes wrong with one of the deployments, the pipeline should halt. 
- Between each environment deployment, you could add testing steps, but that's outside the scope of this course. 
- Once the change has been applied to all the lower environments and validated, the plan is to cut a release tag to trigger the deployment to production. 
- The production deployment can be done in parallel for both prodeast and prodwest. 


# Solution
Also, make sure to update the AWS Access and Secret key ID if they have changed in GH actions secrets

Also, if you are using a sandbox environment and no longer have the setup backend, complete the set set below like in the previous module:

ow I have added the configs to create a bucket in setup/create_backend_storage/main.tf

    $ cd ./setup/create_backend_storage

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out s3-backend.tfplan

    $ terraform apply s3-backend.tfplan  [copy the bucket name and region from the terminal outputs and save somewhere]

        bucket_info = {
        "bucket" = "tw-terraform-state20260605230611342700000001"
        "region" = "us-east-1"
        }   

Switch to the main branch, pull the updated code that was merged to main from the previous module, and create a new branch for this module named tf-cicd-multi-envs
    
    $ cd ./base_app [module project directory]

    $ git checkout main [ switched branch to main]
    
    $ git pull [pull updates code from PR merged]

    $ git checkout -b tf-cicd-multi-envs

    $ git branch [confirm you are on the  new branch]

        main
        tf-ci
        * tf-cicd-multi-envs    

- Now copy the buckname and region as below and paste it as additions to the various envs in all the various stage files with .hcl extensions in backend directory

        bucket = "tw-terraform-state20260605230611342700000001"
        region = "us-east-1"

- A new shared workflow file deploy-environment.yml has been added to .github/workflows and the ci.yml and cd.yml updated
  Read their coontents to understand them before proceeding

- Also corresponding files have been added for staging, prodeast, and prodwest in /environment directory

Now stage and push your new branch, create a new PR (make sure not to merge you PR yet) and watch the ci action kickoff for all envs

Now merge you PR and what the cd action kickoff to deploy to de and staging

Now let us add deployment to the 2 prod environments

- Three new workflow files have been added. check them out to understand them
    * release.yml
    * manual_destroy.yml
    * manual_deploy

- Now stage and push your new code updates to new branch (tf-cicd-multi-envs )
- create a new PR (make sure not to merge you PR yet) and watch the ci action kickoff again for all envs 

Note that the dev and staging environments won't have summary because nothing has changed for them

Time to deploy to prodeast and prodwest using tags

- Go to the repo code in the brower
- click on code
- click on Create a new release [on the RHS]
- make sure Target:main and Select tag are the selected options
- under title enter First prod deploy
- click on Select tag and enter v1.0.0 [note  that the letter 'v' is case sensitive to match what is in workflow] in text area and click on Create new tag
- Click on Publish release at the  end of page


Now the  release workflow for prodeast and prodwest should kickoff


