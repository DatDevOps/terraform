
# Terraform registry:  https://registry.terraform.io

# AWS Terraform registry:  https://registry.terraform.io/providers/hashicorp/aws/latest

# Terraform providers:  https://registry.terraform.io/namespaces/hashicorp


<!-- Terraform Modules -->

# Practical (modularized FronEnd infra)
- improving the Terraform code being developed by the DevOps engineers in various business units
- The Taco Wagon team has come to you asking about potentially using modules in their code
- Switch to a public VPC Module
- Create a new module for Frontend

# Solution

- study the infra in /04-terraform-modules/001/base_app to see what it is like before we apply the above changes

- Moved the core resources for the frontend into ./modules/web-front-end

- We copied most of the related variables into the new module variable file ./modules/variable.tf, like: "launch_template_ami", "public_subnet_ids", "user_data_contents", and "vpc_id"

- Install Terraform docs [terraform.docs.io]. This resource helps to create a Readme file for you modules or configuration. 

  ```
  curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.24.0/terraform-docs-v0.24.0-$(uname)-amd64.tar.gz
  tar -xzf terraform-docs.tar.gz
  chmod +x terraform-docs
  mv terraform-docs /usr/local/bin/terraform-docs

  ```


After install (checkout https://github.com/terraform-docs/terraform-docs), run below in the parent or child module root directory to generate the file

    $ terraform markdown --output-file ./README.md output-mode inject .

# Part	                      Meaning
terraform-docs	              CLI tool that generates documentation from Terraform modules
markdown	                    Output format — generates Markdown
--output-file ./README.md	    Write output to ./README.md
--output-mode inject	        Instead of overwriting the entire file, inject the generated docs between special markers in the existing file
.	                            The Terraform module directory to document (current directory)    
    
    
# NOTE here that the FE module (04-terraform-modules/002/base_app/modules/web-front-end) is using the public subnet IDs from the VPC module in main-ec2.tf

Now run:

  $ terraform init [initialize the configuration and when you add a new module to configuration].

  $ terraform fmt [formats misformatted code]

  $ terraform validate [validates code for syntax error.]

  $ terraform plan -out m1.tfplan [This should pass now]  

  $ terraform apply m2.tfplan  

  $ terraform destroy [if you desire to deploy it. Otherwise skip]

<!-- Publish a Module -->

All you need is a GitHub account and a properly named repository with your module code. 
The steps are very straightforward. For starters, you will need to create a public repository on GitHub with the correct naming convention. 
The repository name should follow the format terraform‑main provider in the module ‑module purpose. Once you have your repository created, you'll push your module files to the repository. 
After the files have been committed, you'll add a release tag that follows semantic versioning. The Terraform registry uses the release tags to know which commit IDs should be published to the registry. 

    <GITHUB_OWNER>/<GH_repo_name> 
    
    # Note the "terraform-aw"s prefix that begins the repo name
    <GITHUB_OWNER>/terraform-aws-web_front_end [translates to "ned1313/web_front_end/aws" on the terraform module page.]

That's all we need to do on GitHub. Next, you'll sign into the Terraform registry using your GitHub account. You'll have to authorize the Terraform registry to access some information about your GitHub account. 
Once you've signed in, you can go to the Publish menu and select your repository to publish the module. The module will be published and available for use. Let's head over to GitHub and get our module uploaded. 

Over in GitHub, I'll start by creating a new repository called terraform‑aws‑web_front_end. I'll give it a description of Web front end for Globomantics. 
Make sure the visibility is set to Public. Set the gitignore to use Terraform. Set the license to MIT License, since that's my favorite, and create the repository. Once the repository is created, I'll manually upload the files from our module. All of these files will go into the root of the repository. Once they're selected, I'll click on Commit changes.
Now I need to create a release. I'll click on Create a new release and add a new release tag of the v1.0.0, and then give the release a title of first version and click on Publish. Once the release is published, we're done on GitHub. Over on the Terraform public registry, 

I'll click to Sign‑in. You can sign in using GitHub or a HashiCorp cloud platform account. I'll pick the legacy sign in and use my GitHub account, authorizing the Terraform registry app to access my GitHub account. Now I can click on Publish and select the repository from the drop‑down. 

I'll tick the agreement box and click on Publish. The registry will validate that my repository does, in fact, have a Terraform module in it, and after a few moments, our web front‑end module is published. Since we've published our module, we can now update our existing taco_wagon configuration to use this module as the source instead of the local folder. 
