environment       = "demo"
location          = "eastus2"
database_location = "centralus"
region_short      = "eus2"
project_name      = "qotd"
cost_center       = "interview"

platform_state_resource_group_name  = "rg-qotd-bootstrap-eastus2"
platform_state_storage_account_name = "stqotdtfstate11"
platform_state_container_name       = "platform-dev"
platform_state_key                  = "platform-dev.tfstate"

app_plan_sku_name       = "P1mv4"
app_plan_zone_redundant = false
sql_sku_name            = "GP_S_Gen5_1"
sql_zone_redundant      = false

alert_email = "ops@qotd.local"