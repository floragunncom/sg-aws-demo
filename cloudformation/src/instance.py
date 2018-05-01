from troposphere import FindInMap, Ref
from troposphere.ec2 import Instance, Tag, NetworkInterfaceProperty, PrivateIpAddressSpecification, BlockDeviceMapping, EBSBlockDevice
from troposphere.iam import InstanceProfile
from troposphere.helpers import userdata

def addSearchGuard(template, role, subnet, keyname, secgroup, profilename):
    profile = InstanceProfile("sgprofile"+profilename, Path = "/", Roles = [Ref(role)])
    template.add_resource(profile)
    instance = Instance("sg"+profilename,
        InstanceType = "m4.xlarge",
        ImageId = FindInMap("RegionToAmi", Ref("AWS::Region"), "stable"),
        DisableApiTermination = False,
        IamInstanceProfile = Ref(profile),
        KeyName = Ref(keyname),
        Monitoring = False,
        InstanceInitiatedShutdownBehavior = "stop",
        UserData = userdata.from_file("src/bootstrap.sh"),
        NetworkInterfaces = [
            NetworkInterfaceProperty(
                DeviceIndex = 0,
                Description = "Primary network interface",
                SubnetId = Ref(subnet),
                DeleteOnTermination = True,
                AssociatePublicIpAddress = True,
                GroupSet = [
                    Ref(secgroup)
                ]
            )
        ],
        Tags = [Tag("Name", "Search Guard "+profilename), Tag("sgnodetag", profilename)],
        EbsOptimized = False,
        BlockDeviceMappings = [
            BlockDeviceMapping (
                DeviceName = "/dev/sda1",
                Ebs = EBSBlockDevice(
                    VolumeSize = 25
                )
           )
        ]
    )
    template.add_resource(instance)
    return instance