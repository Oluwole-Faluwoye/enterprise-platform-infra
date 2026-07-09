resource "aws_iam_policy" "aws_load_balancer_controller" {

  name = "${var.project}-${var.environment}-aws-load-balancer-controller"

  description = "IAM policy for the AWS Load Balancer Controller"

  policy = file("${path.module}/policies/aws-load-balancer-controller-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {

  role = aws_iam_role.aws_load_balancer_controller.name

  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}