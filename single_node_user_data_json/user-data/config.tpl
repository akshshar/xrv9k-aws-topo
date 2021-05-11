username root
group root-lr
group cisco-support
!
hostname ${hostname}
!
interface TenGigE0/0/0/0
ipv4 address ${mgmt_ip}/${mgmt_subnet}
no shutdown
!
router static
address-family ipv4 unicast
0.0.0.0/0 ${mgmt_gw_ip}
!
!
ssh server v2
ssh server vrf default
!
!
end
