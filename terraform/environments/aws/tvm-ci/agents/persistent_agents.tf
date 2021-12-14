resource "aws_iam_role" "persistent_agents" {
  name = "persistent_agents_role"

  # Terraform's "jsonencode" function converts a
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
resource "aws_iam_role_policy" "persistent_agents" {
  name = "describeTags"
  role = aws_iam_role.persistent_agents.id


  policy = <<-EOF
 {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "DescribeTags",
       "Effect": "Allow",
       "Action": [
         "ec2:DescribeTags"
       ],
      "Resource": [
        "*"
      ]
     }
   ]
 }
EOF
}

resource "aws_iam_instance_profile" "persistent_agents" {
  name = "persistent_agents_instance_profile"
  role = aws_iam_role.persistent_agents.name
}

module "Production-Jenkins-Agents" {
  for_each                 = var.persistent_agent_types
  source                   = "../../../../modules/aws/tvm-ci/persistent-agents"
  subnet_id                = local.frontend_subnet_ids[0]
  security_groups          = [aws_security_group.ssh_inbound.id, aws_security_group.egress.id]
  jenkins_instance_profile = aws_iam_instance_profile.persistent_agents.name
  jenkins_token            = var.jenkins_token
  jenkins_url              = "https://ci.tlcpack.ai"
  image_family             = each.value.image_family
  vm_group_name            = each.key
  agent_attributes         = each.value.agent_attributes
  agent_instance_type      = each.value.agent_instance_type
  executor_access_pub_keys = var.executor_access_pub_keys
  jenkins_pub_key          = var.jenkins_pub_key
  replicas                 = each.value.replicas
  template_versions        = each.value.template_versions
}
