from troposphere import Parameter

def keyname(template):
    keyname = Parameter("KeyName", Description = "Required: Specify your AWS EC2 Key Pair.", Type = "AWS::EC2::KeyPair::KeyName")
    template.add_parameter(keyname)
    return keyname
    