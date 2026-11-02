# 完整云连接网络示例

本示例创建一个本端中转路由器（TR），接入两个已有 VPC，并连接一个已有的同账号远端 TR。VPN、专线和跨地域带宽均为可选配置。

## 资源边界

本示例管理：

- 本端 TR。
- 两个本端 VPC 挂载及自动路由发布。
- production 路由表、关联、传播和静态路由。
- 本端到已有远端 TR 的跨地域连接。
- 可选 VPN、专线网关挂载。

调用方负责已有 VPC、子网、远端 TR、远端 VPC 和回程路由、VPN 连接、专线网关及带宽包。本示例不修改远端地域资源，也不购买或删除带宽包。

## 参数

必填参数使用平铺字段：

```hcl
region                     = "cn-beijing"
primary_vpc_id             = "vpc-primary"
primary_subnet_id          = "subnet-primary"
branch_vpc_id              = "vpc-branch"
branch_subnet_id           = "subnet-branch"
peer_transit_router_id     = "tr-remote"
peer_region_id             = "ap-southeast-1"
peer_cidr_block            = "10.21.0.0/16"
```

模块根据子网 ID 自动查询 zone 并校验 VPC 归属。远端 TR 必须已经存在；远端业务 VPC 和回程路由由调用方提前配置。

VPN 需要连接 ID 和 zone，专线只需网关 ID：

```hcl
vpn_connection_id         = "vgc-existing"
vpn_zone_id               = "cn-beijing-a"
direct_connect_gateway_id = "dcg-existing"
```

VPN 对端网段由 VPN ID 自动查询，`vpn_zone_id` 仍需显式填写。专线默认使用路由传播，不要求额外填写静态网段。

跨地域带宽是两个成对可选参数：

```hcl
bandwidth_package_id = "tbp-existing"
peer_bandwidth       = 1
```

两项必须同时填写或同时省略。省略时会创建零带宽控制面连接；跨地域流量需要分配正数带宽。带宽包必须覆盖两端地域，状态正常且剩余容量不少于分配值。

全部输入如下：

| 参数 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `region` | 是 | 无 | 本端地域。 |
| `primary_vpc_id` | 是 | 无 | 主 VPC ID。 |
| `primary_subnet_id` | 是 | 无 | 主 VPC 挂载子网 ID。 |
| `branch_vpc_id` | 是 | 无 | 分支 VPC ID。 |
| `branch_subnet_id` | 是 | 无 | 分支 VPC 挂载子网 ID。 |
| `peer_transit_router_id` | 是 | 无 | 已有远端 TR ID。 |
| `peer_region_id` | 是 | 无 | 远端 TR 地域。 |
| `peer_cidr_block` | 是 | 无 | 远端可达网段。 |
| `name` | 否 | `group-multi-region-ccn` | 本端 TR 名称。 |
| `vpn_connection_id` | 否 | `null` | 已有 VPN 连接 ID。 |
| `vpn_zone_id` | 否 | `null` | VPN 连接所在可用区，与 VPN ID 成对填写。 |
| `direct_connect_gateway_id` | 否 | `null` | 已有专线网关 ID。 |
| `bandwidth_package_id` | 否 | `null` | 已有带宽包 ID。 |
| `peer_bandwidth` | 否 | `null` | 跨地域分配带宽，单位 Mbps。 |

TR 的 ASN 不作为输入，由云端使用默认值。

## 执行

```shell
terraform init
terraform plan -parallelism=1 -var-file=<参数文件> -out=deployment.tfplan
terraform apply -parallelism=1 deployment.tfplan
terraform plan -parallelism=1 -detailed-exitcode -var-file=<参数文件>
terraform destroy -parallelism=1 -var-file=<参数文件>
```

使用 `-parallelism=1` 串行执行同一个 TR 的相关操作。Apply 后可再次执行 Plan 检查配置漂移。

## 网络互通要求

端到端互通要求远端 TR 已接入业务 VPC、两端路由完整、VPC 路由已发布，并配置匹配的安全组和网络 ACL 规则。跨境连接还要求账号具备跨境资质。

带宽包由调用方管理；Destroy 只解除对等连接上的分配，不退订带宽包。
