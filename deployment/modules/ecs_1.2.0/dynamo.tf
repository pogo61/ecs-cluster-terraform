resource "aws_dynamodb_table" "ecs-tracking" {
  name         = "ecs_${var.name}_tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UniqueId"

  attribute {
    name = "UniqueId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name = "ecs_${var.name}_tracking"
  }
}

resource "aws_dynamodb_table" "ecs-auto-stop" {
  count        = var.create_auto_stop_table ? 1 : 0
  name         = "ecs_${var.name}_auto_stop"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Service"
  range_key    = "Cluster"

  attribute {
    name = "Service"
    type = "S"
  }

  attribute {
    name = "Cluster"
    type = "S"
  }

  global_secondary_index {
    name            = "Cluster-index"
    hash_key        = "Cluster"
    projection_type = "ALL"
  }
  tags = {
    Name = "ecs_${var.name}_auto_stop"
  }
}