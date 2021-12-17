module "results_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name      = "${var.prefix}-results"
  hash_key  = "execution"
  range_key = "id"

  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "execution"
      type = "S"
    },
    {
      name = "id"
      type = "S"
    }
  ]

  tags = var.tags
}