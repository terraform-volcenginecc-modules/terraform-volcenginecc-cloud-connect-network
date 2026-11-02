# terraform-volcenginecc-cloud-connect-network

基于火山引擎 Transit Router 的云连接网络 Terraform 模块，用于统一连接 VPC、专线网关和 VPN 连接。

## 1. 概述

模块创建一个 Transit Router 作为云连接核心，并可管理其 VPC、专线网关、VPN 和跨地域对等挂载，以及自定义路由表、路由表关联、路由传播和静态路由。VPC、子网、专线网关、VPN 连接、对端 Transit Router 和带宽包均由调用方管理。

资源 map 的 key 同时是 Terraform 地址。修改 key 会销毁并重建对应的挂载、路由表或路由条目。

## 2. 用法

### 2.1 基础用法

```hcl
module "cloud_connect_network" {
  source  = "terraform-volcenginecc-modules/cloud-connect-network/volcenginecc"
  version = "~> 1.0"

  name = "group-ccn"

  vpc_attachments = {
    application = {
      vpc_id = "vpc-xxxxxxxx"
      attach_points = [{
        subnet_id = "subnet-xxxxxxxx"
        zone_id   = "cn-beijing-a"
      }]
    }
  }
}
```

Provider 凭据和地域由调用方配置，不要在模块配置中写入访问密钥。

跨地域连接必须明确提供已有远端 TR 及其地域：

```hcl
peer_attachments = {
  remote = {
    peer_transit_router_id        = "tr-xxxxxxxx"
    peer_transit_router_region_id = "ap-southeast-1"
  }
}
```

## 3. 示例

- basic：将一个已有 VPC 挂载到新的 Transit Router。
- complete：连接两个本端 VPC 和一个已有远端 TR，可选专线、VPN 和对等带宽。远端业务网络由调用方管理，对等连接仅支持同账号场景。

## 4. 版本要求

| 名称 | 版本 |
|---|---|
| Terraform | `>= 1.5.0` |
| `volcengine/volcenginecc` | `>= 0.0.70` |

## 5. Provider

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. 资源

| 类型 | 名称 |
|---|---|
| Transit Router | `volcenginecc_transitrouter_transit_router.this` |
| VPC 挂载 | `volcenginecc_transitrouter_vpc_attachment.this` |
| 专线挂载 | `volcenginecc_transitrouter_direct_connect_gateway_attachment.this` |
| VPN 挂载 | `volcenginecc_transitrouter_vpn_attachment.this` |
| 对等挂载 | `volcenginecc_transitrouter_peer_attachment.this` |
| 路由表 | `volcenginecc_transitrouter_transit_router_route_table.this` |
| 路由表关联 | `volcenginecc_transitrouter_transit_router_attachment_to_route_table.this` |
| 路由表传播 | `volcenginecc_transitrouter_route_table_propagation.this` |
| 路由条目 | `volcenginecc_transitrouter_transit_router_route_entry.this` |

## 7. 输入

| 名称 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `name` | `string` | 无 | Transit Router 名称。 |
| `description` | `string` | `null` | Transit Router 描述。 |
| `project_name` | `string` | `null` | Transit Router 所属项目。 |
| `multicast_enabled` | `bool` | `null` | 是否启用 Transit Router 组播。 |
| `tags` | `map(string)` | `{}` | 应用于全部受管资源的公共标签；资源级标签可覆盖同名 key。 |
| `vpc_attachments` | `map(object)` | `{}` | 调用方拥有的 VPC 和子网挂载定义。 |
| `direct_connect_gateway_attachments` | `map(object)` | `{}` | 调用方拥有的专线网关挂载定义。 |
| `vpn_attachments` | `map(object)` | `{}` | 调用方拥有的 VPN 连接挂载定义。 |
| `peer_attachments` | `map(object)` | `{}` | 跨地域对等挂载；每项必须提供远端 TR ID 和远端地域。 |
| `route_tables` | `map(object)` | `{}` | 自定义 Transit Router 路由表。 |
| `route_table_associations` | `map(object)` | `{}` | 受管路由表和挂载之间的转发关联。 |
| `route_table_propagations` | `map(object)` | `{}` | 受管路由表和挂载之间的路由学习传播。 |
| `route_entries` | `map(object)` | `{}` | 引用托管路由表和挂载的静态路由条目。 |

## 8. 输出

| 名称 | 说明 |
|---|---|
| `transit_router_id` | Transit Router ID。 |
| `vpc_attachment_ids` | 按稳定 key 输出的 VPC 挂载 ID。 |
| `direct_connect_gateway_attachment_ids` | 按稳定 key 输出的专线挂载 ID。 |
| `vpn_attachment_ids` | 按稳定 key 输出的 VPN 挂载 ID。 |
| `peer_attachment_ids` | 按稳定 key 输出的跨地域对等挂载 ID。 |
| `route_table_ids` | 按稳定 key 输出的自定义路由表 ID。 |
| `route_table_association_ids` | 按稳定 key 输出的路由表关联 ID。 |
| `route_table_propagation_ids` | 按稳定 key 输出的路由表传播 ID。 |
| `route_entry_ids` | 按稳定 key 输出的静态路由条目 ID。 |

## 9. 注意事项

- 模块通过火山引擎 Transit Router 资源创建和管理网络拓扑。
- 对等挂载需要已有对端 Transit Router 和正确的 `peer_transit_router_region_id`，暂不支持跨账号对等连接。
- 模块不创建、修改、打标签或删除带宽包。需要分配跨地域带宽时，同时填写调用方已有的 `bandwidth_package_id` 和正整数 `bandwidth`；两项都省略时只创建零带宽控制面连接。
- Apply 前须确认外部带宽包状态为 Available、覆盖两端地域且剩余容量充足。complete 只暴露 `bandwidth_package_id` 和 `peer_bandwidth` 两项分配配置。
- 这是一次破坏性接口调整。旧 State 如果包含模块创建的带宽包，升级前应先将旧资源地址移出 Terraform State；否则 Terraform 会计划删除该预付费包，而云端普通删除接口会拒绝。
- VPC 互通需要 TR 关联、路由学习和 VPC 回程路由。`auto_publish_route_enabled = true` 将 TR 路由发布到 VPC；默认学习按子网粒度，不代表整个 VPC 网段都可达。
- VPN 推荐使用独立 `route_table_associations`。旧 `route_table_key` 保留兼容，但禁止与独立关联重复管理同一个挂载。静态 VPN 的对端网段使用 `route_entries`，不直接配置通用路由学习。
- Apply 和 Destroy 建议使用 `-parallelism=1`，确保同一个 Transit Router 的相关操作串行执行。
- 路由条目仅支持 `Attachment` 和 `BlackHole` 下一跳。`Attachment` 路由必须引用本模块管理的 VPC、专线网关、VPN 或对等挂载。
