from troposphere import Template, Ref, Equals

def create():
    template = Template()
    template.add_version("2010-09-09")
    template.add_condition("RegionIsUsEast1", Equals(Ref("AWS::Region"), "us-east-1"))
    return template