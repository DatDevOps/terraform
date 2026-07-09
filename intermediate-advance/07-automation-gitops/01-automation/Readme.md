<!-- Automation and GitOps -->

You're a platform engineer at Globomantics. You've been tasked with improving the workflow and automation for the Taco Wagon team. 
At the moment, the Taco Wagon team is using the CLI on their local workstations to plan and apply changes for both their network and application infrastructure configurations. 
You will be helping them embrace the power of automation and GitOps by achieving the following goals. 

# Practicals
- create pre‑commit hooks that automatically run on their local workstations to check code validity. 
- build a continuous integration pipeline that validates code remotely and generates plans for review. 
- create a continuous delivery pipeline that automates the deployment of updates to lower environments when a pull request is merged. 
- create a release pipeline that automates the deployment of updates to production. 
- Create support for these environments: Dev, Stage, Prod West, and Prod East

# Solutions

    $ cd intermediate/07-automation-gitops/01-automation [ module directory]

    $ cp -R ../base_app/ . [copy starter config to be used for module]

To automate our validation step, we are going to employ a pre‑commit hook, which runs before a commit is created.
To understand pre‑commit automation, you only need to know the basics of Git hooks. 
Git hooks are scripts that run automatically during specific Git actions, such as pre‑commit or commit message.
They live in the .git/hooks directory and can block an action if they fail.


# Pre-commit File Syntax
    repos:
        - repo: <remote-repository>
        rev: <version-number>
        hooks:
            -   id: <hook-id>
                files: <filter-expression>
                args: <arguments>
        - repo: local
        hooks:
            -   id: <hook-id>
                name: <hook-name>
                entry: <command-or-script>
                language: <language>

We have added two new files to the root of the directory
  - .pre-commit-config.yaml 
  - .tflint.hcl

Now initialize the project:

    $ terraform init -backend=false [passing the flag bcs the backend terraform.tf is not set up yet]

At this point make sure these points are already taken care off. Otherwise see the NOTES* below:
    - python is install on your machine
    - Create a virtual python environment
    - Then install the pre-commit hook [pip install pre-commit]
    - Check your pre-commit version [pre-commit --version]
    - install terraform docs
    - install terraform lint

# NOTES*

Use these command for the above:

    $ cd [moves to home root directory or do 'cd ~']

    $ python3 -m venv terraform [create a virtual env called terraform. Could be any name you want]

    $ source terraform/bin/activate [activates the env]

    (terraform)$ python3 --version [checks python version in env]

        Python 3.9.25

    (terraform)$ pip3 install pre-commit [installs the pre-commit hook]

        Collecting pre-commit
        ...
        ...

    (terraform)$ pre-commit --version
        
        pre-commit 4.3.0  

Now lets install terraform docs and tflink while still in your user drectory, ~

    #Install tflint
    $ curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    $ sudo mv tflint /usr/local/bin/

    #Install terraform-docs
    VERSION=v0.17.0
    $ curl -Lo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/${VERSION}/terraform-docs-${VERSION}-linux-amd64.tar.gz
    $ tar -xzf terraform-docs.tar.gz terraform-docs
    $ sudo mv terraform-docs /usr/local/bin/
    $ rm -f terraform-docs terraform-docs.tar.gz

    #Verify both are available
    $ tflint --version
    $ terraform-docs --version

Once done, continue with below. 
NOTE THAT THE HOOK RUNS ALL ALL GIT STAGED FILES BUT YOU CAN RUN IT AGAIN ALL FILES IN REPO BY PASSING THE '-a' FLAG
AND RUNS FROM THE ROOT REPO ROOT DIRECTORY (terraform in this case)

    $ tflint --init

    $ tflint --config=.tflint.hcl   

    $ pre-commit run -a [runs the hook on all file. if all is good you see get the below]

    Terraform Format.........................................................Passed
    Terraform Validate.......................................................Passed
    TFLint...................................................................Passed
    Terraform Docs...........................................................Passed

If there are errors or failures the output will tell where they are . Fix them and you should be good.