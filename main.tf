

# Resource to create DynamoDB table
resource "aws_dynamodb_table" "cornelia_bookinventory" {
  name           = "cornelia-bookinventory"
  billing_mode   = "PAY_PER_REQUEST" # Default billing mode
  hash_key       = "ISBN"
  range_key      = "Genre"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.cornelia_bookinventory.name
}
resource "aws_iam_policy" "dynamodb_list_read_policy" {
  name        = "cornelia-dynamodb-read"
  description = "Allows list and read actions on DynamoDB"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:List*",
          "dynamodb:Describe*",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource ="${aws_dynamodb_table.cornelia_bookinventory.arn}"
      }
    ]
  })
}
resource "aws_iam_role" "cornelia-dynamodb-read-role" {
  name               = "cornelia-dynamodb-read-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"  # Trusted entity is EC2
        },
        Action    = "sts:AssumeRole"    # EC2 can assume this role
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_dynamodb_policy_attachment" {
  role       = aws_iam_role.cornelia-dynamodb-read-role.name
  policy_arn = aws_iam_policy.dynamodb_list_read_policy.arn
}

//create instance
resource "aws_iam_instance_profile" "ec2_dynamodb_read_instance_profile" {
  name = "cornelia-dynamodb-read-instance-profile"
  role = aws_iam_role.cornelia-dynamodb-read-role.name  # Link the role here
}

locals {
  department = "book"
}
 
resource "aws_instance" "cornelia-dynamodb-reader" {
  ami                         = "ami-04c913012f8977029"  # Replace with the appropriate AMI ID
  instance_type               = "t2.micro"
  subnet_id                   =  "subnet-004425cdf7e7a28a8"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.cornelia_security_group.id]
  key_name                    = "cornelia-key-pair"


  # Correctly reference the instance profile name
  iam_instance_profile        = aws_iam_instance_profile.ec2_dynamodb_read_instance_profile.name

  tags = {
    Name        = "cornelia-dynamodb-reader"
    Department = local.department
  }
}


resource "aws_security_group" "cornelia_security_group" {
  name        = "ec2-ssh-https-access"
  description = "Allow SSH and HTTPS traffic"

  # Allow SSH from your home IP address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your public IP address
  }

  # Allow HTTPS (port 443) to external endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


