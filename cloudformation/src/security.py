from troposphere.iam import Role, Policy, InstanceProfile
from awacs.aws import Statement, Allow, Principal, Action
from awacs.sts import AssumeRole
import awacs.aws

#def allow_stmt(action):
#    return Statement(Effect = Allow, Resource = ["*"], Action = [Action(action, "*")])


def role(template):

    role = Role("sgdemorole",
        AssumeRolePolicyDocument = awacs.aws.Policy(
            Statement = [
                Statement(
                    Effect = Allow,
                    Principal = Principal("Service", ["ec2.amazonaws.com"]),
                    Action = [AssumeRole]
                )
            ],
            Version = "2012-10-17"
        ),
        Path = "/",
        Policies = [
            Policy(
                PolicyName = "sgdemopolicy",
                PolicyDocument = awacs.aws.Policy(
                    Statement = [Statement(Effect = Allow, Resource = ["*"], Action = [Action("ec2", "DescribeInstances")])]
                    #Statement = map(allow_stmt, ["ec2", "SNS", "elasticloadbalancing", "cloudwatch", "autoscaling", "iam", "ecr", "s3", "cloudformation"])
                )
            )
        ]
    )
    template.add_resource(role)
    return role