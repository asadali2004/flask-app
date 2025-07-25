output "ecs_cluster_name" {
  value = aws_ecs_cluster.flask_cluster.name
}

output "service_name" {
  value = aws_ecs_service.flask_service.name
}
