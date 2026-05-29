<!-- Templates and conditionals -->

# Heredoc syntax: add multiline strings

    local {
        simple_string = "literal_string"
        long_string = <<EOT
        here is my very long string
        terraform will include line breaks
        and provider interpolation
        EOT
    }

# String interpolations: evaluates expressions and convert result to string

- General syntax: "${<any_valid_expression>}"

    local {
        var_reference = "${var.prefix}-vpc"
        func_usage    = "${upper(local.var_reference)}-ALLCAPS"
        arithmetic    = "$webserver-${count.index + 1}"
    }

# String directive: allows you to add if/else and for loops  

- Start of all directives - if/else or for loop: %{<supported directive expression>}
- End of all directives - if/else or for loop: %{<supported directive expression>}

if/else directive 

    %{if condition} true value %{else} false value %{endif}

E.g.
    %{if var.enable_monitoring}
    monitoring = true
    level = INFO
    %{else}
    monitoring = false
    %{endif}

for loop directive

    # for a list [12,3,4,..]
    %{for <item> in <collection>} <item expression> %{endfor}

    # for a list {"key1": "value-1", "key2": "value-2", ...}
    %{for <key>, <value> in <collection>} <item expression> %{endfor} 

E.g. 
    %{for server in var.servers ~}
    ${server.name} = ${server.ip_address}
    %{endfor ~} 

    # result of above that loops through a map - key/value pair
    web-01 = 10.0.0.0.1  
    web-02 = 10.0.0.0.2  

The ~ is used to strip off white spaces at the begining and end 

# templatefile function - templatefile()
- store string template in a file
- dynamically choose source file
- improves readability

E.g.

servers.tpl contains the template:

    %{for server in var.servers ~}
    ${server.name} = ${server.ip_address}
    %{endfor ~} 

main.tf calls and passes the variable at runtime

    locals {
        user_data = templatefile(
            "./servers.tpl",
            {
                servers = var.servers
                environment = var.environment
            }
        )
    }

# Path expression
When your template path is evaluated, the default behaviour is to check the path relative to the current working directory
You can change that with:
- path.module: is the relative path to root module and the most commonly used
- path.root: relative path to root module, most often it is "."
- path.cwd: absolute path to current working directory  

# Template string function
ThThe function takes two arguments, the template to render and a map of values to use for the placeholders. Very similar to how templatefile works
Templatestring makes the creation of the template itself dynamic. For the source of the template, you could reference a local value, an input variable, 
or even a data source. If you'd like the template itself to be more dynamic at runtime, then template string is what you need. 

Function Syntax

    templatestring(template, var_map)

Template with literal string

    <<EOT
    here is my heredoc string
    this is a literal string 
    and not loaded dynamically
    EOT

E.g
    data "aws_ssm_parameter" "template_parameter"{
        name = var.template_parameter
    }

    locals {
        user_data = templatestring(
            data.aws_ssm_parameter.template_parameter.value,
            {
                app_name = var.app_name
                environment = var.environment
                region = var.region
            }
        )
    }

 A word of caution, if you choose to define your templatestrings as local values, you should be aware of how Terraform interprets interpolation and directive expressions

Wrong string interpolation when using templatestring:

    # The processing of the user template local value will fail, because Terraform tries to interpolate 
    # the user placeholder in user_template before storing the value, and it will error out saying that the user is an invalid reference

    locals{
        # creating the template here and passing the dynamic variable ${user}
        user_template = "Hello ${user}"
        renderd = templatestring(local.user_template,{
            user = var.user_name          
        })
    }

Right string interpolation when using templatestring:

    #To remedy this, you have to use the escape sequence of two dollar signs in the template. 
    #Terraform will strip off the first dollar sign and leave the interpolation expression intact,
    #and we can successfully use the local value in our templatestring function to get the desired result and string.
    
    locals{
        # creating the template here and passing the dynamic variable ${user}
        user_template = "Hello $${user}"
        renderd = templatestring(local.user_template,{
            user = var.user_name          
        })
    }

If you have two escape directives, you can do so in the same way by using a double percentage sign.

# Conditions (ternary operator)
    #basic syntax
    condition ? <value_if_true> : <value_if_false>

    #basic example
    instance_type = var.is_prod ? "m5.large" : "t3.micro"

    #nested example
    instance_type = var.is_prod ? "m5.large" : var.is_stg ? "t5.medium" : "t3.micro"

Other conditionals can be used for evaluateing values
- comparison operator includes ==, >, <, !=
- logical operators includes &&, ||, !

Some functions and uses (check docs for details and more function usecases)
- contains()
- endswith() and startswith()
- alltrue() and anytrue()
- fileexists()
- issensitive()
- can() and can(regex())

# practicals
- add a data source for the EC2 instance, 
- a security group that allows HTTP traffic, 
- an EC2 instance with a startup script, and 
= an output with the EC2's public URL.  
- the ingress rule for HTTP traffic should use port 8080 for production and port 80 for all other environments. 
- the instance type should be t3.small for production and t3.micro for all other environments.  
- enabled for production only. 
- a backup tag should be added to the instance with daily for production and weekly for all others. 
- startup script should be updated to support dynamic values for the company, team, and environment. 
- the URL should reflect the correct port number based on the environment

Now copy the solution from previous module to the current module directory

    $ cd 05-hcl-expressions/02-template-conditionals

    $ cp -R  ../005-hcl-expressions/01-expression-operators/base_app .