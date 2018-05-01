from troposphere import Ref, Join, If
from troposphere.ec2 import Tag, VPC, Subnet, InternetGateway, VPCGatewayAttachment, DHCPOptions, VPCDHCPOptionsAssociation
from troposphere.ec2 import NetworkAcl, NetworkAclEntry, SubnetNetworkAclAssociation
from troposphere.ec2 import RouteTable, Route, SubnetRouteTableAssociation, SecurityGroup, SecurityGroupIngress, SecurityGroupEgress

def vpc(template):
    vpc = VPC("sgdemovpc", CidrBlock = "10.0.0.0/16", InstanceTenancy = "default", EnableDnsSupport = True, EnableDnsHostnames = True, Tags = [Tag("Name", "Search Guard Demo VPC")])
    template.add_resource(vpc)
    return vpc

def subnet(template, vpc):
    subnet = Subnet("sgdemosubnet", VpcId = Ref(vpc), CidrBlock = "10.0.0.0/24", Tags = [Tag("Name", "Search Guard Demo  Subnet")])
    template.add_resource(subnet)
    return subnet

def attach_internet_gateway(template, vpc):
    gateway = InternetGateway("sgdemointernetgateway")
    template.add_resource(gateway)
    gatewayattachment = VPCGatewayAttachment("sgdemoigw", VpcId = Ref(vpc), InternetGatewayId = Ref(gateway))
    template.add_resource(gatewayattachment)
    return gateway

def attach_dhcp_options(template, vpc):
    dhcpopts = DHCPOptions("sgdemodhcpoptions", DomainNameServers = ["AmazonProvidedDNS"], DomainName = If("RegionIsUsEast1", "ec2.internal", Join("", [Ref("AWS::Region"), ".compute.internal"])))
    template.add_resource(dhcpopts)
    dhcpassoc = VPCDHCPOptionsAssociation("sgdemodchpassoc", VpcId = Ref(vpc), DhcpOptionsId = Ref(dhcpopts))
    template.add_resource(dhcpassoc)
    return dhcpopts

def attach_acl(template, vpc, subnet):
    acl = NetworkAcl("sgdemoacl", VpcId = Ref(vpc))
    template.add_resource(acl)
    acl1 = NetworkAclEntry("sgdemoacl1", NetworkAclId = Ref(acl), CidrBlock = "0.0.0.0/0", Egress = True, Protocol = "-1", RuleAction = "allow", RuleNumber = "100")
    template.add_resource(acl1)
    acl2 = NetworkAclEntry("sgdemoacl2", NetworkAclId = Ref(acl), CidrBlock = "0.0.0.0/0", Protocol = "-1", RuleAction = "allow", RuleNumber = "100")
    template.add_resource(acl2)
    aclassoc = SubnetNetworkAclAssociation("sgdemosubnetacl1", NetworkAclId = Ref(acl), SubnetId = Ref(subnet))
    template.add_resource(aclassoc)
    return acl

def attach_route_table(template, vpc, subnet, gateway):
    routetable = RouteTable("sgdemoroutetable", VpcId = Ref(vpc))
    template.add_resource(routetable)
    route = Route("sgdemoroute1", RouteTableId = Ref(routetable), DestinationCidrBlock = "0.0.0.0/0", GatewayId = Ref(gateway))
    template.add_resource(route)
    routetableassoc = SubnetRouteTableAssociation("sgdemosubnetroute1", RouteTableId = Ref(routetable), SubnetId = Ref(subnet))
    template.add_resource(routetableassoc)
    return routetable

def attach_security_group(template, vpc):
    secgroup = SecurityGroup("sgdemosecuritygroup", GroupDescription = "sgdemosecuritygroup", VpcId = Ref(vpc))
    template.add_resource(secgroup)
    ingress = SecurityGroupIngress("sgdemoingressssh", GroupId = Ref(secgroup), IpProtocol = "tcp", FromPort = "22", ToPort = "22", CidrIp = "0.0.0.0/0")
    template.add_resource(ingress)
    ingress = SecurityGroupIngress("sgdemoingresses", GroupId = Ref(secgroup), IpProtocol = "tcp", FromPort = "9200", ToPort = "9399", CidrIp = "0.0.0.0/0")
    template.add_resource(ingress)
    ingress = SecurityGroupIngress("sgdemoingresskibana", GroupId = Ref(secgroup), IpProtocol = "tcp", FromPort = "5601", ToPort = "5601", CidrIp = "0.0.0.0/0")
    template.add_resource(ingress)
    egress = SecurityGroupEgress("sgdemoegress", GroupId = Ref(secgroup), IpProtocol = "-1", FromPort = "-1", ToPort = "-1", CidrIp = "0.0.0.0/0")
    template.add_resource(egress)
    return secgroup