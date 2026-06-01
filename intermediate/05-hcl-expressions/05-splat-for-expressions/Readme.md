<!-- Data transformation with for and  Splat Expressions -->

You can't always control the structure of the data you receive for a Terraform configuration. 
You might get a CSV file from a ticketing system or JSON input from a data source. 
Being able to manipulate data in Terraform is an essential skill. 
While Terraform has a laundry list of built‑in functions for doing specific data transformation, it also has a special expression that can do more generalized heavy lifting,
and that is the for expression. The for expression is meant to enable the transformation of complex data types.

A for expression can take any collection or structural type as input. Lists, maps, sets, tuples, and objects, they all work. 
The result of a for expression will be either a tuple or an object. For expressions also support filtering of results using an if conditional statement at the end, 
and they can group results with matching keys together using the dot dot dot expression.

# for expressions

If you only specify a single iterator, it will always be set to the value of the input, so the value in the map or the element of a list or the value in a set. 
If you specify two iterators, the first will be set to the current index for lists for tuple and the current key for maps and objects. 
And the second will be set to the corresponding value. In the case of sets, both iterators are set to the same value since sets are unordered

After the input goes a colon, and the expression to store in the result. For tuples, that will be a single value. 
For objects, you need a unique key and value to store in it, using the assignment expression equals and greater than. 
If and grouping go after the result expression. If uses a conditional statement. If the statement is true, the current value is included; otherwise, it's omitted. 
Grouping is specific to building an object, and it uses three dots after the result expression. 
If two values have the same key, they will be grouped together under that key as a tuple.

Syntax:

#Tuple
    [for value in input_type : tuple_element]
    [for key, value in input_type : tuple_element]

#object
    {for key, value in input_type : object_key => object_value}

#filtering with if
    [for value in input_type : tuple_element if condition]

#grouping for objects
    {for key, value in input_type : object_key => object_value...}

Over in VS Code, there's an examples directory in the exercise files, and in there is a for expression subdirectory. 
The main.tf in there has a bunch of local values that we can use to experiment with the for expression.

Lets test out the for expressionusing teh terraform console

    $ cd 05-hcl-expressions/05-splat-for-expressions/examples/for_expression

    $ terraform init
    
    $ terraform console

    > [for item in local.environments : "globamantics-${lower(item)}"]  # creates a new list of data 

        [
            "globamantics-dev",
            "globamantics-stage",
            "globamantics-prod",
        ]

    > [for item in local.environments : item if item != "Prod"]

        [
            "Dev",
            "Stage",
        ]

    > [for item in local.environments : "globamantics-${lower(item)}" if item != "Prod"]

        [
            "globamantics-dev",
            "globamantics-stage",
        ]

    > {for subnet in local.subnets: subnet.name => subnet}

        {
            "subnet-1" = {
                "cidr_block" = "10.0.0.0/24"
                "name" = "subnet-1"
                "type" = "public"
            }
            "subnet-2" = {
                "cidr_block" = "10.0.1.0/24"
                "name" = "subnet-2"
                "type" = "public"
            }
            "subnet-3" = {
                "cidr_block" = "10.0.2.0/24"
                "name" = "subnet-3"
                "type" = "private"
            }

        } 

    > {for k,v in local.users: v.role => k...}

    {
        "admin" = [
            "alice",
            "barb",
        ]
        "contributor" = [
            "chris",
            "dinesh",
        ]
    }

    >exit

# Working with Count and for_eeach expression

#count with subnets
#Splat expression

    aws_subnet.public[*].arn    ====> returns a array of subnets

#Equivalent of above with for expression

    [for subnet in aws_subnet.public : subnet.arn]  ====> returns a array of subnets

#For-Each with buckets

    [for bucket in aws_s3_bucket.web : bucket.bucket_domain_name]  ====> returns  the unique name of a buckes as an array

Before begining the practicals, do:

    $ cd 05-hcl-expressions/05-splat-for-expressions

    $ cp -R 05-hcl-expressions/04-data-structure-type/base_app .

    $ rm -rf m4.tfplan

# Practicals
- network ACL added to the public subnets of our configuration. 
- They will produce a list of ingress and egress rules to be applied using a CSV file. 
- We need to ingest the CSV, massage the data as needed, and create the network ACLs. 
- add two new outputs, the subnet ARNs and the bucket domain names.

# Solution

1. add to the local block of main.tf

  #new module local varaible to meet requirements
  csv_data = csvdecode(file("${path.module}/m5_rules.csv"))
  
  acl_ingress_rules = {
    for rule in local.csv_data : rule.priority => rule if rule.direction == "ingress"
  }

  acl_egress_rules = {
    for rule in local.csv_data : rule.priority => rule if rule.direction == "egress"
  }

2. add to main.tf at end of page

    resource "aws_network_acl_rule" "ingress" {
    for_each       = local.acl_ingress_rules
    network_acl_id = aws_network_acl.main.id
    rule_number    = (each.value.priority * 10) + 100
    egress         = false
    protocol       = each.value.protocol
    rule_action    = each.value.rule_action
    cidr_block     = each.value.cidr_block
    from_port      = each.value.from_port
    to_port        = each.value.to_port
    }

    resource "aws_network_acl_rule" "egress" {
    for_each       = local.acl_egress_rules
    network_acl_id = aws_network_acl.main.id
    rule_number    = (each.value.priority * 10) + 100
    egress         = true
    protocol       = each.value.protocol
    rule_action    = each.value.rule_action
    cidr_block     = each.value.cidr_block
    from_port      = each.value.from_port
    to_port        = each.value.to_port
    }

- add to the output section

    output "public_subnet_arns" {
    description = "ARNs of the created public subnets"
    value       = [for subnet in aws_subnet.public : subnet.arn]
    }

    output "bucket_domain_names" {
    description = "Domain names for each bucket created"
    value       = [for bucket in aws_s3_bucket.web : bucket.bucket_domain_name]
    }


Now play on the console to  test out our new local variable:

    $ terrafor init [skip if already done]

    $ terrafor console

    > { for rule in local.csv_data : rule.priority => rule if rule.direction == "ingress"}

        {
            "1" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "ingress"
                "from_port" = "80"
                "priority" = "1"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "80"
            }
            "2" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "ingress"
                "from_port" = "443"
                "priority" = "2"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "443"
            }
            "3" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "ingress"
                "from_port" = "1024"
                "priority" = "3"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "65535"
            }
        }

    > { for rule in local.csv_data : rule.priority => rule if rule.direction == "egress"}
        
        {
            "1" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "egress"
                "from_port" = "80"
                "priority" = "1"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "80"
            }
            "2" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "egress"
                "from_port" = "443"
                "priority" = "2"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "443"
            }
            "3" = {
                "cidr_block" = "0.0.0.0/0"
                "direction" = "egress"
                "from_port" = "1024"
                "priority" = "3"
                "protocol" = "tcp"
                "rule_action" = "allow"
                "to_port" = "65535"
            }
        }

    >  exit 

Once you are done, run the below:

    $ terraform fmt
    
    $ terraform validate
    
    $ terraform plan -out m5.tfplan
    
    $ terraform apply m5.tfplan
