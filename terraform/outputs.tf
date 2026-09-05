output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "config_bucket" {
  value = aws_s3_bucket.config.bucket
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.valheim.arn
}
