# Lab 01: Data Setup – The Fabric IQ Foundation

Microsoft Fabric – capacity, workspace, SQL database, and the `sm_retail` semantic model that every Mark version builds on.

## 🎯 Mission Brief

In this lab you build the data foundation for the whole Fabric track. You create a Fabric capacity and workspace, load the Contoso Retail data into a Fabric SQL database, and model it as a governed semantic model with explicit DAX measures.

That semantic model is not just a reporting artifact. In **Fabric IQ**, semantic models are the measure layer that the ontology reuses: in Lab 04 the **Generate Ontology** action turns the tables, relationships, and DAX measures you create here into ontology entity types, relationship types, and metrics. The names and descriptions you write now are what the agents read later.

## 🧭 Where this lab fits in the Fabric IQ journey

| Lab | Mark version | Fabric IQ building block | Grounding |
|---|---|---|---|
| 01 | – | Data + semantic model | `db_retail` SQL database, `sm_retail` semantic model |
| 02 | Mark v1 | Fabric data agent | Raw SQL tables |
| 03 | Mark v2 | Fabric data agent + **Prep data for AI** | Governed DAX measures |
| 04 | Mark IQ | **Ontology (preview)** + Graph + data agent | Business entities, relationships, and rules, plus governed measures |
| 05 | Mark everywhere | **Ontology MCP server** and the Copilot Studio **Fabric IQ MCP** tool | The same ontology, consumed outside Fabric |

## 🔎 Objectives

By completing this lab you will:

1. Confirm the tenant settings that the Fabric IQ labs depend on.
2. Create a Fabric capacity. Concatenate your username to `wsfbcagentic` so the name is unique.
3. Create the workspace `wsfcagentic`, also concatenated with your username.
4. Create the SQL database `db_retail` and load the data.
5. Create the semantic model `sm_retail` with relationships, explicit measures, and descriptions.

---

## 0. Before you start: tenant settings for Fabric IQ

Ask a Fabric administrator to confirm these settings in **Admin portal > Tenant settings** (also reachable from **OneLake catalog > Govern > Configurations > Tenant settings**). Checking them now avoids blocked steps in Labs 02–05.

| Setting | Needed for |
|---|---|
| **Users can create Fabric items** | All labs |
| Fabric data agent settings (Copilot and Azure OpenAI Service; cross-geo processing and storage if your capacity is outside the Azure OpenAI geographies) | Labs 02–04 |
| **Users can create ontology (preview) items** | Labs 04–05 |

See [Fabric data agent tenant settings](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings) and [Ontology tutorial: introduction and prerequisites](https://learn.microsoft.com/en-us/fabric/iq/ontology/tutorial-0-introduction).

> [!NOTE]
> Fabric data agents and ontology require an F2 or higher capacity (or Power BI Premium P1 or higher). A data agent and its data sources must be on capacities in the same region.

---

## 1. Register Microsoft.Fabric as a resource provider in the subscription

a. Open Subscription in Azure Portal

![Open subscription](images/0.1.png)

b. Register the resource in the subscription

![Register Fabric in the subscription](images/0.2.png)

## 2. Create your Microsoft Fabric capacity

a. Sign in to [Microsoft Azure](https://portal.azure.com/#home)

b. Search for the Microsoft Fabric service and select it

![Search Service](images/1.1.png)

c. Click Create a new Microsoft Fabric capacity

![Create Capacity](images/1.1.c.png)

d. Create a resource group for the Microsoft Fabric capacity

![Create Resource Group](images/1.2.png)

e. Set the configuration to be created:

i. Define the name: concatenate your username to `wsfbcagentic`. Capacity names accept only lowercase letters and numbers.
ii. Select the region. Use the same region for every item in this workshop.
iii. Change capacity size
iv. Select the capacity size. **F2** is the minimum for data agents and ontology. A larger SKU (for example F8) gives a smoother experience when several participants run agents and graph refreshes at the same time.
v. Review the configuration

![Validation](images/1.3.e.png)

f. Once the configuration is validated, proceed to create the Microsoft Fabric capacity

![Create Capacity](images/1.6.png)

g. Once the capacity creation is finished, you can go to the resource

![Explore the resource](images/1.7.png)

h. Explore the deployed Microsoft Fabric resource:

i. Start or pause the capacity. Pause it when you finish the workshop to stop billing.
ii. Change the capacity size
iii. Assign new capacity administrators

![Create Capacity](images/1.8.png)

---

## 3. Create your workspace "wsfcagentic"

a. Sign in to [Microsoft Fabric](https://app.fabric.microsoft.com/)

b. Go to the Workspaces tab and select New Workspace

![Create Capacity](images/2.1.png)

c. Specify the workspace configuration

![Create Capacity](images/2.2.png)

d. Specify the workspace type (Fabric)

![Create Capacity](images/2.3.png)

e. Select the Fabric capacity that the workspace will use. Only capacities that are turned on will appear.

![Create Capacity](images/2.4.png)

f. After completing the configuration, specify that the capacity will use the default storage format and apply the changes to create the workspace. 

For more information, see [Large semantic models in Power BI Premium](https://learn.microsoft.com/en-us/fabric/enterprise/powerbi/service-premium-large-models#enable-large-models).

> [!IMPORTANT]
> Don't use **My workspace**. Ontology items and the ontology MCP endpoint need a regular Fabric workspace.

![Create Capacity](images/2.5.png)

g. Once the workspace has been created, it should look like the following image:

![Create Capacity](images/2.6.png)

---

## 4. Create the database and load data

a. Select the option to create a new item

![New Item](images/3.1.png)

b. Filter by SQL database and select the SQL database option as shown in the image

![Search SQL Database](images/3.2.png)

c. Assign the name db_retail and create the database

![Create DB](images/3.3.png)

d. Once the database is created, you will have a new tab open that will allow you to quickly access the database. Likewise, you will be able to quickly navigate through database elements such as tables, views, stored procedures, functions, etc., through the object explorer.

![Explore DB](images/3.4.png)

e. Open a New Query tab to execute SQL scripts

![New Query](images/3.5.png)

f. To create the tables with their respective data, copy the SQL code contained in the file [CreateDatabase.sql](SQLScripts/CreateDatabase.sql) and execute it by clicking the Run option.

![Table creation and data insertion](images/3.6.png)

g. Confirm successful execution of the script

![Script executed successfully](images/3.7.png)

h. To finish adjusting the data, in the SQL Query 1 tab, replace the SQL code that was already executed in the previous step with the code from the file [UpdateDates.sql](SQLScripts/UpdateDates.sql) and execute it.

![Open SQL code execution tab](images/3.8.png)

i. After executing it, it will be shown that several rows of the SQL tables have been affected as a result. This script only shifts the order dates so the data looks recent.

> [!NOTE]
> All data in `db_retail` is synthetic. Names such as *Omar Bennett* and identifiers such as customer `CID-069` or order `F100241` are fictitious. The Fabric labs reuse them as test cases.

![Data update](images/3.9.png)

---

## 5. Create the semantic model `sm_retail`

In Microsoft Fabric, a semantic model is the business layer that gives meaning to technical data and makes it easy to analyze, reuse, and govern. Labs 03, 04, and 05 depend on it, so this section is **required**.

a. Go to the workspace

![Go to Workspace](images/sm4.a.png)

b. Open the SQL Analytics Endpoint of the db_retail database

![SQL Analytics Endpoint ](images/sm4.b.png)

c. Create a new semantic model

![New semantic model](images/sm4.c.png)

d. Configure the semantic model:

i. Name: sm_retail
ii. Corresponding workspace
iii. Tables: customer, orders, orderline, product
iv. Confirm

![Semantic model configuration](images/sm4.d.png)

e. Open the created semantic model

![Open semantic model](images/sm4.e.png)

f. Switch to edit view

![Edit view](images/sm4.f.png)

g. Create semantic model relationships:

![New relationship](images/sm.4.g.png)

Add relationship

![Edit view](images/sm4.g.1.png)

i. Customer → Orders (1:*)

![Customer → Orders](images/sm4.g.2.png)

ii. Orders → Orderline (1:*)

![Orders → Orderline](images/sm4.g.3.png)

iii. Product → Orderline (1:*)

Use `product[ProductID]` on the one side and `orderline[ProductID]` on the many side. Both columns are integers in the source database.

Keep the three relationships **active**, with **single** cross-filter direction (the one side filters the many side). In Lab 04, Generate Ontology converts these relationships into ontology relationship types.

![Product → Orderline](images/sm4.g.4.png)

h. Final result of the semantic model

![Semantic model](images/sm4.g.5.png)

i. Create custom measures

Explicit measures provide reusable business calculations for reports, Copilot, and data agents. Creating the measures in the semantic model ensures that every consumer uses the same calculation logic. In Lab 04, **Generate Ontology** carries these DAX measures into the ontology as **metrics**, so a well-named, well-described measure here becomes a well-understood business metric there.

For each measure:

1. In the semantic model edit view, select the table that will contain the measure.
2. Select **New measure** from the ribbon or the table's context menu.
3. Replace the default formula with the corresponding DAX expression below.
4. Press **Enter** to save the measure.
5. In the measure properties, add the recommended description and set its display format. Don't skip the description: data agents and the ontology use it to choose the right metric.

> [!NOTE]
> A measure's table is its organizational home; the measure can reference columns and measures from other related tables. Measure names must be unique within the model.

### Recommended custom measures

#### Product Count

- **Home table:** `product`
- **Format:** Whole number
- **Description:** Number of distinct products in the current filter context.

```DAX
Product Count =
DISTINCTCOUNT ( 'product'[ProductID] )
```

#### Customer Count

- **Home table:** `customer`
- **Format:** Whole number
- **Description:** Number of distinct customers in the current filter context.

```DAX
Customer Count =
DISTINCTCOUNT ( 'customer'[CustomerId] )
```

#### Order Count

- **Home table:** `orders`
- **Format:** Whole number
- **Description:** Number of distinct orders in the current filter context.

```DAX
Order Count =
DISTINCTCOUNT ( 'orders'[OrderId] )
```

#### Total Order Subtotal

- **Home table:** `orders`
- **Format:** Currency
- **Description:** Sum of order-header subtotals before tax.

```DAX
Total Order Subtotal =
SUM ( 'orders'[SubTotal] )
```

#### Total Order Tax

- **Home table:** `orders`
- **Format:** Currency
- **Description:** Sum of tax recorded at the order-header level.

```DAX
Total Order Tax =
SUM ( 'orders'[TaxAmount] )
```

#### Total Order Value

- **Home table:** `orders`
- **Format:** Currency
- **Description:** Sum of complete order-header values, including applicable tax and charges.

```DAX
Total Order Value =
SUM ( 'orders'[OrderTotal] )
```

#### Average Order Value

- **Home table:** `orders`
- **Format:** Currency
- **Description:** Average complete order value per distinct order.

```DAX
Average Order Value =
DIVIDE ( [Total Order Value], [Order Count] )
```

#### Total Sales

- **Home table:** `orderline`
- **Format:** Currency
- **Description:** Sum of the recorded line totals in the current filter context.

```DAX
Total Sales =
SUM ( 'orderline'[LineTotal] )
```

#### Total Quantity

- **Home table:** `orderline`
- **Format:** Decimal number
- **Description:** Total number of units recorded across order lines.

```DAX
Total Quantity =
SUM ( 'orderline'[Quantity] )
```

#### Total Discount Amount

- **Home table:** `orderline`
- **Format:** Currency
- **Description:** Total monetary value of discounts recorded at the order-line level.

```DAX
Total Discount Amount =
SUM ( 'orderline'[DiscountAmount] )
```

#### Total Tax Amount

- **Home table:** `orderline`
- **Format:** Currency
- **Description:** Total tax recorded at the order-line level.

```DAX
Total Tax Amount =
SUM ( 'orderline'[TaxAmount] )
```

#### Discount % of Sales

- **Home table:** `orderline`
- **Format:** Percentage
- **Description:** Order-line discount amount as a percentage of line sales.

```DAX
Discount % of Sales =
DIVIDE ( [Total Discount Amount], [Total Sales] )
```

#### Tax % of Sales

- **Home table:** `orderline`
- **Format:** Percentage
- **Description:** Order-line tax amount as a percentage of line sales.

```DAX
Tax % of Sales =
DIVIDE ( [Total Tax Amount], [Total Sales] )
```

`DIVIDE` is preferred over the `/` operator for ratio measures because it safely returns blank when the denominator is zero.

### Why these measures matter

| Analysis area | Measures | Business use |
|---|---|---|
| Business coverage | `Product Count`, `Customer Count`, `Order Count` | Understand catalog size, customer reach, and transaction volume. |
| Revenue and volume | `Total Sales`, `Total Order Value`, `Total Quantity` | Compare monetary performance with the number of units sold. |
| Discounts and tax | `Total Discount Amount`, `Total Tax Amount`, `Total Order Tax` | Analyze promotions, tax impact, compliance, and financial reconciliation. |
| Normalized KPIs | `Average Order Value`, `Discount % of Sales`, `Tax % of Sales` | Compare performance across periods, customers, products, and regions. |

The order-header and order-line measures intentionally represent different grains. Use measures from `orders` for order-level financial reporting and measures from `orderline` for product-level analysis. Compare `Total Order Value` with line-level totals as a reconciliation check rather than assuming that the values are interchangeable.

### Validate the measures

Before using the model with a data agent, create a simple report or use the model exploration experience to verify:

1. `Total Order Subtotal + Total Order Tax` reconciles with `Total Order Value`, according to the source data's business rules.
2. `Total Sales`, `Total Discount Amount`, and `Total Tax Amount` respond correctly to product filters.
3. `Order Count`, `Customer Count`, and `Average Order Value` respond correctly to customer and date filters.
4. Percentage measures are formatted as percentages and return blank, not an error, when sales are zero.

### Example questions for a data agent

- "Show Order Count, Customer Count, and Average Order Value by month for the last 12 months."
- "Compare Product Count and Total Quantity by product category."
- "Break down Total Sales, Total Discount Amount, and Total Tax Amount by product category."
- "Show Discount % of Sales by customer and identify the customers with the highest discount rate."
- "Compare Total Order Subtotal, Total Order Tax, and Total Order Value by region."
- "Identify months where Total Order Value increased but Average Order Value decreased."

Clear measure names and descriptions help a data agent select the correct calculation, combine metrics consistently, and explain results using the intended business meaning.

### Prepare the retail domain for Fabric IQ

Lab 04 generates the Fabric IQ ontology from this semantic model. To make that generation clean:

1. Keep the `customer`, `orders`, `orderline`, and `product` tables visible.
2. Confirm that the three relationships are active.
3. Keep the key columns `CustomerId`, `OrderId`, `OrderLineNumber`, and `ProductID`. They become ontology entity keys, which must be string or integer columns (these already are).
4. Keep the explicit DAX measures and their descriptions. They become ontology metrics, and `sm_retail` remains the governed source for every monetary calculation.
5. Confirm that you have **Read** and **Build** permissions on `sm_retail`. Generate Ontology requires both.

---

## Mission Complete

Your Fabric IQ foundation is ready: a SQL database with the transactional facts and a semantic model with governed relationships and measures. Next, create Mark v1 in [Lab 02](lab02-mark-facts-agent.en.md).
