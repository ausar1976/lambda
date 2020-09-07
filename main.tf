provider "aws" {
  version = "~> 2.7"
  region  = "eu-west-2"

}

resource "aws_cloudwatch_event_rule" "shutdown" {
  name        = "ec2shutdown"
  description = "remidiate device shutdown"

  event_pattern = <<PATTERN

{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "stopping"

    ],
    "instance-id": [
      "i-0af49ba720d8d2a86"
    ]
  }
}
PATTERN
}

//resource "aws_cloudwatch_event_target" "sns1" {
  //target_id = "sns1"
  //rule = "${aws_cloudwatch_event_rule.shutdown}"
  //arn = "arn:aws:sns:eu-west-2:097370392576:config-topiclondon"
//}


## Resources ##

data "archive_file" "lambdaec2murk" {

 type        = "zip"

 source_file = "../terraform/lambda/ec2murk.py"

 output_path = "lambdaecmurk.zip"

}


resource "aws_cloudwatch_event_target" "lambdaec2" {
target_id = "lamdaec2_id"
rule = "${aws_cloudwatch_event_rule.shutdown.name}"
arn = "${aws_lambda_function.ec2murk.arn}"
}


resource "aws_lambda_function" "ec2murk" {

filename         = "lambdaecmurk.zip"

function_name    = "startec2"




role             = "${aws_iam_role.ec2murkrole.arn}"

 timeout         = 10

handler          = "ec2murk.lambda_handler"

runtime          = "python2.7"

memory_size      = 128

description      = "Lambda function starts up ec2 instances"




//environment {

//variables =
//{

//aws_account = "097370392576"
//aws_account_id = "simpsoncloud"


  //}

  //}




  //tags {


 //owner      = "me"

// region     = "eu-west-2"


 //}

}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_ec2murk" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ec2murk.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.shutdown.arn}"
}

data "aws_iam_policy_document" "ec2shut" {
  statement {
    sid = "1"

    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }

  statement {
   sid = ""

    actions = [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:StartInstances",
        "ec2:StopInstances",
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_role" "ec2murkrole" {
  name = "ec2murkrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2shut" {
  name   = "ec2shut_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.ec2shut.json}"
}

resource "aws_iam_policy_attachment" "ec2-attach" {
  name       = "ec2-attachment"
  roles      = ["${aws_iam_role.ec2murkrole.name}"]
  policy_arn = "${aws_iam_policy.ec2shut.arn}"
}
