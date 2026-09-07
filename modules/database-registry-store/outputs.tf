# =========================================================
# DATABASE REGISTRY STORE OUTPUTS
# =========================================================

output "table_name" {

  description = "DynamoDB database registry table name"

  value = aws_dynamodb_table.this.name

}


output "table_arn" {

  description = "DynamoDB database registry table ARN"

  value = aws_dynamodb_table.this.arn

}