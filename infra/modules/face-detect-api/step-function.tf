module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "${var.prefix}-processing"
  definition = jsonencode({
    "StartAt" : "Process-Images",
    "States" : {
      "Process-Images" : {
        "Type" : "Map",
        "ItemsPath" : "$.images",
        "ResultPath" : "$.images",
        "OutputPath": "$.callback",
        "MaxConcurrency" : 50,
        "Iterator" : {
          "StartAt" : "Obtain-Encodings",
          "States" : {
            "Obtain-Encodings" : {
              "Type" : "Task",
              "Resource" : "${module.face_recognition_function.function_arn}",
              "Next" : "Save-Data"
            },
            "Save-Data" : {
              "Type" : "Task",
              "Resource" : "arn:aws:states:::dynamodb:putItem",
              "Parameters" : {
                "TableName" : "${module.results_table.dynamodb_table_id}",
                "Item" : {
                  "execution" : {
                    "S.$" : "$$.Execution.Id"
                  },
                  "url.$" : "$.url",
                  "id.$" : "$.id",
                  "encodings.$" : "$.encodings"
                }
              },
              "End" : true,
              "ResultSelector": {},
              "ResultPath" : "$"
            }
          }
        },
        "Next" : "Send-Callback"
      },
      "Send-Callback" : {
        "Type" : "Task",
        "Resource" : "${module.send_callback_function.function_arn}",
        "Parameters": {
            "callback.$": "$",
            "executionId.$": "$$.Execution.Id"
        }
        "End" : true
      }
    }
  })

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  # This may cause problems the first time that this module is created, run the code without this section and then with to bypass
  service_integrations = {
    lambda = {
      lambda = [module.face_recognition_function.function_arn, module.send_callback_function.function_arn]
    }
    dynamodb = {
      dynamodb = [module.results_table.dynamodb_table_arn]
    }
  }

  type = "STANDARD"

  tags = var.tags

  depends_on = [module.face_recognition_function.function_arn, module.send_callback_function.function_arn, module.results_table.dynamodb_table_arn]
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