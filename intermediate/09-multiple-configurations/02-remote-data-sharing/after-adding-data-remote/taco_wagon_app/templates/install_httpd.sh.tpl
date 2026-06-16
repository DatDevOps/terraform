#!/bin/bash
# Install and configure Apache httpd

yum update -y
yum install -y httpd

# Get EC2 instance metadata
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)

# Create index.html from template
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${company_name} - ${environment}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            backdrop-filter: blur(4px);
        }
        h1 {
            font-size: 3em;
            margin: 0 0 20px 0;
        }
        .info {
            font-size: 1.2em;
            margin: 10px 0;
        }
        .label {
            font-weight: bold;
            color: #ffd700;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${company_name}</h1>
        <div class="info">
            <span class="label">Environment:</span> ${environment}
        </div>
        <div class="info">
            <span class="label">Instance ID:</span> $${instance_id}
        </div>
    </div>
</body>
</html>
HTMLEOF

# Replace instance_id placeholder with actual instance ID
sed -i "s/\$${instance_id}/$INSTANCE_ID/g" /var/www/html/index.html

# Start and enable httpd service
systemctl start httpd
systemctl enable httpd