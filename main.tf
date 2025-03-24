resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
    tags = {
        Name = "myvpc"
    }
}
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
    tags = {
        Name = "subnet1"
    }
}
resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
    tags = {
        Name = "subnet2"
    }
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
        tags = {
            Name = "igw"
        }
}
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id    

    }
}


resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable.id
}



resource "aws_security_group" "allow_tls" {
  vpc_id = aws_vpc.myvpc.id
  ingress {
    description = "ssh from VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
     ingress {
        description = "http from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
     ingress {
        description = "https from VPC"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_s3_bucket" "bucketformyfirstterraformproject" {
  bucket = "bucketformyfirstterraformproject"
  
  tags = {
    Name = "bucketformyfirstterraformproject"
  }
  
}
resource "aws_s3_bucket_public_access_block" "bucketformyfirstterraformproject" {
  bucket = aws_s3_bucket.bucketformyfirstterraformproject.bucket
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
}


resource "aws_instance" "server1" {
  ami = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  key_name = "ubuntu1"
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data = base64encode(file("userdata.sh"))
  tags = {
    Name = "project"
  }
  
}
resource "aws_instance" "server2" {
  ami = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  key_name = "ubuntu1"
  subnet_id = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
   user_data = base64encode(file("userdata1.sh"))
  tags = {
    Name = "project1"
  }
  
}

resource "aws_lb" "myalb" { 
    name = "myalb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.allow_tls.id]
    subnets = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    enable_deletion_protection = false
    enable_http2 = true
    idle_timeout = 60       
  
}

resource "aws_lb_target_group" "tg" {

    name = "mytargetgroup"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    target_type = "instance"
    health_check {
        path = "/"
        # protocol = "HTTP"
        port = "traffic-port"
        # interval = 30
        # timeout = 5
        # healthy_threshold = 2
        # unhealthy_threshold = 2
    }
  
}

resource "aws_lb_target_group_attachment" "target1" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.server1.id
    port = 80
}
resource "aws_lb_target_group_attachment" "target2" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.server2.id
    port = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port = "80"
  protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}

output "load_balancer_dns_name" {   
  value = aws_lb.myalb.dns_name
  
}