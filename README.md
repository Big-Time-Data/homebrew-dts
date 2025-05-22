# Data Tools Suite (DTS)

A comprehensive CLI tool by Big-Time-Data that helps with data management, testing, and baseline operations for data teams.

## Installation

```bash
# Install the dts CLI
brew install Big-Time-Data/dts/dts
```

## Basic Usage

```bash
# Get help on available commands
dts --help

# Run specific commands
dts diff my_model --filter prod_sample
dts clone my_model --from prod --to dev
```

## Commands

### diff

Compare data between environments (typically prod vs dev).

```bash
dts diff [model] [flags]
```

Flags:
- `--config` - The config file path
- `--filter` - Filter name to use from config file
- `--print-results` - Whether to print the diff results
- `--debug` - Set to debug level

Example:
```bash
dts diff my_model --filter last_7_days
```

### clone

Clone data from one environment to another (defaults 'prod' to 'dev').

```bash
dts clone [models...] [flags]
```

Flags:
- `--exclude` - Space-separated list of items to exclude
- `--dry-run` - Run without making changes
- `--print` - Print DBT logs

Example:
```bash
dts clone my_model another_model --dry-run
```

### gen

Generate code and utilities.

#### Staging Tables

Generate staging tables from source schema.

```bash
dts gen staging-tables [flags]
```

Flags:
- `--target` - DBT target to use
- `--source-schema` - Source schema to generate models for (required)
- `--source-name` - Source name for the DBT source (defaults to source schema name)
- `--model-schema` - Schema for the generated models (default "staging")
- `--staging-path` - Path to the staging models folder (required)
- `--tables` - Specific tables to generate models for (empty means all tables)
- `--dry-run` - Run without making changes
- `--print` - Print DBT logs
- `--config` - Path to the DTS config file

Example:
```bash
dts gen staging-tables --source-schema raw_data --staging-path models/staging
```

#### Drop Stale Models

Generate drop commands for stale models.

```bash
dts gen drop-stale-models [flags]
```

Flags:
- `--profile` - DBT profile to use
- `--target` - DBT target to use
- `--schemas` - Specific schemas to check for stale models
- `--dry-run` - Run without making changes
- `--print` - Print DBT logs
- `--config` - Path to the config file

Example:
```bash
dts gen drop-stale-models --schemas staging,intermediate --dry-run
```

#### Snowflake Key Pair

Generate key pair for Snowflake with ALTER USER statement.

```bash
dts gen snowflake-key-pair [user] [flags]
```

Flags:
- `--passphrase` - Passphrase for encrypting the private key (optional)
- `--config` - Path to the config file

Example:
```bash
dts gen snowflake-key-pair john_smith --passphrase my_secure_passphrase
```

### mcp

Start the MCP server for tool calls.

```bash
dts mcp
```

## Configuration

DTS uses a configuration file (typically `dts_config.yaml`) to store settings for environments, targets, and filters.

Example config:
```yaml
dbt_project: /path/to/project

tests:
  - name: sample_test
    description: This is an example test
    selects: []  # the dbt model selectors to include
    excludes: [] # the dbt model selectors for excluding
    filters: [ test_orders ]

  - name: another_sample_test
    description: This is another example test
    selects: [ 4+stripe_subscription_arr ]  # the dbt model selectors to include
    excludes: [] # the dbt model selectors for excluding
    filters: [ enterprise_customers ]

targets:
  prod: prod  # defaults to "prod"
  dev: dev    # defaults to "dev"


# manual mapping of models to dev/prod full table names, also unique key
model_defs:
  stripe_subscription_arr:
    dev: ANALYTICS_DEV.DBT_FRITZ.STRIPE_SUBSCRIPTION_ARR
    prod: ANALYTICS.FINANCE.STRIPE_SUBSCRIPTION_ARR
    columns: [ col1, col2 ] # only include specific columns 
    key: [customer_id]
  stripe_subscription_arr2:
    dev: ANALYTICS_DEV.DBT_FRITZ.STRIPE_SUBSCRIPTION_ARR
    prod: ANALYTICS.FINANCE.STRIPE_SUBSCRIPTION_ARR
    columns: [ -col1, -col2 ] # exclude specific columns (with prefix '-')
    key: [customer_id]

# reusable filters
filters:
  
  test_orders:
     - column: order_id
       values: [ 1002 ]
  
  test_range:
     - column: order_date
       range: [ '2025-01-01', '2025-03-01' ]
  
  test_expression:
     - expression: "{table}.CODE > 5000"

  enterprise_customers:
    - column: stripe_customer_id
      values: [ xxxxxxxxxx, xxxxxxxxxxxx ]
      models_map:
        stg__stripe_customers: id

global:
  output_schema: ANALYTICS_DEV.DBT_FRITZ
  filters_use_and: true
```

## Use Cases

1. **Testing Data Models**
   - Compare production vs. development environments
   - Validate that changes maintain data integrity

2. **Data Cloning**
   - Copy production data to development environment for testing
   - Clone specific models without copying entire database

3. **Code Generation**
   - Generate staging models from source schemas
   - Identify and clean up stale database objects

## Advanced Usage with MCP

The MCP (Model Context Protocol) server allows programmatic interaction with DTS:

```bash
# Start the MCP server
dts mcp
```

This enables tool-based workflows and integration with AI assistants.
