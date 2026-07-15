environment       = "prod"
location          = "eastus2"
database_location = "centralus"
region_short      = "eus2"
project_name      = "qotd"
cost_center       = "interview"

platform_state_resource_group_name  = "rg-qotd-bootstrap-eastus2"
platform_state_storage_account_name = "stqotdtfstate11"
platform_state_container_name       = "platform-prod"
platform_state_key                  = "platform-prod.tfstate"

app_plan_sku_name         = "P1v2"
app_plan_zone_redundant   = false #should be true
app_plan_enable_autoscale = true
sql_sku_name              = "GP_Gen5_2"
sql_zone_redundant        = true

alert_email = "ops@qotd.local"
