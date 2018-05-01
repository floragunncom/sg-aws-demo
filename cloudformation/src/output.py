from troposphere import GetAtt, Output, Ref
import uuid

def add(template, instances):
	for instance in instances:
		template.add_output([
			Output("PublicIP"+str(uuid.uuid4()).replace("-", ""), Description = "SG Server", Value = GetAtt(instance, "PublicIp"))
		])