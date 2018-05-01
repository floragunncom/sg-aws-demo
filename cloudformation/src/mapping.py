def add(template):
    template.add_mapping("RegionToAmi", {



        "ap-northeast-1": {"stable": "ami-0d74386b"}, #Tokyo
        "ap-northeast-2": {"stable": "ami-a414b9ca"}, #Seoul

        "ap-southeast-1": {"stable": "ami-52d4802e"}, #Singapore
        "ap-southeast-2": {"stable": "ami-d38a4ab1"}, #Sydney
        "ap-south-1": {"stable": "ami-0189d76e"}, #Mumbai

        "eu-west-1": {"stable": "ami-f90a4880"}, #Ireland
        "eu-west-2": {"stable": "ami-f4f21593"}, #London
        "eu-west-3": {"stable": "ami-0e55e373"}, #Paris

        "eu-central-1": {"stable": "ami-7c412f13"}, #Frankfurt

        "us-east-1": {"stable": "ami-43a15f3e"}, #N. Virgina
        "us-east-2": {"stable": "ami-916f59f4"}, #Ohio
        "us-west-1": {"stable": "ami-925144f2"}, #CA
        "us-west-2": {"stable": "ami-4e79ed36"}, #Oregon

        #Sao Paulo
        "sa-east-1": {"stable": "ami-423d772e"},

        #Canada
        "ca-central-1": {"stable": "ami-ae55d2ca"}

    })