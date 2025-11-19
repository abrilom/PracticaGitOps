variable "ec2_instance_type" {
  type = string
  default = "t3.micro"
  description = "The type of ec2"
  
}

variable "ec2_volume_type" {
  type = string
  default = "gp3"
}

variable "ec2_volume_size" {
  type = string
  default = "10"
  
}