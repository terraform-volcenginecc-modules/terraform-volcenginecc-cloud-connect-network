# 云连接网络真实云测试报告

## 结论

`basic` 场景已在真实云完成 `plan -> apply -> 二次 plan -> destroy` 全流程，VPC 挂载和 Transit Router 状态均为 `Available`，二次 plan 返回 `No changes`，destroy 后通过两地域的云端列表查询确认测试 VPC 和 Transit Router 均不存在。

`complete` 的无跨境带宽包子场景已在真实云完成 `plan -> apply -> 二次 plan -> destroy` 全流程。两个地域的 Transit Router、VPC、子网、VPC 挂载、路由表、路由表关联和传播、北京到新加坡的对等挂载及静态路由均创建成功；二次 plan 返回 `No changes`。最终资源分两次串行销毁（服务端状态收敛期间首次删除部分路由表返回短暂冲突），随后通过两地域 Transit Router 列表数据源确认测试资源已不存在。

## 验证环境

| 项目 | 值 |
|---|---|
| 执行日期 | 2026-10-16 |
| Terraform | `1.5.7` |
| Provider | 在线 `volcengine/volcenginecc` `0.0.72` |
| Provider 覆盖 | `TF_CLI_CONFIG_FILE=/dev/null`，未使用本地开发覆盖 |
| 凭据 | 仅通过 `VOLCENGINE_ACCESS_KEY`、`VOLCENGINE_SECRET_KEY`、`VOLCENGINE_SESSION_TOKEN` 环境变量传入；未写入仓库、日志或报告 |
| 测试地域 | `cn-beijing`、`ap-southeast-1` |
| 测试资源隔离 | 新建 VPC、子网及带 `ManagedBy=terraform-real-cloud-validation` 标签的 Transit Router 资源 |
| 执行方式 | 临时隔离夹具引用当前工作区根模块；未直接执行示例目录，因为其 `source` 指向尚未发布的 Registry 模块，且 complete 需要调用方提供既有专线网关、VPN 和对端 Transit Router |

## 验证对象

| 场景 | 覆盖对象 |
|---|---|
| `examples/basic` | VPC、子网、Transit Router、VPC 挂载 |
| `examples/complete` | 北京/新加坡 VPC 与子网、两地 Transit Router、VPC 挂载、自定义路由表、路由表关联、路由传播、跨地域对等挂载、跨境带宽包、静态路由 |

## 已执行验证

| 验证项 | 结果 | 证据 | 结论 |
|---|---|---|---|
| basic 初次 plan | 通过 | `Plan: 4 to add, 0 to change, 0 to destroy.` | 配置可由在线 Provider 解析和规划。 |
| basic apply | 通过 | `Apply complete! Resources: 4 added, 0 changed, 0 destroyed.` | 隔离 VPC、子网、Transit Router 和 VPC 挂载已创建。 |
| basic 网络实例状态 | 通过 | Transit Router 与 VPC 挂载均返回 `Available`。 | CCN 核心和网络实例关联可用。 |
| basic 二次 plan | 通过 | `No changes. Your infrastructure matches the configuration.` | 无漂移。 |
| basic destroy | 通过 | `Destroy complete! Resources: 4 destroyed.` | 挂载先于 Transit Router、子网和 VPC 删除。 |
| basic 删除后查询 | 通过 | 北京列表中未发现 `vpc-1a1jbejd1aha88nvepjojheie` 或 `tr-yg0oyqql76rk41kxofa6rzs1`。 | 测试资源已彻底移除。 |
| complete 初次 plan（含跨境带宽包） | 通过 | `Plan: 19 to add, 0 to change, 0 to destroy.` | 两地域资源、带宽包、对等挂载、路由发布/学习和静态路由均可规划。 |
| complete 跨境带宽包 | 阻断 | `Forbidden.CreateCrossBorderBandwidthPackage: You can not create cross border bandwidth package due to have not passed cross-border audit yet.` | 账号未通过跨境带宽审核，无法验证带宽分配。 |
| complete 无带宽包初次 plan | 通过 | `Plan: 18 to add, 0 to change, 0 to destroy.` | 无带宽包对等挂载、两地路由策略与静态路由可由在线 Provider 规划。 |
| complete 无带宽包首次 apply | 部分通过 | 对等挂载创建成功，`bandwidth = 0`、状态 `Available`；对等路由传播因两侧默认 ASN 均为 `64512` 被拒绝。 | 对等 Transit Router 的 ASN 必须不同。 |
| complete 无带宽包完整 apply | 通过 | 新加坡 Transit Router 显式 ASN `64513` 后，`Apply complete! Resources: 18 added, 0 changed, 0 destroyed.` | 两地 VPC 挂载、路由表、关联、传播、对等挂载及北京静态路由均创建成功。 |
| complete 无带宽包二次 plan | 通过 | `No changes. Your infrastructure matches the configuration.` | 无配置漂移。 |
| complete 无带宽包 destroy | 通过 | 两次串行 destroy 后分别返回 `Destroy complete! Resources: 7 destroyed.` | 服务端状态收敛导致首次删除部分资源短暂冲突，重试后全部清理。 |
| complete 无带宽包删除后查询 | 通过 | 两地域 `volcenginecc_transitrouter_transit_routers` 列表查询未包含最终测试 Transit Router。 | 测试 Transit Router 已彻底移除。 |
| 跨账号授权 | 未覆盖 | 仅提供了一个账号的凭据。 | 需第二个已授权账号和已接受的共享关系后验证。 |

## 命令输出

### basic

```text
$ terraform init -upgrade
Terraform has been successfully initialized!

$ terraform plan -out=initial.tfplan
Plan: 4 to add, 0 to change, 0 to destroy.

$ terraform apply -auto-approve initial.tfplan
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
Outputs:
transit_router_id = "tr-yg0oyqql76rk41kxofa6rzs1"
vpc_attachment_ids = {
  "workload" = "tr-attach-3sogha7df66tc686nhu5vlrd7"
}

$ terraform plan -detailed-exitcode
No changes. Your infrastructure matches the configuration.

$ terraform destroy -auto-approve -parallelism=1
Destroy complete! Resources: 4 destroyed.
```

### complete

```text
$ terraform init -upgrade
Terraform has been successfully initialized!

$ terraform plan -out=initial.tfplan
Plan: 19 to add, 0 to change, 0 to destroy.

$ terraform apply -auto-approve initial.tfplan
Error: QuotaExceeded.TransitRouter:
You've reached the maximum number of transit routers that one account can have.

Error: Forbidden.CreateCrossBorderBandwidthPackage:
You can not create cross border bandwidth package due to have not passed
cross-border audit yet.

$ terraform destroy -auto-approve -parallelism=1
Destroy complete! Resources: 6 destroyed.

$ cloud list-query assertion
true
```

### complete（跳过跨境带宽包）

```text
$ terraform plan -out=initial.tfplan
Plan: 18 to add, 0 to change, 0 to destroy.

$ terraform apply -auto-approve -parallelism=1 initial.tfplan
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

$ terraform plan -detailed-exitcode
No changes. Your infrastructure matches the configuration.

$ terraform destroy -auto-approve -parallelism=1
Destroy complete! Resources: 7 destroyed.

$ terraform plan -chdir=.real-cloud-validation/deletion-verification
No changes. Your infrastructure matches the configuration.
```

## 未完成项与限制

1. 跨境带宽包及其带宽分配仍未验证，账号尚未通过跨境审核；本次对等挂载以服务端返回的 `bandwidth = 0` 验证控制面能力。
2. 未创建 ECS 或执行 ICMP/TCP 探测；本次仅验证控制面资源状态和 Terraform 无漂移。数据面探测需在两地实例和安全组规则准备完成后补充。
3. 单账号凭据无法覆盖跨账号授权、接受与撤销流程。

## 后续动作

1. 完成跨境带宽包审核后，补充带宽包创建、带宽分配和带宽计费项验证。
2. 准备第二个账号的对等 Transit Router，完成资源授权和接受。
3. 在两地 VPC 部署测试 ECS，验证双向路由、连通性和 VPC 路由表自动发布；保留命令输出作为数据面证据。

## 成功测试参数

以下参数用于复现已通过的 `complete` 无跨境带宽包控制面验证；不包含凭据、会话令牌或已销毁资源 ID。

```hcl
terraform {
  required_version = "= 1.5.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "0.0.72"
    }
  }
}

provider "volcenginecc" {
  alias  = "beijing"
  region = "cn-beijing"
}

provider "volcenginecc" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

# 调用方创建的隔离 VPC 和挂载子网。
resource "volcenginecc_vpc_vpc" "beijing" {
  provider   = volcenginecc.beijing
  cidr_block = "10.248.0.0/16"
  vpc_name   = "tf-ccn-no-bandwidth-bj"
}

resource "volcenginecc_vpc_subnet" "beijing" {
  provider    = volcenginecc.beijing
  vpc_id      = volcenginecc_vpc_vpc.beijing.vpc_id
  zone_id     = "cn-beijing-a"
  cidr_block  = "10.248.1.0/24"
  subnet_name = "tf-ccn-no-bandwidth-bj-a"
}

resource "volcenginecc_vpc_vpc" "singapore" {
  provider   = volcenginecc.singapore
  cidr_block = "10.249.0.0/16"
  vpc_name   = "tf-ccn-no-bandwidth-sg"
}

resource "volcenginecc_vpc_subnet" "singapore" {
  provider    = volcenginecc.singapore
  vpc_id      = volcenginecc_vpc_vpc.singapore.vpc_id
  zone_id     = "ap-southeast-1a"
  cidr_block  = "10.249.1.0/24"
  subnet_name = "tf-ccn-no-bandwidth-sg-a"
}

module "singapore" {
  source = "../.."

  providers = {
    volcenginecc = volcenginecc.singapore
  }

  name = "tf-ccn-no-bandwidth-sg"
  asn  = 64513

  vpc_attachments = {
    workload = {
      vpc_id = volcenginecc_vpc_vpc.singapore.vpc_id
      attach_points = [{
        subnet_id = volcenginecc_vpc_subnet.singapore.subnet_id
        zone_id   = "ap-southeast-1a"
      }]
      name = "tf-ccn-no-bandwidth-sg-vpc"
    }
  }

  route_tables = {
    workload = {
      name = "tf-ccn-no-bandwidth-sg-rt"
    }
  }

  route_table_associations = {
    workload = {
      route_table_key = "workload"
      attachment_key  = "workload"
    }
  }

  route_table_propagations = {
    workload = {
      route_table_key = "workload"
      attachment_key  = "workload"
    }
  }
}

module "beijing" {
  source = "../.."

  providers = {
    volcenginecc = volcenginecc.beijing
  }

  name = "tf-ccn-no-bandwidth-bj"
  asn  = 64512

  vpc_attachments = {
    workload = {
      vpc_id = volcenginecc_vpc_vpc.beijing.vpc_id
      attach_points = [{
        subnet_id = volcenginecc_vpc_subnet.beijing.subnet_id
        zone_id   = "cn-beijing-a"
      }]
      name = "tf-ccn-no-bandwidth-bj-vpc"
    }
  }

  route_tables = {
    workload = {
      name = "tf-ccn-no-bandwidth-bj-rt"
    }
  }

  peer_attachments = {
    singapore = {
      peer_transit_router_id        = module.singapore.transit_router_id
      peer_transit_router_region_id = "ap-southeast-1"
      name                          = "tf-ccn-no-bandwidth-bj-sg"
      # 不设置 bandwidth_package_key 或 bandwidth。
    }
  }

  route_table_associations = {
    workload = {
      route_table_key = "workload"
      attachment_key  = "workload"
    }
    singapore = {
      route_table_key = "workload"
      attachment_key  = "singapore"
    }
  }

  route_table_propagations = {
    workload = {
      route_table_key = "workload"
      attachment_key  = "workload"
    }
    singapore = {
      route_table_key = "workload"
      attachment_key  = "singapore"
    }
  }

  route_entries = {
    singapore-vpc = {
      route_table_key         = "workload"
      destination_cidr_block  = "10.249.0.0/16"
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "singapore"
      name                    = "tf-ccn-no-bandwidth-to-sg"
    }
  }

  tags = {
    ManagedBy = "terraform-real-cloud-validation"
    Scenario  = "complete-no-bandwidth"
  }
}
```

执行时设置 `TF_CLI_CONFIG_FILE=/dev/null`，确保使用在线 Provider 而非本地开发覆盖。
