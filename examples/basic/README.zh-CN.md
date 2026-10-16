# 基础云连接网络示例

创建一个 Transit Router，并通过已有子网挂载一个已有 VPC。

## 1. 概述

本示例仅管理 Transit Router 和 VPC 挂载，VPC 与子网必须预先存在。

## 2. 用法

提供 `region`、`vpc_id`、`attachment_subnet_id` 和 `attachment_zone_id` 后执行：

```shell
terraform init
terraform plan
terraform apply
```

## 3. 示例

这是基础示例。

## 4. 版本要求

要求 Terraform `>= 1.5.0` 和 `volcengine/volcenginecc >= 0.0.70`。

## 5. Provider

调用方配置 `volcenginecc`。

## 6. 资源

由已发布的 cloud-connect-network 模块创建资源。

## 7. 输入

四个必填输入用于指定目标地域、VPC、子网和可用区。

## 8. 输出

示例输出 Transit Router 和 VPC 挂载 ID。

## 9. 注意事项

apply 后再次执行 `terraform plan`；验收要求无变更。仅在确认不再需要 VPC 挂载后执行 destroy。
