# docker-ecs-route53

This Docker container can be used to have e.g. all your ECS instances "register" themselves with a Route53 record of a zone you are using.
If no `--action` parameter is provided, it will assume that is should add the provided IP to that record.
The created record will be a round-robin A record.
* If no record exists, a new one will be created.
* If a record exists, it will be deleted and recreated with the addresses it previously contained (plus the supplied address, of course).
* If the IP is supposed to be removed, the record will also be deleted and recreated (minus the supplied address).
* If the is supposed to be removed and it is the only address in the record, the record will be deleted.

## Required IAM Permissions
I highly recommend using IAM Roles for your ECS instances, and granting the following permissions via a policy:
* route53:ListHostedZones
* route53:ListResourceRecordSets
* route53:ChangeResourceRecordSets

## CoreOS systemd unit
The CoreOS systemd unit isn't thouroughly tested, but it seems to work fine. New ECS instances are added on boot and removed on reboot/shutdown.
Make sure to edit or provide values for the variables `$domain` and `$cluster`, but `$public_ipv4` should be filled by CoreOS. You can also use `$private_ipv4` or anything else you want to use.
```
- name: route53-register.service
    command: start
    content: |
      [Unit]
      Description=route53-register
      After=docker.service
      Requires=docker.service
      [Service]
      Type=oneshot
      RemainAfterExit=yes
      ExecStartPre=-/usr/bin/docker rm route53-register
      ExecStartPre=/usr/bin/docker pull jangrewe/ecs-route53
      ExecStart=/bin/sh -c "/usr/bin/docker run --name route53-register jangrewe/ecs-route53:latest --action add --domain $domain --record $cluster --ip $public_ipv4"
      ExecStop=/bin/sh -c "/usr/bin/docker run --name route53-register jangrewe/ecs-route53:latest --action remove --domain $domain --record $cluster --ip $public_ipv4"

```
