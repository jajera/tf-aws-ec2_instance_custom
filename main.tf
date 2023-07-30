# create rg, list created resources
resource "aws_resourcegroups_group" "example" {
  name        = "tf-rg-example"
  description = "Resource group for example resources"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Owner",
          "Values": ["John Ajera"]
        }
      ]
    }
    JSON
  }

  tags = {
    Name  = "tf-rg-example"
    Owner = "John Ajera"
  }
}

# create vpc
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name  = "tf-vpc-example"
    Owner = "John Ajera"
  }
}

# create subnet
resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name  = "tf-subnet-example"
    Owner = "John Ajera"
  }
}

# create ig
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name  = "tf-ig-example"
    Owner = "John Ajera"
  }
}

# create rt
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.example.id
  }

  tags = {
    Name  = "tf-rt-example"
    Owner = "John Ajera"
  }
}

# set rt association
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

# create sg
resource "aws_security_group" "example" {
  name        = "tf-sg-example"
  description = "Security group for example resources"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "tf-sg-example"
    Owner = "John Ajera"
  }
}

# get image ami
data "aws_ami" "example" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-8.8.0_HVM-20230623-x86_64-3-Hourly2-GP2"]
  }
}

# get ssh key pair
resource "aws_key_pair" "example" {
  key_name   = "tf-kp-example"
  public_key = file("~/.ssh/id_ed25519_aws_2023-07-30.pub")
}

# create vm
resource "aws_instance" "example" {
  ami                         = data.aws_ami.example.id
  instance_type               = "m5.large"
  key_name                    = aws_key_pair.example.key_name
  subnet_id                   = aws_subnet.example.id
  vpc_security_group_ids      = [aws_security_group.example.id]
  associate_public_ip_address = true

  lifecycle {
    ignore_changes = [
      associate_public_ip_address
    ]
  }

  tags = {
    Name  = "tf-instance-example"
    Owner = "John Ajera"
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
}
