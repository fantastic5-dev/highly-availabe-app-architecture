# Parameter Store
resource "aws_ssm_parameter" "image_tag" {
  name  = "/ha-platform/app/image-tag"
  type  = "String"
  value = "initial"
}
