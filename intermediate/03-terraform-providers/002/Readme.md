<!-- Terraform Providers -->
# Visit here to read about various provider docs and modules: https://registry.terraform.io/browse/providers

# AWS provider modules(under Overview) and resource definitions(under documentation) with Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest

# Execise module by Ned Bellavance repo: https://github.com/ned1313/Terraform-Providers


# Provider Tiers
- Official : maintained by Hashicorp and in the 'hashicorp' namespace
- Partner: maintained by Hashicorp partners
- Community: maintained by the community

This is a continuation of the previous module. So copy the project 03-terraform-providers/001/base_app into current 002

    $ cp -R 03-terraform-providers/001/base_app 03-terraform-providers/002

# Practicals
- Add an S3 bucket for VPC flow logs
- Use random provider for bucket name
  - use the version 2.3.1 for the random provider
  - use random_string resource

To search for the 'random' provider:
- Go to https://registry.terraform.io/browse/providers
- In the search box type 'random'
- Click the 'hashicorp/random' when it populates
- Click on the Documentation tab to read about the provider
- Click on the 'Version <version_number>' textbox to display all available version
- Click on the version you want to read about its documentation
- In left hand pane, click on Resources to see the provider various resources
- Click on 'random_string' to read more about it usgae


Now add the provider to terraform.tf:

      random = {
        source  = "hashicorp/random"
        version = "~>3.7.0"
      } 

Now add the provider to maintf:

    resource "random_string" "bucket_suffix" {
      length  = 12
      special = false
      upper   = false
    }

Initialize and validate onfigurations

    $ terraform init  [downloads the new random provider plugin in addition to the aws plugin already downloaded]

      - Finding hashicorp/random versions matching "~> 3.7.0"...
      - Using previously-installed hashicorp/aws v6.46.0
      - Installing hashicorp/random v3.7.2...
      - Installed hashicorp/random v3.7.2 (signed by HashiCorp)
      ...
      ...

    $ terraform validate  [checks for syntax error]

      Success! The configuration is valid.

Provider plugins can begin to take so much of you machine disk (several 100MB in size) space and may  be an issue to download if you have poor network bandwidth  
There are 2 options to help with  this:

1. Terraform Providr File Mirror 
  - stores provider plugin locally
  - used for low bandwidth or restricted environments 
    * Polulates files and build JSON index
    * You have to configure the client file (create if it does not exist) in %APPDATA%/terraform.rc [windows] or $home/.terraformrc [Linux]  



Terraform checks for the plugin locally and if it is in the include list before reaching out to the internet
You can include multiple mirror path and public registry
Below is a sample of the client connfiguration:

      provider_installation{
        filesystem_mirror{
          path = "usr/share/terraform/providers" # OR <FILE_SYSTEM> OR <URL_OF_NETWORK_MIRROR>
          include = ["registry.terraform.io/hashicorp/*, .....]
        }
      }

For example of Terraform Client file congiiguration with multple configurations:

    provider_installation {
      # Primary mirror - core HashiCorp providers
      filesystem_mirror {
        path    = "/usr/share/terraform/providers"
        include = [
          "registry.terraform.io/hashicorp/aws",
          "registry.terraform.io/hashicorp/azurerm",
          "registry.terraform.io/hashicorp/google",
          "registry.terraform.io/hashicorp/random",
          "registry.terraform.io/hashicorp/null",
          "registry.terraform.io/hashicorp/local",
          "registry.terraform.io/hashicorp/template",
        ]
      }

      # Secondary mirror - utility providers
      filesystem_mirror {
        path    = "/opt/terraform/mirrors/utility"
        include = [
          "registry.terraform.io/hashicorp/random",
          "registry.terraform.io/hashicorp/null",
          "registry.terraform.io/hashicorp/local",
          "registry.terraform.io/hashicorp/template",
          "registry.terraform.io/hashicorp/tls",
        ]
      }

      # Third-party providers from a separate location
      filesystem_mirror {
        path    = "/opt/terraform/mirrors/third-party"
        include = [
          "registry.terraform.io/datadog/datadog",
          "registry.terraform.io/PaloAltoNetworks/panos",
          "registry.terraform.io/mongodb/mongodbatlas",
        ]
      }

      # Network mirror as a fallback for anything else in-house
      network_mirror {
        url     = "https://terraform-mirror.internal.example.com/"
        include = ["registry.terraform.io/*/*"]
      }      

      # Catch-all: anything not matched above goes direct
      direct {
        exclude = [
          "registry.terraform.io/hashicorp/aws",
          "registry.terraform.io/hashicorp/azurerm",
          "registry.terraform.io/hashicorp/google",
          "registry.terraform.io/hashicorp/random",
          "registry.terraform.io/hashicorp/null",
          "registry.terraform.io/hashicorp/local",
          "registry.terraform.io/hashicorp/template",
        ]
      }
    }
  
  Key notes:
    filesystem_mirror:	Uses providers from a local directory (air-gapped/offline)
    network_mirror:	Fetches from an HTTP mirror (corporate proxy)
    direct:	Downloads directly from the registry (default behavior)
    Blocks: are evaluated in order — first match wins.
    The include/exclude patterns use glob syntax (* matches any single path segment).
    The expected directory structure under the mirror path follows: <HOSTNAME>/<NAMESPACE>/<TYPE>/terraform-provider-<TYPE>_<VERSION>_<OS>_<ARCH>.zip


2. Plugin cache
  - Terraform checks plugin cache first
  - If plugin not in cache, it goes to the registry, downloads it, and place it in a cache
  - note that terraform does not clean the  cache or remove old provider download

Below is a sample of the client connfiguration:

      provider_installation{
        filesystem_mirror{
          path = "usr/share/terraform/providers" # OR <FILE_SYSTEM> OR <URL_OF_NETWORK_MIRROR>
          include = ["registry.terraform.io/hashicorp/*, .....]
        }
      }

      plugin_cache_dir = "/var/shared/terraform_plugin_cache"  [Linux ]# this directory must exist as terraform will not create it if it does not exist

For windows the path will be something like:

plugin_cache_dir = "C:\\Users\\NedBallavance\\terraform.d\\plugins-cache"  [windows ]# this directory must exist as terraform will not create it if it does not exist


Or You can use an environment variable for cache location:

    TF_PLUGIN_CACHE_DIR="/var/shared/terraform_plugin_cache"  [linux]

    TF_PLUGIN_CACHE_DIR="C:\\Users\\NedBallavance\\terraform.d\\plugins-cache"  [Windows]

# Versioning

You can upgrade from one provider version to the other but you must be aware of major upgrade that can break your configurations
 
version = "=3.2.1" # match exactly 3.2.1
 
version = ">=4.0" # greater than or equal to 4.0
 
version = ">=4.1, < 5.0" # greater than or equal to 4.1 and less than 5.0

version = "!=4.1.2" # any version except 4.1.2

version = "~> 1.4.0" # versions that match 1.4.x

The .terraform.lock.hcl locks that the version, version constraints and should be checked into the repo so all collaborative  users will all have same hash stored therein.
Whe the project is iniatilized and nothing has chnaged, Terraform will use the  provider version in .terrafor.lock.hcl even if there is a newwer version that meets the constraint
This ensures consistency and makes an upgrade from a version easy

# Provide Upgrade

It is best to upgrade each provider version at a time. That way you can test and troubleshoot easily if something breaks

  $ terraform init --upgrade

After the upgrade test you code and if all is good check the .terraform.lock.hcl into version control or rollback chnages if it breaks stuff you can't fix


<!-- Common Cloud Providers -->
# AWS Provider
  1. aws
    - Original provider
    - Primary option for AWS
  2. awscc
    - Cloud Control API
    - Programmatically generated
    - Faster release of new features and services
    - Less user-friendly

# Azure Provider
  1. azurerm
    - Primary option for Azure
    - Can not configures Entra ID Objects
  2. azapi
    - Thin wrapper over Azure APIs
    - Broader feature support
    - Less usser-friendly
    - Can not configures Entra ID Objects
  3. azuread
    - Configures Entra ID Objects
  4. msgraph
    - Manage Microsoft Graph API resources
  
# Google Provider
  1. google
    - Primary option
    - Support general availability services and features
  2. google-beta
    - Supports beta and preview features
    - Uses the  beta API endpoint
    - Switching is simple and non-disruptive

 <!-- Provider Authentication -->

 There are roughly 5 methods to authenticate to each of the above providers:
 1. CLI
 2. Environment variables
 3. Terraform variables
 4. Machine identity
 5. Open ID connect (OIDC)

 <!-- Provider Troubleshooting  -->
 1. Check the provider credentials and environment variables, e.g region, access keys, subscription ID etc
 2. Adjust Terraform logging and can be of the following in increasing order of logs - INFO, WARNING, ERROR, DEBUG, TRACE, JSON 
    - TF_LOG: set Logging level
    - TF_LOG_PATH: set logging destination to a file in a path
    - TF_LOG_CORE: set core process logging level and used for when the error is from a provider plugin
    - TF_LOG_PROVIDER: set core provider logging level and used for when the error is from a provider plugin

Check log level in [Linux]

    $ echo $TF_LOG [prints the log level  for the variable] 

    $ echo $TF_LOG_PATH [prints the log level  for the variable]

    $ echo $TF_LOG_CORE [prints the log level  for the variable]

    $ echo $TF_LOG_PROVIDER [prints the log level  for the variable]

    # [print values for all 4 variable above]
    $ printf "TF_LOG=%s\nTF_LOG_PATH=%s\nTF_LOG_CORE=%s\nTF_LOG_PROVIDER=%s\n" "$TF_LOG" "$TF_LOG_PATH" "$TF_LOG_CORE" "$TF_LOG_PROVIDER" 

Check log level in [Powershell]

    > echo $env:TF_LOG

    > echo $env:TF_LOG_PATH

    > echo $env:TF_LOG_CORE

    > echo $env:TF_LOG_PROVIDER

Supported log levels (important):
    - TRACE (most verbose)
    - DEBUG
    - INFO
    - WARN
    - ERROR (least verbose)
    - JSON (special format)

Set log level in [Linux]

  $ export TF_LOG=DEBUG

  $ export TF_LOG_PATH=./terraform.log

  $ export TF_LOG_CORE=INFO

  $ export TF_LOG_PROVIDER=TRACE

  $ TF_LOG=DEBUG TF_LOG_CORE=INFO TF_LOG_PROVIDER=TRACE TF_LOG_PATH=terraform.log terraform plan




Set log level in [Powershell]

  > $env:TF_LOG="DEBUG"

  > $env:TF_LOG_PATH="terraform.log"

  > $env:TF_LOG_CORE="INFO"

  > $env:TF_LOG_PROVIDER="TRACE"

To remove a setting for a set log level just  make the value of any of them an empty string, like TF_LOG=""
