resource "aws_key_pair" "key" {
  key_name   = "${var.dc_tag_prefix}-hashi-key"
  public_key = file(var.public_key)
}

# Create VPC and Networking

resource "aws_vpc" "hashi_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "hashi-network"
  }
}

resource "aws_subnet" "hashi_subnet" {
  vpc_id            = aws_vpc.hashi_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "hashi-network"
  }
}
/*
resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.hashi_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "foo" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

}
*/

# Create Servers
resource "aws_instance" "servers" {
  ami           = local.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.key.key_name
  count         = var.server_count

  tags = {
    Name = "${var.dc_tag_prefix}-${var.server_name_prefix}${format("%02d", count.index + 1)}"
  }

}

resource "aws_instance" "clients" {
  ami           = local.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.key.key_name
  count         = var.client_count

  tags = {
    Name = "${var.dc_tag_prefix}-${var.client_name_prefix}${format("%02d", count.index + 1)}"
  }

}
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      servers = tomap({
        for instance in aws_instance.servers :
        instance.tags.Name => instance.public_ip
      })
      clients = tomap({
        for instance in aws_instance.clients :
        instance.tags.Name => instance.public_ip
      })
    }
  )
  filename = "../inventory"
}
