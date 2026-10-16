# 完整云连接网络示例

描述跨地域 VPC、对等挂载、带宽包、转发和路由学习策略、专线网关及 VPN 连接的统一互联场景。

## 1. 概述

本示例仅管理本端 Transit Router 拓扑，两个 VPC、挂载子网、专线网关、VPN 连接和远端对等 Transit Router 均为外部依赖。

## 2. 用法

提供所有已有网络依赖的 ID 与可用区后执行：

```shell
terraform init
terraform plan
terraform apply
```

## 3. 示例

这是集团网络完整示例，覆盖跨地域 VPC、专线接入、VPN 容灾和中国大陆至亚太的对等连接。

## 4. 版本要求

要求 Terraform `>= 1.5.0` 和 `volcengine/volcenginecc >= 0.0.70`。

## 5. Provider

调用方配置 `volcenginecc`。

## 6. 资源

由已发布的 cloud-connect-network 模块创建 Transit Router 资源。

## 7. 输入

输入用于指定已有 VPC、挂载子网、专线网关、VPN 连接、远端对等 Transit Router、可达远端 CIDR 及其可用区。

## 8. 输出

示例输出 Transit Router、挂载、路由表、转发关联、路由传播和带宽包 ID。

## 9. 注意事项

对端 Transit Router 必须位于配置的远端地域。跨账号对等连接需要在 apply 前完成授权与接受；创建中国大陆至亚太带宽包还需要账号通过跨境带宽审核。apply 后再次执行 `terraform plan`；验收要求无变更。
