# INSTANCE
resource "aws_instance" "nodejs1" {
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg-nodejs-instance.id]
  key_name               = var.ssh_key_name

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }
}
