# terraform-volcenginecc-cloud-connect-network

基于火山引擎 Transit Router 的云连接网络 Terraform 模块，用于统一连接 VPC、专线网关和 VPN 连接。

## 1. 概述

模块创建一个 Transit Router 作为 CCN 核心，并可管理其 VPC、专线网关、VPN 和跨地域对等挂载，自定义路由表、路由表关联和路由传播、静态路由及 Transit Router 带宽包。VPC、子网、专线网关、VPN 连接和对端 Transit Router 均由调用方管理。

资源 map 的 key 同时是 Terraform 地址。修改 key 会销毁并重建其对应的挂载、路由表、路由条目或带宽包。

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

## 3. 示例

- basic：将一个已有 VPC 挂载到新的 Transit Router。
- complete：描述跨地域 VPC、专线、VPN、对等挂载、转发和传播策略、静态路由及中国大陆至亚太带宽包的组合场景。

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
| 带宽包 | `volcenginecc_transitrouter_transit_router_bandwidth_package.this` |

## 7. 输入

| 名称 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `name` | `string` | 无 | Transit Router 名称。 |
| `description` | `string` | `null` | Transit Router 描述。 |
| `asn` | `number` | `null` | 私有 BGP ASN。 |
| `project_name` | `string` | `null` | Transit Router 和带宽包所属项目。 |
| `multicast_enabled` | `bool` | `null` | 是否启用 Transit Router 组播。 |
| `tags` | `map(string)` | `{}` | 应用于全部受管资源的公共标签；资源级标签可覆盖同名 key。 |
| `vpc_attachments` | `map(object)` | `{}` | 调用方拥有的 VPC 和子网挂载定义。 |
| `direct_connect_gateway_attachments` | `map(object)` | `{}` | 调用方拥有的专线网关挂载定义。 |
| `vpn_attachments` | `map(object)` | `{}` | 调用方拥有的 VPN 连接挂载定义。 |
| `peer_attachments` | `map(object)` | `{}` | 跨地域对等挂载定义。 |
| `route_tables` | `map(object)` | `{}` | 自定义 Transit Router 路由表。 |
| `route_table_associations` | `map(object)` | `{}` | 受管路由表和挂载之间的转发关联。 |
| `route_table_propagations` | `map(object)` | `{}` | 受管路由表和挂载之间的路由学习传播。 |
| `route_entries` | `map(object)` | `{}` | 引用托管路由表和挂载的静态路由条目。 |
| `bandwidth_packages` | `map(object)` | `{}` | 包年包月跨地域带宽包。 |

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
| `bandwidth_package_ids` | 按稳定 key 输出的带宽包 ID。 |

## 9. 注意事项

- Provider 资源族名称为 `transitrouter`；本模块将其用作火山引擎 CCN 实现，不从 AWS Transit Gateway 或阿里云 CEN 推断字段。
- 对等挂载需要调用方提供对端 Transit Router 和正确的 `peer_transit_router_region_id`。跨账号对等连接必须在 apply 前完成授权与接受。分配带宽时必须同时配置 `bandwidth_package_key` 和正数 `bandwidth`。
- Provider v0.0.70 多个可选字段为 `Optional+Computed`。未指定的标量会传递 `null`，标签会显式渲染所有 key/value。真实 apply 后必须再次执行 `terraform plan`，发布验收要求显示 `No changes`。
- 路由条目仅支持 `Attachment` 和 `BlackHole` 下一跳。`Attachment` 路由必须引用本模块管理的 VPC、专线网关、VPN 或对等挂载。
- 真实云验证明细和账户级限制见 [`examples/TEST_REPORT.zh-CN.md`](examples/TEST_REPORT.zh-CN.md)。
