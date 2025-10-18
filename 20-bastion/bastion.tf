resource "aws_instance" "this" {
  ami                    = var.ami # This is our devops-practice AMI ID
  vpc_security_group_ids = [data.aws_ssm_parameter.bastion_sg_id.value]
  instance_type          = "t3.large"
  subnet_id   = local.public_subnet_id
  associate_public_ip_address = true 
  # 20GB is not enough
  root_block_device {
    volume_size = 40  # Set root volume size to 50GB
    volume_type = "gp3"  # Use gp3 for better performance (optional)
  }
  user_data = file("bastion.sh")
  
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-bastion"
    }
  )
}

output "bastion_public_ip" {
  value = aws_instance.this.public_ip
}
