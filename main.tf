resource "aws_vpc" "PROYECTO-VPC" {
    cidr_block = "192.168.0.0/16"

    tags = {
      "Name" = "PROYECTO-VPC"
    }      
}



resource "aws_internet_gateway" "INTERNET-GW-PROYECTO" {
    vpc_id = aws_vpc.proyecto-vpc.id  
}




resource "aws_subnet" "SUBNET-PUBLIC-14" {

    vpc_id = aws_vpc.PROYECTO-VPC.id
    cidr_block = "192.168.3.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "SUBNET-PUBLIC-14"
    }  
}



resource "aws_subnet" "SUBNET-PRIVATE-15" {
    vpc_id = aws_vpc.PROYECTO-VPC.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "SUBNET-PRIVATE-15"
    }
  
    
    
    resource "aws_subnet" "SUBNET-PUBLICA" {

    vpc_id = aws_vpc.PROYECTO-VPC.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "SUBNET-PUBLICA"
    }  
}
   
    
}

resource "aws_subnet" "SUBNET-PRIVATE-16" {
    vpc_id = aws_vpc.PROYECTO-VPC.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "SUBNET-PRIVATE-16"
    }
  
}


resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION" {
    subnet_id = aws_subnet.SUBNET-PUBLICA.id
    route_table_id = aws_route_table.R-PUBLIC.id  
}



resource "aws_route_table" "ROUTES-PUBLIC-8" {
    vpc_id = aws_vpc.PROYECTO-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.INTERNET-GW-PROYECTO.id
    }

    tags = {
      "Name" = "ROUTES-PUBLIC-8"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-ASSOCIATION-8" {
    subnet_id = aws_subnet.SUBNET-PUBLIC-14.id
    route_table_id = aws_route_table.ROUTES-PUBLIC-8.id  
}

resource "aws_route_table" "R-PUBLIC" {
    vpc_id = aws_vpc.PROYECTO-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.INTERNET-GW-PROYECTO.id
    }

    tags = {
      "Name" = "R-PUBLIC"
    }
  
}



resource "aws_eip" "EIP-NATGATWAY" {
    vpc = true

    tags = {
        Name = "EIP-NATGATWAY"
    }  
}

resource "aws_nat_gateway" "NAT-GW-PROYECTO" {
    allocation_id = aws_eip.NATGATWAY.id
    subnet_id = aws_subnet.SUBNET-PUBLICA.id

    tags = {
      "Name" = "NAT-GW-PROYECTO"
    }
}



resource "aws_route_table" "ROUTES-PRIVATE-7" {
      vpc_id = aws_vpc.PROYECTO-VPC.id

      route {
          cidr_block = "0.0.0.0/0"
          nat_gateway_id = aws_nat_gateway.INTERNET-GW-PROYECTO.id
      }

      tags = {
        "Name" = "ROUTES-PRIVATE"
      }
}


resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-7" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-15.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-7.id  
}

resource "aws_route_table" "ROUTES-PRIVATE-8" {
    vpc_id = aws_vpc.PROYECTO-VPC.id

    route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.INTERNET-GW-PROYECTO.id
    }
    
    tags = {
      "Name" = "ROUTES-PRIVATE-8"
    }  
}

resource "aws_route_table_association" "ROUTES-SUBNETS-PRIVATE-ASSOCIATION-8" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-16.id
    route_table_id = aws_route_table.ROUTES-PRIVATE-8.id  
}



resource "aws_security_group" "SECG-LINUX" {
    name = "Allow_Traffic"
    description = "Allow_Traffic"
    vpc_id = aws_vpc.PROYECTO-VPC.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all ping"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SECG-LINUX"
    }
}



resource "aws_network_interface" "NC-L" {
    subnet_id = aws_subnet.SUBNET-PUBLICA.id
    private_ips = ["192.168.0.50"]
    security_groups = [aws_security_group.SECG-LINUX.id]  
}


resource "aws_network_interface" "NC-LIN-PRIV-A" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-15.id
    private_ips = ["192.168.1.50"]
    security_groups = [aws_security_group.SECG-LINUX.id]   
}

resource "aws_network_interface" "NC-LIN-PRIV-B" {
    subnet_id = aws_subnet.SUBNET-PRIVATE-16.id
    private_ips = ["192.168.2.50"]
    security_groups = [aws_security_group.SECG-LINUX.id]   
}





resource "aws_eip" "EIP-LINUX" {
    vpc = true
    network_interface = aws_network_interface.NC-L.id
    associate_with_private_ip = "192.168.0.50"
    depends_on = [
      aws_internet_gateway.INTERNET-GW-PROYECTO
    ]  
}




output "SERVER-PUBLICO-IP" {
    value = aws_eip.EIP-LINUX   
}


resource "aws_instance" "EC2-LINUX" {
    ami = " ami-02ae90ad0061241fa"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "clavesproyecto"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LINUX.id
    }

    tags = {
      "Name" = "EC2-LINUX"
    }
     
}


resource "aws_instance" "EC2-LINUX-PRIVATE-7" {
    ami = " ami-02ae90ad0061241fa"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "clavesproyecto"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NC-LIN-PRIV-A.id
    }

     user_data = <<-EOF
            #!/bin/bash           
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF

    tags = {
      "Name" = "EC2-LINUX-PRIVATE-7"
    }     
}

resource "aws_instance" "EC2-LINUX-PRIVATE-8" {
    ami = " ami-02ae90ad0061241fa"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "clavesproyecto"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NC-LIN-PRIV-8.id
    }

    user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF


    tags = {
      "Name" = "EC2-LINUX-PRIVATE-8"
    }
     
}


output "MY-SERVER-PRIVATE-IP" {
    value = aws_instance.EC2-LINUX.private_ip  
}


output "server_id" {
    value = aws_instance.EC2-LINUX.id  
} 
