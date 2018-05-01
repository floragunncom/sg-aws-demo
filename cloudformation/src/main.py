import template
import params
import network
import mapping
import instance
import output
import security

template = template.create()

keyname = params.keyname(template)
mapping.add(template)
vpc = network.vpc(template)
subnet = network.subnet(template, vpc)
gateway = network.attach_internet_gateway(template, vpc)
dhcp = network.attach_dhcp_options(template, vpc)
acl = network.attach_acl(template, vpc, subnet)
routetable = network.attach_route_table(template, vpc, subnet, gateway)
secgroup = network.attach_security_group(template, vpc)
role = security.role(template)


sg1 = instance.addSearchGuard(template, role, subnet, keyname, secgroup,"node1")
sg2 = instance.addSearchGuard(template, role, subnet, keyname, secgroup,"node2")
sg3 = instance.addSearchGuard(template, role, subnet, keyname, secgroup,"node3")
output.add(template, [sg1,sg2,sg3])

print(template.to_json())