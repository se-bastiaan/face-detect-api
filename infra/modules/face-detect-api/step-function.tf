module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "${var.prefix}-processing"
  definition = jsonencode({
    "StartAt" : "Process-All",
    "States" : {
      "Process-All" : {
        "Type" : "Map",
        "ItemsPath" : "$.images",
        "ResultPath" : "$.images",
        "MaxConcurrency" : 50,
        "Iterator" : {
          "StartAt" : "Process",
          "States" : {
            "Process" : {
              "Type" : "Task",
              "Resource" : "${module.face_recognition_function.function_arn}",
              "End" : true
            }
          }
        },
        "End" : true
      }
    }
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  service_integrations = {
    lambda = {
      lambda = [module.face_recognition_function.function_arn]
    }
  }

  type = "STANDARD"

  tags = var.tags

  depends_on = [module.face_recognition_function.function_arn]
}

resource "aws_iam_role" "step_function_execution" {
  name = "${var.prefix}-gateway-start-processing"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "allow_state_machine_start"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "states:StartExecution"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${module.step_function.state_machine_arn}"
          ]
        }
      ]
    })
  }

  tags = var.tags
}