output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_task.id
}

output "ecs_cluster" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.valheim.family
}

output "config_bucket" {
  value = aws_s3_bucket.config.bucket
}
